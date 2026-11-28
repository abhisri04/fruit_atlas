# UPLYFA branding migration

Canonical product name: **UPLYFA**. Canonical tagline: **Experience more.**

## Source of truth

`lib/models/app_branding.dart` owns `appName`, `tagline`, and the natural text-share signature. Existing `ShareBrandingConfig` defaults delegate to it and retain optional/custom logo, name and tagline support. Flutter widgets and book share payloads use these constants; platform metadata mirrors them because native labels cannot import Dart. Regression tests verify the native values against the Dart configuration.

## User-facing changes

| Surface | Result |
| --- | --- |
| Android installed name | Manifest references `@string/app_name`; new `res/values/strings.xml` provides UPLYFA. |
| Flutter | MaterialApp title and exit snackbar use AppBranding. |
| Home | Existing hero title is UPLYFA; fruit catalogue action and catalogue title say “Browse fruits”. Greetings, progress and navigation remain. |
| India Passport share | Both existing brand areas now default to UPLYFA and Experience more.; Story/Square layout and live status data remain. |
| My Journey / Highlights | Preview footer and shared text use the canonical name and tagline. |
| Books / author / genre / collection | BookSharePayload brand defaults to UPLYFA; generated sharing text ends with the canonical signature. |
| iOS / macOS | Display names updated; macOS window and About/Hide/Quit menu labels updated. |
| Web | HTML title, install name, short name and description updated. |
| Windows / Linux | Window titles updated; Windows product description/name updated. |
| Catalogue copy | Shipped fruit and collection descriptions use the neutral phrase “fruit catalogue”; editorial metadata is unbranded. |
| Developer photo review | Generated HTML and current review page use “Fruit photo review”. |

No dedicated onboarding, Settings/About, notification or branded Flutter splash screen exists. Android launch background is plain white; iOS launch image is an empty transparent placeholder. These require no branding edits or redesign. Existing quest/achievement wording contains no retired product name and remains unchanged. macOS native About menu is covered above. No standalone achievement-card template exists; future templates can use the shared branding configuration.

## Identifiers and compatibility

Android applicationId and namespace remain **com.example.fruit_atlas**. Kotlin package remains `com.example.fruit_atlas`. iOS/macOS bundle identifier remains `com.example.fruitAtlas`. Dart package `fruit_atlas`, `FruitAtlasApp`/`FruitAtlasData` class names, loading method names, seed filename, persistence keys and canonical IDs remain stable. Native binary/product build filenames remain technical compatibility names; display labels are UPLYFA.

## Search audit

Searched the project, including ignored/hidden source files while excluding Git/build/dependency caches, for the old spaced product name, its India variant, both case variants of the app-name placeholder, the former tagline, and the old greeting. Also searched underscore/camel-case compatibility names and all share-text generation.

- **A — shipped user-facing copy:** no retired branding remains in `lib`, `assets/data`, or native/web display labels. This includes alternate backup Dart entrypoints, so switching entrypoints cannot restore the retired title. The branded editorial generator was updated so regenerating yoga data cannot reintroduce the retired name.
- **B — internal technical/data names:** package/class/file/persistence identifiers and the Gradle wrapper's `APP_NAME="Gradle"` shell variable are intentionally preserved. Photo tooling docstrings refer to the original fruit dataset, rather than the app display name.
- **C — historical/test fixtures:** previous data-source/report titles and snapshot-integrity descriptions retain their historical wording. Four state exploration test descriptions name the original fruit dataset. Tests explicitly checking that retired branding is absent must contain those strings as negative expectations/regex patterns. None of these are shipped app copy.

The real category label “Life Experiences”, Fruit/Fruits names, and scientific/content titles remain unchanged. It is only the old *product signature* in book sharing that was replaced.

## Logo and asset inspection

Representative Android, iOS, web, macOS and Windows launcher images were visually inspected. They are generic Flutter artwork without old product text. The iOS launch placeholder is empty. No text-based retired product logo was found and no image/logo assets were modified or generated. Generic Flutter launcher icons remain and can be replaced by final product artwork in a separate task.

## Files

Created:
- `lib/models/app_branding.dart`
- `android/app/src/main/res/values/strings.xml`
- `test/app_branding_test.dart`
- `docs/uplyfa_branding_migration.md`

Modified Dart/UI/sharing:
- `lib/app/app.dart`
- `lib/screens/home/home_page.dart`
- `lib/screens/share/share_studio_page.dart`
- `lib/models/share_branding_config.dart`
- `lib/models/book.dart`
- `lib/services/book_collection_service.dart`
- `lib/main_backup.dart`
- `lib/main_before_varieties.dart`
- `tool/generate_yoga_catalogue.dart`

Modified platform/project metadata:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `macos/Runner/Info.plist`
- `macos/Runner/Base.lproj/MainMenu.xib`
- `web/index.html`
- `web/manifest.json`
- `windows/runner/main.cpp`
- `windows/runner/Runner.rc`
- `linux/runner/my_application.cc`
- `pubspec.yaml` (description only)
- `README.md`

Modified data (description/editorial strings only, no ID or path changes):
- `assets/data/fruit_atlas_seed.json`
- `assets/data/yoga_poses.json`
- Collection files under `assets/data/`: `andaman_nicobar_collections.json`, `andhra_pradesh_collections.json`, `arunachal_pradesh_collections.json`, `assam_collections.json`, `chandigarh_collections.json`, `dadra_nagar_haveli_daman_diu_collections.json`, `delhi_collections.json`, `haryana_collections.json`, `himachal_pradesh_collections.json`, `jammu_kashmir_collections.json`, `karnataka_collections.json`, `kerala_collections.json`, `ladakh_collections.json`, `lakshadweep_collections.json`, `manipur_collections.json`, `meghalaya_collections.json`, `mizoram_collections.json`, `nagaland_collections.json`, `puducherry_collections.json`, `punjab_collections.json`, `tamil_nadu_collections.json`, `telangana_collections.json`, `tripura_collections.json`, `uttarakhand_collections.json`, `uttar_pradesh_collections.json`.

Modified tests/tools/documentation:
- `test/back_navigation_test.dart`
- `test/home_polish_test.dart`
- `test/daily_discovery_ui_test.dart`
- `test/india_passport_share_test.dart`
- `test/share_studio_test.dart`
- `test/books_integration_test.dart`
- `tools/fruit_photo_pipeline.py`
- `docs/image_sources/fruit_photo_review.html`
- `docs/india_passport_sharing.md`

## Validation

Regression coverage verifies the canonical constants, Flutter title, Home title, share defaults, both Passport export formats, Highlights footer, book branding, platform labels and unchanged Android ID. A shipped-source/data audit test prevents retired display branding from returning.

`flutter analyze`: **no issues found** (including the updated generator).

Full `flutter test --concurrency=1 --reporter expanded --timeout 120s`: **245 tests passed**. Photo tooling syntax also validated. Both Passport export formats were regenerated with canonical branding, and the Story export was visually reviewed.

Native builds and installed-device launcher checks were not run; platform resource values were inspected and tested.
