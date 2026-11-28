/// "Start gardening": three quick answers that turn into an easy starter set.
library;

enum GardenSpace { windowsill, balcony, terrace, ground, indoors }

enum GardenLight { sun, some, low }

enum GardenWish { flowers, food, herbs, greenery, lowCare }

extension GardenSpaceText on GardenSpace {
  String get label => switch (this) {
    GardenSpace.windowsill => 'A windowsill',
    GardenSpace.balcony => 'A balcony',
    GardenSpace.terrace => 'A terrace or rooftop',
    GardenSpace.ground => 'A garden or open ground',
    GardenSpace.indoors => 'Indoors only',
  };

  String get hint => switch (this) {
    GardenSpace.windowsill => 'A few small pots on a sill or ledge',
    GardenSpace.balcony => 'Pots and planters, with an eye on weight',
    GardenSpace.terrace => 'Room for big pots and grow bags',
    GardenSpace.ground => 'Beds or soil you can plant into',
    GardenSpace.indoors => 'Rooms, desks and corners',
  };

  /// Simple first steps to set up this space.
  List<String> get setup => switch (this) {
    GardenSpace.windowsill => [
      'Pick the sill that gets the most light.',
      'Use small pots with drainage holes and a tray underneath.',
      'Turn the pots every few days so plants grow straight.',
    ],
    GardenSpace.balcony => [
      'Watch where the sun falls through the day.',
      'Use light pots (plastic or grow bags); wet soil gets heavy.',
      'Group pots together; they stay moist for longer.',
    ],
    GardenSpace.terrace => [
      'Use grow bags or large pots, never soil straight on the roof.',
      'Add a little shade for the hottest summer afternoons.',
      'Keep a watering can or hose close by; it makes daily care easy.',
    ],
    GardenSpace.ground => [
      'Clear a small patch first; you can always grow it later.',
      'Loosen the soil and mix in compost.',
      'Plant tall plants at the back and small ones in front.',
    ],
    GardenSpace.indoors => [
      'Put plants near the brightest window you have.',
      'Water less than you think; indoor soil dries slowly.',
      'Wipe dusty leaves now and then so they can breathe.',
    ],
  };

  /// Tag used in the plant data.
  String get tag => name;
}

extension GardenLightText on GardenLight {
  String get label => switch (this) {
    GardenLight.sun => 'Lots of sun',
    GardenLight.some => 'Some sun or bright shade',
    GardenLight.low => 'Low light',
  };

  String get hint => switch (this) {
    GardenLight.sun => 'Direct sun for 4 hours or more',
    GardenLight.some => 'A couple of hours of sun, or bright all day',
    GardenLight.low => 'Away from windows, little direct light',
  };

  String get tag => name;
}

extension GardenWishText on GardenWish {
  String get label => switch (this) {
    GardenWish.flowers => 'Flowers',
    GardenWish.food => 'Food I can eat',
    GardenWish.herbs => 'Herbs for the kitchen',
    GardenWish.greenery => 'Green leaves and calm',
    GardenWish.lowCare => 'Something hard to kill',
  };

  String get hint => switch (this) {
    GardenWish.flowers => 'Colour and scent',
    GardenWish.food => 'Vegetables and fruit',
    GardenWish.herbs => 'Tulsi, mint, coriander and more',
    GardenWish.greenery => 'Houseplants, succulents and trees',
    GardenWish.lowCare => 'Forgiving plants for busy people',
  };

  bool matches(Map<String, dynamic> plant) {
    final group = plant['filter_group'];
    return switch (this) {
      GardenWish.flowers => group == 'Flowers',
      GardenWish.food => group == 'Vegetables' || group == 'Fruit',
      GardenWish.herbs => group == 'Herbs',
      GardenWish.greenery =>
        group == 'Houseplants' ||
            group == 'Succulents & Cacti' ||
            group == 'Trees',
      GardenWish.lowCare => plant['low_care'] == true,
    };
  }
}

T? _enum<T extends Enum>(List<T> values, Object? raw) =>
    values.where((v) => v.name == raw).firstOrNull;

class StarterAnswers {
  final GardenSpace space;
  final GardenLight light;
  final GardenWish wish;

  const StarterAnswers({
    required this.space,
    required this.light,
    required this.wish,
  });

  Map<String, dynamic> toJson() => {
    'space': space.name,
    'light': light.name,
    'wish': wish.name,
  };

  static StarterAnswers? fromJson(Map<String, dynamic> json) {
    final space = _enum(GardenSpace.values, json['space']);
    final light = _enum(GardenLight.values, json['light']);
    final wish = _enum(GardenWish.values, json['wish']);
    if (space == null || light == null || wish == null) return null;
    return StarterAnswers(space: space, light: light, wish: wish);
  }
}

/// One suggested plant and why it was picked.
class StarterPick {
  final Map<String, dynamic> plant;
  final List<String> reasons;

  /// False when it suits the space and light but not the wish.
  final bool matchesWish;

  const StarterPick(this.plant, this.reasons, {this.matchesWish = true});

  String get id => plant['id'] as String;
  String get name => plant['name'] as String;
}

class StarterSet {
  final List<StarterPick> picks;

  /// A kind note when the set had to stretch beyond the wish.
  final String? note;

  const StarterSet(this.picks, {this.note});
}

bool sowsIn(Map<String, dynamic> plant, int month) =>
    (plant['sow_months'] as List<dynamic>? ?? const []).contains(month);

bool _anyTime(Map<String, dynamic> plant) =>
    (plant['sow_months'] as List<dynamic>? ?? const []).length >= 12;

/// Whether a plant suits the space and light.
bool suitsSpace(Map<String, dynamic> plant, StarterAnswers answers) {
  final spaces = (plant['spaces'] as List<dynamic>? ?? const []);
  final light = (plant['light_levels'] as List<dynamic>? ?? const []);
  if (!light.contains(answers.light.tag)) return false;
  if (answers.space == GardenSpace.indoors) {
    // A sunny indoor window works like a windowsill.
    return spaces.contains('indoors') ||
        (answers.light == GardenLight.sun && spaces.contains('windowsill'));
  }
  return spaces.contains(answers.space.tag);
}

/// The easy starter set for [answers]: beginner plants first, and plants
/// you can start this month before the rest.
StarterSet starterSet(
  List<Map<String, dynamic>> plants,
  StarterAnswers answers, {
  required int month,
  int size = 5,
}) {
  int score(Map<String, dynamic> p) =>
      (p['beginner'] == true ? 4 : 0) +
      (sowsIn(p, month) && !_anyTime(p) ? 2 : 0) +
      (_anyTime(p) ? 1 : 0) +
      (p['low_care'] == true ? 1 : 0);

  List<String> reasons(Map<String, dynamic> p) => [
    if (p['beginner'] == true) 'Beginner-friendly',
    if (_anyTime(p))
      'Start any time'
    else if (sowsIn(p, month))
      'Good to start now',
    switch (answers.light) {
      GardenLight.sun => 'Loves sun',
      GardenLight.some => 'Happy with some sun',
      GardenLight.low => 'Copes with low light',
    },
  ];

  List<Map<String, dynamic>> ranked(Iterable<Map<String, dynamic>> list) {
    final indexed = list.toList();
    final order = {for (final (i, p) in indexed.indexed) p['id']: i};
    return indexed..sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      return byScore != 0
          ? byScore
          : order[a['id']]!.compareTo(order[b['id']]!);
    });
  }

  final fits = plants.where((p) => suitsSpace(p, answers)).toList();
  final wished = ranked(fits.where(answers.wish.matches));
  final picks = [for (final p in wished.take(size)) StarterPick(p, reasons(p))];
  String? note;
  if (picks.length < 3) {
    final extra = ranked(
      fits.where((p) => !answers.wish.matches(p) && p['beginner'] == true),
    ).take(size - picks.length);
    picks.addAll([
      for (final p in extra) StarterPick(p, reasons(p), matchesWish: false),
    ]);
    note = switch ((answers.wish, picks.length - extra.length)) {
      (GardenWish.food, 0) when answers.light != GardenLight.sun =>
        'Most vegetables need 4+ hours of sun. These easy plants suit your '
            'light instead, and a sunnier spot later opens up food.',
      (_, 0) =>
        'Nothing in that group suits your space and light yet, so '
            'here are easy plants that do.',
      _ =>
        'Only a few of those suit your space and light, so we added some '
            'other easy plants that do.',
    };
  }
  return StarterSet(picks, note: note);
}
