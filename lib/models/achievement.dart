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
      description: 'Explore all 110 fruits.',
      threshold: 110,
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
      description: 'Learn 30 yoga poses.',
      threshold: 30,
      challengeId: 'learn_yoga_poses',
      iconIdentifier: 'trophy',
    ),
  ];

  static const hobbyChallengeAchievements = [
    Achievement(
      id: 'hobby_first',
      title: 'First Hobby',
      description: 'Try your first hobby.',
      threshold: 1,
      challengeId: 'try_easy_hobbies',
      iconIdentifier: 'hobby',
    ),
    Achievement(
      id: 'hobby_five',
      title: 'Hobby Sampler',
      description: 'Try 5 hobbies.',
      threshold: 5,
      challengeId: 'try_easy_hobbies',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'hobby_fifteen',
      title: 'Curious Mind',
      description: 'Try 15 hobbies.',
      threshold: 15,
      challengeId: 'try_easy_hobbies',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'hobby_fifty',
      title: 'Hobby Explorer',
      description: 'Try 50 hobbies.',
      threshold: 50,
      challengeId: 'try_easy_hobbies',
      iconIdentifier: 'flag',
    ),
    Achievement(
      id: 'hobby_complete',
      title: 'Renaissance Explorer',
      description: 'Try all 150 hobbies.',
      threshold: 150,
      challengeId: 'try_easy_hobbies',
      iconIdentifier: 'trophy',
    ),
  ];

  static const gameChallengeAchievements = [
    Achievement(
      id: 'game_first',
      title: 'Game On',
      description: 'Play your first game.',
      threshold: 1,
      challengeId: 'play_great_games',
      iconIdentifier: 'game',
    ),
    Achievement(
      id: 'game_five',
      title: 'Games Night',
      description: 'Play 5 games.',
      threshold: 5,
      challengeId: 'play_great_games',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'game_fifteen',
      title: 'Player',
      description: 'Play 15 games.',
      threshold: 15,
      challengeId: 'play_great_games',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'game_forty',
      title: 'Game Master',
      description: 'Play 40 games.',
      threshold: 40,
      challengeId: 'play_great_games',
      iconIdentifier: 'flag',
    ),
    Achievement(
      id: 'game_complete',
      title: 'Played Them All',
      description: 'Play all 100 games.',
      threshold: 100,
      challengeId: 'play_great_games',
      iconIdentifier: 'trophy',
    ),
  ];

  static const scentFamilyAchievements = [
    Achievement(
      id: 'scent_family_first',
      title: 'First Family',
      description: 'Get to know your first scent family.',
      threshold: 1,
      challengeId: 'explore_scent_families',
      iconIdentifier: 'perfume',
    ),
    Achievement(
      id: 'scent_family_five',
      title: 'Nose in Training',
      description: 'Get to know 5 scent families.',
      threshold: 5,
      challengeId: 'explore_scent_families',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'scent_family_all',
      title: 'Scent Wheel Complete',
      description: 'Get to know all 9 scent families.',
      threshold: 9,
      challengeId: 'explore_scent_families',
      iconIdentifier: 'trophy',
    ),
  ];

  static const perfumeAchievements = [
    Achievement(
      id: 'perfume_first',
      title: 'First Spritz',
      description: 'Smell your first famous perfume.',
      threshold: 1,
      challengeId: 'explore_iconic_perfumes',
      iconIdentifier: 'perfume',
    ),
    Achievement(
      id: 'perfume_ten',
      title: 'Perfume Explorer',
      description: 'Smell 10 famous perfumes.',
      threshold: 10,
      challengeId: 'explore_iconic_perfumes',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'perfume_twenty_five',
      title: 'Seasoned Nose',
      description: 'Smell 25 famous perfumes.',
      threshold: 25,
      challengeId: 'explore_iconic_perfumes',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'perfume_all',
      title: 'Perfume Connoisseur',
      description: 'Smell all 58 famous perfumes.',
      threshold: 58,
      challengeId: 'explore_iconic_perfumes',
      iconIdentifier: 'trophy',
    ),
  ];

  static const scentNoteAchievements = [
    Achievement(
      id: 'note_first',
      title: 'First Note',
      description: 'Smell your first scent note.',
      threshold: 1,
      challengeId: 'explore_scent_notes',
      iconIdentifier: 'perfume',
    ),
    Achievement(
      id: 'note_fifteen',
      title: 'Note Hunter',
      description: 'Smell 15 scent notes.',
      threshold: 15,
      challengeId: 'explore_scent_notes',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'note_all',
      title: 'Master Nose',
      description: 'Smell all 42 scent notes.',
      threshold: 42,
      challengeId: 'explore_scent_notes',
      iconIdentifier: 'trophy',
    ),
  ];

  static const attarAchievements = [
    Achievement(
      id: 'attar_first',
      title: 'First Attar',
      description: 'Try your first Indian attar.',
      threshold: 1,
      challengeId: 'explore_indian_attars',
      iconIdentifier: 'perfume',
    ),
    Achievement(
      id: 'attar_five',
      title: 'Attar Lover',
      description: 'Try 5 attars.',
      threshold: 5,
      challengeId: 'explore_indian_attars',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'attar_all',
      title: 'Kannauj Connoisseur',
      description: 'Try all 14 attars.',
      threshold: 14,
      challengeId: 'explore_indian_attars',
      iconIdentifier: 'trophy',
    ),
  ];

  static const collectingAchievements = [
    Achievement(
      id: 'collecting_first',
      title: 'Collector',
      description: 'Start your first collection.',
      threshold: 1,
      challengeId: 'start_a_collection',
      iconIdentifier: 'collecting',
    ),
    Achievement(
      id: 'collecting_three',
      title: 'Curator',
      description: 'Start 3 collections.',
      threshold: 3,
      challengeId: 'start_a_collection',
      iconIdentifier: 'explore',
    ),
  ];

  static const gardenPlantAchievements = [
    Achievement(
      id: 'plant_first',
      title: 'First Sprout',
      description: 'Grow your first plant.',
      threshold: 1,
      challengeId: 'explore_garden_plants',
      iconIdentifier: 'garden',
    ),
    Achievement(
      id: 'plant_ten',
      title: 'Green Thumb',
      description: 'Grow 10 plants.',
      threshold: 10,
      challengeId: 'explore_garden_plants',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'plant_twenty_five',
      title: 'Garden Keeper',
      description: 'Grow 25 plants.',
      threshold: 25,
      challengeId: 'explore_garden_plants',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'plant_all',
      title: 'Master Gardener',
      description: 'Grow all 72 plants.',
      threshold: 72,
      challengeId: 'explore_garden_plants',
      iconIdentifier: 'trophy',
    ),
  ];

  static const gardenSkillAchievements = [
    Achievement(
      id: 'garden_skill_first',
      title: 'Learning to Grow',
      description: 'Learn your first garden skill.',
      threshold: 1,
      challengeId: 'explore_garden_skills',
      iconIdentifier: 'garden',
    ),
    Achievement(
      id: 'garden_skill_ten',
      title: 'Handy Gardener',
      description: 'Learn 10 garden skills.',
      threshold: 10,
      challengeId: 'explore_garden_skills',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'garden_skill_all',
      title: 'Garden Expert',
      description: 'Learn all 25 garden skills.',
      threshold: 25,
      challengeId: 'explore_garden_skills',
      iconIdentifier: 'trophy',
    ),
  ];

  static const gardenVisitAchievements = [
    Achievement(
      id: 'garden_visit_first',
      title: 'Garden Wanderer',
      description: 'Visit your first famous garden.',
      threshold: 1,
      challengeId: 'explore_garden_visits',
      iconIdentifier: 'garden',
    ),
    Achievement(
      id: 'garden_visit_five',
      title: 'Garden Traveller',
      description: 'Visit 5 famous gardens.',
      threshold: 5,
      challengeId: 'explore_garden_visits',
      iconIdentifier: 'map',
    ),
    Achievement(
      id: 'garden_visit_all',
      title: 'Every Bloom in India',
      description: 'Visit all 16 famous gardens.',
      threshold: 16,
      challengeId: 'explore_garden_visits',
      iconIdentifier: 'trophy',
    ),
  ];

  static const indiaStatesChallengeAchievements = [
    Achievement(
      id: 'india_states_first',
      title: 'First Journey',
      description: 'Visit your first State or UT.',
      threshold: 1,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'start',
    ),
    Achievement(
      id: 'india_states_five',
      title: 'India Explorer',
      description: 'Visit 5 States & UTs.',
      threshold: 5,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'india_states_ten',
      title: 'Traveller',
      description: 'Visit 10 States & UTs.',
      threshold: 10,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'explore',
    ),
    Achievement(
      id: 'india_states_halfway',
      title: 'Halfway Across India',
      description: 'Visit 18 States & UTs.',
      threshold: 18,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'map',
    ),
    Achievement(
      id: 'india_states_twenty_five',
      title: 'India Veteran',
      description: 'Visit 25 States & UTs.',
      threshold: 25,
      challengeId: 'explore_indian_states',
      iconIdentifier: 'flag',
    ),
    Achievement(
      id: 'india_states_complete',
      title: 'All India',
      description: 'Visit all 36 States & UTs.',
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

  static const bookAchievements = [
    Achievement(
      id: 'book_first_chapter',
      title: 'First Chapter',
      description: 'Read your first book.',
      threshold: 1,
      challengeId: 'explore_great_books',
      iconIdentifier: 'book',
    ),
    Achievement(
      id: 'book_bookworm',
      title: 'Bookworm',
      description: 'Read 5 books.',
      threshold: 5,
      challengeId: 'explore_great_books',
      iconIdentifier: 'book',
    ),
    Achievement(
      id: 'book_page_turner',
      title: 'Page Turner',
      description: 'Read 10 books.',
      threshold: 10,
      challengeId: 'explore_great_books',
      iconIdentifier: 'book',
    ),
    Achievement(
      id: 'book_bibliophile',
      title: 'Bibliophile',
      description: 'Read 25 books.',
      threshold: 25,
      challengeId: 'explore_great_books',
      iconIdentifier: 'book',
    ),
  ];

  static List<Achievement> forChallenge(String challengeId) {
    return switch (challengeId) {
      'taste_fruits_of_india' => fruitChallengeAchievements,
      'visit_12_jyotirlingas' => jyotirlingaChallengeAchievements,
      'learn_yoga_poses' => yogaChallengeAchievements,
      'try_easy_hobbies' => hobbyChallengeAchievements,
      'play_great_games' => gameChallengeAchievements,
      'explore_scent_families' => scentFamilyAchievements,
      'explore_iconic_perfumes' => perfumeAchievements,
      'explore_scent_notes' => scentNoteAchievements,
      'explore_indian_attars' => attarAchievements,
      'explore_garden_plants' => gardenPlantAchievements,
      'start_a_collection' => collectingAchievements,
      'explore_garden_skills' => gardenSkillAchievements,
      'explore_garden_visits' => gardenVisitAchievements,
      'explore_indian_states' => indiaStatesChallengeAchievements,
      'explore_great_books' => bookAchievements,
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
