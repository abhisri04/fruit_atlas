/// A country, with its continent and flag.
class WorldCountry {
  final String code;
  final String name;
  final String continent;
  const WorldCountry(this.code, this.name, this.continent);

  static const continents = [
    'Asia',
    'Europe',
    'Africa',
    'North America',
    'South America',
    'Oceania',
  ];

  /// The flag emoji for an ISO country code ("IN" -> 🇮🇳).
  String get flag => flagOf(code);

  static String flagOf(String code) => String.fromCharCodes(
    code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
  );
}
