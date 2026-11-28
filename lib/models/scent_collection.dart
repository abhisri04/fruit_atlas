/// Which shelf a perfume sits on in My Collection.
enum ScentShelf { own, tried, wantToSmell }

/// How someone has a perfume. Samples, decants and attars count as much as
/// full bottles, which keeps collecting open to everyone. No prices.
enum ScentFormat { bottle, sample, decant, attar }

enum ScentSeason { summer, monsoon, winter }

extension ScentShelfLabel on ScentShelf {
  String get label => switch (this) {
    ScentShelf.own => 'Own',
    ScentShelf.tried => 'Tried',
    ScentShelf.wantToSmell => 'Want to smell',
  };
}

extension ScentFormatLabel on ScentFormat {
  String get label => switch (this) {
    ScentFormat.bottle => 'Bottle',
    ScentFormat.sample => 'Sample',
    ScentFormat.decant => 'Decant',
    ScentFormat.attar => 'Attar',
  };
}

extension ScentSeasonLabel on ScentSeason {
  String get label => switch (this) {
    ScentSeason.summer => 'Summer',
    ScentSeason.monsoon => 'Monsoon',
    ScentSeason.winter => 'Winter',
  };

  /// Indian seasons: Mar–Jun summer, Jul–Sep monsoon, Oct–Feb winter.
  static ScentSeason of(DateTime date) => switch (date.month) {
    >= 3 && <= 6 => ScentSeason.summer,
    >= 7 && <= 9 => ScentSeason.monsoon,
    _ => ScentSeason.winter,
  };
}

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) =>
    values.where((v) => v.name == raw).firstOrNull ?? fallback;

/// A perfume or attar on someone's shelves.
class ScentEntry {
  /// Catalogue item id (perfume_…, attar_…) or custom_….
  final String id;
  final String name;
  final String? maker;

  /// Scent family label, e.g. "Woody". Null if unknown.
  final String? family;
  final ScentShelf shelf;
  final ScentFormat format;
  final DateTime addedAt;
  final String? note;

  const ScentEntry({
    required this.id,
    required this.name,
    this.maker,
    this.family,
    required this.shelf,
    this.format = ScentFormat.bottle,
    required this.addedAt,
    this.note,
  });

  bool get custom => id.startsWith('custom_');

  ScentEntry copyWith({ScentShelf? shelf, ScentFormat? format}) => ScentEntry(
    id: id,
    name: name,
    maker: maker,
    family: family,
    shelf: shelf ?? this.shelf,
    format: format ?? this.format,
    addedAt: addedAt,
    note: note,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (maker != null) 'maker': maker,
    if (family != null) 'family': family,
    'shelf': shelf.name,
    'format': format.name,
    'added_at': addedAt.toUtc().toIso8601String(),
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  factory ScentEntry.fromJson(Map<String, dynamic> json) => ScentEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    maker: json['maker'] as String?,
    family: json['family'] as String?,
    shelf: _enum(ScentShelf.values, json['shelf'], ScentShelf.tried),
    format: _enum(ScentFormat.values, json['format'], ScentFormat.bottle),
    addedAt: DateTime.parse(json['added_at'] as String).toLocal(),
    note: json['note'] as String?,
  );
}

/// One "wore it today" entry in the wear diary.
class ScentWear {
  final String entryId;
  final DateTime at;
  final String? occasion;
  final String? note;

  const ScentWear({
    required this.entryId,
    required this.at,
    this.occasion,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'entry_id': entryId,
    'at': at.toUtc().toIso8601String(),
    if (occasion != null) 'occasion': occasion,
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  factory ScentWear.fromJson(Map<String, dynamic> json) => ScentWear(
    entryId: json['entry_id'] as String,
    at: DateTime.parse(json['at'] as String).toLocal(),
    occasion: json['occasion'] as String?,
    note: json['note'] as String?,
  );
}

/// Someone's perfume collection: shelves plus a wear diary, with the
/// insights the collection page shows.
class ScentCollection {
  final Map<String, ScentEntry> entries;
  final List<ScentWear> wears;

  const ScentCollection({this.entries = const {}, this.wears = const []});

  bool get isEmpty => entries.isEmpty;

  List<ScentEntry> shelf(ScentShelf shelf) =>
      entries.values.where((e) => e.shelf == shelf).toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  /// Perfumes they own or have tried: what they actually know.
  Iterable<ScentEntry> get experienced =>
      entries.values.where((e) => e.shelf != ScentShelf.wantToSmell);

  /// How many experienced perfumes fall in each family.
  Map<String, int> familyCounts() {
    final counts = <String, int>{};
    for (final entry in experienced) {
      final family = entry.family;
      if (family != null) counts[family] = (counts[family] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> wearCounts({DateTime? since}) {
    final counts = <String, int>{};
    for (final wear in wears) {
      if (since != null && wear.at.isBefore(since)) continue;
      if (!entries.containsKey(wear.entryId)) continue;
      counts[wear.entryId] = (counts[wear.entryId] ?? 0) + 1;
    }
    return counts;
  }

  /// Most-worn perfumes, most first.
  List<(ScentEntry, int)> mostWorn({int limit = 3}) {
    final counts = wearCounts().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final count in counts.take(limit))
        (entries[count.key]!, count.value),
    ];
  }

  /// The most-worn perfume in each season, if any.
  Map<ScentSeason, ScentEntry> signatures() {
    final perSeason = <ScentSeason, Map<String, int>>{};
    for (final wear in wears) {
      if (!entries.containsKey(wear.entryId)) continue;
      final counts = perSeason.putIfAbsent(
        ScentSeasonLabel.of(wear.at),
        () => {},
      );
      counts[wear.entryId] = (counts[wear.entryId] ?? 0) + 1;
    }
    return {
      for (final season in perSeason.entries)
        season.key:
            entries[(season.value.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key]!,
    };
  }

  /// Owned perfumes not worn in [days] days (or never).
  List<ScentEntry> gatheringDust(DateTime now, {int days = 60}) {
    final cutoff = now.subtract(Duration(days: days));
    final lastWorn = <String, DateTime>{};
    for (final wear in wears) {
      final previous = lastWorn[wear.entryId];
      if (previous == null || wear.at.isAfter(previous)) {
        lastWorn[wear.entryId] = wear.at;
      }
    }
    return shelf(ScentShelf.own).where((entry) {
      final last = lastWorn[entry.id] ?? entry.addedAt;
      return last.isBefore(cutoff);
    }).toList();
  }

  /// Distinct perfumes worn in the calendar month of [now].
  int distinctWornThisMonth(DateTime now) => {
    for (final wear in wears)
      if (wear.at.year == now.year && wear.at.month == now.month) wear.entryId,
  }.length;

  /// Days with at least one wear logged.
  int wearDays() => {
    for (final wear in wears)
      if (entries.containsKey(wear.entryId))
        DateTime(wear.at.year, wear.at.month, wear.at.day),
  }.length;

  bool woreOn(String entryId, DateTime day) => wears.any(
    (w) =>
        w.entryId == entryId &&
        w.at.year == day.year &&
        w.at.month == day.month &&
        w.at.day == day.day,
  );

  /// Collector path, worked out from the collection itself:
  /// 0 Tried: anything on a shelf; 1 Learning: 5 experienced across 3
  /// families; 2 Practising: wears logged on 20 days; 3 Confident: all
  /// [familyTotal] families experienced. Returns rungs reached (0–4).
  int collectorLevel({int familyTotal = 9}) {
    if (entries.isEmpty) return 0;
    var reached = 1;
    final families = familyCounts();
    if (experienced.length >= 5 && families.length >= 3) reached = 2;
    if (reached == 2 && wearDays() >= 20) reached = 3;
    if (reached == 3 && families.length >= familyTotal) reached = 4;
    return reached;
  }

  Map<String, dynamic> toJson() => {
    'entries': [for (final e in entries.values) e.toJson()],
    'wears': [for (final w in wears) w.toJson()],
  };

  factory ScentCollection.fromJson(Map<String, dynamic> json) =>
      ScentCollection(
        entries: {
          for (final raw in json['entries'] as List<dynamic>? ?? [])
            (raw as Map<String, dynamic>)['id'] as String: ScentEntry.fromJson(
              raw,
            ),
        },
        wears: [
          for (final raw in json['wears'] as List<dynamic>? ?? [])
            ScentWear.fromJson(raw as Map<String, dynamic>),
        ],
      );
}
