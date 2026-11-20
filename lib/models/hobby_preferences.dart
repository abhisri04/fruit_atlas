import 'hobby.dart';

/// What a person told the hobby finder about themselves.
class HobbyPreferences {
  /// Preferred place; [HobbySetting.either] means "both".
  final HobbySetting place;
  final HobbyCost budget;

  /// Longest session they usually have time for.
  final int maxMinutes;

  /// Preferred energy; null means "a mix".
  final HobbyEnergy? energy;

  /// Preferred company; [HobbySocial.either] means "either".
  final HobbySocial company;
  final Set<HobbyGoal> goals;

  const HobbyPreferences({
    this.place = HobbySetting.either,
    this.budget = HobbyCost.low,
    this.maxMinutes = 60,
    this.energy,
    this.company = HobbySocial.either,
    this.goals = const {},
  });

  HobbyPreferences copyWith({
    HobbySetting? place,
    HobbyCost? budget,
    int? maxMinutes,
    HobbyEnergy? energy,
    bool clearEnergy = false,
    HobbySocial? company,
    Set<HobbyGoal>? goals,
  }) => HobbyPreferences(
    place: place ?? this.place,
    budget: budget ?? this.budget,
    maxMinutes: maxMinutes ?? this.maxMinutes,
    energy: clearEnergy ? null : energy ?? this.energy,
    company: company ?? this.company,
    goals: goals ?? this.goals,
  );

  Map<String, dynamic> toJson() => {
    'place': place.name,
    'budget': budget.name,
    'max_minutes': maxMinutes,
    'energy': energy?.name,
    'company': company.name,
    'goals': [for (final goal in goals) goal.name],
  };

  factory HobbyPreferences.fromJson(Map<String, dynamic> json) {
    T pick<T extends Enum>(List<T> values, Object? raw, T fallback) =>
        values.where((value) => value.name == raw).firstOrNull ?? fallback;
    return HobbyPreferences(
      place: pick(HobbySetting.values, json['place'], HobbySetting.either),
      budget: pick(HobbyCost.values, json['budget'], HobbyCost.low),
      maxMinutes: (json['max_minutes'] as num?)?.toInt() ?? 60,
      energy: HobbyEnergy.values
          .where((value) => value.name == json['energy'])
          .firstOrNull,
      company: pick(HobbySocial.values, json['company'], HobbySocial.either),
      goals: {
        for (final raw in json['goals'] as List<dynamic>? ?? [])
          ?HobbyGoal.values.where((goal) => goal.name == raw).firstOrNull,
      },
    );
  }
}
