# India Passport percentage and sharing

## Files

Modified:
- `lib/screens/travel/india_passport_page.dart`: header ring and top-right preview action.
- `lib/services/share_studio_service.dart`: reusable RepaintBoundary PNG rendering, native image/text sharing, rendering fallback.

Created:
- `lib/models/india_passport_share_data.dart`: immutable canonical status snapshot and derived counts.
- `lib/models/share_branding_config.dart`: app name, tagline, optional logo asset.
- `lib/widgets/india_passport_ring.dart`: shared animated percentage ring.
- `lib/widgets/india_passport_share_card.dart`: illustrative Story and Square poster layouts and status map painter.
- `lib/screens/share/india_passport_share_page.dart`: live preview, format selector and explicit Share action.
- `test/india_passport_share_test.dart`: data, animation, export, live preview and sharing failure tests.
- This report.

## Progress and animation

The precise ratio is `visitedCount / IndiaLocationRegistry.allLocationIds.length` (36). Displayed percentage is `(ratio * 100).round()`. Want to Visit contributes nothing. Not marked is `36 - visited - wanted`.

The header ring first renders at the loaded ratio, rather than animating from zero. Subsequent changes animate the precise ring and rounded number over 350 ms with easeOutCubic. Existing map fill transitions remain 180 ms. No new confetti or achievement logic was added.

## Share architecture and map

The Passport action opens a dedicated template preview using the existing Share Studio service and `ShareCardFormat`. It does not immediately share. The preview listens to its travel service and persisted status change notifications; newly opened previews also use current statuses.

The share snapshot reads every canonical location from `StateTravelService.statusFor`. The map reuses `IndiaMapRepository` boundary paths, `IndiaPassportMap.fittedPath`, and `passportColor`. Visited is teal, wanted amber, unmarked neutral. Lakshadweep's marine administrative footprint remains translucent with a center marker. OSM attribution is included on the card.

Story defaults to 9:16 and exports 1080×1920 PNG. Square rearranges the same elements into a ring/map row and exports 1080×1080; it is not cropped. Both use cream gradients, navy typography, teal progress, amber sun, and original vector mountains/river decoration. The scenery conveys no landmark completion data.

`ShareBrandingConfig` defaults to `AppBranding.appName` (UPLYFA) and `AppBranding.tagline` (Experience more.) with an optional logo asset. Changing this configuration updates both brand areas. The repository currently exposes no user display-name field; the template accepts an optional display name and hides null/blank names.

## Native flow and failures

Preview → Share → settle current animation → render only the card's RepaintBoundary at 1080-pixel width → Share Studio service → SharePlus native sheet with an image/png attachment named `india-passport.png`. No direct social APIs are used. Android recipient apps determine their supported image handling.

Rendering failure falls back to the same snapshot's text, for example: `I've visited 13 of India's 36 States & UTs — 36% of India.` Invocation exceptions or an unavailable native sheet produce a visible retry snackbar. Share is disabled while preparing the export. The image resource is disposed after encoding.

## Validation

`flutter analyze`: no issues found. Full `flutter test --concurrency=1 --reporter expanded --timeout 120s`: **241 tests passed**. Story and Square exports were visually inspected; an unsupported decorative text glyph found in review was removed.

The new tests cover precise ratio and rounding, excluded intent, counts, immutable snapshot updates, all three shared map colors, initial ring state and intermediate/final animation values, both PNG dimensions, branding, absent/present name, live preview status updates, default/switchable formats, existing service invocation, rendering fallback and visible invocation errors.

Local review images are generated at `build/ui_review/passport_share_story.png` and `build/ui_review/passport_share_square.png`; phone header previews remain in `build/ui_review/india_passport.png`.

Physical Android QA remains necessary for recipient-specific WhatsApp/Instagram/Messages behavior: open preview, switch both formats, share an image, cancel the sheet, reopen after changing statuses, and verify the received image and counts.
