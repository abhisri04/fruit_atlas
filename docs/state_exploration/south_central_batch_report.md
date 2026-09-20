# South / central State Exploration batch report

Validated 2026-09-17. Integrated Mizoram, Tripura, Andhra Pradesh, Telangana and Karnataka directly into the existing generic architecture.

## Counts

District counts were verified against current government directories before writing runtime files. See the [source ledger](south_central_batch_sources.md) for references and naming decisions.

| State | Districts | Canonical experiences | Collections | Dynamic Fruit Atlas members |
| --- | ---: | ---: | ---: | ---: |
| Mizoram | 11 | 26 | 9 | 3 |
| Tripura | 8 | 27 | 9 | 0 |
| Andhra Pradesh | 28 | 30 | 9 | 7 |
| Telangana | 33 | 30 | 9 | 2 |
| Karnataka | 31 | 33 | 9 | 5 |
| **Total** | **111** | **146** | **45** | **17 state memberships** |

Fruit counts are derived from the unchanged canonical seed at validation time; they are not hard-coded collection memberships. All five Fruits collections have `entity_type: fruit` and empty `member_entity_ids`. Tripura currently has no verified canonical fruit-state links, so its Fruits collection remains empty. The 17 state memberships may refer to the same global fruit entities.

| Collection | Mizoram | Tripura | Andhra Pradesh | Telangana | Karnataka |
| --- | ---: | ---: | ---: | ---: | ---: |
| Landmarks & Heritage | 4 | 6 | 6 | 6 | 7 |
| Nature & Wildlife | 6 | 4 | 5 | 5 | 5 |
| Experiences & Activities | 2 | 2 | 2 | 2 | 2 |
| Fruits (dynamic) | 3 | 0 | 7 | 2 | 5 |
| Dishes | 4 | 5 | 6 | 6 | 8 |
| Drinks | 1 | 1 | 1 | 1 | 1 |
| Arts & Crafts | 3 | 2 | 5 | 4 | 4 |
| Festivals & Fairs | 3 | 4 | 3 | 3 | 3 |
| Music & Dance | 3 | 3 | 3 | 3 | 3 |

Places contains Districts, Landmarks & Heritage, and Nature & Wildlife. Things to Do contains Experiences & Activities. Food & Drink and Culture each retain their three collections. Districts are a separate canonical entity type, not a tenth collection.

Andhra Pradesh has 31 experience memberships but 30 canonical experience records: `exp_andhra_pradesh_tholu_bommalata` is intentionally referenced by both Arts & Crafts and Music & Dance. Culture therefore aggregates 10 unique IDs, not 11 memberships. No entities are newly duplicated across states, and no pre-existing IDs were renamed.

## Validation

- New experience records: 146; duplicate IDs within the batch: **0**.
- Duplicate experience IDs across all 1,729 registered records: **0**.
- Cross-state ID collisions involving this batch: **0**.
- New normalized-title collisions within the batch or against all existing experience files: **0**. Normalization checked case, punctuation, whitespace and accents. Existing data contains 23 repeated normalized-title groups; none involves a new entity and those older records were preserved as requested. This report does not claim older title duplication has been repaired.
- Dangling collection member IDs: **0**. Every new experience is referenced by at least one collection.
- Unexpected state/context mismatches: **0** across districts, experiences and collections.
- Duplicate district IDs across all 727 registered districts: **0**.
- Configured assets missing: **0**. All 15 new dataset files are bundled in `pubspec.yaml`; all five district and experience files are registered.
- All **36** State/UT configs resolve. **30** are populated after this batch; six retain their existing placeholders.
- Fruits remain dynamic/global, using `completed_fruit_ids`. No seed records or state relationships were added.
- Experience completion retains `completed_experience_ids`; district completion retains `completed_district_ids`; State Visited retains `completed_india_state_ut_ids`. These completion domains remain independent.
- Snapshot verification covered 214 existing files: only the nine intended existing files below changed; the other 205 remain byte-for-byte identical. In particular, all previously populated state configs/datasets, runtime Dart code, Fruit Atlas seed, and Northeast test file are unchanged.

## Tests and tools

Added **24 tests** in `test/south_central_state_exploration_test.dart`: repository/count/membership/search checks, dynamic Fruits UI, completion-key independence and actual Places/overall unique-ID progress for each state; administrative name/alias checks; global IDs/title/bundling checks; My Life canonical counting; and actual multi-collection puppetry completion/progress in Culture.

The existing empty-context UI regression now uses Lakshadweep because Tripura is populated. Its scroll explicitly reveals Dishes before asserting, allowing for the longer context label. No application code change was needed.

- `flutter test --reporter expanded --timeout 90s`: **114 passed, 0 failed**, exit 0. This includes the 23 unchanged Northeast tests, all-36 resolution, Search, Saved, My Life, State Visited, district and canonical completion regressions.
- `flutter analyze`: **0 errors, 0 warnings, 3 existing informational deprecation findings**, exit 1. The existing `value` parameter findings are at `lib/main_backup.dart:359`, `lib/main_before_varieties.dart:360` and `lib/screens/home/home_page.dart:417`. They are unrelated to this batch and were preserved.
- Dart formatting completed for the two changed test files.

## Research and administrative ambiguity

The [source ledger](south_central_batch_sources.md) maps all 146 canonical experience IDs to government/tourism sources and records district baselines. Main sources include Mizoram Tourism, Mizoram government departments, Tripura Rural Livelihood Mission and IGNCA, Andhra Pradesh district portals, Telangana Tourism, Karnataka Tourism, Incredible India, Coffee Board and the Development Commissioner (Handicrafts).

Current district counts are 11/8/28/33/31. Andhra Pradesh includes Markapuram and Polavaram, superseding the older count of 26. Mizoram uses Siaha with Saiha as an alias. Telangana uses Hanumakonda and Warangal rather than the former Urban/Rural names. Karnataka uses Bengaluru South with Ramanagara as an alias. The currently consulted NIC and district administrative portals still say Bengaluru Rural despite the Bengaluru North cabinet announcement; the latter is retained as an alias and the inconsistency is explicitly documented. No duplicate district is created for a renamed jurisdiction.

No ZIP, release freeze, tag or physical-phone QA was performed.

## Exact files changed in this batch

**27 files: 18 new files and 9 existing files updated.** This list is relative to the start-of-task snapshot, not the broader pre-existing working-tree changes.

- `assets/data/state_exploration/mizoram.json`
- `assets/data/mizoram_districts.json`
- `assets/data/mizoram_experiences.json`
- `assets/data/mizoram_collections.json`
- `assets/data/state_exploration/tripura.json`
- `assets/data/tripura_districts.json`
- `assets/data/tripura_experiences.json`
- `assets/data/tripura_collections.json`
- `assets/data/state_exploration/andhra_pradesh.json`
- `assets/data/andhra_pradesh_districts.json`
- `assets/data/andhra_pradesh_experiences.json`
- `assets/data/andhra_pradesh_collections.json`
- `assets/data/state_exploration/telangana.json`
- `assets/data/telangana_districts.json`
- `assets/data/telangana_experiences.json`
- `assets/data/telangana_collections.json`
- `assets/data/state_exploration/karnataka.json`
- `assets/data/karnataka_districts.json`
- `assets/data/karnataka_experiences.json`
- `assets/data/karnataka_collections.json`
- `assets/data/district_sources.json`
- `assets/data/experience_sources.json`
- `pubspec.yaml`
- `test/south_central_state_exploration_test.dart`
- `test/state_exploration_architecture_test.dart`
- `docs/state_exploration/south_central_batch_sources.md`
- `docs/state_exploration/south_central_batch_report.md`
