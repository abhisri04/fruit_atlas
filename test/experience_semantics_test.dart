import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/screens/discover/discover_page.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/widgets/challenge_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  List<Challenge> loadChallenges() {
    final json = jsonDecode(
      File('assets/data/challenges.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    return (json['challenges'] as List<dynamic>)
        .map((item) => Challenge.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void installAssetHandler(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final name = utf8.decode(message!.buffer.asUint8List());
        if (name == 'AssetManifest.bin') {
          return const StandardMessageCodec().encodeMessage(<String, Object>{});
        }
        final file = File(name);
        return file.existsSync()
            ? ByteData.sublistView(file.readAsBytesSync())
            : null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      ),
    );
  }

  test('active experiences have complete semantic configuration', () {
    final active = loadChallenges()
        .where((challenge) => challenge.status == 'active')
        .toList();
    final expected = {
      'taste_fruits_of_india': (
        shortTitle: 'Fruits of India',
        verb: 'tried',
        start: 'Start tasting',
        continueLabel: 'Continue tasting',
      ),
      'explore_indian_dishes': (
        shortTitle: 'Indian Dishes',
        verb: 'tried',
        start: 'Start tasting',
        continueLabel: 'Continue tasting',
      ),
      'explore_indian_drinks': (
        shortTitle: 'Indian Drinks',
        verb: 'tried',
        start: 'Start tasting',
        continueLabel: 'Continue tasting',
      ),
      'visit_12_jyotirlingas': (
        shortTitle: '12 Jyotirlingas',
        verb: 'visited',
        start: 'Start exploring',
        continueLabel: 'Continue exploring',
      ),
      'learn_yoga_poses': (
        shortTitle: 'Yoga Poses',
        verb: 'learned',
        start: 'Start learning',
        continueLabel: 'Continue learning',
      ),
      'explore_indian_states': (
        shortTitle: 'India Passport',
        verb: 'visited',
        start: 'Start exploring',
        continueLabel: 'Continue exploring',
      ),
      'explore_great_books': (
        shortTitle: 'Books',
        verb: 'read',
        start: 'Start reading',
        continueLabel: 'Continue reading',
      ),
      'try_easy_hobbies': (
        shortTitle: 'Easy Hobbies',
        verb: 'tried',
        start: 'Start a hobby',
        continueLabel: 'Try another hobby',
      ),
      'play_great_games': (
        shortTitle: 'Games',
        verb: 'played',
        start: 'Start playing',
        continueLabel: 'Play another',
      ),
      'explore_scent_families': (
        shortTitle: 'Scent Families',
        verb: 'smelled',
        start: 'Start smelling',
        continueLabel: 'Smell another',
      ),
      'explore_iconic_perfumes': (
        shortTitle: 'Famous Perfumes',
        verb: 'smelled',
        start: 'Start smelling',
        continueLabel: 'Smell another',
      ),
      'explore_scent_notes': (
        shortTitle: 'Scent Notes',
        verb: 'smelled',
        start: 'Start smelling',
        continueLabel: 'Smell another',
      ),
      'explore_indian_attars': (
        shortTitle: 'Indian Attars',
        verb: 'smelled',
        start: 'Start smelling',
        continueLabel: 'Smell another',
      ),
      'mix_drinks': (
        shortTitle: 'Mix Drinks',
        verb: 'made',
        start: 'Start mixing',
        continueLabel: 'Mix another',
      ),
      'taste_world_nuts': (
        shortTitle: 'Nuts',
        verb: 'tried',
        start: 'Start tasting',
        continueLabel: 'Continue tasting',
      ),
      'make_something': (
        shortTitle: 'DIY & Art',
        verb: 'made',
        start: 'Start making',
        continueLabel: 'Make another',
      ),
      'start_a_collection': (
        shortTitle: 'Collections',
        verb: 'started',
        start: 'Start collecting',
        continueLabel: 'Start another',
      ),
      'explore_garden_plants': (
        shortTitle: 'Plants to Grow',
        verb: 'grown',
        start: 'Start growing',
        continueLabel: 'Grow another',
      ),
      'explore_garden_skills': (
        shortTitle: 'Garden Skills',
        verb: 'learned',
        start: 'Start learning',
        continueLabel: 'Learn another',
      ),
      'explore_garden_visits': (
        shortTitle: 'Gardens to Visit',
        verb: 'visited',
        start: 'Plan a visit',
        continueLabel: 'Visit another',
      ),
    };

    expect(active, hasLength(expected.length));
    for (final challenge in active) {
      final semantics = expected[challenge.id]!;
      expect(challenge.compactTitle, semantics.shortTitle);
      expect(challenge.progressVerb, semantics.verb);
      expect(challenge.startLabel, semantics.start);
      expect(challenge.continueLabel, semantics.continueLabel);
      expect(challenge.categoryName, isNotEmpty);
      expect(challenge.iconIdentifier, isNot('challenge'));
    }

    final quickExplore =
        active.where((challenge) => challenge.showInQuickExplore).toList()
          ..sort(
            (a, b) => a.quickExplorePriority.compareTo(b.quickExplorePriority),
          );
    expect(quickExplore, hasLength(10));
    expect(quickExplore.take(10).map((item) => item.compactTitle), [
      'Fruits of India',
      'Indian Dishes',
      'Indian Drinks',
      '12 Jyotirlingas',
      'Yoga Poses',
      'India Passport',
      'Books',
      'Easy Hobbies',
      'Games',
      'Famous Perfumes',
    ]);
  });

  testWidgets('challenge card uses configured progress and CTA semantics', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final challenge = loadChallenges().firstWhere(
      (item) => item.id == 'taste_fruits_of_india',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChallengeCard(
                challenge: challenge,
                isActive: true,
                completedCount: 0,
                totalCount: 115,
              ),
              ChallengeCard(
                challenge: challenge,
                isActive: true,
                completedCount: 26,
                totalCount: 115,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('0 of 115 tried'), findsOneWidget);
    expect(find.text('26 of 115 tried'), findsOneWidget);
    expect(find.text('Start tasting'), findsOneWidget);
    expect(find.text('Continue tasting'), findsOneWidget);
  });

  testWidgets('Explore category shortcuts filter canonical recommendations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    installAssetHandler(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: DiscoverPage(dailyDiscoveryService: _ExploreFakeService()),
      ),
    );
    for (
      var attempt = 0;
      attempt < 40 && find.text('Food Pick').evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
    }

    expect(find.text('Food Pick'), findsOneWidget);
    expect(find.text('Wellness Pick'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('explore-shortcut-food_drink')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Food Pick'), findsOneWidget);
    expect(find.text('Wellness Pick'), findsNothing);
    await tester.tap(find.byTooltip('Save'));
    await tester.pump();
    expect(await ProgressService.isEntitySaved('indiaLocation:food'), isTrue);
    expect(find.byTooltip('Remove from Saved'), findsOneWidget);
  });
}

class _ExploreFakeService extends DailyDiscoveryService {
  const _ExploreFakeService();

  @override
  Future<List<DailyDiscovery>> buildEligiblePool() async => const [
    DailyDiscovery(
      type: DailyDiscoveryType.indiaLocation,
      canonicalId: 'food',
      title: 'Food Pick',
      subtitle: 'Food',
      categoryId: 'food_drink',
    ),
    DailyDiscovery(
      type: DailyDiscoveryType.indiaLocation,
      canonicalId: 'wellness',
      title: 'Wellness Pick',
      subtitle: 'Wellness',
      categoryId: 'fitness_wellness',
    ),
  ];
}
