import 'world_country.dart';

export 'world_country.dart';

/// Something that goes into a drink: lime, mint, soda, gin.
class DrinkIngredient {
  final String id;
  final String name;
  final String group;
  const DrinkIngredient(this.id, this.name, this.group);
}

/// One line of a recipe, such as "30 ml lime juice".
class RecipeLine {
  final String ingredientId;
  final double? qty;
  final String unit;
  final String label;
  final bool optional;
  const RecipeLine({
    required this.ingredientId,
    this.qty,
    this.unit = '',
    required this.label,
    this.optional = false,
  });

  factory RecipeLine.fromJson(Map<String, dynamic> json) => RecipeLine(
    ingredientId: json['id'] as String,
    qty: (json['qty'] as num?)?.toDouble(),
    unit: json['unit'] as String? ?? '',
    label: json['label'] as String,
    optional: json['optional'] as bool? ?? false,
  );

  /// "60 ml lime juice" for two glasses of a 30 ml recipe.
  String format(int glasses) {
    final q = qty;
    if (q == null) return unit.isEmpty ? label : '$label, $unit';
    final amount = formatAmount(q * glasses);
    final u = switch (unit) {
      '' => '',
      _ when q * glasses == 1 => _singular(unit),
      _ => unit,
    };
    return [amount, u, label].where((s) => s.isNotEmpty).join(' ');
  }

  static String _singular(String unit) => switch (unit) {
    'leaves' => 'leaf',
    'dashes' => 'dash',
    'slices' => 'slice',
    'wedges' => 'wedge',
    'cups' => 'cup',
    'fruits' => 'fruit',
    'drops' => 'drop',
    _ => unit,
  };

  /// 0.5 -> "½", 1.5 -> "1½", 2.0 -> "2", 0.25 -> "¼".
  static String formatAmount(double v) {
    final whole = v.floor();
    final frac = v - whole;
    final part = switch ((frac * 100).round()) {
      0 => '',
      25 => '¼',
      50 => '½',
      75 => '¾',
      _ => null,
    };
    if (part == null) return v.toStringAsFixed(1);
    if (whole == 0) return part.isEmpty ? '0' : part;
    return '$whole$part';
  }
}

/// A mocktail or cocktail you can make at home.
class MixedDrink {
  static const mocktail = 'Mocktail';
  static const cocktail = 'Cocktail';

  final String id;
  final String name;
  final List<String> aliases;
  final String about;
  final String type;
  final String country;
  final String? spirit;
  final String method;
  final String glass;
  final int minutes;
  final List<String> flavours;
  final List<RecipeLine> ingredients;
  final List<String> steps;
  final String garnish;
  final String? zeroProof;
  final String fact;
  final String? safety;

  const MixedDrink({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.about = '',
    required this.type,
    required this.country,
    this.spirit,
    required this.method,
    this.glass = '',
    this.minutes = 3,
    this.flavours = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.garnish = '',
    this.zeroProof,
    this.fact = '',
    this.safety,
  });

  bool get isCocktail => type == cocktail;

  /// Ingredient ids you must have: optional extras don't count.
  Set<String> get needs => {
    for (final l in ingredients)
      if (!l.optional) l.ingredientId,
  };

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        aliases.any((a) => a.toLowerCase().contains(q)) ||
        ingredients.any((l) => l.label.toLowerCase().contains(q));
  }

  factory MixedDrink.fromJson(Map<String, dynamic> json) {
    final d = json['drink'] as Map<String, dynamic>;
    List<String> list(Object? v) =>
        (v as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    return MixedDrink(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: list(json['aliases']),
      about: json['about'] as String? ?? '',
      type: d['type'] as String,
      country: d['country'] as String,
      spirit: d['spirit'] as String?,
      method: d['method'] as String,
      glass: d['glass'] as String? ?? '',
      minutes: (d['minutes'] as num?)?.toInt() ?? 3,
      flavours: list(d['flavours']),
      ingredients: (d['ingredients'] as List<dynamic>)
          .map((e) => RecipeLine.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      steps: list(d['steps']),
      garnish: d['garnish'] as String? ?? '',
      zeroProof: d['zero_proof'] as String?,
      fact: d['fact'] as String? ?? '',
      safety: d['safety'] as String?,
    );
  }
}

/// Every drink, the ingredients they use and where they come from.
class DrinkBook {
  /// Always in the kitchen, so never asked for.
  static const assumed = {'ice', 'water'};
  static const flavours = [
    'Citrusy',
    'Fruity',
    'Minty',
    'Spicy',
    'Tangy',
    'Sweet',
    'Creamy',
    'Fizzy',
    'Bitter',
    'Warming',
  ];
  static const methods = [
    'Build',
    'Muddle',
    'Shake',
    'Stir',
    'Blend',
    'Whisk',
    'Heat',
  ];
  static const spirits = [
    'Rum',
    'Tequila',
    'Gin',
    'Vodka',
    'Whisky',
    'Brandy',
    'Wine & bubbly',
    'Other',
  ];

  final List<MixedDrink> drinks;
  final Map<String, WorldCountry> countries;
  final Map<String, DrinkIngredient> ingredients;
  final List<String> groups;
  final Set<String> alcoholGroups;

  const DrinkBook({
    required this.drinks,
    required this.countries,
    required this.ingredients,
    required this.groups,
    required this.alcoholGroups,
  });

  factory DrinkBook.fromJson(Map<String, dynamic> json) => DrinkBook(
    drinks: (json['items'] as List<dynamic>)
        .map((e) => MixedDrink.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    countries: {
      for (final MapEntry(:key, :value)
          in (json['countries'] as Map<String, dynamic>).entries)
        key: WorldCountry(
          key,
          (value as Map<String, dynamic>)['name'] as String,
          value['continent'] as String,
        ),
    },
    ingredients: {
      for (final MapEntry(:key, :value)
          in (json['ingredients'] as Map<String, dynamic>).entries)
        key: DrinkIngredient(
          key,
          (value as Map<String, dynamic>)['name'] as String,
          value['group'] as String,
        ),
    },
    groups: (json['ingredient_groups'] as List<dynamic>).cast<String>(),
    alcoholGroups: (json['alcohol_groups'] as List<dynamic>)
        .cast<String>()
        .toSet(),
  );

  WorldCountry country(String code) =>
      countries[code] ?? WorldCountry(code, code, 'Asia');

  MixedDrink? byId(String id) => drinks.where((d) => d.id == id).firstOrNull;

  String ingredientName(String id) => ingredients[id]?.name ?? id;

  bool isAlcohol(String ingredientId) =>
      alcoholGroups.contains(ingredients[ingredientId]?.group);

  /// Drinks to show: mocktails only, unless cocktails are switched on.
  List<MixedDrink> visible({required bool cocktails}) => [
    for (final d in drinks)
      if (cocktails || !d.isCocktail) d,
  ];

  /// What's still missing to make [drink] with what's on the shelf.
  Set<String> missing(MixedDrink drink, Set<String> shelf) => {
    for (final id in drink.needs.difference(shelf).difference(assumed))
      if (!shelf.contains(madeFrom[id])) id,
  };

  /// Things you can make yourself from what's on the shelf.
  static const madeFrom = {'sugar_syrup': 'sugar'};

  /// Drinks you can make right now.
  List<MixedDrink> canMake(Set<String> shelf, {required bool cocktails}) => [
    for (final d in visible(cocktails: cocktails))
      if (missing(d, shelf).isEmpty) d,
  ];

  /// Drinks you could make with just one more thing.
  List<(MixedDrink, String)> oneAway(
    Set<String> shelf, {
    required bool cocktails,
  }) => [
    for (final d in visible(cocktails: cocktails))
      if (missing(d, shelf) case final m when m.length == 1) (d, m.single),
  ];

  /// Countries the made drinks first came from.
  Set<String> originCountries(Iterable<String> madeIds) => {
    for (final d in drinks)
      if (madeIds.contains(d.id)) d.country,
  };
}
