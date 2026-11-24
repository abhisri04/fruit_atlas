import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/models/india_location_registry.dart';
import 'package:fruit_atlas/models/state_travel_status.dart';
import 'package:fruit_atlas/screens/garden/sow_now_card.dart';
import 'package:fruit_atlas/screens/hubs/category_hub_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/challenge_groups.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
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
      'explore_garden_ways',
      'explore_garden_plants',
      'explore_garden_skills',
      'explore_garden_visits',
    });
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
    expect(hub.totalItems, 12 + 62 + 25 + 16);
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
    await ProgressService.toggleChallengeItem(
      'completed_garden_way_ids',
      ways.first['id'] as String,
    );
    final rewards = await ProgressService.getRewardedEventIds();
    expect(rewards, contains('completion:plant:${plants.first['id']}'));
    expect(rewards, contains('completion:gardenway:${ways.first['id']}'));
    final summary = await const ProgressSummaryService().load();
    expect(
      summary.achievementIds,
      containsAll(['plant_first', 'garden_way_first']),
    );

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
    expect(garden, hasLength(12 + 62 + 25 + 16 - 1));
    expect(garden.every((d) => d.categoryId == 'garden'), isTrue);
  });

  test('gardening hobbies exist in the hobby catalogue', () {
    final hobbies = _raw('easy_hobbies.json').map((h) => h['id']).toSet();
    expect(hobbies, containsAll(gardeningHobbyIds));
  });

  testWidgets('the garden hub shows four collections and the sow-now card', (
    tester,
  ) async {
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
    for (var i = 0; i < 80; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.textContaining('What to sow').evaluate().isNotEmpty &&
          find.byType(ActionChip).evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
    expect(find.text('Garden & Plants'), findsWidgets);
    expect(find.text('What to sow in June'), findsOneWidget);
    expect(find.byType(ActionChip), findsWidgets);
    for (final id in [
      'explore_garden_ways',
      'explore_garden_plants',
      'explore_garden_skills',
      'explore_garden_visits',
    ]) {
      expect(find.byKey(ValueKey('hub-collection-$id')), findsOneWidget);
    }
  });
}
