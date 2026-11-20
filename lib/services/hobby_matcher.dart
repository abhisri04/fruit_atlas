import 'dart:math';

import '../models/hobby.dart';
import '../models/hobby_preferences.dart';

/// A hobby with how well it fits someone and the reasons why.
class HobbyMatch {
  final Hobby hobby;
  final double score;
  final List<String> reasons;

  const HobbyMatch(this.hobby, this.score, this.reasons);
}

/// Quick filters on the hobby finder. Every field is optional; a null field
/// does not filter.
class HobbyFilters {
  final HobbySetting? setting;
  final bool freeOnly;
  final bool quick;
  final HobbyEnergy? energy;
  final HobbySocial? social;
  final HobbyGoal? goal;

  /// Sessions of this many minutes or fewer count as quick.
  static const quickMinutes = 30;

  const HobbyFilters({
    this.setting,
    this.freeOnly = false,
    this.quick = false,
    this.energy,
    this.social,
    this.goal,
  });

  bool get isEmpty =>
      setting == null &&
      !freeOnly &&
      !quick &&
      energy == null &&
      social == null &&
      goal == null;

  bool accepts(Hobby hobby) {
    if (setting case final wanted?) {
      if (hobby.setting != wanted && hobby.setting != HobbySetting.either) {
        return false;
      }
    }
    if (freeOnly && hobby.cost != HobbyCost.free) return false;
    if (quick && hobby.sessionMinutes > quickMinutes) return false;
    if (energy case final wanted? when hobby.energy != wanted) return false;
    if (social case final wanted?) {
      if (hobby.social != wanted && hobby.social != HobbySocial.either) {
        return false;
      }
    }
    if (goal case final wanted? when !hobby.goals.contains(wanted)) {
      return false;
    }
    return true;
  }
}

/// Scores hobbies against [HobbyPreferences]. Higher is a better fit; the
/// reasons are short, human labels for what matched ("Indoors", "Free").
class HobbyMatcher {
  const HobbyMatcher();

  HobbyMatch match(Hobby hobby, HobbyPreferences prefs) {
    var score = 0.0;
    final reasons = <String>[];

    // Place.
    if (prefs.place == HobbySetting.either) {
      score += 1;
    } else if (hobby.setting == prefs.place) {
      score += 2;
      reasons.add(prefs.place == HobbySetting.indoor ? 'Indoors' : 'Outdoors');
    } else if (hobby.setting == HobbySetting.either) {
      score += 1;
    } else {
      score -= 3;
    }

    // Budget: anything over budget is strongly penalised.
    if (hobby.cost.index <= prefs.budget.index) {
      score += 2;
      if (hobby.cost == HobbyCost.free) reasons.add('Free');
    } else {
      score -= 4;
    }

    // Time.
    if (hobby.sessionMinutes <= prefs.maxMinutes) {
      score += 1.5;
      if (hobby.sessionMinutes <= HobbyFilters.quickMinutes) {
        reasons.add('Quick to do');
      }
    } else {
      final over = hobby.sessionMinutes / prefs.maxMinutes;
      score -= over >= 3 ? 3 : 1.5;
    }

    // Energy.
    if (prefs.energy case final wanted?) {
      final gap = (hobby.energy.index - wanted.index).abs();
      if (gap == 0) {
        score += 1.5;
        reasons.add(switch (wanted) {
          HobbyEnergy.calm => 'Calming',
          HobbyEnergy.moderate => 'Easy-going',
          HobbyEnergy.active => 'Active',
        });
      } else if (gap == 2) {
        score -= 2;
      }
    }

    // Company.
    if (prefs.company != HobbySocial.either) {
      if (hobby.social == prefs.company) {
        score += 1;
        reasons.add(
          prefs.company == HobbySocial.solo ? 'On your own' : 'With others',
        );
      } else if (hobby.social != HobbySocial.either) {
        score -= 1.5;
      }
    }

    // Goals: the strongest positive signal, so they lead the reasons.
    final goalReasons = <String>[];
    for (final goal in prefs.goals) {
      if (hobby.goals.contains(goal)) {
        score += 2;
        goalReasons.add(goal.label);
      }
    }

    return HobbyMatch(hobby, score, [...goalReasons, ...reasons]);
  }

  /// All hobbies that pass [filters], best fit first. Without preferences
  /// the catalogue order is kept.
  List<HobbyMatch> rank(
    List<Hobby> hobbies,
    HobbyPreferences? prefs, {
    HobbyFilters filters = const HobbyFilters(),
  }) {
    final matches = [
      for (final hobby in hobbies)
        if (filters.accepts(hobby))
          prefs == null ? HobbyMatch(hobby, 0, const []) : match(hobby, prefs),
    ];
    if (prefs != null) {
      // Stable sort: equal scores keep catalogue order.
      final indexed = matches.indexed.toList()
        ..sort((a, b) {
          final byScore = b.$2.score.compareTo(a.$2.score);
          return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
        });
      return [for (final entry in indexed) entry.$2];
    }
    return matches;
  }

  /// A good-fit hobby the person hasn't tried or turned down, chosen at
  /// random from the top few so repeated taps feel fresh.
  HobbyMatch? pick(
    List<Hobby> hobbies,
    HobbyPreferences? prefs, {
    Set<String> exclude = const {},
    HobbyFilters filters = const HobbyFilters(),
    Random? random,
    int poolSize = 5,
  }) {
    final candidates = rank(
      hobbies,
      prefs,
      filters: filters,
    ).where((match) => !exclude.contains(match.hobby.id)).toList();
    if (candidates.isEmpty) return null;
    final pool = candidates.take(poolSize).toList();
    return pool[(random ?? Random()).nextInt(pool.length)];
  }
}
