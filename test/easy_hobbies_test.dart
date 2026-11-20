import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/achievement.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
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

  test('hobby catalogue has 60 complete, unique, beginner items', () {
    expect(items, hasLength(60));
    expect(items.map((item) => item.id).toSet(), hasLength(60));
    expect(items.map((item) => item.name).toSet(), hasLength(60));
    expect(items.map((item) => item.filterGroup).toSet(), {
      'Creative & Crafts',
      'Mind & Words',
      'Outdoors & Nature',
      'Grow & Make',
      'Music & Play',
      'Capture & Share',
    });
    for (final item in items) {
      expect(item.id, startsWith('hobby_'));
      expect(item.challengeId, challengeId);
      expect(item.category, isNotEmpty, reason: item.id);
      expect(item.description, isNotEmpty, reason: item.id);
      expect(item.difficulty, isNotNull, reason: item.id);
      expect(item.howToSteps, hasLength(3), reason: item.id);
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
    expect(loaded, hasLength(60));
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
    expect((hobbies.completed, hobbies.total), (1, 60));
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
    expect(achievements.map((a) => a.threshold), [1, 5, 15, 30, 60]);
    expect(Achievement.achievedFor(challengeId, 60), hasLength(5));
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
}
