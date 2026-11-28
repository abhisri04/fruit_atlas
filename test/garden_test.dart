import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/models/india_location_registry.dart';
import 'package:fruit_atlas/models/state_travel_status.dart';
import 'package:fruit_atlas/screens/garden/sow_now_card.dart';
import 'package:fruit_atlas/models/garden_starter.dart';
import 'package:fruit_atlas/screens/garden/garden_home_page.dart';
import 'package:fruit_atlas/screens/garden/garden_sheets.dart';
import 'package:fruit_atlas/screens/garden/garden_starter_page.dart';
import 'package:fruit_atlas/screens/garden/plant_browse_page.dart';
import 'package:fruit_atlas/screens/hubs/category_hub_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/challenge_groups.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/my_garden_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/services/state_travel_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/garden_hub_link.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Map<String, dynamic>> _raw(String file) =>
    ((jsonDecode(File('assets/data/$file').readAsStringSync())
                as Map<String, dynamic>)['items']
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final ways = _raw('garden_ways.json');
  final plants = _raw('garden_plants.json');
  final skills = _raw('garden_skills.json');
  final visits = _raw('garden_visits.json');

  setUpAll(() async {
    await GardenCatalogue.raw();
    await GardenCatalogue.ways();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('garden data is complete, unique and money-free', () {
    final all = [...ways, ...plants, ...skills, ...visits];
    expect(all.map((i) => i['id']).toSet(), hasLength(all.length));
    for (final item in all) {
      expect(item['name'], isNotEmpty);
      expect(item['about'], isNotEmpty, reason: '${item['id']}');
      expect(item['howToSteps'], isNotEmpty, reason: '${item['id']}');
    }
    for (final file in [
      'garden_ways.json',
      'garden_plants.json',
      'garden_skills.json',
      'garden_visits.json',
    ]) {
      final text = File('assets/data/$file').readAsStringSync();
      expect(text, isNot(contains('₹')), reason: file);
      expect(text.toLowerCase(), isNot(contains('price')), reason: file);
    }
    for (final plant in plants) {
      final months = (plant['sow_months'] as List).cast<int>();
      expect(months, isNotEmpty);
      expect(months.every((m) => m >= 1 && m <= 12), isTrue);
    }
  });

  test('every garden visit belongs to a real state', () {
    for (final visit in visits) {
      final state = ProgressService.stateForGardenVisit(visit['id'] as String);
      expect(state, isNotNull, reason: '${visit['id']}');
      expect(IndiaLocationRegistry.allLocationIds, contains(state));
    }
    expect(ProgressService.stateForGardenVisit('plant_tomato'), isNull);
  });

  test('garden category and challenges are registered and bundled', () async {
    final data = const AssetDataService();
    expect((await data.loadCategories()).map((c) => c.id), contains('garden'));
    final challenges = (await data.loadChallenges())
        .where((c) => c.categoryId == 'garden')
        .toList();
    expect(challenges.map((c) => c.id).toSet(), {
      'explore_garden_plants',
      'explore_garden_skills',
    });
    // Visits live with travel; ways are untracked ideas now.
    final all = await data.loadChallenges();
    expect(
      all.singleWhere((c) => c.id == 'explore_garden_visits').categoryId,
      'travel_exploration',
    );
    expect(all.where((c) => c.id == 'explore_garden_ways'), isEmpty);
    challenges.add(all.singleWhere((c) => c.id == 'explore_garden_visits'));
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final challenge in challenges) {
      expect(pubspec, contains('- ${challenge.dataAsset}'));
      expect(
        await data.loadChallengeItems(challenge),
        hasLength(challenge.totalItems),
      );
    }
  });

  test('garden collections collapse into one hub tile', () async {
    final active = (await const AssetDataService().loadChallenges())
        .where((c) => c.status == 'active')
        .toList();
    final grouped = groupHubChallenges(active);
    expect(grouped.where((c) => c.categoryId == 'garden'), hasLength(1));
    final hub = grouped.singleWhere((c) => c.id == gardenHubId);
    expect(hub.totalItems, 72 + 25);
    expect(hubForId(gardenHubId)?.categoryId, gardenCategoryId);
  });

  test('sow-now suggestions follow the season and skip any-time plants', () {
    final june = plantsForMonth(plants, 6);
    expect(june, isNotEmpty);
    for (final plant in june) {
      final months = (plant['sow_months'] as List).cast<int>();
      expect(months, contains(6));
      expect(months.length, lessThan(12));
    }
    final march = plantsForMonth(plants, 3).map((p) => p['id']);
    expect(march, isNot(equals(june.map((p) => p['id']))));
  });

  test('gardening earns XP, badges and quest credit', () async {
    final now = DateTime(2026, 11, 24, 12);
    await ProgressService.toggleChallengeItem(
      'completed_garden_plant_ids',
      plants.first['id'] as String,
    );
    final rewards = await ProgressService.getRewardedEventIds();
    expect(rewards, contains('completion:plant:${plants.first['id']}'));
    final summary = await const ProgressSummaryService().load();
    expect(summary.achievementIds, contains('plant_first'));

    SharedPreferences.setMockInitialValues({});
    await ProgressService.recordMeaningfulCompletion(
      'gardenskill:${skills.first['id']}',
      now: now,
    );
    final quest = (await const GamificationService().load(
      await const ProgressSummaryService().load(),
      now: now,
    )).quest;
    expect(quest.tasks.singleWhere((t) => t.id == 'world').completed, isTrue);
  });

  test('visiting a garden stamps its state, and unmarking keeps it', () async {
    final visit = visits.first['id'] as String;
    final state = ProgressService.stateForGardenVisit(visit)!;
    await ProgressService.toggleChallengeItem(
      'completed_garden_visit_ids',
      visit,
    );
    final travel = StateTravelService();
    await travel.load();
    expect(travel.statusFor(state), TravelStatus.visited);

    await ProgressService.toggleChallengeItem(
      'completed_garden_visit_ids',
      visit,
    );
    await travel.load();
    expect(travel.statusFor(state), TravelStatus.visited);
    travel.dispose();
  });

  test('garden items appear in Discovery until done', () async {
    SharedPreferences.setMockInitialValues({
      'completed_garden_plant_ids': [plants.first['id']],
    });
    final garden = (await DailyDiscoveryService().buildEligiblePool())
        .where((d) => d.type == DailyDiscoveryType.garden)
        .toList();
    expect(garden, hasLength(72 + 25 - 1));
    expect(garden.every((d) => d.categoryId == 'garden'), isTrue);
  });

  test('gardening hobbies exist in the hobby catalogue', () {
    final hobbies = _raw('easy_hobbies.json').map((h) => h['id']).toSet();
    expect(hobbies, containsAll(gardeningHobbyIds));
  });

  group('starter plants', () {
    StarterSet set(
      GardenSpace s,
      GardenLight l,
      GardenWish w, {
      int month = 11,
    }) => starterSet(
      plants,
      StarterAnswers(space: s, light: l, wish: w),
      month: month,
    );

    test('every plant has starter tags', () {
      for (final p in plants) {
        expect(p['light_levels'], isNotEmpty, reason: '${p['id']}');
        expect(p['spaces'], isNotEmpty, reason: '${p['id']}');
        expect(p['beginner'], isA<bool>());
        expect(p['low_care'], isA<bool>());
      }
      expect(plants.where((p) => p['filter_group'] == 'Flowers').length, 22);
    });

    test('a sunny balcony that wants flowers gets easy flowers', () {
      final result = set(
        GardenSpace.balcony,
        GardenLight.sun,
        GardenWish.flowers,
      );
      expect(result.picks, hasLength(5));
      expect(result.note, isNull);
      for (final pick in result.picks) {
        expect(pick.plant['filter_group'], 'Flowers');
        expect(pick.plant['beginner'], isTrue);
        expect(pick.reasons, contains('Beginner-friendly'));
      }
    });

    test('low light indoors gets houseplants that cope', () {
      final result = set(
        GardenSpace.indoors,
        GardenLight.low,
        GardenWish.greenery,
      );
      expect(result.picks, isNotEmpty);
      for (final pick in result.picks) {
        expect(pick.plant['light_levels'], contains('low'));
        expect(pick.plant['spaces'], contains('indoors'));
      }
    });

    test('food in low light explains gently and still suggests plants', () {
      final result = set(GardenSpace.indoors, GardenLight.low, GardenWish.food);
      expect(result.note, contains('sun'));
      expect(result.picks, isNotEmpty);
      expect(result.picks.every((p) => !p.matchesWish), isTrue);
    });

    test('every combination suggests at least one plant', () {
      for (final s in GardenSpace.values) {
        for (final l in GardenLight.values) {
          for (final w in GardenWish.values) {
            expect(
              set(s, l, w).picks,
              isNotEmpty,
              reason: '${s.name} ${l.name} ${w.name}',
            );
          }
        }
      }
    });

    test('in-season plants come before off-season ones', () {
      final june = set(
        GardenSpace.terrace,
        GardenLight.sun,
        GardenWish.food,
        month: 6,
      );
      expect(june.picks.first.reasons, contains('Good to start now'));
    });

    test('the sow-now card mixes kinds, flowers first', () {
      final mix = seasonalMix(plants, 11);
      expect(mix, hasLength(8));
      expect(mix.first['filter_group'], 'Flowers');
      expect(mix.map((p) => p['filter_group']).toSet().length, greaterThan(2));
    });
  });

  Future<void> settle(WidgetTester tester, Finder ready) async {
    for (var i = 0; i < 80; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (ready.evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the garden hub opens the beginner-first home', (tester) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CategoryHubPage(
          categoryId: gardenCategoryId,
          clock: () => DateTime(2026, 6, 10),
        ),
      ),
    );
    await settle(tester, find.byKey(const ValueKey('shelf-flowers')));
    expect(find.byType(GardenHomePage), findsOneWidget);
    expect(find.text('New to plants? Start here'), findsOneWidget);
    for (final id in ['flowers', 'food', 'herbs', 'indoor', 'succulents']) {
      expect(find.byKey(ValueKey('shelf-$id')), findsOneWidget);
    }
    expect(find.text('What to sow in June'), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-basics')), findsOneWidget);
  });

  testWidgets('three answers lead to a starter set', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GardenStarterQuizPage(clock: () => DateTime(2026, 11, 28)),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('starter-space-balcony')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('starter-light-sun')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('starter-wish-flowers')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await settle(tester, find.text('Start with these'));
    expect(find.text('Start with these'), findsOneWidget);
    expect(find.textContaining('Set up a balcony'), findsOneWidget);
    expect(find.text('Add'), findsWidgets);
    await tester.runAsync(() async {
      final saved = await MyGardenService.starterAnswers();
      expect(saved?.wish, GardenWish.flowers);
    });
  });

  testWidgets('the Flowers shelf lists every flower, easiest first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PlantBrowsePage(
          shelf: plantShelves.first,
          clock: () => DateTime(2026, 11, 28),
        ),
      ),
    );
    await settle(tester, find.byKey(const ValueKey('browse-plant_marigold')));
    final flowers = plants.where((p) => p['filter_group'] == 'Flowers');
    for (final f in flowers) {
      expect(find.byKey(ValueKey('browse-${f['id']}')), findsOneWidget);
    }
    expect(find.text('Add'), findsWidgets);
    // Moderate plants sit after the beginner-friendly ones.
    final pansy = tester.getTopLeft(
      find.byKey(const ValueKey('browse-plant_pansy')),
    );
    final marigold = tester.getTopLeft(
      find.byKey(const ValueKey('browse-plant_marigold')),
    );
    expect(marigold.dy, lessThan(pansy.dy));

    await tester.tap(find.byKey(const ValueKey('browse-easy-only')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('browse-plant_pansy')), findsNothing);
  });
}
