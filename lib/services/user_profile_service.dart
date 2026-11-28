import 'package:shared_preferences/shared_preferences.dart';

/// Something a person said they're into on the welcome screen. Each maps to
/// the collections Home suggests first.
class Interest {
  final String id;
  final String label;
  final List<String> challengeIds;
  const Interest(this.id, this.label, this.challengeIds);
}

abstract final class Interests {
  static const all = <Interest>[
    Interest('hobbies', 'Trying hobbies', ['try_easy_hobbies']),
    Interest('travel', 'Travel', ['explore_indian_states']),
    Interest('food', 'Food & drinks', [
      'explore_indian_dishes',
      'taste_fruits_of_india',
      'taste_world_nuts',
      'explore_indian_drinks',
      'mix_drinks',
    ]),
    Interest('garden', 'Plants & gardening', ['garden_hub']),
    Interest('wellness', 'Yoga & wellness', ['learn_yoga_poses']),
    Interest('reading', 'Reading', ['explore_great_books']),
    Interest('games', 'Games', ['play_great_games']),
    Interest('collecting', 'Collecting', ['start_a_collection', 'scent_hub']),
    Interest('making', 'DIY, art & journaling', ['make_something']),
    Interest('faith', 'Pilgrimage', ['visit_12_jyotirlingas']),
  ];

  /// What Home suggests when someone skipped the question.
  static const defaults = ['hobbies', 'travel', 'food'];

  /// Collections to suggest, in the order of the chosen interests.
  static List<String> challengeIdsFor(Iterable<String> interestIds) => [
    for (final id in interestIds)
      ...all.where((i) => i.id == id).expand((i) => i.challengeIds),
  ];
}

/// The small things the app remembers about the person: whether they've
/// seen the welcome, and what they're into. Stays on the device.
abstract final class UserProfileService {
  static const welcomeKey = 'welcome_done_v1';
  static const _interestsKey = 'interests_v1';

  static Future<bool> welcomeDone() async =>
      (await SharedPreferences.getInstance()).getBool(welcomeKey) ?? false;

  static Future<void> finishWelcome(List<String> interests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_interestsKey, interests);
    await prefs.setBool(welcomeKey, true);
  }

  static Future<List<String>> interests() async {
    final saved = (await SharedPreferences.getInstance()).getStringList(
      _interestsKey,
    );
    return saved == null || saved.isEmpty ? Interests.defaults : saved;
  }
}
