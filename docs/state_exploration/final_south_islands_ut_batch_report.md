# Final South, islands and UT State Exploration batch report

Validated against the canonical repository schema on 2026-09-20. The later user instruction to place Landmarks & Heritage and Nature & Wildlife under Things to Do in **every** State/UT supersedes the section diagram in the pasted batch brief. The global correction is included here.

## Batch counts

| Context | Districts | Generic experiences | Landmarks | Nature | Activities | Fruits (stored) | Dishes | Drinks | Arts | Festivals | Music | Dynamic fruit links |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Kerala | 14 | 32 | 6 | 5 | 2 | 0 | 7 | 1 | 4 | 3 | 4 | 4 |
| Tamil Nadu | 38 | 25 | 6 | 4 | 1 | 0 | 5 | 1 | 4 | 3 | 2 | 2 |
| Puducherry | 2 | 16 | 5 | 3 | 2 | 0 | 1 | 0 | 2 | 2 | 1 | 0 |
| Andaman & Nicobar Islands | 3 | 17 | 4 | 4 | 2 | 0 | 1 | 0 | 3 | 2 | 1 | 0 |
| Lakshadweep | 1 | 13 | 2 | 2 | 2 | 0 | 1 | 0 | 2 | 1 | 3 | 0 |
| Dadra & Nagar Haveli and Daman & Diu | 3 | 15 | 6 | 2 | 1 | 0 | 1 | 0 | 1 | 1 | 3 | 0 |

The Fruits stored-member count is zero for every context; fruit memberships come from `fruit_atlas_seed.json` state relationships at runtime. Kerala currently has 4 canonical Fruit links and Tamil Nadu 2; the four UT contexts have no verified canonical links and therefore render an empty Fruit collection. Drinks are empty in four UT contexts rather than manufacturing local non-alcoholic items or copying the already-canonical tender coconut water experience.

## Validation and architecture

- 36/36 canonical State and UT configurations resolve; 36 ? 9 = 324 collections. All configured assets exist.
- Whole catalogue: 788 district IDs and 1,847 generic experience IDs. The six new contexts contribute 61 districts and 118 experiences.
- New-batch duplicate IDs: 0. New-batch dangling collection IDs: 0. Global duplicate district IDs: 0. Global duplicate experience IDs: 0. New versus prior normalized-title collisions: 0.
- Three Things to Do collections now exist in all 36 contexts in order: Landmarks & Heritage, Nature & Wildlife, Experiences & Activities. Places is reserved for Districts. The cross-catalogue correction moved 32 collection parents, aligned 657 linked experience section values, and standardized Activities at sort order 3 where needed. Existing entity IDs and completion keys did not change.
- Rajasthan has three deliberate cross-section memberships: local bazaar, handicraft market, and heritage haveli belong to Culture canonically but also appear in the Activities collection. Their Culture section remains intact; the Landmarks and Nature collections are correctly under Things to Do.
- `completed_district_ids`, `completed_experience_ids`, `completed_fruit_ids`, and State Visited stay independent. No new model fields or special-case UI were added. Search, Saved, My Life, Daily Discovery, and Yoga code was not changed for this batch.
- The Chennai Margazhi music season is one Tamil Nadu experience ID referenced by both Festivals & Fairs and Music & Dance, so completion is shared. Generic South Indian dosa, idli, filter coffee, and tender coconut water records were not duplicated. The Kanchipuram-specific idli entry is named and identified by location.
- Previously populated State/UT **districts, entity IDs, and collection memberships** remain unchanged. Their collection parent/ordering and experience section fields were updated where necessary for the user-requested global Things to Do correction; see the exact changed-file list below. Rajasthan collection data was restored byte-for-byte because it already satisfied the requested placement.

## District baseline and source decisions

| Context | Count and basis |
|---|---|
| Kerala | 14 districts from the [government directory](https://igod.gov.in/sg/KL/E042/organizations). |
| Tamil Nadu | 38 districts from the [government directory](https://igod.gov.in/sg/TN/E042/organizations). |
| Puducherry | 2 revenue districts (Puducherry and Karaikal) from the [UT district page](https://www.py.gov.in/districts) and [planning department](https://pandr.py.gov.in/sites/default/files/Sectoral%20Document%202019-2020.pdf). Mahe and Yanam are outlying administrative units of Puducherry district. The UT page also uses loose four-district wording elsewhere; the explicit revenue-district list governs this dataset. |
| Andaman & Nicobar Islands | 3 districts from the [government directory](https://igod.gov.in/sg/AN/E042/organizations). |
| Lakshadweep | 1 district from the [UT administrative setup](https://lakshadweep.gov.in/about-lakshadweep/administrative-setup/); inhabited islands are not separate districts. |
| Dadra & Nagar Haveli and Daman & Diu | 3 districts (Dadra & Nagar Haveli, Daman, Diu) from the [merged UT FAQ](https://ddd.gov.in/faqs/). |

The [source ledger](final_south_islands_ut_batch_sources.md) maps every one of the 118 new experience IDs to government, tourism, or other official evidence. Public island experiences were chosen with protected/restricted areas and activity permits in mind.

## Exact files changed for this batch and global placement correction

86 files relative to the pre-batch workspace snapshot. Existing unrelated work in the checkout is excluded.

- `assets/data/andaman_nicobar_collections.json`
- `assets/data/andaman_nicobar_districts.json`
- `assets/data/andaman_nicobar_experiences.json`
- `assets/data/andhra_pradesh_collections.json`
- `assets/data/andhra_pradesh_experiences.json`
- `assets/data/arunachal_pradesh_collections.json`
- `assets/data/arunachal_pradesh_experiences.json`
- `assets/data/assam_collections.json`
- `assets/data/assam_experiences.json`
- `assets/data/bihar_experiences.json`
- `assets/data/chandigarh_collections.json`
- `assets/data/chandigarh_experiences.json`
- `assets/data/chhattisgarh_collections.json`
- `assets/data/chhattisgarh_experiences.json`
- `assets/data/dadra_nagar_haveli_daman_diu_collections.json`
- `assets/data/dadra_nagar_haveli_daman_diu_districts.json`
- `assets/data/dadra_nagar_haveli_daman_diu_experiences.json`
- `assets/data/delhi_collections.json`
- `assets/data/delhi_experiences.json`
- `assets/data/district_sources.json`
- `assets/data/experience_sources.json`
- `assets/data/goa_collections.json`
- `assets/data/goa_experiences.json`
- `assets/data/gujarat_collections.json`
- `assets/data/gujarat_experiences.json`
- `assets/data/haryana_collections.json`
- `assets/data/haryana_experiences.json`
- `assets/data/himachal_pradesh_collections.json`
- `assets/data/himachal_pradesh_experiences.json`
- `assets/data/jammu_kashmir_collections.json`
- `assets/data/jammu_kashmir_experiences.json`
- `assets/data/jharkhand_experiences.json`
- `assets/data/karnataka_collections.json`
- `assets/data/karnataka_experiences.json`
- `assets/data/kerala_collections.json`
- `assets/data/kerala_districts.json`
- `assets/data/kerala_experiences.json`
- `assets/data/ladakh_collections.json`
- `assets/data/ladakh_experiences.json`
- `assets/data/lakshadweep_collections.json`
- `assets/data/lakshadweep_districts.json`
- `assets/data/lakshadweep_experiences.json`
- `assets/data/madhya_pradesh_collections.json`
- `assets/data/madhya_pradesh_experiences.json`
- `assets/data/maharashtra_collections.json`
- `assets/data/maharashtra_experiences.json`
- `assets/data/manipur_collections.json`
- `assets/data/manipur_experiences.json`
- `assets/data/meghalaya_collections.json`
- `assets/data/meghalaya_experiences.json`
- `assets/data/mizoram_collections.json`
- `assets/data/mizoram_experiences.json`
- `assets/data/nagaland_collections.json`
- `assets/data/nagaland_experiences.json`
- `assets/data/odisha_experiences.json`
- `assets/data/puducherry_collections.json`
- `assets/data/puducherry_districts.json`
- `assets/data/puducherry_experiences.json`
- `assets/data/punjab_collections.json`
- `assets/data/punjab_experiences.json`
- `assets/data/sikkim_experiences.json`
- `assets/data/state_exploration/andaman_nicobar.json`
- `assets/data/state_exploration/dadra_nagar_haveli_daman_diu.json`
- `assets/data/state_exploration/kerala.json`
- `assets/data/state_exploration/lakshadweep.json`
- `assets/data/state_exploration/puducherry.json`
- `assets/data/state_exploration/tamil_nadu.json`
- `assets/data/tamil_nadu_collections.json`
- `assets/data/tamil_nadu_districts.json`
- `assets/data/tamil_nadu_experiences.json`
- `assets/data/telangana_collections.json`
- `assets/data/telangana_experiences.json`
- `assets/data/tripura_collections.json`
- `assets/data/tripura_experiences.json`
- `assets/data/uttar_pradesh_collections.json`
- `assets/data/uttar_pradesh_experiences.json`
- `assets/data/uttarakhand_collections.json`
- `assets/data/uttarakhand_experiences.json`
- `assets/data/west_bengal_experiences.json`
- `docs/state_exploration/final_south_islands_ut_batch_report.md`
- `docs/state_exploration/final_south_islands_ut_batch_sources.md`
- `pubspec.yaml`
- `test/final_south_islands_ut_state_exploration_test.dart`
- `test/northeast_state_exploration_test.dart`
- `test/south_central_state_exploration_test.dart`
- `test/state_exploration_architecture_test.dart`

## Checks

- Global JSON/schema audit: 36 contexts, 324 collections, 788 districts, 1,847 experiences; zero duplicate IDs; zero dangling members; correct Things to Do parents for all 36.
- `flutter analyze`: completed; exits 1 solely on three pre-existing `deprecated_member_use` info messages in `lib/main_backup.dart:359`, `lib/main_before_varieties.dart:360`, and `lib/screens/home/home_page.dart:417`. No new analysis errors or warnings.
- `flutter test --reporter expanded --timeout 90s`: 142 tests passed (exit 0).
- Consolidated phone QA has not been performed. The code is ready for that QA after these automated checks pass; freezing/tagging should follow successful phone QA.
