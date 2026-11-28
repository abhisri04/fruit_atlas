import 'world_country.dart';

export 'world_country.dart';

/// A country in the nut atlas.
typedef NutCountry = WorldCountry;

/// A kind of a nut you can buy: Mamra almonds, W180 cashews, Antep pistachios.
class NutKind {
  final String id;
  final String name;
  final String? from;
  final String? fromName;
  final String description;
  const NutKind({
    required this.id,
    required this.name,
    this.from,
    this.fromName,
    this.description = '',
  });

  /// Flag of the place this kind comes from, if it has one.
  String? get flag => from == null ? null : NutCountry(from!, '', '').flag;

  factory NutKind.fromJson(Map<String, dynamic> json) => NutKind(
    id: json['id'] as String,
    name: json['name'] as String,
    from: json['from'] as String?,
    fromName: json['from_name'] as String?,
    description: json['description'] as String? ?? '',
  );
}

/// A nut (or something we call a nut) from anywhere in the world.
class Nut {
  final String id;
  final String name;
  final List<String> aliases;
  final String scientificName;
  final String about;
  final String kind;
  final List<String> native;
  final List<String> grown;
  final List<String> indiaStates;
  final String find;
  final List<String> tastes;
  final String taste;
  final List<String> ways;
  final String? shopKinds;
  final String fact;
  final String? safety;
  final List<NutKind> kinds;

  const Nut({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.scientificName = '',
    this.about = '',
    required this.kind,
    required this.native,
    required this.grown,
    this.indiaStates = const [],
    required this.find,
    this.tastes = const [],
    this.taste = '',
    this.ways = const [],
    this.shopKinds,
    this.fact = '',
    this.safety,
    this.kinds = const [],
  });

  /// Every country linked to this nut: where it's from and where it grows.
  Set<String> get countries => {...native, ...grown};

  bool get grownInIndia => grown.contains('IN') || indiaStates.isNotEmpty;

  /// Dry-fruit shops, supermarkets and seasonal stalls: easy to find here.
  bool get easyInIndia => find != NutAtlas.travel;

  factory Nut.fromJson(Map<String, dynamic> json) {
    final n = json['nut'] as Map<String, dynamic>;
    List<String> list(Object? v) =>
        (v as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    return Nut(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: list(json['aliases']),
      scientificName: json['scientific_name'] as String? ?? '',
      about: json['about'] as String? ?? '',
      kind: n['kind'] as String,
      native: list(n['native']),
      grown: list(n['grown']),
      indiaStates: list(n['india_states']),
      find: n['find'] as String,
      tastes: list(n['tastes']),
      taste: n['taste'] as String? ?? '',
      ways: list(n['ways']),
      shopKinds: n['shop_kinds'] as String?,
      fact: n['fact'] as String? ?? '',
      safety: n['safety'] as String?,
      kinds: (n['kinds'] as List<dynamic>? ?? const [])
          .map((k) => NutKind.fromJson(k as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        aliases.any((a) => a.toLowerCase().contains(q)) ||
        kinds.any((k) => k.name.toLowerCase().contains(q)) ||
        scientificName.toLowerCase().contains(q);
  }
}

/// All the nuts and the countries they come from.
class NutAtlas {
  static const shop = 'Dry-fruit shop';
  static const supermarket = 'Supermarket or online';
  static const seasonal = 'Seasonal in India';
  static const travel = 'Try on your travels';
  static const finds = [shop, supermarket, seasonal, travel];
  static const kinds = [
    'True nut',
    'Drupe seed',
    'Seed',
    'Legume',
    'Not a nut',
  ];
  static const tastes = [
    'Sweet',
    'Buttery',
    'Rich',
    'Earthy',
    'Starchy',
    'Bold',
  ];
  static const continents = [
    'Asia',
    'Europe',
    'Africa',
    'North America',
    'South America',
    'Oceania',
  ];

  final List<Nut> nuts;
  final Map<String, NutCountry> countries;
  const NutAtlas({required this.nuts, required this.countries});

  factory NutAtlas.fromJson(Map<String, dynamic> json) => NutAtlas(
    nuts: (json['items'] as List<dynamic>)
        .map((e) => Nut.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    countries: {
      for (final MapEntry(:key, :value)
          in (json['countries'] as Map<String, dynamic>).entries)
        key: NutCountry(
          key,
          (value as Map<String, dynamic>)['name'] as String,
          value['continent'] as String,
        ),
    },
  );

  NutCountry country(String code) =>
      countries[code] ?? NutCountry(code, code, 'Asia');

  Nut? byId(String id) => nuts.where((n) => n.id == id).firstOrNull;

  /// Nuts linked to a country: first those native there, then those grown.
  List<Nut> nutsFor(String code) => [
    ...nuts.where((n) => n.native.contains(code)),
    ...nuts.where((n) => !n.native.contains(code) && n.grown.contains(code)),
  ];

  /// Continents a nut first came from.
  Set<String> continentsOf(Nut nut) => {
    for (final c in nut.native) country(c).continent,
  };

  /// Countries the tried nuts first came from: "tasted your way to N countries".
  Set<String> originCountries(Iterable<String> triedIds) => {
    for (final n in nuts)
      if (triedIds.contains(n.id)) ...n.native,
  };
}
