"""Exact-name searches and explicit human approval for the bounded image pilot."""
import csv
import html
import json
from pathlib import Path
import download_dish_images_pexels as common

APPROVAL_FIELDS = ['dishId', 'dishName', 'approvedSource', 'approvedPhotoId',
                   'approvedCandidateNumber', 'reviewStatus', 'reviewNotes']
SOURCE_PRIORITY = ['pexels', 'pixabay', 'openverse', 'wikimedia_reviewed', 'manually_licensed']


def queries(dish, aliases):
    names = list(dict.fromkeys([dish['name'], *dish.get('aliases', []), *aliases]))
    states = [s.replace('_', ' ') for s in dict.fromkeys(dish.get('origin_state_ids', []) + dish.get('associated_state_ids', []))]
    result = []
    for name in names:
        result.extend([f'{name} {state}' for state in states])
        result.append(name)
        result.append(f"{name} {dish.get('dish_type', '').replace('_', ' ')}".strip())
    return list(dict.fromkeys(q for q in result if len(q) <= 100))


def candidates(state):
    # Metadata is a review priority, never evidence of exact visual identity.
    return sorted((c for c in state['candidates'] if c['score'] >= 60 and not c['flags']),
                  key=lambda c: c['score'], reverse=True)[:5]


def load_approvals(path, rows):
    if not path.exists():
        raise common.StopRun('Human approval CSV missing; no downloads performed')
    with path.open(encoding='utf-8-sig', newline='') as file:
        decisions = list(csv.DictReader(file))
    by_id = {r['dishId']: r for r in rows}
    seen = set()
    changes = []
    for decision in decisions:
        identity = decision['dishId']
        if identity in seen or identity not in by_id:
            raise ValueError('Duplicate or out-of-batch approval ID')
        seen.add(identity)
        row = by_id[identity]
        state = row['sourceRuns']['pixabay']
        status = decision['reviewStatus']
        if status not in {'pending', 'approved', 'none_correct', 'needs_more_search'}:
            raise ValueError('Invalid human review status')
        choice = None
        if status == 'approved':
            choice = next((c for c in state['candidates'] if c['source'] == decision['approvedSource'] and c['sourceId'] == decision['approvedPhotoId']), None)
            if not choice or choice not in candidates(state) or not decision['reviewNotes'].strip():
                raise ValueError('Approval requires a saved eligible candidate and exact-dish review notes')
        changes.append((state, status, choice, decision['reviewNotes']))
    if seen != set(by_id):
        raise ValueError('Approval CSV must account for every dish in the existing batch')
    for state, status, choice, notes in changes:
        state.update(reviewStatus=status, visualReviewed=status == 'approved', notes=notes,
                     selectedSourceId=choice['sourceId'] if choice else None,
                     status='reviewed_high' if choice else 'unresolved' if status == 'none_correct' else 'pending_review')


def reports(manifest, batch, root, report_dir, approval_path, duplicates):
    dishes = {d['id']: d for d in common.canonical()}
    rows = {r['dishId']: r for r in manifest['items']}
    sections, template, review = [], [], []
    esc = lambda value: html.escape(str(value), quote=True)
    for item in batch:
        row = rows[item['dishId']]
        dish = dishes[row['dishId']]
        state = row['sourceRuns']['pixabay']
        template.append(dict(dishId=row['dishId'], dishName=dish['name'], approvedSource='', approvedPhotoId='', approvedCandidateNumber='', reviewStatus='pending', reviewNotes=''))
        cards = []
        for number, c in enumerate(candidates(state), 1):
            cards.append(f'''<label class="candidate"><strong>Candidate {number}</strong>
            <img loading="lazy" src="{esc(c['reviewUrl'])}" alt="{esc(c['tags'])}">
            <p>{esc(c['source'])} #{esc(c['sourceId'])} · {esc(c['creator'])}</p>
            <a href="{esc(c['pageUrl'])}" target="_blank" rel="noopener">Source page</a>
            <p>Query: {esc(c['searchQueryUsed'])}</p><p>{c['originalWidth']} × {c['originalHeight']}</p>
            <p>Metadata priority: {esc(c['confidence'])} · {esc(c['flags'])}</p><p>Tags: {esc(c['tags'])}</p>
            <input type="radio" name="{esc(row['dishId'])}" value="approved" data-source="{esc(c['source'])}" data-photo="{esc(c['sourceId'])}" data-number="{number}"> Approve Candidate {number}</label>''')
        context = [('Aliases', dish.get('aliases', [])), ('Image search aliases', state.get('imageSearchAliases', [])),
                   ('Origin', dish.get('origin_state_ids', [])), ('Associated states', dish.get('associated_state_ids', [])),
                   ('Dish type', dish.get('dish_type', '')), ('Dietary type', dish.get('dietary_type', ''))]
        details = ''.join(f'<p><strong>{label}:</strong> {esc(", ".join(value) if isinstance(value, list) else value)}</p>' for label, value in context)
        sections.append(f'''<section data-dish="{esc(row['dishId'])}" data-name="{esc(dish['name'])}"><h2>{esc(dish['name'])}</h2><strong>{esc(row['dishId'])}</strong>
        {details}<p>{esc(dish.get('short_description', ''))}</p><p>Status: {esc(state['status'])}</p>
        <div class="candidates">{''.join(cards) or '<p>No candidates. Keep the dish placeholder.</p>'}</div>
        <label><input type="radio" name="{esc(row['dishId'])}" value="none_correct"> None are correct</label>
        <label><input type="radio" name="{esc(row['dishId'])}" value="needs_more_search"> Needs more search</label>
        <textarea placeholder="Explain exact dish identity and photo quality; required for approval"></textarea></section>''')
        review.append(dict(dishId=row['dishId'], dishName=dish['name'], group=item['group'], reviewStatus=state.get('reviewStatus', 'pending'), candidatesShown=len(candidates(state))))
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><title>UPLYFA dish candidate review</title>
    <style>body{font:16px system-ui;background:#faf7ef;color:#142238;margin:24px}header{background:#faf7ef;padding:16px}section{background:white;padding:24px;margin:24px 0;border-radius:20px}.candidates{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:16px}.candidate{border:1px solid #ddd;padding:12px;border-radius:12px}.candidate img{display:block;width:100%;height:340px;object-fit:contain}textarea{display:block;width:95%;height:80px;margin-top:16px}button{padding:14px}</style>
    <header><h1>UPLYFA · exact dish candidate review</h1><p>Correct image &gt; beautiful image &gt; coverage. Same 20 common + 10 obscure dishes. Metadata confidence, including HIGH, only prioritizes review. No candidate is automatically approved.</p>
    <p>Verify exact dish identity, real photograph, quality, license and attribution on the source page. Generic substitutes must be rejected. Unresolved dishes keep the existing placeholder. <a href="https://pixabay.com/service/license-summary/">Pixabay license</a></p><button onclick="save()">Export approval CSV</button></header>''' + ''.join(sections) + '''
    <script>function save(){const fields=['dishId','dishName','approvedSource','approvedPhotoId','approvedCandidateNumber','reviewStatus','reviewNotes'];const rows=[fields];for(const s of document.querySelectorAll('section')){const p=s.querySelector('input:checked');const notes=s.querySelector('textarea').value.trim();if(p?.value==='approved'&&!notes){alert('Add exact-dish identification and quality notes.');return;}rows.push([s.dataset.dish,s.dataset.name,p?.dataset.source||'',p?.dataset.photo||'',p?.dataset.number||'',p?.value||'pending',notes]);}const csv=rows.map(r=>r.map(v=>'"'+v.replaceAll('"','""')+'"').join(',')).join('\\r\\n');const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'}));a.download='dish_image_approvals.csv';a.click();URL.revokeObjectURL(a.href);}</script></html>'''
    report_dir.mkdir(parents=True, exist_ok=True)
    (report_dir / 'dish_image_review.html').write_text(page, encoding='utf-8')
    if not approval_path.exists():
        common.write_csv(approval_path, APPROVAL_FIELDS, template)
    common.write_csv(report_dir / 'dish_image_review.csv', list(review[0]), review)
    common.write_csv(report_dir / 'dish_images_unresolved.csv', list(review[0]), [r for r in review if r['reviewStatus'] == 'none_correct'])
    common.write_csv(report_dir / 'dish_image_duplicates.csv', ['source', 'sourceId', 'dishIds'], duplicates)
    states = [rows[b['dishId']]['sourceRuns']['pixabay'] for b in batch]
    summary = dict(batchSize=30, candidateDishes=sum(bool(candidates(s)) for s in states),
        noPlausibleMetadataCandidates=sum(not candidates(s) for s in states),
        strongExactCandidates=None, genericOrWrongDishes=None, commonApprovedRate=None, obscureApprovedRate=None,
        pending=sum(s.get('reviewStatus', 'pending') == 'pending' for s in states),
        unresolved=sum(s.get('reviewStatus') == 'none_correct' or s['status'] == 'unresolved' for s in states),
        finalImages=sum((root / rows[b['dishId']]['expectedImageFile']).exists() for b in batch),
        accuracyAssessment='Human review required; metadata ranking cannot establish exact identity',
        newQueriesRemaining=sum(len(set(s['queries']) - set(s['completedQueries'])) for s in states))
    for group in ['common', 'obscure']:
        reviewed = [s for s in states if s['batchGroup'] == group and s.get('reviewStatus') in {'approved', 'none_correct'}]
        summary[group + 'ApprovedRate'] = sum(s['reviewStatus'] == 'approved' for s in reviewed)/len(reviewed) if reviewed else None
    common.atomic_json(report_dir / 'summary.json', summary)
    return summary
