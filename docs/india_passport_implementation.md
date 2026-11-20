# India Passport implementation

India Passport tracks visits and travel intent independently of Explore India.
Passport updates never call experience, food, drink, book, or legacy challenge
completion methods. Existing category metrics and historical state progress are
retained; passport status does not contribute to those metrics in this sprint.

## Files created

- `lib/models/state_travel_status.dart`
- `lib/services/state_travel_service.dart`
- `lib/services/india_map_repository.dart`
- `lib/widgets/india_passport_map.dart`
- `lib/widgets/travel_journeys.dart`
- `lib/screens/travel/india_passport_page.dart`
- `lib/screens/travel/explore_india_page.dart`
- `assets/data/india_passport_boundaries.json`
- `docs/data_sources/india_passport_attribution.md`
- `docs/data_sources/india_passport_source_license.txt`
- `test/india_passport_test.dart`
- This report.

## Files modified for this task

- `assets/data/challenges.json`: Explore India title and exploration vocabulary.
- `pubspec.yaml`: bundles the offline map geometry.
- `lib/theme/app_colors.dart`: passport color tokens.
- `lib/navigation/challenge_navigation.dart`: state journey opens derived exploration.
- `lib/screens/home/home_page.dart`: separate passport/exploration entry cards.
- `lib/screens/discover/discover_page.dart`: separate travel journeys.
- `lib/screens/challenge/checklist_item_details_page.dart`: removes the state visit
  checkbox from exploration details and explains the passport entry point.
- `test/india_states_challenge_test.dart`, `test/state_exploration_test.dart`,
  `test/experience_semantics_test.dart`: expectations follow the separated copy.
- `test/ui_preview_test.dart`: phone preview for the new passport screen.

The workspace contained other pre-existing edits, which were preserved.

## Map source and canonical alignment

The bundled, unmodified low-resolution GeoJSON comes from
[Vardhan Systems](https://github.com/Vardhan-Systems/vardhan-maps), source revision
`37989cabe48ce9d235747e6b128bc9dbf2161ec9`, file
`src/data/generated/states.low.json`. It contains 36 Polygon/MultiPolygon
features. Source data derives from OpenStreetMap under ODbL 1.0; source code
license and data attribution are retained in `docs/data_sources`. The app shows
OpenStreetMap attribution and its copyright URL. This is general travel geometry,
not an official or survey-grade map.

`IndiaMapRepository.sourceIds` explicitly maps each source ISO region code to
the existing `IndiaLocationRegistry` ID, e.g. `IN-RJ` → `rajasthan`, `IN-DL` →
`delhi`, `IN-DH` → `dadra_nagar_haveli_daman_diu`. There is no second application
ID system. Loading rejects duplicate, missing, or unknown regions. Tests assert
exact equality with all 36 registry IDs and non-empty paths.

Coordinates are projected to Flutter `Path` objects, preserving multiple
polygons and interior rings with even-odd fills. Painting and hit detection use
the same fitted paths. Smaller overlapping regions take precedence. The map is
clipped and wrapped in `InteractiveViewer` with pinch/drag, 1–8× zoom, and reset.
Lakshadweep's source geometry is its marine administrative footprint. It is
rendered translucently with a labeled status marker so the footprint does not
appear to be one large island. Its source path remains selectable.

## Status and persistence

`StateTravelStatus` contains `stateId`, one `TravelStatus` enum, and `updatedAt`.
Storage values are `none`, `want_to_visit`, and `visited`; missing entries default
to `none`. The single enum prevents contradictory statuses.

- Visited replaces Want to Visit.
- Want to Visit is disabled while Visited is active, and the service enforces it.
- Toggling Visited off or selecting Clear resets to Unmarked.
- Counts include only entries with the exact respective enum value.

Status changes notify listeners immediately, then persist to SharedPreferences
key `india_passport_status_v1`. Writes are serialized to preserve action order.
Reopening reloads statuses, counts, and corresponding colors. Save failures show
a retry message rather than silently claiming success.

## Colors and interactions

Theme tokens define neutral grey for Unmarked, amber for Want to Visit, teal for
Visited, and a gold selected-region outline. Region fills transition over 180 ms.
Tap opens a sheet with canonical state name, current status, selected action
chips, Clear, and Explore State. Selection clears when the sheet closes.

Map is the default view. List fallback includes every canonical State & UT,
accessible labeled rows, status chips, and the same detail actions. It makes Goa,
Delhi, Chandigarh, Puducherry, Lakshadweep, northeastern states, and other compact
regions selectable without requiring precise map taps. The map also gives a
zoom/List hint.

Explore State resolves the existing canonical item and opens
`ChecklistItemDetailsPage`. Explore India calculates per-state completed/total
canonical linked experience IDs, deduplicating IDs for its overall explored
count. Historical manually checked state progress is not used for this new
experience-depth screen, and no visit status changes it.

## Validation

The passport tests cover map taps, statuses/counts, precedence, Clear, theme
colors, persistence reload, canonical ID coverage, independence from experience
and legacy progress, small-region list actions, and Explore State navigation.
The UI preview test writes `build/ui_review/india_passport.png`.

- `flutter analyze`: passed, no issues found.
- `flutter test --concurrency=1 --reporter expanded --timeout 120s`: passed,
  all 230 tests.
- Passport-specific tests: all four test groups passed.
- Phone preview inspected at 390 × 844; map, summary, legend, reset control,
  List fallback, and attribution fit the screen.
