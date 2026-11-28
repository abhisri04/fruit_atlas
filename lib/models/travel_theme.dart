import 'package:flutter/material.dart';

import 'experience.dart';

/// Ways to explore India by what you love. An experience can fit more than
/// one theme. Matching uses whole words in its title, description and
/// keywords.
enum TravelTheme {
  nature(
    'Nature',
    'Hills, lakes, waterfalls and valleys',
    Icons.landscape_outlined,
    Color(0xFF3E8E4F),
    r'\b(waterfalls?|falls|lakes?|valleys?|hills?|mountains?|peaks?|forests?|meadows?|landscapes?|caves?|rivers?|gardens?|wetlands?|glaciers?|desert|dunes?|natural|sunrise|sunset|viewpoint|plateau|orchards?)\b',
  ),
  wildlife(
    'Wildlife',
    'Parks, sanctuaries and birding',
    Icons.pets_outlined,
    Color(0xFF8A6D3B),
    r'\b(wildlife|national park|sanctuary|tigers?|elephants?|birds?|birding|birdwatch\w*|safaris?|rhinos?|lions?|marine|ramsar|flamingos?)\b',
  ),
  beach(
    'Beaches',
    'Coasts, backwaters and the sea',
    Icons.beach_access_outlined,
    Color(0xFF2498D1),
    r'\b(beach(es)?|coast|coastal|seaside|shore|lagoon|backwaters?|snorkel\w*|surf\w*)\b',
  ),
  heritage(
    'Heritage',
    'Forts, palaces, museums and ruins',
    Icons.account_balance_outlined,
    Color(0xFFB5651D),
    r'\b(heritage|forts?|palaces?|museums?|monuments?|archaeolog\w*|architect\w*|unesco|stupas?|tombs?|ruins?|havelis?|stepwells?|colonial|memorial|mughal|rock-cut)\b',
  ),
  spiritual(
    'Spiritual',
    'Temples, monasteries and shrines',
    Icons.temple_hindu_outlined,
    Color(0xFFE0861F),
    r'\b(temples?|shrines?|monaster\w*|church(es)?|mosques?|dargah|gurudwara|gurdwara|sacred|pilgrim\w*|ghats?|basilica|jyotirlinga|char dham|cathedral|gompa|ashram)\b',
  ),
  adventure(
    'Adventure',
    'Treks, rafting, diving and more',
    Icons.hiking_outlined,
    Color(0xFFD9467A),
    r'\b(trek\w*|raft\w*|paraglid\w*|ski\w*|scuba|div(e|ing)|snorkel\w*|climb\w*|camp(ing)?|cycl\w*|road trip|kayak\w*|zipline|hik(e|ing)|bungee|surf\w*|windsurf)\b',
  ),
  culture(
    'Arts & culture',
    'Dance, music, crafts and festivals',
    Icons.theater_comedy_outlined,
    Color(0xFF8B5CF6),
    r'\b(dances?|music|crafts?|weav\w*|handloom|festivals?|theatre|embroidery|paintings?|puppet\w*|folk|textiles?|pottery)\b',
  ),
  food(
    'Food',
    'Food walks, tea estates and spices',
    Icons.ramen_dining_outlined,
    Color(0xFFE07A1F),
    r'\b(food|cuisine|dish(es)?|street food|coffee|tea estates?|tea gardens?|spices?|feast|cook\w*|pakwaan|biryani|sweets|tasting)\b',
  );

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String _pattern;

  const TravelTheme(
    this.label,
    this.subtitle,
    this.icon,
    this.color,
    this._pattern,
  );

  static final Map<TravelTheme, RegExp> _regex = {
    for (final t in values) t: RegExp(t._pattern, caseSensitive: false),
  };

  bool matches(Experience e) {
    if (this == culture && e.type == 'culture') return true;
    final text = '${e.title} . ${e.description} . ${e.keywords.join(' ')}';
    return _regex[this]!.hasMatch(text);
  }

  static Set<TravelTheme> of(Experience e) => {
    for (final t in values)
      if (t.matches(e)) t,
  };
}
