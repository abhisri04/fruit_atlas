import 'challenge.dart';

class CategoryProgressSummary {
  final String categoryId;
  final String label;
  final int completed;
  final int total;

  const CategoryProgressSummary({
    required this.categoryId,
    required this.label,
    required this.completed,
    required this.total,
  });

  double get progress => total <= 0 ? 0 : completed / total;
}

class QuestTask {
  final String id;
  final String label;
  final String conditionGroup;
  final bool completed;

  const QuestTask({
    this.id = '',
    required this.label,
    this.conditionGroup = '',
    required this.completed,
  });
}

class DailyQuestSummary {
  final String id;
  final String date;
  final String title;
  final String description;
  final List<QuestTask> tasks;
  final int rewardXp;
  final bool rewardClaimed;
  final bool justRewarded;

  const DailyQuestSummary({
    this.id = 'expand_world',
    this.date = '',
    required this.title,
    required this.description,
    required this.tasks,
    required this.rewardXp,
    this.rewardClaimed = false,
    this.justRewarded = false,
  });

  int get completed => tasks.where((task) => task.completed).length;
  bool get isComplete => completed == tasks.length;
}

class GamificationSummary {
  final int level;
  final int totalXp;
  final int currentLevelXp;
  final int nextLevelXp;
  final int streakDays;
  final int longestStreakDays;

  /// Days with any activity, ever.
  final int activeDays;
  final int achievementCount;
  final int experienceCount;
  final List<CategoryProgressSummary> categories;
  final DailyQuestSummary quest;
  final List<Challenge> activeChallenges;

  const GamificationSummary({
    required this.level,
    required this.totalXp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.streakDays,
    this.longestStreakDays = 0,
    this.activeDays = 0,
    required this.achievementCount,
    required this.experienceCount,
    required this.categories,
    required this.quest,
    required this.activeChallenges,
  });

  double get levelProgress =>
      nextLevelXp <= 0 ? 0 : currentLevelXp / nextLevelXp;

  int get xpToNextLevel => (nextLevelXp - currentLevelXp).clamp(0, nextLevelXp);

  String get levelTitle => switch (level) {
    <= 6 => 'Explorer',
    <= 9 => 'Pathfinder',
    <= 14 => 'Trailblazer',
    _ => 'Life Adventurer',
  };
}
