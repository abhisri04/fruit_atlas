"""Bounded, review-first, source-neutral dish photo validation batch."""
import argparse
import dish_image_review as human
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib
import html
import io
import json
import os
from pathlib import Path
import sys
from PIL import Image, ImageOps
import download_dish_images_pexels as common
from dish_image_sources import ACTIVE_ADAPTERS, download_pixabay_image, trusted_url

ROOT = common.ROOT
BATCH = ROOT / 'docs/image_sources/dishes/pixabay_validation_batch.json'
REPORTS = ROOT / 'docs/image_sources/dishes/pixabay_30'
WORK = ROOT / '.dish_pixabay_work'
APPROVALS = ROOT / 'docs/image_sources/dishes/dish_image_approvals.csv'
ALIASES = ROOT / 'docs/image_sources/dishes/image_search_aliases.json'


def prepare():
    manifest = common.initialize()
    batch = common.read_json(BATCH, {})['dishes']
    if len(batch) != 30 or Counter(r['group'] for r in batch) != {'common': 20, 'obscure': 10} or len({r['dishId'] for r in batch}) != 30:
        raise ValueError('Validation batch must contain exactly 20 common and 10 obscure unique dishes')
    dishes = {r['id']: r for r in common.canonical()}
    rows = {r['dishId']: r for r in manifest['items']}
    for item in batch:
        dish = dishes[item['dishId']]
        row = rows[item['dishId']]
        state = row.setdefault('sourceRuns', {}).setdefault('pixabay', {})
        aliases = common.read_json(ALIASES, {}).get(dish['id'], [])
        state['imageSearchAliases'] = aliases
        state['queries'] = human.queries(dish, aliases)
        state.setdefault('completedQueries', [])
        state.setdefault('candidates', [])
        state.setdefault('status', 'pending_review')
        state.setdefault('reviewStatus', 'pending')
        if state['status'] not in {'pixabay_approved', 'reviewed_high'}:
            state['status'] = 'unresolved' if state['reviewStatus'] == 'none_correct' else 'pending_review'
        state.setdefault('confidence', 'UNRESOLVED')
        state['batchGroup'] = item['group']
    manifest.update(schemaVersion=2, activeSource='pixabay', source='multi_source',
                    selectionPolicy=human.SOURCE_PRIORITY + ['placeholder'])
    common.atomic_json(common.MANIFEST, manifest)
    return manifest, batch, dishes


def selected_rows(manifest, batch):
    rows = {r['dishId']: r for r in manifest['items']}
    return [rows[item['dishId']] for item in batch]


def discover(manifest, batch, dishes, key):
    adapter = ACTIVE_ADAPTERS['pixabay'](key, WORK)
    for row in selected_rows(manifest, batch):
        state = row['sourceRuns']['pixabay']
        if state['status'] in {'reviewed_high', 'pixabay_approved'} or (ROOT / row['expectedImageFile']).exists():
            continue
        for query in state['queries']:
            if query in state['completedQueries']:
                continue
            hits = adapter.search(query)
            candidates = {c['sourceId']: c for c in state['candidates']}
            for hit in hits:
                dish = dict(dishes[row['dishId']])
                dish['aliases'] = dish.get('aliases', []) + state.get('imageSearchAliases', [])
                choice = adapter.candidate(hit, dish, query)
                if choice['sourceId'] not in candidates or choice['score'] > candidates[choice['sourceId']]['score']:
                    candidates[choice['sourceId']] = choice
            state['candidates'] = sorted(candidates.values(), key=lambda c: c['score'], reverse=True)
            state['completedQueries'].append(query)
            state.update(status='pending_review',
                         confidence='MEDIUM' if any(c['confidence'] == 'MEDIUM' for c in candidates.values()) else 'LOW' if candidates else 'UNRESOLVED')
            common.atomic_json(common.MANIFEST, manifest)
        if not human.candidates(state):
            state.update(status='unresolved', confidence='UNRESOLVED')
        common.atomic_json(common.MANIFEST, manifest)


def duplicate_assignments(manifest):
    groups = defaultdict(list)
    for row in manifest['items']:
        for source, state in row.get('sourceRuns', {}).items():
            if state.get('selectedSourceId'):
                groups[(source, state['selectedSourceId'])].append(row['dishId'])
    return [dict(source=key[0], sourceId=key[1], dishIds=';'.join(ids)) for key, ids in groups.items() if len(ids) > 1]


def refresh(manifest, batch, dishes, key):
    adapter = ACTIVE_ADAPTERS['pixabay'](key, WORK)
    for row in selected_rows(manifest, batch):
        state = row['sourceRuns']['pixabay']
        selected = state.get('selectedSourceId')
        if not selected or state['status'] == 'pixabay_approved':
            continue
        hits = adapter.get_photo(selected)
        hit = next((hit for hit in hits if str(hit['id']) == selected), None)
        if not hit:
            raise common.StopRun('Selected photo is no longer available; review another candidate')
        previous = next(c for c in state['candidates'] if c['sourceId'] == selected)
        updated = adapter.candidate(hit, dishes[row['dishId']], previous['searchQueryUsed'])
        state['candidates'] = [updated if c['sourceId'] == selected else c for c in state['candidates']]
        if updated['flags']:
            state.update(status='needs_review', confidence='LOW', visualReviewed=False)
        common.atomic_json(common.MANIFEST, manifest)


def finalize(manifest, batch):
    if duplicate_assignments(manifest):
        raise common.StopRun('Duplicate selections blocked; see review report')
    for row in selected_rows(manifest, batch):
        state = row['sourceRuns']['pixabay']
        if state['status'] != 'reviewed_high' or state.get('reviewStatus') != 'approved':
            continue
        target = ROOT / row['expectedImageFile']
        if target.exists():
            if state.get('sha256') == hashlib.sha256(target.read_bytes()).hexdigest():
                state['status'] = 'pixabay_approved'
                row.update(state['exportMetadata'], status='pixabay_approved')
                common.atomic_json(common.MANIFEST, manifest)
                continue
            raise common.StopRun('Existing image protected; no overwrite')
        choice = next(c for c in state['candidates'] if c['sourceId'] == state['selectedSourceId'])
        if not state.get('visualReviewed') or choice['flags'] or not trusted_url(choice['downloadUrl']):
            raise common.StopRun('Approval/source validation failed')
        try:
            raw = download_pixabay_image(choice['downloadUrl'])
            if len(raw) > 25 * 1024 * 1024:
                raise common.StopRun('Source exceeds download budget')
            with Image.open(io.BytesIO(raw)) as image:
                image.load()
                image = ImageOps.exif_transpose(image).convert('RGB')
                image.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
                if max(image.size) < 1200 or min(image.size) < 600:
                    raise common.StopRun('Returned source too small; never upscale')
                output = io.BytesIO()
                image.save(output, format='WEBP', quality=85, method=6)
                encoded = output.getvalue()
                size = image.size
        except (OSError, ValueError):
            raise common.StopRun('Image download/encoding failed. URL may have expired; checkpoint retained.') from None
        metadata = {key: choice[key] for key in ['source', 'sourceId', 'pixabayImageId', 'pageUrl', 'creator', 'creatorPageUrl', 'licenseReference', 'originalWidth', 'originalHeight', 'searchQueryUsed']}
        metadata.update(imageFile=row['expectedImageFile'], downloadedSourceUrl=choice['downloadUrl'],
                        downloadDate=datetime.now(timezone.utc).isoformat(), outputWidth=size[0], outputHeight=size[1], outputBytes=len(encoded),
                        confidence='HIGH', notes=state['notes'], sha256=hashlib.sha256(encoded).hexdigest())
        state.update(exportMetadata=metadata, sha256=metadata['sha256'])
        common.atomic_json(common.MANIFEST, manifest)
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as file:
            file.write(encoded)
        state['status'] = 'pixabay_approved'
        row.update(metadata, status='pixabay_approved')
        common.atomic_json(common.MANIFEST, manifest)


def reports(manifest, batch):
    return human.reports(manifest, batch, ROOT, REPORTS, APPROVALS, duplicate_assignments(manifest))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['diagnose', 'init', 'discover', 'approve', 'refresh', 'finalize', 'reports', 'validate'])
    parser.add_argument('--source', choices=['pixabay'], default='pixabay')
    parser.add_argument('--approvals', type=Path)
    parser.add_argument('--approved-only', action='store_true', help='Finalize only explicit human CSV approvals')
    parser.add_argument('--quality-approved', action='store_true', help='Explicit permission to export visually reviewed selections from this batch only')
    args = parser.parse_args()
    if args.command == 'diagnose':
        key = os.environ.get('PIXABAY_API_KEY', '').strip()
        if not key:
            print('PIXABAY_API_KEY is not available to this Python process. No request made.')
            return 2
        try:
            ACTIVE_ADAPTERS['pixabay'](key, WORK).diagnose()
            return 0
        except common.StopRun as error:
            print(str(error))
            return 2
    manifest, batch, dishes = prepare()
    result = 0
    try:
        key = os.environ.get('PIXABAY_API_KEY', '').strip()
        if args.command in {'discover', 'refresh'} and not key:
            raise common.StopRun('PIXABAY_API_KEY unavailable. No searches/downloads attempted. Set it and resume the 30-dish batch.')
        if args.command == 'discover':
            discover(manifest, batch, dishes, key)
        elif args.command == 'refresh':
            refresh(manifest, batch, dishes, key)
        elif args.command == 'approve':
            if not args.approvals:
                raise ValueError('--approvals is required')
            human.load_approvals(args.approvals, selected_rows(manifest, batch))
            common.atomic_json(common.MANIFEST, manifest)
        elif args.command == 'finalize':
            if not args.approved_only:
                raise common.StopRun('--approved-only required. No unreviewed images can be exported.')
            human.load_approvals(args.approvals or APPROVALS, selected_rows(manifest, batch))
            common.atomic_json(common.MANIFEST, manifest)
            finalize(manifest, batch)
        elif args.command == 'validate':
            errors = common.validate(manifest)
            if duplicate_assignments(manifest):
                errors.append('Duplicate source-scoped photo assignments')
            if errors:
                raise ValueError('; '.join(errors))
    except common.StopRun as error:
        print(str(error))
        result = 2
    finally:
        print(json.dumps(reports(manifest, batch), indent=2))
    return result


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError):
        print('Pipeline validation failed; inspect canonical IDs, batch file and review selections. No credentials logged.', file=sys.stderr)
        sys.exit(1)
