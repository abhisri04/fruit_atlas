# UPLYFA

**Experience more.** A Flutter app for collecting real-life experiences across India: fruits, dishes and drinks to try, yoga poses to learn, places and pilgrimages to visit, and books to read. Progress earns XP, levels, streaks, achievements and a daily quest.

The app is fully offline. All content ships as JSON assets and progress is stored on the device with `shared_preferences`.

> The internal Dart package is still named `fruit_atlas`, and the Android/iOS bundle IDs, class names and persistence keys keep their original names so existing installs retain progress. See [docs/uplyfa_branding_migration.md](docs/uplyfa_branding_migration.md).

## Features

| Area | What it does |
|---|---|
| Fruits of India | 115 fruits, nested varieties, verified growing states/UTs |
| Indian Dishes / Drinks | 640 dishes and 68 drinks with tried/cooked tracking |
| India Passport | Interactive state/UT map, visited / want-to-visit, share cards |
| State exploration | Districts, experiences and collections for all 36 states/UTs |
| Yoga | 132 poses with images |
| 12 Jyotirlingas | Pilgrimage checklist |
| Great Books | 1,000-book catalogue with reading status and languages |
| Gamification | XP, levels, streaks, achievements, daily quest, celebrations |
| Share Studio | "My Journey" highlight cards |

## Getting started

Requires Flutter 3.47 (stable) / Dart 3.13.

```sh
flutter pub get
flutter run              # pick a device or emulator
flutter run -d chrome    # or run in the browser
```

## Checks

These run in CI on every pull request (`.github/workflows/ci.yml`):

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Project layout

```
lib/
  app/          App shell and bottom navigation (Home, Explore, My Life)
  models/       Data models (fruit, dish, book, challenge, achievement, ...)
  services/     Asset repositories, progress, gamification, search, sharing
  screens/      Feature screens, one folder per area
  widgets/      Reusable UI components
  navigation/   Cross-screen navigation helpers
  theme/        Colours, gradients and the Material theme
assets/data/    JSON content (catalogues, challenges, per-state data)
assets/images/  Fruit, yoga and map images (WebP/PNG)
docs/           Data-source records, batch reports and design notes
tools/          Python data/photo pipelines; tool/ holds Dart generators
test/           Widget, integration and data-integrity tests
```

### Progress and rewards

`ProgressService` is the single place that records completions. Every new completion goes through `recordMeaningfulCompletion`, which writes an idempotent reward ledger (10 XP per completion, 25 per achievement, 50 per daily quest) and the activity dates used for streaks. `ProgressSummaryService` builds the canonical counts, and `GamificationService` turns them into levels and quest state. Widgets never keep their own counters.

### Adding or updating a state/UT

Each state has a config in `assets/data/state_exploration/<state_id>.json` that points to three files:

- `<state_id>_districts.json`
- `<state_id>_experiences.json`
- `<state_id>_collections.json`

New asset files must also be listed in `pubspec.yaml` and registered in `district_sources.json` / `experience_sources.json`. The `*_state_exploration_test.dart` suites check IDs, counts and cross-references.

## Data tooling

The Python scripts in `tools/` (Python 3.10+) maintain the catalogues. None of them run during app builds or tests.

- `fruit_photo_pipeline.py`: discover, review, finalise and validate fruit photos
- `download_dish_images*.py`, `dish_image_review.py`: dish photo sourcing and review
- `build_book_catalogue.py`: build `books.json` from cached Open Library metadata

`tool/generate_yoga_catalogue.dart` regenerates the yoga data.

Sources and licences are recorded under `docs/data_sources/` and `docs/image_sources/`.
