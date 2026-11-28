enum CelebrationIntensity { small, medium, large }

enum CelebrationKind {
  canonicalCompletion,
  milestone,
  achievement,
  quest,
  levelUp,
  collectionComplete,
  streakMilestone,
}

class CelebrationEvent {
  final String id;
  final CelebrationKind kind;
  final CelebrationIntensity intensity;
  final String title;
  final String message;
  final int xp;
  final int? previousLevel;
  final int? newLevel;

  const CelebrationEvent({
    required this.id,
    required this.kind,
    required this.intensity,
    required this.title,
    required this.message,
    this.xp = 0,
    this.previousLevel,
    this.newLevel,
  });
}
