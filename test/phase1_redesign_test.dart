import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/models/gamification_summary.dart';
import 'package:fruit_atlas/services/indian_dishes_repository.dart';
import 'package:fruit_atlas/widgets/quest_card.dart';

void main() {
  test(
    'gamification derives XP, quest and categories from canonical progress',
    () async {
      SharedPreferences.setMockInitialValues({});
      final today = DateTime(2026, 9, 28, 12);
      const food = Challenge(
        id: 'food',
        categoryId: 'food_drink',
        categoryName: 'Food & Drink',
        name: 'Food',
        description: '',
        itemType: 'fruit',
        totalItems: 10,
        hasSubItems: false,
        status: 'active',
        presentationType: 'checklist',
        progressVerb: 'tried',
      );
      const wellness = Challenge(
        id: 'wellness',
        categoryId: 'fitness_wellness',
        categoryName: 'Fitness & Wellness',
        name: 'Wellness',
        description: '',
        itemType: 'yoga_pose',
        totalItems: 20,
        hasSubItems: false,
        status: 'active',
        presentationType: 'checklist',
        progressVerb: 'learned',
      );
      const source = AppProgressSummary(
        challenges: {
          'food': ChallengeProgressSummary(
            challenge: food,
            completed: 2,
            total: 10,
            completedReferences: {'fruit:F1', 'dish:D1'},
            eligibleReferences: {'fruit:F1', 'fruit:F2', 'dish:D1'},
          ),
          'wellness': ChallengeProgressSummary(
            challenge: wellness,
            completed: 1,
            total: 20,
            completedReferences: {'yoga:Y1'},
            eligibleReferences: {'yoga:Y1', 'yoga:Y2'},
          ),
        },
        dishesTried: 0,
        dishesCooked: 0,
        drinksTried: 0,
        achievementCount: 2,
        achievementIds: {'A1', 'A2'},
      );

      await ProgressService.recordMeaningfulCompletion('fruit:F1', now: today);
      await ProgressService.recordMeaningfulCompletion('yoga:Y1', now: today);
      final result = await const GamificationService().load(source, now: today);

      expect(result.experienceCount, 3);
      expect(result.quest.completed, 2);
      expect(result.totalXp, 130);
      expect(result.level, 1);
      expect(result.categories, hasLength(2));
      expect(result.categories.first.completed, 2);
      expect(result.categories.first.total, 3);
      expect(result.streakDays, 1);
      expect(result.quest.rewardClaimed, isTrue);
      expect(result.quest.justRewarded, isTrue);

      final rebuilt = await const GamificationService().load(
        source,
        now: today,
      );
      expect(rebuilt.totalXp, 130);
      expect(rebuilt.quest.justRewarded, isFalse);
    },
  );

  test(
    'typed canonical references deduplicate overlaps without ID collisions',
    () {
      const first = Challenge(
        id: 'first',
        categoryId: 'food_drink',
        name: 'First',
        description: '',
        itemType: 'indian_dish',
        totalItems: 2,
        hasSubItems: false,
        status: 'active',
        presentationType: 'checklist',
      );
      const second = Challenge(
        id: 'second',
        categoryId: 'food_drink',
        name: 'Second',
        description: '',
        itemType: 'fruit',
        totalItems: 2,
        hasSubItems: false,
        status: 'active',
        presentationType: 'checklist',
      );
      const summary = AppProgressSummary(
        challenges: {
          'first': ChallengeProgressSummary(
            challenge: first,
            completed: 1,
            total: 2,
            completedReferences: {'dish:001'},
            eligibleReferences: {'dish:001', 'dish:002'},
          ),
          'second': ChallengeProgressSummary(
            challenge: second,
            completed: 2,
            total: 2,
            completedReferences: {'dish:001', 'fruit:001'},
            eligibleReferences: {'dish:001', 'fruit:001'},
          ),
        },
        dishesTried: 1,
        dishesCooked: 0,
        drinksTried: 0,
        achievementCount: 0,
      );

      expect(summary.experiencesExplored, 2);
      expect(summary.eligibleReferences, {'dish:001', 'dish:002', 'fruit:001'});
    },
  );

  test('completion rewards and streak activity are idempotent', () async {
    SharedPreferences.setMockInitialValues({});
    final dayOne = DateTime(2026, 9, 25, 10);
    final dayTwo = DateTime(2026, 9, 26, 11);
    final dayFour = DateTime(2026, 9, 28, 9);

    await ProgressService.recordMeaningfulCompletion('fruit:001', now: dayOne);
    await ProgressService.recordMeaningfulCompletion('fruit:001', now: dayOne);
    await ProgressService.recordMeaningfulCompletion('dish:001', now: dayOne);
    expect((await ProgressService.getStreak(now: dayOne)).current, 1);
    expect(await ProgressService.getRewardedXp(), 20);

    await ProgressService.recordMeaningfulCompletion('yoga:001', now: dayTwo);
    final consecutive = await ProgressService.getStreak(now: dayTwo);
    expect(consecutive.current, 2);
    expect(consecutive.longest, 2);

    await ProgressService.recordMeaningfulCompletion('state:001', now: dayFour);
    final reset = await ProgressService.getStreak(now: dayFour);
    expect(reset.current, 1);
    expect(reset.longest, 2);
    expect(await ProgressService.getRewardedXp(), 40);

    await ProgressService.toggleSavedEntity('fruit:002');
    expect(await ProgressService.getRewardedXp(), 40);
    expect((await ProgressService.getStreak(now: dayFour)).current, 1);
  });

  test('toggling a completion cannot farm XP', () async {
    SharedPreferences.setMockInitialValues({});
    for (var index = 0; index < 3; index++) {
      await ProgressService.toggleCategoryItemAction(
        categoryId: IndianDishesRepository.categoryId,
        itemId: 'D1',
        action: 'tried',
      );
    }
    expect(await ProgressService.getRewardedXp(), 10);
    expect(
      (await ProgressService.getCategoryItemProgress(
        IndianDishesRepository.categoryId,
      ))['D1']?.tried,
      isTrue,
    );
  });

  testWidgets('completed quest uses earned copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuestCard(
            quest: DailyQuestSummary(
              title: 'Expand Your World',
              description: 'Two paths today.',
              tasks: [
                QuestTask(label: 'Food', completed: true),
                QuestTask(label: 'World', completed: true),
              ],
              rewardXp: 50,
              rewardClaimed: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('QUEST COMPLETE'), findsOneWidget);
    expect(find.text('+50 XP earned'), findsOneWidget);
    expect(find.textContaining('when both paths'), findsNothing);
  });
}
