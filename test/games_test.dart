import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/hobby_journal_service.dart';
import 'package:fruit_atlas/services/hobby_matcher.dart';
import 'package:fruit_atlas/services/hobby_repository.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const challengeId = 'play_great_games';
  const progressKey = 'completed_game_ids';
  final raw = jsonDecode(
    File('assets/data/games.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final items = (raw['items'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .map(Item.fromJson)
      .toList(growable: false);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('games catalogue has 116 complete, unique games in six groups', () {
    expect(items, hasLength(116));
    expect(items.map((item) => item.id).toSet(), hasLength(116));
    expect(items.map((item) => item.name).toSet(), hasLength(116));
    expect(items.map((item) => item.filterGroup).toSet(), {
      'Card Games',
      'Board Games',
      'Traditional Indian Games',
      'Outdoor Games',
      'Party & Indoor Games',
      'Puzzles & Brainteasers',
    });
    for (final item in items) {
      expect(item.id, startsWith('game_'));
      expect(item.challengeId, challengeId);
      expect(item.category, isNotEmpty, reason: item.id);
      expect(item.description, isNotEmpty, reason: item.id);
      expect(item.howToSteps, hasLength(3), reason: item.id);
      expect(item.ladder, hasLength(4), reason: item.id);
      expect(item.metadata.keys.toSet(), {
        'Players',
        'Time',
        'Where',
      }, reason: item.id);
    }
    final names = items.map((item) => item.category).toSet();
    expect(
      names,
      containsAll(['Monopoly', 'Catan', 'Uno', 'Rummy', 'Ludo', 'Gilli-danda']),
    );
  });

  test('games challenge and category are registered and bundled', () async {
    final data = const AssetDataService();
    final challenge = (await data.loadChallenges()).singleWhere(
      (c) => c.id == challengeId,
    );
    expect(challenge.status, 'active');
    expect(challenge.categoryId, 'games_play');
    expect(challenge.progressKey, progressKey);
    expect(challenge.totalItems, items.length);
    expect(
      (await data.loadCategories()).map((c) => c.id),
      contains('games_play'),
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- ${challenge.dataAsset}'),
    );
    expect(await data.loadChallengeItems(challenge), hasLength(116));
  });

  test('playing a game earns XP, a badge and quest credit', () async {
    final id = items.first.id;
    final now = DateTime(2026, 11, 20, 12);
    await ProgressService.toggleChallengeItem(progressKey, id);
    expect(
      await ProgressService.getRewardedEventIds(),
      contains('completion:game:$id'),
    );
    final summary = await const ProgressSummaryService().load();
    expect(summary.challenges[challengeId]!.completed, 1);
    expect(summary.achievementIds, contains('game_first'));

    SharedPreferences.setMockInitialValues({});
    await ProgressService.recordMeaningfulCompletion('game:$id', now: now);
    final quest = (await const GamificationService().load(
      await const ProgressSummaryService().load(),
      now: now,
    )).quest;
    expect(quest.tasks.singleWhere((t) => t.id == 'world').completed, isTrue);
  });

  test('games appear in Discovery until played', () async {
    SharedPreferences.setMockInitialValues({
      progressKey: [items.first.id],
    });
    final games = (await DailyDiscoveryService().buildEligiblePool())
        .where((d) => d.type == DailyDiscoveryType.game)
        .toList();
    expect(games, hasLength(115));
    expect(games.every((d) => d.categoryId == 'games_play'), isTrue);
    expect(games.every((d) => d.hobbyChallenge?.id == challengeId), isTrue);
  });

  test('the finder includes games and can filter to them', () async {
    final all = await const HobbyRepository().loadAll();
    expect(all, hasLength(266));
    const matcher = HobbyMatcher();
    final gamesOnly = matcher.rank(
      all,
      null,
      filters: const HobbyFilters(gamesOnly: true),
    );
    expect(gamesOnly, hasLength(116));
    expect(
      matcher.rank(all, null, filters: const HobbyFilters(gamesOnly: false)),
      hasLength(150),
    );
    // Games carry no cost: money is never part of how they're matched.
    expect(
      File('assets/data/games.json').readAsStringSync(),
      isNot(contains('"cost"')),
    );
  });

  test('a game can be tracked in My Hobbies and marks it played', () async {
    final id = items.firstWhere((i) => i.category == 'Catan').id;
    await HobbyJournalService.start(
      hobbyId: id,
      name: 'Catan',
      group: 'Board Games',
    );
    await HobbyJournalService.logSession(id, minutes: 75);
    expect(await ProgressService.getChallengeItemIds(progressKey), {id});
    expect(
      await ProgressService.getChallengeItemIds('completed_hobby_ids'),
      isEmpty,
    );
  });
}
