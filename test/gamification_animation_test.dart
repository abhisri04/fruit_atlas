import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fruit_atlas/models/celebration_event.dart';
import 'package:fruit_atlas/models/gamification_summary.dart';
import 'package:fruit_atlas/services/celebration_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/widgets/reward_animations.dart';
import 'package:fruit_atlas/widgets/reward_feedback_host.dart';

void main() {
  final celebrations = CelebrationService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    celebrations.resetSessionForTest();
  });

  test(
    'XP feedback emits only when a canonical reward is first claimed',
    () async {
      final events = <CelebrationEvent>[];
      final subscription = celebrations.events.listen(events.add);
      addTearDown(subscription.cancel);

      await ProgressService.recordMeaningfulCompletion('fruit:FR001');
      await ProgressService.recordMeaningfulCompletion('fruit:FR001');

      expect(
        events.where(
          (event) => event.kind == CelebrationKind.canonicalCompletion,
        ),
        hasLength(1),
      );
      expect(events.single.xp, 10);
      expect(await ProgressService.getRewardedXp(), 10);
    },
  );

  test('canonical completion does not celebrate again after restart', () async {
    await ProgressService.recordMeaningfulCompletion('book:BK0001');
    celebrations.resetSessionForTest();
    final events = <CelebrationEvent>[];
    final subscription = celebrations.events.listen(events.add);
    addTearDown(subscription.cancel);

    await ProgressService.recordMeaningfulCompletion('book:BK0001');

    expect(events, isEmpty);
    expect(await ProgressService.getRewardedXp(), 10);
  });

  test('Daily Quest celebration and reward happen only once', () async {
    final today = DateTime(2026, 9, 30, 10);
    await ProgressService.recordMeaningfulCompletion('fruit:FR001', now: today);
    await ProgressService.recordMeaningfulCompletion('yoga:Y001', now: today);
    celebrations.resetSessionForTest();
    final events = <CelebrationEvent>[];
    final subscription = celebrations.events.listen(events.add);
    addTearDown(subscription.cancel);
    const summary = AppProgressSummary(
      challenges: {},
      dishesTried: 0,
      dishesCooked: 0,
      drinksTried: 0,
      achievementCount: 0,
    );

    final first = await const GamificationService().load(summary, now: today);
    final second = await const GamificationService().load(summary, now: today);

    expect(first.quest.justRewarded, isTrue);
    expect(second.quest.justRewarded, isFalse);
    expect(
      events.where((event) => event.kind == CelebrationKind.quest),
      hasLength(1),
    );
    expect(await ProgressService.getRewardedXp(), 70);
  });

  test(
    'level-up transition emits once and leaves calculations untouched',
    () async {
      final events = <CelebrationEvent>[];
      final subscription = celebrations.events.listen(events.add);
      addTearDown(subscription.cancel);
      final before = summary(level: 6, totalXp: 1490, currentLevelXp: 240);
      final after = summary(level: 7, totalXp: 1500, currentLevelXp: 0);

      celebrations.presentSummaryTransition(before, after);
      celebrations.presentSummaryTransition(before, after);

      expect(
        events.where((event) => event.kind == CelebrationKind.levelUp),
        hasLength(1),
      );
      expect(after.totalXp, 1500);
      expect(after.levelTitle, 'Pathfinder');
    },
  );

  test('achievement celebration consumption persists', () async {
    const event = CelebrationEvent(
      id: 'achievement:test',
      kind: CelebrationKind.achievement,
      intensity: CelebrationIntensity.medium,
      title: 'Achievement unlocked',
      message: 'Test achievement',
      xp: 25,
    );
    expect(await celebrations.emitOnce(event), isTrue);
    celebrations.resetSessionForTest();
    expect(await celebrations.emitOnce(event), isFalse);
    expect(await ProgressService.getRewardedXp(), 0);
  });

  testWidgets('reduced motion keeps feedback but removes particles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: RewardFeedbackHost(child: Scaffold(body: SizedBox.expand())),
        ),
      ),
    );

    celebrations.emit(
      const CelebrationEvent(
        id: 'reduced-motion',
        kind: CelebrationKind.quest,
        intensity: CelebrationIntensity.medium,
        title: 'Quest complete',
        message: 'Two paths explored.',
        xp: 50,
      ),
    );
    await tester.pump();

    expect(find.text('QUEST COMPLETE'), findsOneWidget);
    expect(find.byKey(const ValueKey('celebration-particles')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('progress animates from its previous value', (tester) async {
    double value = .2;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return AnimatedProgressValue(value: value);
            },
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .2,
    );

    update(() => value = .6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    final midway = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;
    expect(midway, greaterThan(.2));
    expect(midway, lessThan(.6));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .6,
    );
  });
}

GamificationSummary summary({
  required int level,
  required int totalXp,
  required int currentLevelXp,
}) => GamificationSummary(
  level: level,
  totalXp: totalXp,
  currentLevelXp: currentLevelXp,
  nextLevelXp: 250,
  streakDays: 1,
  achievementCount: 0,
  experienceCount: 1,
  categories: const [],
  quest: const DailyQuestSummary(
    title: 'Quest',
    description: '',
    tasks: [],
    rewardXp: 50,
  ),
  activeChallenges: const [],
);
