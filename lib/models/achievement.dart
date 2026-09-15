class Achievement {
  final String id;
  final String title;
  final String description;
  final int threshold;
  final String challengeId;
  final String? iconIdentifier;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.threshold,
    required this.challengeId,
    this.iconIdentifier,
  });

  bool isAchieved(int completedCount) => completedCount >= threshold;

  static const fruitChallengeAchievements = [
    Achievement(
      id: 'fruit_first_taste',
      title: 'First Taste',
      description: 'Explore your first fruit.',
      threshold: 1,
      challengeId: 'taste_fruits_of_india',
      iconIdentifier: 'eco',
    ),
    Achievement(
      id: 'fruit_getting_started',
      title: 'Getting Started',
      description: 'Explore 5 fruits.',
      threshold: 5,
      challengeId: 'taste_fruits_of_india',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'fruit_adventurer',
      title: 'Fruit Adventurer',
      description: 'Explore 10 fruits.',
      threshold: 10,
      challengeId: 'taste_fruits_of_india',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'fruit_quarter',
      title: 'Quarter Way There',
      description: 'Explore 25 fruits.',
      threshold: 25,
      challengeId: 'taste_fruits_of_india',
      iconIdentifier: 'flag',
    ),
    Achievement(
      id: 'fruit_halfway',
      title: 'Halfway Explorer',
      description: 'Explore 50 fruits.',
      threshold: 50,
      challengeId: 'taste_fruits_of_india',
      iconIdentifier: 'map',
    ),
    Achievement(
      id: 'fruit_complete',
      title: 'India Fruit Explorer',
      description: 'Explore all 100 fruits.',
      threshold: 100,
      challengeId: 'taste_fruits_of_india',
      iconIdentifier: 'trophy',
    ),
  ];

  static const jyotirlingaChallengeAchievements = [
    Achievement(
      id: 'jyotirlinga_first',
      title: 'First Jyotirlinga',
      description: 'Visit your first Jyotirlinga.',
      threshold: 1,
      challengeId: 'visit_12_jyotirlingas',
      iconIdentifier: 'temple',
    ),
    Achievement(
      id: 'jyotirlinga_progress',
      title: 'Pilgrim in Progress',
      description: 'Visit 3 Jyotirlingas.',
      threshold: 3,
      challengeId: 'visit_12_jyotirlingas',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'jyotirlinga_halfway',
      title: 'Halfway to Twelve',
      description: 'Visit 6 Jyotirlingas.',
      threshold: 6,
      challengeId: 'visit_12_jyotirlingas',
      iconIdentifier: 'flag',
    ),
    Achievement(
      id: 'jyotirlinga_complete',
      title: 'Jyotirlinga Explorer',
      description: 'Visit all 12 Jyotirlingas.',
      threshold: 12,
      challengeId: 'visit_12_jyotirlingas',
      iconIdentifier: 'trophy',
    ),
  ];

  static const yogaChallengeAchievements = [
    Achievement(
      id: 'yoga_first',
      title: 'First Pose',
      description: 'Learn your first yoga pose.',
      threshold: 1,
      challengeId: 'learn_yoga_poses',
      iconIdentifier: 'yoga',
    ),
    Achievement(
      id: 'yoga_five',
      title: '5 Poses Learned',
      description: 'Learn 5 yoga poses.',
      threshold: 5,
      challengeId: 'learn_yoga_poses',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'yoga_ten',
      title: '10 Poses Learned',
      description: 'Learn 10 yoga poses.',
      threshold: 10,
      challengeId: 'learn_yoga_poses',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'yoga_halfway',
      title: 'Halfway There',
      description: 'Learn 15 yoga poses.',
      threshold: 15,
      challengeId: 'learn_yoga_poses',
      iconIdentifier: 'flag',
    ),
    Achievement(
      id: 'yoga_complete',
      title: '30 Pose Explorer',
      description: 'Learn all 30 yoga poses.',
      threshold: 30,
      challengeId: 'learn_yoga_poses',
      iconIdentifier: 'trophy',
    ),
  ];

  static const indiaStatesChallengeAchievements = [
    Achievement(
      id: 'india_states_first',
      title: 'First Step',
      description: 'Explore your first state or union territory.',
      threshold: 1,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'india_states_ten',
      title: 'India Explorer',
      description: 'Explore 10 states and union territories.',
      threshold: 10,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'india_states_halfway',
      title: 'Halfway Across India',
      description: 'Explore 18 states and union territories.',
      threshold: 18,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'map',
    ),
    Achievement(
      id: 'india_states_twenty_five',
      title: 'India Traveller',
      description: 'Explore 25 states and union territories.',
      threshold: 25,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'flag',
    ),
    Achievement(
      id: 'india_states_complete',
      title: 'India Completed',
      description: 'Explore all 36 states and union territories.',
      threshold: 36,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'trophy',
    ),
  ];

  static const experienceAchievements = [
    Achievement(
      id: 'experience_first',
      title: 'Curious Start',
      description: 'Complete your first experience.',
      threshold: 1,
      challengeId: 'all_experiences',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'experience_ten',
      title: 'Explorer',
      description: 'Complete 10 experiences.',
      threshold: 10,
      challengeId: 'all_experiences',
      iconIdentifier: 'explore',
    ),
  ];

  static List<Achievement> forChallenge(String challengeId) {
    return switch (challengeId) {
      'taste_fruits_of_india' => fruitChallengeAchievements,
      'visit_12_jyotirlingas' => jyotirlingaChallengeAchievements,
      'learn_yoga_poses' => yogaChallengeAchievements,
      'explore_indian_states' => indiaStatesChallengeAchievements,
      'all_experiences' => experienceAchievements,
      _ => const [],
    };
  }

  static List<Achievement> achievedFor(String challengeId, int count) {
    return forChallenge(challengeId)
        .where((item) => item.isAchieved(count))
        .toList();
  }

  static Achievement? latestFor(String challengeId, int count) {
    final achieved = achievedFor(challengeId, count);
    return achieved.isEmpty ? null : achieved.last;
  }
}
