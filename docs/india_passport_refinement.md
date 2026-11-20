# India Passport refinement

This refines the existing map, passport, and canonical state exploration pages.
No map data or geographic shapes were replaced.

## Files changed in this refinement

- `assets/data/challenges.json`: historical state visit journey now displays
  India Passport and uses visited labels; its legacy ID and progress key remain.
- `lib/models/state_travel_status.dart`: Unmarked → Not Marked.
- `lib/models/achievement.dart`: visit-specific milestone copy and a 5-visit
  milestone, preserving existing milestone/reward IDs.
- `lib/services/state_travel_service.dart`: one-time migration, serialized status
  writes across instances, existing completion reward integration, change events,
  and disposal-safe notifications.
- `lib/services/progress_service.dart`: historical state-progress APIs now read
  and update the passport's canonical visit statuses.
- `lib/services/state_exploration_repository.dart`: extracts the existing derived
  exploration calculation so every travel surface uses the same counts.
- `lib/services/india_map_repository.dart`: caches unchanged vector geometry and
  allows retry after a loading failure.
- `lib/navigation/challenge_navigation.dart`: state visit journey opens Passport.
- `lib/screens/travel/explore_india_page.dart`: uses shared exploration counts.
- `lib/screens/travel/india_passport_page.dart`: sheet exploration count, searchable
  and filterable List, Not Marked labels, subtle Remove status, scrollable sheet,
  refreshed exploration counts after returning from the canonical state page,
  and chip labels that explicitly inherit the app body font and use readable
  selected/unselected theme colors.
- `lib/widgets/travel_journeys.dart`: runtime values and explicit map/state CTAs
  on both cards, refreshed after navigation and passport changes.
- `lib/screens/challenge/generic_checklist_challenge_page.dart`: legacy visit
  checklist filters use Visited/Not Visited instead of exploration terminology.
- `lib/screens/my_life/my_life_page.dart`: focused travel summary with separate
  visits, intent, and exploration counts, replacing the travel category ring.
- `test/india_passport_test.dart`: migration, score/reward/streak exclusion for
  intent, reward idempotence, concurrent writes, mixed Sikkim progress, search,
  filters, runtime entry counts, and selection of all 36 regions.
- `test/india_states_challenge_test.dart`, `test/experience_semantics_test.dart`,
  `test/india_states_search_test.dart`: updated visit semantics and milestones.
- `test/ui_preview_test.dart`: phone previews for the refined List and state sheet.
- This report.

## Confirmations

The existing List fallback was enhanced, not newly introduced. It now has
Search States & UTs and All / Visited / Want to Visit / Not Marked filters. Each
row shows travel status and the state's canonical exploration count. Map and
List use the same `StateTravelService` instance. The state sheet uses the same
shared exploration summary as the entry cards and Explore India.

All 36 canonical region IDs still match the existing registry exactly. The
all-regions widget test searches for and selects each one, including compact
UTs and northeastern states. Pinch zoom, pan, clipping, vector hit detection,
status color tokens, and selected outline remain in place. No shapes were
distorted to increase tap areas.

Both active status chips toggle off. A subtle Remove status text action also
resets to none. Visited replaces Want to Visit, and intent remains disabled
while Visited is active; toggling Visited off permits choosing intent.

Explore State still resolves the canonical registry ID to the existing
`ChecklistItemDetailsPage`, without introducing another detail screen. On return,
Passport refreshes experience counts. Sikkim with 7 completed linked experiences
and no physical visit is tested explicitly; marking it Visited retains those
same 7 experience IDs.

## Existing-data migration and rewards

On first load, canonical IDs from `completed_india_state_ut_ids` are copied to
Visited only if that state has no explicit passport record. Newer explicit
choices, including none and Want to Visit, win. Unknown historical IDs are
ignored for canonical counts. The original legacy list remains untouched as a
historical backup. After successful persistence, the
`india_passport_legacy_migrated_v1` marker prevents a removed visit from being
reintroduced on restart. No Want to Visit is inferred and no experience, dish,
drink, book, or district progress is cleared or completed.

Visits reuse the existing `state:<canonicalId>` completion reference and
`completion:state:<canonicalId>` reward ID. Historical visits bootstrap through
the existing reward ledger without creating a current activity date. New first
visits invoke existing completion XP/activity handling once. Removing and
revisiting a state retains its claimed reward and does not create another
completion reward or another activity event. Want to Visit produces neither
completion references nor XP/streak activity/Life Experience Score.

Generic visit achievements use thresholds 1, 5, 10, 18, 25, 36. Existing IDs are
retained; the added 5-visit milestone uses `india_states_five`. There is no parallel
XP counter or reward ledger. My Life's travel display keeps all three metrics
distinct rather than combining visits and exploration into one percentage.

## Device QA checklist

These checks are for a physical device; automated checks do not substitute for
device gesture and restart testing.

- [ ] Pinch to zoom in/out; verify boundaries stay crisp and reset restores view.
- [ ] Pan after zooming; verify clipping and no accidental sheet opening.
- [ ] Tap Rajasthan at normal and zoomed scales; confirm its name and outline.
- [ ] Select Want to Visit; confirm amber fill and only the intent count increases.
- [ ] Select Visited; confirm teal fill, visit count increases, intent decreases.
- [ ] Toggle the active status off or use Remove status; verify neutral fill.
- [ ] Switch Map/List; confirm the same status and counts on both views.
- [ ] Search and filter All, Visited, Want to Visit, and Not Marked; verify rows
  update immediately after changing a status and empty searches show feedback.
- [ ] Select Delhi, Goa, Chandigarh, Puducherry, Lakshadweep, Sikkim, and small
  northeastern states using zoom or List; confirm the correct sheet each time.
- [ ] Fully close and restart the app; confirm statuses, counts, colors, and
  removed historical visits remain correct.
- [ ] Tap Explore State; confirm the existing canonical exploration page opens
  and back returns to Passport with refreshed experience counts.
- [ ] Complete state-linked experiences without visiting; verify exploration
  increases while the travel status stays Not Marked.
- [ ] Mark a state Visited; verify its experience progress stays unchanged and
  My Life shows distinct visit, intent, and India exploration counts.
- [ ] Remove/re-add a visit; verify no repeated completion XP. Mark intent only;
  verify no completion XP or streak activity.

## Validation

- `flutter analyze`: passed, no issues found.
- `flutter test --concurrency=1 --reporter expanded --timeout 120s`: passed,
  all 236 tests.
- Map/List/status-sheet phone previews rendered and visually inspected at
  390 × 844; chip text, search, responsive filters, counts, and actions are legible.
- Device QA checklist is provided above; physical-device gestures and restart
  checks have not been performed in this environment.
