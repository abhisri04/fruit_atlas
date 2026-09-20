# State Exploration integration report

## A. Exact files changed in this task

Existing unrelated working-tree changes were preserved. No application Dart code or persistence keys were changed by this task.

- `assets/data/state_exploration/madhya_pradesh.json`
- `assets/data/state_exploration/gujarat.json`
- `assets/data/state_exploration/maharashtra.json`
- `assets/data/state_exploration/goa.json`
- `assets/data/state_exploration/chhattisgarh.json`
- `assets/data/madhya_pradesh_districts.json`
- `assets/data/madhya_pradesh_experiences.json`
- `assets/data/madhya_pradesh_collections.json`
- `assets/data/gujarat_districts.json`
- `assets/data/gujarat_experiences.json`
- `assets/data/gujarat_collections.json`
- `assets/data/maharashtra_districts.json`
- `assets/data/maharashtra_experiences.json`
- `assets/data/maharashtra_collections.json`
- `assets/data/goa_districts.json`
- `assets/data/goa_experiences.json`
- `assets/data/goa_collections.json`
- `assets/data/chhattisgarh_districts.json`
- `assets/data/chhattisgarh_experiences.json`
- `assets/data/chhattisgarh_collections.json`
- `assets/data/district_sources.json`
- `assets/data/experience_sources.json`
- `pubspec.yaml`
- `test/state_exploration_architecture_test.dart`
- `test/global_search_test.dart`
- `STATE_EXPLORATION_INTEGRATION_REPORT.md`

## B-F. Validated counts

| State | Districts | Experiences | Collections |
|---|---:|---:|---:|
| Madhya Pradesh | 55 | 84 | 9 |
| Gujarat | 33 | 84 | 9 |
| Maharashtra | 36 | 91 | 9 |
| Goa | 3 | 71 | 9 |
| Chhattisgarh | 33 | 79 | 9 |

All nine per-collection counts match the request and are asserted in tests. Goa retains North Goa, South Goa, and Kushavati. Every district state_id, experience state_id, and collection context_id matches its state. Every configured asset exists and is bundled. The 20 JSON files were initially copied byte-identically. Following the requested category correction, the five collection files place Landmarks & Heritage and Nature & Wildlife under Things to Do, ordered before Experiences & Activities. Research markdown is not loaded by Flutter.

## G-J. Integrity and regression

- Zero duplicate experience IDs, zero dangling collection memberships, and zero collisions against the 796 previously populated experience IDs.
- Fruit collections have empty explicit membership and continue deriving fruits from canonical Fruit Atlas state relationships; no fruits were copied into experience data.
- Hash comparison against the pre-integration working tree confirmed previously populated state data and all other existing data files are unchanged, apart from the two source registries and five target placeholder configurations.
- All 36 configurations resolve through StateExplorationRepository.
- Canonical experience, fruit, and district completion stores are preserved. State Visited and district completion remain independent. Unique canonical-ID aggregation regression passes.
- Search, Saved, and My Life regressions pass. Broad search remains capped at 60; the search test now checks Somnath with a specific query rather than requiring it within the first 60 Temple matches.
- The empty-state fixture now uses Meghalaya, since Goa is populated and Kerala has canonical fruits.

## K. flutter analyze

Exit code 1: three existing informational deprecated_member_use diagnostics in unchanged files:

- lib/main_backup.dart:359
- lib/main_before_varieties.dart:360
- lib/screens/home/home_page.dart:417

No diagnostics in changed files.

## L. flutter test

Full suite: **51 passed, 0 failed**, exit code 0. Includes all existing State Exploration regressions and the new integration checks.
