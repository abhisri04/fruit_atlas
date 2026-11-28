import '../models/gamification_summary.dart';
import '../models/celebration_event.dart';
import 'celebration_service.dart';
import 'progress_service.dart';
import 'progress_summary_service.dart';

class GamificationService {
  static const xpPerExperience = 10;
  static const xpPerAchievement = 25;
  static const questCompletionXp = 50;
  static const xpPerLevel = 250;
  static const dailyQuestId = 'expand_world';

  const GamificationService();

  /// Builds presentation state from canonical progress and the persistent,
  /// idempotent reward/activity ledgers. Nothing in widgets owns a progress
  /// counter or an XP total.
  Future<GamificationSummary> load(
    AppProgressSummary progress, {
    DateTime? now,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final date = _dateKey(localNow);
    final grouped =
        <
          String,
          ({String label, Set<String> completed, Set<String> eligible})
        >{};
    for (final value in progress.challenges.values) {
      final id = value.challenge.categoryId;
      final existing = grouped[id];
      grouped[id] = (
        label: value.challenge.displayCategoryName,
        completed: {...?existing?.completed, ...value.completedReferences},
        eligible: {...?existing?.eligible, ...value.eligibleReferences},
      );
    }
    final categories = [
      for (final entry in grouped.entries)
        CategoryProgressSummary(
          categoryId: entry.key,
          label: entry.value.label,
          completed: entry.value.completed.length,
          total: entry.value.eligible.length,
        ),
    ];

    // Existing installations are bootstrapped into the ledger without
    // recording false activity dates. Subsequent completions are added by
    // ProgressService at the mutation boundary.
    await ProgressService.ensureRewardEvents([
      for (final reference in progress.completedReferences)
        'completion:$reference',
      for (final id in progress.achievementIds) 'achievement:$id',
    ]);

    final todayActivity = await ProgressService.getActivityReferencesForDate(
      localNow,
    );
    final foodComplete = todayActivity.any(
      (item) =>
          item.startsWith('fruit:') ||
          item.startsWith('variety:') ||
          item.startsWith('dish:') ||
          item.startsWith('drink:') ||
          item.startsWith('nut:') ||
          item.startsWith('nutkind:'),
    );
    final worldComplete = todayActivity.any(
      (item) =>
          item.startsWith('yoga:') ||
          item.startsWith('state:') ||
          item.startsWith('experience:') ||
          item.startsWith('district:') ||
          item.startsWith('hobby:') ||
          item.startsWith('game:') ||
          item.startsWith('scent:') ||
          item.startsWith('perfume:') ||
          item.startsWith('note:') ||
          item.startsWith('attar:') ||
          item.startsWith('plant:') ||
          item.startsWith('collecting:') ||
          item.startsWith('make:') ||
          item.startsWith('gardenskill:') ||
          item.startsWith('gardenvisit:') ||
          item.startsWith('jyotirlinga:'),
    );
    final questComplete = foodComplete && worldComplete;
    final questRewardId = 'dailyQuest:$date:$dailyQuestId';
    var justRewarded = false;
    if (questComplete) {
      justRewarded = await ProgressService.claimReward(questRewardId);
      if (justRewarded) {
        CelebrationService.instance.emit(
          CelebrationEvent(
            id: questRewardId,
            kind: CelebrationKind.quest,
            intensity: CelebrationIntensity.large,
            title: 'Quest complete',
            message: 'You tried two different kinds of things today.',
            xp: questCompletionXp,
          ),
        );
      }
    }
    final rewarded = await ProgressService.getRewardedEventIds();
    final rewardClaimed = rewarded.contains(questRewardId);
    final totalXp = await ProgressService.getRewardedXp();
    final streak = await ProgressService.getStreak(now: localNow);
    final activeDays = await ProgressService.getActiveDayCount();
    final level = totalXp ~/ xpPerLevel + 1;

    return GamificationSummary(
      level: level,
      totalXp: totalXp,
      currentLevelXp: totalXp % xpPerLevel,
      nextLevelXp: xpPerLevel,
      streakDays: streak.current,
      longestStreakDays: streak.longest,
      activeDays: activeDays,
      achievementCount: progress.achievementCount,
      experienceCount: progress.experiencesExplored,
      categories: categories,
      quest: DailyQuestSummary(
        id: dailyQuestId,
        date: date,
        title: 'Try two kinds of things',
        description:
            'Taste something, and do one other thing: visit, read, play or '
            'try a hobby.',
        tasks: [
          QuestTask(
            id: 'food',
            label: 'Try a fruit, nut, dish or drink',
            conditionGroup: 'food_drink',
            completed: foodComplete,
          ),
          QuestTask(
            id: 'world',
            label: 'Visit, learn, play or try something new',
            conditionGroup: 'wellness_travel_faith',
            completed: worldComplete,
          ),
        ],
        rewardXp: questCompletionXp,
        rewardClaimed: rewardClaimed,
        justRewarded: justRewarded,
      ),
      activeChallenges: progress.challenges.values
          .map((value) => value.challenge)
          .toList(growable: false),
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
