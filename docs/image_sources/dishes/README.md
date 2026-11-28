# Canonical Indian dish photographs — Pexels pipeline

## Current run: API key unavailable

Inspected `assets/data/indian_dishes.json` (`items`): **640 canonical dishes**, **0 existing photographs**, **640 requiring photographs**. The dishes folder contains only `.gitkeep`. No API searches or food-image downloads were made, and no dishes are claimed to have failed a Pexels search.

All 640 rows are `awaiting_api_key` with confidence `UNRESOLVED`, rather than `UNRESOLVED_PEXELS`. They are pending sourcing, not confirmed no-match cases. Approved/high/medium/low matches, downloads and duplicate photo assignments are all **0**. Final asset size is **0 bytes**, average **0 bytes**, with no largest files or oversized images.

IDs are **627 `exp_…` IDs and 13 `DSH…` IDs**. Both are canonical and are preserved exactly. The example DSH filename format must not be used to reassign existing IDs. All current `image_asset` values already point to `assets/images/dishes/<canonical-id>.webp`. No changes to the canonical catalogue, collections, progress or achievements were required.

Metadata contains names, aliases, origin and associated state IDs, dish type and dietary type. **529 dishes have no aliases**. Obscure names such as Aamin, Aikibeye, Akini Chokibo and Amrusu, and qualified names such as Amritsari Kulcha Chandigarh Style, may need careful visual review. Actual search/matching difficulty cannot be established until API access is available. Existing catalogue provenance mentioning Incredible India is business data; no Incredible India imagery is used by this pipeline.

## Set the key without putting it in command history

Obtain a key from [Pexels API](https://www.pexels.com/api/). In a PowerShell terminal in the project root:

```powershell
$env:PEXELS_API_KEY = [System.Net.NetworkCredential]::new('', (Read-Host 'Pexels API key' -AsSecureString)).Password
python tools/download_dish_images_pexels.py discover --limit 30 --max-requests 180
```

The prompt masks the key. The key is read only from this process environment, sent only in the official API Authorization header, and never printed or persisted. Do not paste it into chat, source files, `.env` files or a command argument. The environment is local to the terminal; an already-running IDE/agent does not inherit changes made in another terminal. Run the pipeline in the terminal where the variable was set.

Pillow is already available in this workspace. On another machine, install the sole dependency with:

```powershell
python -m pip install -r tools/requirements-dish-photo-pipeline.txt
```

## Workflow and resume

1. `python tools/download_dish_images_pexels.py init` inventories canonical IDs and protects any existing file. Existing images without verified provenance are `existing_needs_review`; they are never silently approved or overwritten.
2. `python tools/download_dish_images_pexels.py discover --limit 30 --max-requests 180` searches exact names, specific food queries, state-qualified names, actual aliases and normalized spellings. Each query returns up to 15 candidates. Queries and results are cached and checkpointed after every successful query. Ranking compares full name/alias phrases, resolution, composition hints and orientation; it never picks result #1 blindly. No generic-category query replaces a regional dish name.
3. Open `docs/image_sources/dishes/dish_image_review.html` in a browser. Compare candidate images and originals, verify the exact dish and food-focused composition, and reject packaging, text, screenshots, watermark/logo, people, collages and uncertain identification. The first 12 ranked candidates are shown per dish; all collected candidate metadata remains in the manifest. The CSV links the top 3. Selected photo and confidence are displayed in the regenerated page.
4. Choose a photo, confirm visual verification, and write identification evidence. Use “Export reviewed decisions JSON”, then import it:

   ```powershell
   python tools/download_dish_images_pexels.py approve --approvals "$env:USERPROFILE\Downloads\dish_photo_approvals.json"
   python tools/download_dish_images_pexels.py finalize
   python tools/download_dish_images_pexels.py validate
   ```

   Only visually reviewed HIGH selections can be finalized. Metadata alone reaches at most MEDIUM; LOW candidates never silently become app assets. A reviewer can positively identify an otherwise weak-metadata candidate, but the quality filters must still pass. MEDIUM candidates remain remote review candidates, not approved app files. This deliberately favors accuracy over automatic coverage.

5. Repeat `discover` for the next batch. It skips approved/protected rows and completed queries, including after a partial failure. “Reject all” marks `UNRESOLVED_PEXELS`; these decisions are not silently retried. Reports are regenerated after every command and on graceful stops.

The script uses only `https://api.pexels.com/v1/search` for discovery and `https://images.pexels.com` for downloads, refuses cross-host redirects, and never scrapes any site. A cache hit requires no request. Single-process operation is intended; do not run multiple concurrent writers against one manifest.

## Rate limits

[Official API documentation](https://www.pexels.com/api/documentation/) lists default limits of 200 requests/hour and 20,000/month. The local rolling hourly guard stops at 190 and a normal run stops at 180 requests. Monthly remaining/reset response headers are preserved. HTTP 429 stops immediately with no repeated retries, persisting the next allowed time. Rerun the same discover command after the checkpoint permits it; do not delete the rate checkpoint or repeatedly restart to evade limits. Network/auth errors stop safely with sanitized messages and retain work.

Local query cache and quota checkpoints live in `.dish_pexels_work/` and are ignored by Git. Canonical manifest/candidate provenance and reports remain versioned. No API key appears in these files.

## Final assets and app integration

Finalization downloads an aspect-preserving, sufficiently resolved source variant from the saved official Pexels original. Pillow applies EXIF orientation, resizes down only, and writes WebP quality 85 with a maximum 1600-pixel long edge. Output requires at least a 1200-pixel long edge and 600-pixel short edge; there is no upscale or destructive crop. Source download budget is 25 MiB. Existing files are protected by exclusive creation. A saved checksum permits recovery if a completed export was interrupted before its final manifest status checkpoint.

Duplicate selections are blocked, rather than reused across dishes. Every approved image retains photo ID, photo page, photographer and profile, original dimensions, exact download URL, search query, UTC date, review notes, output dimensions/bytes and checksum. Reports list total/average bytes, largest files, and files above 750 KB.

`pubspec.yaml` already declares `assets/images/dishes/` once. `IndianDish.imageAsset` is used by dish cards/details, and `DishImage` checks the Flutter asset manifest and uses its existing food placeholder when an image is absent or decoding fails. Thus pending/unresolved canonical paths are intentional and safe. The sourcing manifest is a tool/provenance artifact; no new runtime loader or app UI redesign was introduced.

## License and attribution

Consult the [Pexels license](https://www.pexels.com/license/), [terms](https://www.pexels.com/terms-of-service/) and [API guidelines](https://www.pexels.com/api/documentation/). The general license allows reuse and modification, with restrictions; the API guidelines separately require a prominent Pexels link during API use and encourage photographer credits. The review flow provides both. Provenance is never discarded, and images do not receive text overlays. No standalone stock-photo distribution, trademark/logo reuse or implied endorsement is part of this workflow.

Before shipping future approved images, retain an accessible Pexels/source-credit link appropriate to the finished app's use of API-sourced content; per-image provenance is available in the manifest. No image is currently included in the shipped app, so no attribution UI was added to empty placeholders.

## Outputs

- `assets/data/dish_image_manifest.json`: all canonical rows, candidate metadata, provenance and checkpointed queries.
- `docs/image_sources/dishes/dish_image_review.csv`: top candidates, selected photo, confidence and review status.
- `docs/image_sources/dishes/dish_image_review.html`: browser review and exported decisions.
- `docs/image_sources/dishes/dish_images_unresolved.csv`: pending/review/unresolved rows with honest reasons.
- `docs/image_sources/dishes/dish_image_duplicates.csv`: duplicate selected Pexels IDs.
- `docs/image_sources/dishes/dish_image_summary.json`: counts, asset performance and first 30 pending rows.
- `tools/download_dish_images_pexels.py`: reusable pipeline.
- `tools/test_dish_images_pexels.py`: offline tests using fabricated local fixtures, not sourced dish photos.
- `tools/requirements-dish-photo-pipeline.txt`: Pillow dependency.

Only `.gitignore` was modified in existing project files. All files above were created; business data and Flutter code/pubspec are unchanged.

## First 30 pending / unresolved dishes

All are **not yet searched**, awaiting the API key:

1. Aam Achar Ilish
2. Aam Papad
3. Aamat
4. Aamin
5. Abar Khabo Sandesh
6. Ada Pradhaman
7. Agra Petha
8. Aikibeye
9. Akini Chokibo
10. Aktori
11. Al Yakhni
12. Aloo ke Gutke
13. Aloo Palda
14. Aloo Paratha
15. Aloo Pitika
16. Aloo Tikki
17. Alsandyanche Tonakh
18. Alu Phing Sha
19. Ambadyachi Uddamethi
20. Ambal
21. Ambot Tik
22. Amritsari Fish
23. Amritsari Kulcha
24. Amritsari Kulcha Chandigarh Style
25. Amrusu
26. Andaman Fish Curry
27. Andaman Prawn Curry
28. Andhra Chicken Pakodi
29. Andhra Kodi Kura
30. Angakar Roti

## Validation

Pipeline validation checks exact canonical/manifest membership, safe canonical filenames, approved existence/WebP/dimensions, corruption, checksums, complete provenance, selected duplicate IDs, unknown assets, and the existing pubspec folder declaration. Missing unapproved images are allowed and covered by the existing Flutter placeholder test.

Python unit tests cover real local WebP encoding, protection, metadata confidence, specific queries, resume, cache, duplicate/corrupt data, missing-key stop and 429/hourly guards: **12 tests passed**. Real 640-row manifest validation passed. `flutter analyze`: **no issues found**. Full `flutter test --concurrency=1 --reporter expanded --timeout 120s`: **245 tests passed**, including the existing missing-dish-photo placeholder test. Live API search accuracy and connectivity cannot be tested without PEXELS_API_KEY.
