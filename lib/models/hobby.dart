import 'item.dart';

enum HobbySetting { indoor, outdoor, either }

enum HobbyCost { free, low, medium }

enum HobbyEnergy { calm, moderate, active }

enum HobbySocial { solo, social, either }

enum HobbyGoal { relax, active, create, connect, learn }

extension HobbyCostLabel on HobbyCost {
  String get label => switch (this) {
    HobbyCost.free => 'Free',
    HobbyCost.low => 'Under ₹300',
    HobbyCost.medium => 'Under ₹1,500',
  };
}

extension HobbyGoalLabel on HobbyGoal {
  String get label => switch (this) {
    HobbyGoal.relax => 'Relax',
    HobbyGoal.active => 'Get active',
    HobbyGoal.create => 'Be creative',
    HobbyGoal.connect => 'Meet people',
    HobbyGoal.learn => 'Learn something',
  };
}

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) =>
    values.where((value) => value.name == raw).firstOrNull ?? fallback;

/// A hobby from the catalogue: the checklist [item] plus the attributes the
/// hobby finder uses to match it to a person.
class Hobby {
  final Item item;
  final HobbySetting setting;
  final HobbyCost cost;
  final int sessionMinutes;
  final HobbyEnergy energy;
  final HobbySocial social;
  final Set<HobbyGoal> goals;

  const Hobby({
    required this.item,
    required this.setting,
    required this.cost,
    required this.sessionMinutes,
    required this.energy,
    required this.social,
    required this.goals,
  });

  String get id => item.id;

  /// The first win, e.g. "Fold a paper crane".
  String get title => item.name;

  /// The hobby itself, e.g. "Origami".
  String get name => item.category ?? item.name;

  factory Hobby.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    return Hobby(
      item: Item.fromJson(json),
      setting: _enum(
        HobbySetting.values,
        attributes['setting'],
        HobbySetting.either,
      ),
      cost: _enum(HobbyCost.values, attributes['cost'], HobbyCost.low),
      sessionMinutes: (attributes['session_minutes'] as num?)?.toInt() ?? 60,
      energy: _enum(
        HobbyEnergy.values,
        attributes['energy'],
        HobbyEnergy.moderate,
      ),
      social: _enum(
        HobbySocial.values,
        attributes['social'],
        HobbySocial.either,
      ),
      goals: {
        for (final raw in attributes['goals'] as List<dynamic>? ?? [])
          ?HobbyGoal.values.where((goal) => goal.name == raw).firstOrNull,
      },
    );
  }
}
