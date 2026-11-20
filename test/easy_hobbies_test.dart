import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/achievement.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/widgets/daily_discovery_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const challengeId = 'try_easy_hobbies';
  const progressKey = 'completed_hobby_ids';
  final raw = jsonDecode(
    File('assets/data/easy_hobbies.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final items = (raw['items'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(Item.fromJson)
      .toList(growable: false);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('hobby catalogue has 150 complete, unique, beginner items', () {
    expect(items, hasLength(150));
    expect(items.map((item) => item.id).toSet(), hasLength(150));
    expect(items.map((item) => item.name).toSet(), hasLength(150));
    expect(items.map((item) => item.filterGroup).toSet(), {
      'Creative & Crafts',
      'Mind & Words',
      'Outdoors & Nature',
      'Grow & Make',
      'Music & Play',
      'Capture & Share',
      'Fitness & Movement',
      'Learn & Explore',
      'People & Community',
    });
    for (final item in items) {
      expect(item.id, startsWith('hobby_'));
      expect(item.challengeId, challengeId);
      expect(item.category, isNotEmpty, reason: item.id);
      expect(item.description, isNotEmpty, reason: item.id);
      expect(item.difficulty, isNotNull, reason: item.id);
      expect(item.howToSteps, hasLength(3), reason: item.id);
      expect(item.ladder.map((step) => step.level), [
        'tried',
        'learning',
        'practising',
        'confident',
      ], reason: item.id);
      expect(item.ladder.first.milestone, item.name, reason: item.id);
      expect(item.metadata.keys.toSet(), {
        'Cost',
        'Where',
        'Time',
      }, reason: item.id);
    }
  });

  test('challenge is active, bundled and matches the catalogue', () async {
    final challenge = (await const AssetDataService().loadChallenges())
        .singleWhere((c) => c.id == challengeId);
    expect(challenge.status, 'active');
    expect(challenge.categoryId, 'life_experiences');
    expect(challenge.progressKey, progressKey);
    expect(challenge.totalItems, items.length);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- ${challenge.dataAsset}'),
    );
    final loaded = await const AssetDataService().loadChallengeItems(challenge);
    expect(loaded, hasLength(150));
  });

  test('trying a hobby earns XP once and counts in the summary', () async {
    final id = items.first.id;
    await ProgressService.toggleChallengeItem(progressKey, id);
    expect(
      await ProgressService.getRewardedEventIds(),
      contains('completion:hobby:$id'),
    );
    await ProgressService.toggleChallengeItem(progressKey, id);
    await ProgressService.toggleChallengeItem(progressKey, id);
    expect(await ProgressService.getRewardedXp(), 10);

    final summary = await const ProgressSummaryService().load();
    final hobbies = summary.challenges[challengeId]!;
    expect((hobbies.completed, hobbies.total), (1, 150));
    expect(summary.completedReferences, contains('hobby:$id'));
    expect(summary.achievementIds, contains('hobby_first'));
  });

  test('a hobby satisfies the world path of the daily quest', () async {
    final now = DateTime(2026, 11, 20, 12);
    await ProgressService.recordMeaningfulCompletion(
      'hobby:${items.first.id}',
      now: now,
    );
    final summary = await const ProgressSummaryService().load();
    final quest = (await const GamificationService().load(
      summary,
      now: now,
    )).quest;
    expect(quest.tasks.singleWhere((t) => t.id == 'world').completed, isTrue);
    expect(quest.tasks.singleWhere((t) => t.id == 'food').completed, isFalse);
  });

  test('hobby achievements scale up to the full catalogue', () {
    final achievements = Achievement.forChallenge(challengeId);
    expect(achievements.map((a) => a.threshold), [1, 5, 15, 50, 150]);
    expect(Achievement.achievedFor(challengeId, 150), hasLength(5));
  });

  test('hobbies are searchable', () async {
    final search = GlobalSearchService();
    await search.load();
    final results = search.search('origami');
    expect(
      results.map((result) => result.title),
      contains('Fold a paper crane'),
    );
  });

  test('hobbies feed Explore recommendations until tried', () async {
    final first = items.first.id;
    SharedPreferences.setMockInitialValues({
      progressKey: [first],
    });
    final pool = await DailyDiscoveryService().buildEligiblePool();
    final hobbies = pool
        .where((item) => item.type == DailyDiscoveryType.hobby)
        .toList();
    expect(hobbies, hasLength(149));
    expect(hobbies.map((item) => item.canonicalId), isNot(contains(first)));
    expect(
      hobbies.every((item) => item.categoryId == 'life_experiences'),
      isTrue,
    );
    expect(hobbies.every((item) => item.hobbyChallenge != null), isTrue);
  });

  testWidgets('discovery card presents a hobby as an action', (tester) async {
    final hobby = items.first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DailyDiscoveryCard(
              discovery: DailyDiscovery(
                type: DailyDiscoveryType.hobby,
                canonicalId: hobby.id,
                title: hobby.name,
                subtitle: hobby.category!,
                categoryId: 'life_experiences',
                hobby: hobby,
              ),
              isLoading: false,
              isSaved: false,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Fold a paper crane'), findsWidgets);
    expect(find.text('Try Fold a paper crane'), findsNothing);
    expect(find.text('Try this hobby →'), findsOneWidget);
  });
}
