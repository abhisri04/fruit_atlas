# Northeast State Exploration integration report

Completed 17 September 2026. Scope: Assam, Arunachal Pradesh, Meghalaya, Nagaland and Manipur. No ZIP created.

## Counts

| Metric | Assam | Arunachal Pradesh | Meghalaya | Nagaland | Manipur |
|---|---:|---:|---:|---:|---:|
| Official districts | 35 | 28 | 12 | 17 | 16 |
| Generic experiences | 33 | 32 | 31 | 27 | 33 |
| Landmarks & Heritage | 7 | 5 | 4 | 3 | 7 |
| Nature & Wildlife | 5 | 6 | 7 | 4 | 6 |
| Experiences & Activities | 2 | 2 | 2 | 2 | 2 |
| Fruits (static members) | 0 | 0 | 0 | 0 | 0 |
| Dishes | 7 | 6 | 8 | 6 | 5 |
| Drinks (non-alcoholic) | 1 | 1 | 1 | 1 | 1 |
| Arts & Crafts | 4 | 3 | 3 | 3 | 4 |
| Festivals & Fairs | 3 | 5 | 4 | 6 | 4 |
| Music & Dance | 4 | 4 | 2 | 2 | 4 |
| Fruits (current dynamic membership) | 5 | 4 | 0 | 1 | 1 |

**Batch totals: 108 districts, 156 generic experiences, 45 collections.** All nine collections exist for each state. Fruits have zero static members; the current dynamic counts above are derived from the unchanged Fruit Atlas seed, not copied into collections or Experience files.

## Structure and canonical behaviour

- Places contains Districts, Landmarks & Heritage, and Nature & Wildlife. Things to Do contains Experiences & Activities, as specified in this batch request.
- No new repository, model, state-specific UI, persistence key or source field was introduced.
- A regression test exposed an existing overall-progress bug: when districts existed, the overall count excluded every Experience with section `Places`, even if it was displayed in a collection. The small generic fix in `checklist_item_details_page.dart` includes Places experiences referenced by collections. It iterates canonical Experience records, so shared memberships do not multiply overall progress. Existing section progress already deduplicates IDs.
- `completed_experience_ids`, `completed_fruit_ids`, `completed_district_ids` and `completed_india_state_ut_ids` remain unchanged and independent. Existing saved progress is retained.
- Fruits remain global/canonical. Current dynamic membership includes both nonempty and empty state relationships; no unsupported relationships were added.
- Dzüko/Dzukou Valley is represented once under Nagaland and acknowledges the Manipur border. Existing Momos, Thukpa, Butter Tea and Losar records were not duplicated.

## Validation

| Check | Result |
|---|---|
| Duplicate new experience IDs | 0 |
| Dangling new collection member IDs | 0 |
| New-to-existing experience ID collisions | 0 |
| Duplicate new district IDs | 0 |
| Duplicate new collection IDs | 0 |
| Wrong district/experience state IDs or collection context IDs | 0 |
| Missing configured assets | 0 |
| New normalized title collisions with previous records | 0 |
| All canonical State/UT configs resolve | 36 / 36 |
| Registered canonical experience IDs, all states | 1583 unique |
| Registered canonical district IDs, all states | 616 unique |

Compared SHA-256 hashes against 176 baseline files captured before this batch. All previously populated state/UT JSON files, Fruit Atlas data, canonical index and persistence service are byte-for-byte unchanged. Only the five target placeholder configs, two registries, pubspec and the documented progress-rendering fix differ among baseline files. Other pre-existing working-tree edits were retained.

## Tests and analysis

- `flutter test --reporter expanded --timeout 90s`: **90 passed, 0 failed** (exit 0).
- Added 23 tests: five each for repository resolution/memberships/canonical Search, dynamic Fruits UI, independent completion, and actual UI unique-ID aggregation; plus administrative names, My Life canonical/stale-ID handling, and global uniqueness/asset registration/non-alcoholic Drinks.
- The existing empty-state fixture now uses unpopulated Tripura instead of newly populated Meghalaya. Existing regression coverage for Search navigation, Saved canonical references, My Life and all 36 configurations passes.
- `flutter analyze`: **0 errors, 0 warnings, 3 pre-existing informational deprecations** (exit 1). The unchanged notices concern deprecated `value` arguments in `lib/main_backup.dart:359`, `lib/main_before_varieties.dart:360`, and `lib/screens/home/home_page.dart:417`.
- The first runs exposed test scrolling/empty-fixture assumptions and the real Places aggregation defect. All were corrected before the successful full run.

## Exact files changed in this batch

28 files. This list excludes changes already present before the batch.

- `assets/data/state_exploration/assam.json`
- `assets/data/assam_districts.json`
- `assets/data/assam_experiences.json`
- `assets/data/assam_collections.json`
- `assets/data/state_exploration/arunachal_pradesh.json`
- `assets/data/arunachal_pradesh_districts.json`
- `assets/data/arunachal_pradesh_experiences.json`
- `assets/data/arunachal_pradesh_collections.json`
- `assets/data/state_exploration/meghalaya.json`
- `assets/data/meghalaya_districts.json`
- `assets/data/meghalaya_experiences.json`
- `assets/data/meghalaya_collections.json`
- `assets/data/state_exploration/nagaland.json`
- `assets/data/nagaland_districts.json`
- `assets/data/nagaland_experiences.json`
- `assets/data/nagaland_collections.json`
- `assets/data/state_exploration/manipur.json`
- `assets/data/manipur_districts.json`
- `assets/data/manipur_experiences.json`
- `assets/data/manipur_collections.json`
- `assets/data/district_sources.json`
- `assets/data/experience_sources.json`
- `pubspec.yaml`
- `lib/screens/challenge/checklist_item_details_page.dart`
- `test/northeast_state_exploration_test.dart`
- `test/state_exploration_architecture_test.dart`
- `docs/state_exploration/northeast_batch_sources.md`
- `docs/state_exploration/northeast_batch_report.md`

## Government and tourism sources

The [research ledger](northeast_batch_sources.md) maps every new Experience ID to its government/tourism source and records administrative reconciliation. Main district sources:

- Assam: [government district dashboard](https://brikhyabandhu.assam.statedatacenter.in/summary-report) and [Sribhumi district portal](https://sribhumi.assam.gov.in/about-us/geography).
- Arunachal Pradesh: [state portal](https://www.arunachalpradesh.gov.in/), [government investment district map](https://arunachalinvestment.in/investment/) and [Itanagar Capital Complex](https://itanagar.nic.in/).
- Meghalaya: [government district directory](https://www.meghalaya.gov.in/districts).
- Nagaland: [tourism district directory](https://tourism.nagaland.gov.in/districts/) and [Meluri notification/inauguration](https://ipr.nagaland.gov.in/CHIEF-MINISTER-NEIPHIU-RIO-INAUGURATES-MELURI-AS-THE-17TH-DISTRICT).
- Manipur: [NIC state profile](https://manipur.nic.in/profile/).
