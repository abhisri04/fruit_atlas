# UPLYFA — Pixabay 30-dish validation

Pixabay is the only active adapter for this test. Existing Pexels and Commons/fruit tooling is preserved; Commons dish sourcing is not invoked. No canonical business data or Flutter code was changed.

## Current result

`PIXABAY_API_KEY` is missing. **30 dishes prepared, 0 tested, 30 awaiting API access**. HIGH, MEDIUM, LOW rejected, confirmed unresolved, duplicate selections and final images are all **0**. Common/obscure success rates and average source resolution are **not measurable**, represented as null in `summary.json`. Suitability for the remaining catalogue cannot be inferred before actual search and visual review.

Do not interpret pending dishes as no-match findings. No API calls, thumbnail/image downloads or final exports have been performed.

## Obtain/set the key and run only this batch

### Python HTTP diagnosis

The adapter now uses Requests with structured `params=`, an explicit `User-Agent: UPLYFA/1.0 dish-image-validation`, `Accept: application/json`, GET, a 30-second timeout, and disabled API redirects. Install/update dependencies in the same Python environment with `python -m pip install -r tools/requirements-dish-photo-pipeline.txt`.

In the PowerShell terminal where the valid key is already set, run:

```powershell
python tools/download_dish_images.py diagnose --source pixabay
```

This performs exactly one uncached request to `https://pixabay.com/api/` using only `key`, `q=butter chicken`, `image_type=photo`, `per_page=3`, and `safesearch=true`, matching the reported successful PowerShell request. It prints HTTP status, hit count, total hits and first image ID on success. Errors include redacted response body and selected response headers. Plain/URL-encoded credentials and credential-bearing full URLs are sanitized. No manifest, batch, cache, rate checkpoint, image or review file is written by diagnosis.

After HTTP 200, resume `discover --source pixabay` for the existing 30-dish batch. Discovery retains its existing higher-resolution/food filters, completed queries, cached results and per-query checkpoints. Its requests use the same new client and headers. An error displays sanitized details and stops without retries; no automatic parameter weakening or fallback sourcing occurs.

Inspection established that the original request already had the correct endpoint, key parameter, GET method and URL encoding. It differed from PowerShell by using urllib's default Python user agent and adding filters, and it discarded HTTP error bodies. Those differences alone do **not** establish the cause of 403. The reported PowerShell HTTP 200 confirms the user's key works; the agent's process and Windows saved environment currently do not contain that key. Live response-body diagnosis and resumed discovery are therefore pending execution in the user's keyed terminal. No unsupported claim about an invalid key or proven rate-limit cause is made.

Updated Python verification: **25 pipeline tests pass**, including exact request params/headers, one-request behavior, credential redaction and diagnose isolation. No Flutter/runtime/business-data changes were made for this HTTP correction.

Create or sign into a [Pixabay account](https://pixabay.com/accounts/register/), then open [API documentation](https://pixabay.com/api/docs/) while signed in to obtain your API key. In a PowerShell terminal in the project root:

```powershell
$env:PIXABAY_API_KEY = [System.Net.NetworkCredential]::new('', (Read-Host 'Pixabay API key' -AsSecureString)).Password
python tools/download_dish_images.py discover --source pixabay
```

The prompt masks the key. Run the command in the same terminal. Do not paste the key into chat, source files or command arguments. Pixabay requires a `key` query parameter on API requests; the adapter never logs the credential-bearing URL, response error bodies or raw request exceptions, and never persists the key. Downloads do not carry API credentials. API redirects are refused.

The CLI processes only the saved 30 unique canonical IDs: exactly 20 common and 10 obscure. There is no full-catalogue option or automatic source fallback. It checkpoints every successful query and stops after this batch. Review files come before final exports or expansion.

## Batch selection

The actual canonical IDs are in `../pixabay_validation_batch.json`. This catalogue has both `DSH…` and `exp_…` IDs; neither is renamed or reassigned.

Common (20): Aloo Paratha, Aloo Tikki, Amritsari Kulcha, Butter Chicken, Chole Bhature, Dal Makhani, Dhokla, Hyderabadi Biryani, Idli with Sambar, Jalebi, Mysuru Masala Dosa, Momos, Pav Bhaji, Rajma Chawal, Samosa, Vada Pav, Poha, Chole Kulche, Makhana Kheer, Neer Dosa.

Obscure/regional (10): Aamat, Aamin, Aikibeye, Akini Chokibo, Amrusu, Bai, Jadoh, Chak-Hao Kheer, Rugra Curry, Muya Bai Wahan.

Plain Dosa, Gulab Jamun, Lassi, plain Masala Dosa, Palak Paneer, Rasgulla and Pani Puri are absent as exact canonical dish names. Existing dishes were selected without pretending a variant is identical to an absent dish or adding duplicate records. Mysuru Masala Dosa, Idli with Sambar and Neer Dosa are searched and judged as their own canonical dishes. The 10 obscure dishes cover Chhattisgarh, Arunachal Pradesh, Nagaland, Mizoram, Meghalaya, Manipur, Jharkhand and Tripura.

## Architecture/provenance

- `tools/dish_image_sources.py`: source-neutral candidate adapter contract and official Pixabay client. Only Pixabay is registered as active; retained source-specific tooling is available separately.
- `tools/download_dish_images.py`: bounded orchestration, review imports, optional approved export, source-scoped duplicates and reports.
- `assets/data/dish_image_manifest.json`: existing 640-row manifest extended to schema 2. Per-dish `sourceRuns.pixabay` preserves its own queries/candidates/checkpoints alongside untouched Pexels candidates and progress. `activeSource` is pixabay; the future selection policy is Pixabay → Pexels → manually licensed → placeholder.

Pixabay selections preserve `source`, `sourceId`, `pixabayImageId`, `pageUrl`, creator/profile, Content License reference, query, original dimensions, download URL/date, review evidence, output dimensions/bytes and SHA-256. Raw returned candidate metadata also remains in the manifest. Numeric IDs are source-scoped so equal Pexels/Pixabay numbers do not create false duplicate collisions.

The shared Pexels validator recognizes approved Pixabay images and checks their required provenance, without deleting or disabling Pexels functionality. Existing final files remain protected.

## Review quality and workflow

`dish_image_review.html` shows three candidates side by side at desktop sizes with 320-pixel-tall, full-width images. Narrow layouts use 400-pixel-tall cards. Images use `object-fit: contain`, not a destructive crop. Click through to source pages for full-size inspection. The page includes dish ID/name/origin, source ID, creator, original dimensions, selected ID, confidence and review status.

Official `image_type=photo`, food-category and safe-search filters are used. Exact canonical/alias tag alignment, dimensions, landscape orientation and quality-warning flags guide ranking. A generic potato curry cannot substitute for Aloo ke Gutke. Metadata alone reaches at most MEDIUM. AI/generated/render/illustration hints, buffet, packaging, logo, watermark and other warnings prevent finalization. Since API type metadata cannot prove an image is a real photograph or accurately identify a regional recipe, **all selections require visual inspection**, including real-photo status, food prominence, lighting, clutter, branding and exact dish identity.

The CSV records confidence/review status. LOW is not finalized. Review rejection marks `UNRESOLVED_PIXABAY`; no results also mark confirmed unresolved only after the actual queries finish. Missing assets continue to use the existing UPLYFA dish placeholder.

After reviewing images, the browser can export `pixabay_30_approvals.json`. Import those exact-dish/quality decisions:

```powershell
python tools/download_dish_images.py approve --source pixabay --approvals "$env:USERPROFILE\Downloads\pixabay_30_approvals.json"
```

**Stop and approve this batch's quality before proceeding.** Only after that explicit approval:

```powershell
python tools/download_dish_images.py finalize --source pixabay --quality-approved
python tools/download_dish_images.py validate --source pixabay
```

The flag documents explicit batch-quality authorization, and exports still require stored HIGH confidence, visual verification and evidence notes. No command expands beyond the 30-dish batch. Do not use this flag as a substitute for reviewing the photographs.

If approved source URLs expire before export, refresh the selected IDs through the API, retaining their query/provenance:

```powershell
python tools/download_dish_images.py refresh --source pixabay
```

## API/license constraints

See the [official API documentation](https://pixabay.com/api/docs/), [Content License summary](https://pixabay.com/service/license-summary/) and [terms](https://pixabay.com/service/terms/). API documentation requires 24-hour caching, lists a default 100-requests-per-60-seconds limit, and prohibits systematic mass downloads. The adapter caches for 24 hours, spaces requests by two seconds, records rate headers, caps the local minute budget at 90, and stops on 429 without retries. These safeguards do not grant permission to systematically download the full 640-dish catalogue; any later expansion must first address the API's bulk-use restrictions.

Search-result previews link to Pixabay and source pages. Temporary preview display is allowed by the API; permanent app hotlinking is not used. Normal API access often supplies a maximum 1280-pixel long-edge `largeImageURL`. Full-HD/original URLs require extended API access and are used only if supplied. No unsupported endpoint or HTML scraping is used to obtain larger images.

Final WebP export preserves aspect ratio, applies EXIF orientation, uses quality 85 and downsizes to at most 1600 pixels. A minimum 1200-pixel long edge and 600-pixel short edge is required; no upscaling. Thus an accurate 1280-pixel source can qualify, while poor small sources cannot. Licensing/visual review must also reject prominent protected logos/brands, misleading endorsement, or unsuitable third-party content; a metadata license label does not waive separate rights restrictions.

## Reports/files

Created: the two source/orchestration scripts, `tools/test_dish_images_pixabay.py`, `pixabay_validation_batch.json`, and this directory's README, review HTML/CSV, unresolved CSV, duplicate CSV, and `summary.json`.

Modified: `.gitignore` (local Pixabay cache exclusion), `assets/data/dish_image_manifest.json` (source runs, not canonical dishes), and `tools/download_dish_images_pexels.py` (approved-source validation compatibility). Original Pexels tooling/reports and any Commons tooling remain intact.

Review HTML: `docs/image_sources/dishes/pixabay_30/dish_image_review.html`.
Review CSV: `docs/image_sources/dishes/pixabay_30/dish_image_review.csv`.
Manifest: `assets/data/dish_image_manifest.json`.

Validation passed: **22 Python pipeline tests** (retained Pexels tests plus Pixabay metadata, missing-key, caching, rate-limit, scope, review, authorization and WebP/provenance export tests), **24 focused Flutter branding/catalogue/placeholder tests**, and **flutter analyze with no issues**. The real 640-row shared manifest and fixed 30-dish batch also validated. The full Flutter suite was not repeated for this tooling-only change; it passed 245 tests in the prior sourcing setup.

Live quality, success rates, average source resolution and remaining-catalogue suitability are untested until PIXABAY_API_KEY is available. This run stops at prepared review files; it does not continue sourcing or fabricate candidate photographs.
