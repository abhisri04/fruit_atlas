"""Official-API-only, checkpointed Pexels dish discovery and reviewed WebP export.

No metadata-only candidate is silently treated as a visually verified dish.
Credentials are read from PEXELS_API_KEY and are never saved or printed.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
from datetime import datetime, timezone
import hashlib
import html
import io
import json
import os
from pathlib import Path
import re
import sys
import time
import unicodedata
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlparse
from urllib.request import Request, build_opener, HTTPRedirectHandler

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
CATALOGUE = ROOT / 'assets/data/indian_dishes.json'
MANIFEST = ROOT / 'assets/data/dish_image_manifest.json'
REPORTS = ROOT / 'docs/image_sources/dishes'
WORK = ROOT / '.dish_pexels_work'
APPROVED = {'existing_approved', 'pexels_approved', 'pixabay_approved', 'manual_approved'}
FIELDS = ['dishId', 'dishName', 'imageFile', 'status', 'confidence',
          'pexelsPhotoId', 'pexelsPageUrl', 'photographer', 'photographerUrl',
          'originalWidth', 'originalHeight', 'downloadedSourceUrl',
          'searchQueryUsed', 'downloadDate', 'notes']


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    temporary.replace(path)


def read_json(path, default):
    return json.loads(path.read_text(encoding='utf-8')) if path.exists() else default


def normal(text):
    text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode().lower()
    return ' '.join(re.findall(r'[a-z0-9]+', text))


def queries(dish):
    name = dish['name']
    states = dish.get('origin_state_ids') or dish.get('associated_state_ids', [])
    values = [name, f'{name} Indian food']
    values += [f"{name} {state.replace('_', ' ')}" for state in states[:2]]
    values += [f'{alias} food' for alias in dish.get('aliases', []) if normal(alias)]
    if normal(name) != name.lower():
        values.append(f'{normal(name)} food')
    return list(dict.fromkeys(values))


def canonical():
    dishes = read_json(CATALOGUE, {})['items']
    if len({d['id'] for d in dishes}) != len(dishes):
        raise ValueError('Duplicate canonical dish IDs')
    if len({d['id'].casefold() for d in dishes}) != len(dishes):
        raise ValueError('Canonical filenames collide on case-insensitive systems')
    for dish in dishes:
        if not re.fullmatch(r'[A-Za-z0-9_-]+', dish['id']):
            raise ValueError('Unsafe canonical ID')
        if dish['image_asset'] != f"assets/images/dishes/{dish['id']}.webp":
            raise ValueError(f"Review noncanonical image reference: {dish['id']}")
    return dishes


def inspect_image(path):
    with Image.open(path) as image:
        image.load()
        return image.format, image.width, image.height


def initialize():
    dishes = canonical()
    manifest = read_json(MANIFEST, {'schemaVersion': 1, 'source': 'Pexels', 'items': []})
    entries = {r['dishId']: r for r in manifest['items']}
    if len(entries) != len(manifest['items']):
        raise ValueError('Duplicate manifest dish IDs; repair before proceeding')
    if set(entries) - {d['id'] for d in dishes}:
        raise ValueError('Manifest contains unknown dish IDs; review before proceeding')
    for dish in dishes:
        if dish['id'] in entries:
            continue
        row = {field: None for field in FIELDS}
        row.update(dishId=dish['id'], dishName=dish['name'], imageFile=None,
                   status='awaiting_api_key', confidence='UNRESOLVED',
                   notes='Not searched. API key required; not a Pexels no-match conclusion.',
                   expectedImageFile=dish['image_asset'], candidates=[], completedQueries=[],
                   queries=queries(dish), originStateIds=dish['origin_state_ids'],
                   associatedStateIds=dish['associated_state_ids'], aliases=dish.get('aliases', []),
                   dishType=dish['dish_type'], dietaryType=dish['dietary_type'])
        path = ROOT / dish['image_asset']
        if path.exists():
            row.update(status='existing_needs_review', imageFile=dish['image_asset'],
                       notes='Protected existing file. Needs visual/provenance review; never overwritten.')
            try:
                row['existingImageInspection'] = inspect_image(path)
            except (OSError, ValueError):
                row['notes'] += ' Image is invalid; explicit repair required.'
        entries[dish['id']] = row
    manifest['items'] = [entries[d['id']] for d in dishes]
    atomic_json(MANIFEST, manifest)
    return manifest


class StopRun(Exception):
    pass


class TrustedRedirects(HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, newurl):
        if urlparse(newurl).scheme != 'https' or urlparse(newurl).hostname != urlparse(request.full_url).hostname:
            raise StopRun('Refused redirect outside the official source host')
        return super().redirect_request(request, response, code, message, headers, newurl)


class PexelsClient:
    def __init__(self, key, max_requests=180, pause=1):
        self.key, self.max_requests, self.pause = key, max_requests, pause
        self.calls = 0
        self.cache_file = WORK / 'search_cache.json'
        self.rate_file = WORK / 'rate_checkpoint.json'
        self.cache = read_json(self.cache_file, {})
        self.rate = read_json(self.rate_file, {'requests': []})
        self.opener = build_opener(TrustedRedirects())

    def search(self, query):
        if query in self.cache:
            return self.cache[query]
        now = time.time()
        recent = [stamp for stamp in self.rate.get('requests', []) if stamp > now - 3600]
        blocked = self.rate.get('blockedUntil', 0)
        if blocked > now:
            raise StopRun(f'Rate checkpoint blocks requests until {datetime.fromtimestamp(blocked, timezone.utc).isoformat()}. Resume discover then.')
        if len(recent) >= 190:
            raise StopRun('Conservative hourly budget reached. Resume discover after an hour; checkpoints are preserved.')
        if self.calls >= self.max_requests:
            raise StopRun('Per-run request budget reached. Resume discover; completed queries are skipped.')
        recent.append(now)
        self.rate['requests'] = recent
        atomic_json(self.rate_file, self.rate)
        self.calls += 1
        url = 'https://api.pexels.com/v1/search?' + urlencode({'query': query, 'per_page': 15, 'page': 1})
        try:
            with self.opener.open(Request(url, headers={'Authorization': self.key}), timeout=30) as response:
                result = json.load(response)
                remaining = response.headers.get('X-Ratelimit-Remaining')
                reset = response.headers.get('X-Ratelimit-Reset')
                self.rate.update(remaining=remaining, reset=reset)
                if remaining == '0':
                    self.rate['blockedUntil'] = max(now + 3600, float(reset or 0))
                atomic_json(self.rate_file, self.rate)
        except HTTPError as error:
            if error.code == 429:
                delay = error.headers.get('Retry-After', '')
                self.rate['blockedUntil'] = now + (max(60, int(delay)) if delay.isdigit() else 3600)
                atomic_json(self.rate_file, self.rate)
                raise StopRun('Pexels rate-limited this request. No retries; wait for rate checkpoint expiry and resume discover.') from None
            raise StopRun(f'Pexels HTTP {error.code}. Check API access; checkpoints preserved.') from None
        except (URLError, TimeoutError, ValueError):
            raise StopRun('Pexels connection/response failed. No rapid retry; resume discover later.') from None
        self.cache[query] = result.get('photos', [])
        atomic_json(self.cache_file, self.cache)
        time.sleep(self.pause)
        return self.cache[query]


def candidate(photo, dish, query):
    alt = normal(photo.get('alt', ''))
    names = [normal(dish['name']), *map(normal, dish.get('aliases', []))]
    exact = any(name and f' {name} ' in f' {alt} ' for name in names)
    flags = [word for word in ['collage', 'packaging', 'watermark', 'advertisement', 'logo', 'person', 'people'] if word in alt.split()]
    width, height = int(photo.get('width', 0)), int(photo.get('height', 0))
    if max(width, height) < 1200 or min(width, height) < 600:
        flags.append('insufficient_resolution')
    src = photo.get('src', {})
    if urlparse(src.get('original', '')).hostname != 'images.pexels.com':
        flags.append('invalid_source')
    if urlparse(photo.get('url', '')).hostname not in {'pexels.com', 'www.pexels.com'}:
        flags.append('invalid_photo_page')
    score = (60 if exact else 0) + (15 if not flags else 0) + (10 if width >= height else 0)
    return dict(pexelsPhotoId=str(photo['id']), pexelsPageUrl=photo['url'],
                photographer=photo.get('photographer', ''), photographerUrl=photo.get('photographer_url', ''),
                originalWidth=width, originalHeight=height, src=src, alt=photo.get('alt', ''),
                searchQueryUsed=query, score=score, confidence='MEDIUM' if exact and not flags else 'LOW',
                flags=flags, notes='Metadata ranking only; visual identification required before HIGH approval.')


def discover(manifest, args, key):
    dishes = {d['id']: d for d in canonical()}
    client = PexelsClient(key, args.max_requests, args.pause)
    processed = 0
    for row in manifest['items']:
        if row['status'] in APPROVED | {'reviewed_high', 'UNRESOLVED_PEXELS'} or (ROOT / row['expectedImageFile']).exists():
            continue
        if args.dish_id and row['dishId'] != args.dish_id:
            continue
        if set(row['queries']) <= set(row['completedQueries']):
            continue
        if processed >= args.limit:
            break
        for query in row['queries']:
            if query in row['completedQueries']:
                continue
            photos = client.search(query)
            found = {c['pexelsPhotoId']: c for c in row['candidates']}
            for photo in photos:
                choice = candidate(photo, dishes[row['dishId']], query)
                if choice['pexelsPhotoId'] not in found or choice['score'] > found[choice['pexelsPhotoId']]['score']:
                    found[choice['pexelsPhotoId']] = choice
            row['candidates'] = sorted(found.values(), key=lambda c: c['score'], reverse=True)
            row['completedQueries'].append(query)
            row['status'] = 'needs_review' if row['candidates'] else 'searching'
            row['confidence'] = 'MEDIUM' if any(c['confidence'] == 'MEDIUM' for c in row['candidates']) else 'LOW' if row['candidates'] else 'UNRESOLVED'
            row['notes'] = 'Candidate metadata saved; no image approved without visual review.'
            atomic_json(MANIFEST, manifest)
        if not row['candidates']:
            row.update(status='UNRESOLVED_PEXELS', confidence='UNRESOLVED', notes='All generated queries searched; no Pexels candidates.')
        atomic_json(MANIFEST, manifest)
        processed += 1


def approve(manifest, decisions_path):
    decisions = read_json(Path(decisions_path), None)
    if not isinstance(decisions, list):
        raise ValueError('Approvals must be a JSON array exported by the review page')
    rows = {r['dishId']: r for r in manifest['items']}
    # Validate the entire import before changing any row.
    changes = []
    for decision in decisions:
        row = rows[decision['dishId']]
        if row['status'] in APPROVED or (ROOT / row['expectedImageFile']).exists():
            raise ValueError('Protected existing image; approval import cannot overwrite it')
        if decision.get('rejectAll'):
            changes.append((row, decision, None))
            continue
        choice = next((c for c in row['candidates'] if c['pexelsPhotoId'] == str(decision.get('selectedPhotoId'))), None)
        if not choice or not decision.get('visualReviewed') or decision.get('confidence') != 'HIGH' or not decision.get('notes', '').strip():
            raise ValueError('Final approval needs saved candidate, HIGH confidence, visualReviewed=true, and visual evidence notes')
        if choice['flags']:
            raise ValueError('Candidate failed quality filters; do not finalize it')
        changes.append((row, decision, choice))
    for row, decision, choice in changes:
        if choice is None:
            row.update(status='UNRESOLVED_PEXELS', confidence='UNRESOLVED', notes=decision.get('notes') or 'Candidates rejected during visual review.')
        else:
            row.update({field: choice.get(field) for field in FIELDS if field in choice})
            row.update(status='reviewed_high', confidence='HIGH', visualReviewed=True,
                       notes=decision['notes'], selectedPhotoId=choice['pexelsPhotoId'],
                       approvedAt=datetime.now(timezone.utc).isoformat())
    atomic_json(MANIFEST, manifest)


def finalize(manifest):
    used = {r['pexelsPhotoId'] for r in manifest['items'] if r['status'] in APPROVED and r.get('pexelsPhotoId')}
    selections = Counter(r.get('selectedPhotoId') for r in manifest['items'] if r['status'] == 'reviewed_high')
    opener = build_opener(TrustedRedirects())
    for row in manifest['items']:
        if row['status'] != 'reviewed_high' or not row.get('visualReviewed'):
            continue
        photo_id = row['selectedPhotoId']
        if photo_id in used or selections[photo_id] > 1:
            row.update(status='needs_review', notes=row['notes'] + ' Duplicate selection blocked; choose a different photo.')
            atomic_json(MANIFEST, manifest)
            continue
        destination = ROOT / row['expectedImageFile']
        if destination.exists():
            # Recover a completed exclusive write after interruption before the
            # final manifest checkpoint. Never adopt an unrelated existing file.
            if row.get('sha256') == hashlib.sha256(destination.read_bytes()).hexdigest():
                row.update(status='pexels_approved')
                used.add(photo_id)
                atomic_json(MANIFEST, manifest)
                continue
            raise StopRun('Protected destination exists. No images overwritten.')
        choice = next(c for c in row['candidates'] if c['pexelsPhotoId'] == photo_id)
        original = choice['src']['original']
        if urlparse(original).scheme != 'https' or urlparse(original).hostname != 'images.pexels.com':
            raise StopRun('Non-Pexels download URL refused')
        width, height = choice['originalWidth'], choice['originalHeight']
        scaled_width = max(1, round(width * min(1, 1600 / max(width, height))))
        url = original.split('?')[0] + '?' + urlencode({'auto': 'compress', 'cs': 'tinysrgb', 'w': scaled_width})
        try:
            with opener.open(Request(url), timeout=45) as response:
                raw = response.read(25 * 1024 * 1024 + 1)
            if len(raw) > 25 * 1024 * 1024:
                raise StopRun('Source exceeds safe download budget')
            with Image.open(io.BytesIO(raw)) as image:
                image.load()
                image = ImageOps.exif_transpose(image).convert('RGB')
                image.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
                if max(image.size) < 1200 or min(image.size) < 600:
                    raise StopRun('Downloaded image is too small; approval needs review')
                buffer = io.BytesIO()
                image.save(buffer, format='WEBP', quality=85, method=6)
                encoded = buffer.getvalue()
                output_size = image.size
            destination.parent.mkdir(parents=True, exist_ok=True)
            row.update(imageFile=row['expectedImageFile'], downloadedSourceUrl=url,
                       downloadDate=datetime.now(timezone.utc).isoformat(),
                       outputWidth=output_size[0], outputHeight=output_size[1], outputBytes=len(encoded),
                       sha256=hashlib.sha256(encoded).hexdigest())
            atomic_json(MANIFEST, manifest)
            # Exclusive creation protects files even if another process writes first.
            with destination.open('xb') as output:
                output.write(encoded)
        except (HTTPError, URLError, OSError, ValueError):
            raise StopRun(f"Image export failed for {row['dishId']}; checkpoints preserved.") from None
        row.update(status='pexels_approved', imageFile=row['expectedImageFile'],
                   downloadedSourceUrl=url, downloadDate=datetime.now(timezone.utc).isoformat(),
                   outputWidth=output_size[0], outputHeight=output_size[1], outputBytes=len(encoded),
                   sha256=hashlib.sha256(encoded).hexdigest())
        used.add(photo_id)
        atomic_json(MANIFEST, manifest)


def write_csv(path, fields, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w', encoding='utf-8-sig', newline='') as output:
        writer = csv.DictWriter(output, fieldnames=fields, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(rows)


def duplicates(manifest):
    groups = defaultdict(list)
    for row in manifest['items']:
        photo_id = row.get('selectedPhotoId') or row.get('pexelsPhotoId')
        if photo_id:
            groups[photo_id].append(row['dishId'])
    return [dict(pexelsPhotoId=photo_id, dishIds=';'.join(ids), count=len(ids)) for photo_id, ids in groups.items() if len(ids) > 1]


def reports(manifest):
    rows = manifest['items']
    review = []
    for row in rows:
        review.append(dict(dishId=row['dishId'], dishName=row['dishName'], query=' | '.join(row['queries']),
                           **{f'candidate{i + 1}': c['pexelsPageUrl'] for i, c in enumerate(row['candidates'][:3])},
                           selectedPhotoId=row.get('selectedPhotoId', ''), confidence=row['confidence'], reviewStatus=row['status']))
    write_csv(REPORTS / 'dish_image_review.csv', ['dishId', 'dishName', 'query', 'candidate1', 'candidate2', 'candidate3', 'selectedPhotoId', 'confidence', 'reviewStatus'], review)
    unresolved = [r for r in rows if r['status'] not in APPROVED]
    write_csv(REPORTS / 'dish_images_unresolved.csv', ['dishId', 'dishName', 'status', 'confidence', 'notes'], unresolved)
    write_csv(REPORTS / 'dish_image_duplicates.csv', ['pexelsPhotoId', 'dishIds', 'count'], duplicates(manifest))
    sections = []
    escape = lambda value: html.escape(str(value), quote=True)
    for row in rows:
        cards = []
        for choice in row['candidates'][:12]:
            thumb = choice['src'].get('medium', '')
            if urlparse(thumb).hostname != 'images.pexels.com':
                thumb = ''
            checked = ' checked' if row.get('selectedPhotoId') == choice['pexelsPhotoId'] else ''
            cards.append(f'''<label><input type="radio" name="{escape(row['dishId'])}" value="{escape(choice['pexelsPhotoId'])}"{checked}>
                <img loading="lazy" src="{escape(thumb)}" alt="{escape(choice['alt'])}">
                <a href="{escape(choice['pexelsPageUrl'])}" target="_blank" rel="noopener">Photo {escape(choice['pexelsPhotoId'])}</a>
                <p>Photo by {escape(choice['photographer'])} on Pexels</p>
                <p>{escape(choice['alt'])}</p><small>{escape(choice['confidence'])} · {escape(choice['flags'])}</small></label>''')
        sections.append(f'''<section data-dish="{escape(row['dishId'])}"><h2>{escape(row['dishName'])}</h2>
            <p>{escape(row['dishId'])} · {escape(', '.join(row['originStateIds']))} · {escape(row['dishType'])} · {escape(row['dietaryType'])} · {escape(row['status'])} · {escape(row['confidence'])}</p>
            <p>Selected photo: {escape(row.get('selectedPhotoId') or 'None')}</p>
            <p>Aliases: {escape(', '.join(row['aliases']))}</p><div class="cards">{''.join(cards) or '<p>No candidates yet.</p>'}</div>
            <p><label><input class="visual" type="checkbox"> Visually verified exact dish, food-focused quality and absence of logos, people, watermarks or overlays</label></p>
            <p><label><input class="reject" type="checkbox"> Reject all candidates</label></p>
            <textarea placeholder="Visual identification evidence and review notes"></textarea></section>''')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><title>Dish photo review</title>
    <style>body{font:16px system-ui;background:#faf6ec;color:#162338;margin:30px}section{padding:20px;border-top:1px solid #ccc}.cards{display:flex;flex-wrap:wrap;gap:12px}.cards label{width:230px;background:white;padding:12px}.cards img{width:230px;height:170px;object-fit:contain}textarea{width:90%;height:60px}button{padding:12px;position:sticky;top:10px}</style>
    <h1>Canonical Indian dishes: review before export</h1><p><a href="https://www.pexels.com">Photos provided by Pexels</a>. Metadata scores do not establish dish identity. Open multiple originals and review each candidate. No selected photo enters the app until finalized.</p>
    <button onclick="exportReviews()">Export reviewed decisions JSON</button>''' + ''.join(sections) + '''
    <script>function exportReviews(){const decisions=[];for(const section of document.querySelectorAll('section')){const chosen=section.querySelector('input[type=radio]:checked');const rejectAll=section.querySelector('.reject').checked;const visualReviewed=section.querySelector('.visual').checked;const notes=section.querySelector('textarea').value.trim();if(!chosen&&!rejectAll)continue;if(!rejectAll&&(!visualReviewed||!notes)){alert('A selected photo needs visual verification and evidence notes.');return;}decisions.push({dishId:section.dataset.dish,selectedPhotoId:chosen?.value,confidence:'HIGH',visualReviewed,rejectAll,notes});}const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([JSON.stringify(decisions,null,2)],{type:'application/json'}));a.download='dish_photo_approvals.json';a.click();URL.revokeObjectURL(a.href);}</script></html>'''
    REPORTS.mkdir(parents=True, exist_ok=True)
    (REPORTS / 'dish_image_review.html').write_text(page, encoding='utf-8')
    images = [(r['dishId'], (ROOT / r['imageFile']).stat().st_size) for r in rows if r['status'] in APPROVED and r.get('imageFile') and (ROOT / r['imageFile']).exists()]
    summary = dict(totalCanonical=len(rows), existingApproved=sum(r['status'] == 'existing_approved' for r in rows),
                   searched=sum(bool(r['completedQueries']) for r in rows), highConfidence=sum(r['confidence'] == 'HIGH' for r in rows),
                   mediumNeedsReview=sum(r['confidence'] == 'MEDIUM' for r in rows), lowCandidateCount=sum(c['confidence'] == 'LOW' for r in rows for c in r['candidates']),
                   unresolvedOrPending=len(unresolved), finalImages=len(images), duplicatePhotos=len(duplicates(manifest)),
                   totalBytes=sum(size for _, size in images), averageBytes=sum(size for _, size in images) / len(images) if images else 0,
                   largestFiles=sorted(images, key=lambda item: item[1], reverse=True)[:10], unusuallyLarge=[item for item in images if item[1] > 750_000],
                   first30Unresolved=[{'dishId': r['dishId'], 'dishName': r['dishName'], 'status': r['status']} for r in unresolved[:30]])
    atomic_json(REPORTS / 'dish_image_summary.json', summary)
    return summary


def validate(manifest):
    dishes = {d['id']: d for d in canonical()}
    errors = []
    rows = manifest['items']
    if len({r['dishId'] for r in rows}) != len(rows) or {r['dishId'] for r in rows} != set(dishes):
        errors.append('Manifest IDs must match the canonical catalogue exactly once')
    for row in rows:
        if row['dishId'] not in dishes:
            continue
        expected = dishes[row['dishId']]['image_asset']
        if row['expectedImageFile'] != expected or row.get('imageFile') not in (None, expected):
            errors.append(f"Noncanonical image path: {row['dishId']}")
        if row['status'] in APPROVED:
            path = ROOT / expected
            try:
                fmt, width, height = inspect_image(path)
                if fmt != 'WEBP' or not 1200 <= max(width, height) <= 1600 or min(width, height) < 600:
                    errors.append(f"Invalid WebP dimensions/format: {row['dishId']}")
                if row['status'] == 'pexels_approved' and (not row.get('pexelsPhotoId') or not row.get('photographer') or not row.get('downloadDate') or not row.get('downloadedSourceUrl')):
                    errors.append(f"Incomplete provenance: {row['dishId']}")
                if row['status'] == 'pixabay_approved' and any(not row.get(field) for field in ['pixabayImageId', 'pageUrl', 'creator', 'licenseReference', 'downloadDate', 'downloadedSourceUrl']):
                    errors.append(f"Incomplete Pixabay provenance: {row['dishId']}")
                if row.get('sha256') and hashlib.sha256(path.read_bytes()).hexdigest() != row['sha256']:
                    errors.append(f"Image no longer matches approved checksum: {row['dishId']}")
            except (OSError, ValueError):
                errors.append(f"Missing/corrupt approved image: {row['dishId']}")
        elif (ROOT / expected).exists() and row['status'] != 'existing_needs_review':
            errors.append(f"Unapproved file would be visible in app: {row['dishId']}")
        elif row['status'] == 'existing_needs_review':
            try:
                inspect_image(ROOT / expected)
            except (OSError, ValueError):
                errors.append(f"Corrupt existing protected image: {row['dishId']}")
    if duplicates(manifest):
        errors.append('Duplicate selected Pexels photo IDs; see duplicate report')
    for path in (ROOT / 'assets/images/dishes').glob('*.webp'):
        if path.stem not in dishes:
            errors.append(f'Unknown dish filename: {path.name}')
    if 'assets/images/dishes/' not in (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'):
        errors.append('Dish images folder is not declared in pubspec.yaml')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['init', 'discover', 'approve', 'finalize', 'reports', 'validate'])
    parser.add_argument('--limit', type=int, default=30)
    parser.add_argument('--max-requests', type=int, default=180)
    parser.add_argument('--pause', type=float, default=1)
    parser.add_argument('--dish-id')
    parser.add_argument('--approvals', type=Path)
    args = parser.parse_args()
    if args.limit < 1 or not 1 <= args.max_requests <= 190 or args.pause < 0:
        parser.error('Use positive limit, max-requests 1..190 and nonnegative pause')
    manifest = initialize()
    result = 0
    try:
        key = os.environ.get('PEXELS_API_KEY', '').strip()
        if args.command in ('discover', 'finalize') and not key:
            raise StopRun('PEXELS_API_KEY is unavailable. No API calls or image downloads attempted. Set it and resume.')
        if args.command == 'discover':
            discover(manifest, args, key)
        elif args.command == 'approve':
            if not args.approvals:
                parser.error('approve requires --approvals <reviewed JSON>')
            approve(manifest, args.approvals)
        elif args.command == 'finalize':
            finalize(manifest)
        elif args.command == 'validate':
            errors = validate(manifest)
            if errors:
                print('\n'.join(errors))
                result = 1
    except StopRun as error:
        print(str(error))
        result = 2
    finally:
        summary = reports(manifest)
        print(json.dumps({k: summary[k] for k in ['totalCanonical', 'searched', 'finalImages', 'unresolvedOrPending', 'totalBytes']}, indent=2))
    return result


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError) as error:
        print(f'Pipeline validation failed: {error}', file=sys.stderr)
        sys.exit(1)
