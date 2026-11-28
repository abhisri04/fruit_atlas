/// The moments a gardener can log for a plant. Sown, sprouted, flowered and
/// harvested are "firsts" the first time they happen; tending and harvesting
/// can repeat.
enum GardenMoment { added, sown, sprouted, flowered, harvested, tended }

extension GardenMomentLabel on GardenMoment {
  String get label => switch (this) {
    GardenMoment.added => 'Added to garden',
    GardenMoment.sown => 'Sown',
    GardenMoment.sprouted => 'First sprout',
    GardenMoment.flowered => 'First flower',
    GardenMoment.harvested => 'Harvested',
    GardenMoment.tended => 'Tended',
  };

  /// How the first one reads in the record, e.g. "First harvest".
  String get firstLabel => switch (this) {
    GardenMoment.added => 'Joined your garden',
    GardenMoment.sown => 'Sown',
    GardenMoment.sprouted => 'First sprout',
    GardenMoment.flowered => 'First flower',
    GardenMoment.harvested => 'First harvest',
    GardenMoment.tended => 'First tended',
  };

  /// Moments worth celebrating as firsts.
  bool get isMilestone => switch (this) {
    GardenMoment.sprouted ||
    GardenMoment.flowered ||
    GardenMoment.harvested => true,
    _ => false,
  };
}

enum GardenPlantStatus { growing, letGo }

/// Plant types, matching the Plants to Grow filter groups.
const gardenPlantTypes = [
  'Vegetables',
  'Herbs',
  'Flowers',
  'Houseplants',
  'Succulents & Cacti',
  'Fruit',
  'Trees',
];

/// Gentle, common reasons a plant doesn't make it. None of them is a failure.
const gardenLessons = [
  'Too much water',
  'Not enough water',
  'Not enough sun',
  'Too much sun or heat',
  'Pests',
  'Wrong season',
  'Moved or repotted',
  'Not sure, and that is okay',
];

T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) =>
    values.where((v) => v.name == raw).firstOrNull ?? fallback;

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// One plant in someone's garden. The same catalogue plant can be grown
/// again later, so [id] is unique per planting and [catalogueId] links back.
class GardenPlant {
  final String id;

  /// Plants to Grow id (plant_…), or null for a plant they added by name.
  final String? catalogueId;
  final String name;

  /// One of [gardenPlantTypes], or null if unknown.
  final String? type;
  final DateTime addedAt;
  final GardenPlantStatus status;
  final DateTime? letGoAt;

  /// What they learned when letting the plant go.
  final String? lesson;

  const GardenPlant({
    required this.id,
    this.catalogueId,
    required this.name,
    this.type,
    required this.addedAt,
    this.status = GardenPlantStatus.growing,
    this.letGoAt,
    this.lesson,
  });

  bool get growing => status == GardenPlantStatus.growing;

  GardenPlant letGo(DateTime at, String? lesson) => GardenPlant(
    id: id,
    catalogueId: catalogueId,
    name: name,
    type: type,
    addedAt: addedAt,
    status: GardenPlantStatus.letGo,
    letGoAt: at,
    lesson: lesson?.trim().isEmpty ?? true ? null : lesson!.trim(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (catalogueId != null) 'catalogue_id': catalogueId,
    'name': name,
    if (type != null) 'type': type,
    'added_at': addedAt.toUtc().toIso8601String(),
    'status': status.name,
    if (letGoAt != null) 'let_go_at': letGoAt!.toUtc().toIso8601String(),
    if (lesson != null) 'lesson': lesson,
  };

  factory GardenPlant.fromJson(Map<String, dynamic> json) => GardenPlant(
    id: json['id'] as String,
    catalogueId: json['catalogue_id'] as String?,
    name: json['name'] as String,
    type: json['type'] as String?,
    addedAt: DateTime.parse(json['added_at'] as String).toLocal(),
    status: _enum(
      GardenPlantStatus.values,
      json['status'],
      GardenPlantStatus.growing,
    ),
    letGoAt: json['let_go_at'] == null
        ? null
        : DateTime.parse(json['let_go_at'] as String).toLocal(),
    lesson: json['lesson'] as String?,
  );
}

/// One logged moment, with an optional photo (stored separately by id).
class GardenLog {
  final String id;
  final String plantId;
  final GardenMoment moment;
  final DateTime at;
  final String? photoId;

  const GardenLog({
    required this.id,
    required this.plantId,
    required this.moment,
    required this.at,
    this.photoId,
  });

  GardenLog withPhoto(String? photoId) => GardenLog(
    id: id,
    plantId: plantId,
    moment: moment,
    at: at,
    photoId: photoId,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'plant_id': plantId,
    'moment': moment.name,
    'at': at.toUtc().toIso8601String(),
    if (photoId != null) 'photo_id': photoId,
  };

  factory GardenLog.fromJson(Map<String, dynamic> json) => GardenLog(
    id: json['id'] as String,
    plantId: json['plant_id'] as String,
    moment: _enum(GardenMoment.values, json['moment'], GardenMoment.tended),
    at: DateTime.parse(json['at'] as String).toLocal(),
    photoId: json['photo_id'] as String?,
  );
}

/// What happened in a month, for the gentle monthly recap.
class GardenMonthRecap {
  final int newPlants;
  final List<(GardenPlant, GardenMoment)> firsts;
  final int harvests;
  final int tendedDays;

  const GardenMonthRecap({
    required this.newPlants,
    required this.firsts,
    required this.harvests,
    required this.tendedDays,
  });

  bool get isEmpty =>
      newPlants == 0 && firsts.isEmpty && harvests == 0 && tendedDays == 0;
}

/// Someone's garden: the plants, every logged moment, and the insights the
/// My Garden page shows. Nothing here counts what was missed.
class MyGarden {
  final Map<String, GardenPlant> plants;
  final List<GardenLog> logs;

  const MyGarden({this.plants = const {}, this.logs = const []});

  bool get isEmpty => plants.isEmpty;

  List<GardenPlant> get growing =>
      plants.values.where((p) => p.growing).toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  /// Plants they let go, with what they learned. Newest first.
  List<GardenPlant> get lessons =>
      plants.values.where((p) => !p.growing).toList()..sort(
        (a, b) => (b.letGoAt ?? b.addedAt).compareTo(a.letGoAt ?? a.addedAt),
      );

  /// Logs for one plant, oldest first.
  List<GardenLog> logsFor(String plantId) =>
      logs.where((l) => l.plantId == plantId).toList()
        ..sort((a, b) => a.at.compareTo(b.at));

  /// When each moment first happened for [plantId].
  Map<GardenMoment, DateTime> firstsFor(String plantId) {
    final firsts = <GardenMoment, DateTime>{};
    for (final log in logsFor(plantId)) {
      firsts.putIfAbsent(log.moment, () => log.at);
    }
    return firsts;
  }

  bool has(String plantId, GardenMoment moment) =>
      logs.any((l) => l.plantId == plantId && l.moment == moment);

  bool tendedOn(String plantId, DateTime day) => logs.any(
    (l) =>
        l.plantId == plantId &&
        l.moment == GardenMoment.tended &&
        _sameDay(l.at, day),
  );

  int harvestsFor(String plantId) => logs
      .where((l) => l.plantId == plantId && l.moment == GardenMoment.harvested)
      .length;

  /// The newest photo for a plant, if any.
  String? coverPhotoFor(String plantId) => logs
      .where((l) => l.plantId == plantId && l.photoId != null)
      .fold<GardenLog?>(
        null,
        (best, l) => best == null || l.at.isAfter(best.at) ? l : best,
      )
      ?.photoId;

  /// Newest photos across the garden, for the share card.
  List<String> recentPhotos({int limit = 3}) {
    final withPhotos = logs.where((l) => l.photoId != null).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return [for (final l in withPhotos.take(limit)) l.photoId!];
  }

  /// Plants growing now, per type.
  Map<String, int> typeCounts() {
    final counts = <String, int>{};
    for (final plant in growing) {
      final type = plant.type ?? 'Other';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Distinct days anything was logged.
  int activeDays() =>
      {for (final l in logs) DateTime(l.at.year, l.at.month, l.at.day)}.length;

  int tendedDays() => {
    for (final l in logs)
      if (l.moment == GardenMoment.tended)
        DateTime(l.at.year, l.at.month, l.at.day),
  }.length;

  /// Months (1–12) with any activity in [year]: the garden through the year.
  Set<int> activeMonths(int year) => {
    for (final l in logs)
      if (l.at.year == year) l.at.month,
  };

  /// Every first sprout, flower and harvest, newest first.
  List<(GardenPlant, GardenMoment, DateTime)> milestones() {
    final list = <(GardenPlant, GardenMoment, DateTime)>[];
    for (final plant in plants.values) {
      for (final first in firstsFor(plant.id).entries) {
        if (first.key.isMilestone) list.add((plant, first.key, first.value));
      }
    }
    return list..sort((a, b) => b.$3.compareTo(a.$3));
  }

  /// Plants with a first flower or harvest.
  int plantsThatGaveBack() => {
    for (final l in logs)
      if (l.moment == GardenMoment.flowered ||
          l.moment == GardenMoment.harvested)
        l.plantId,
  }.length;

  GardenMonthRecap recap(DateTime month) {
    bool inMonth(DateTime d) => d.year == month.year && d.month == month.month;
    return GardenMonthRecap(
      newPlants: plants.values.where((p) => inMonth(p.addedAt)).length,
      firsts: [
        for (final m in milestones())
          if (inMonth(m.$3)) (m.$1, m.$2),
      ],
      harvests: logs
          .where((l) => l.moment == GardenMoment.harvested && inMonth(l.at))
          .length,
      tendedDays: {
        for (final l in logs)
          if (l.moment == GardenMoment.tended && inMonth(l.at)) l.at.day,
      }.length,
    );
  }

  /// "This day last year": what happened a year ago today, if anything.
  List<(GardenPlant, GardenLog)> onThisDayLastYear(DateTime now) {
    final day = DateTime(now.year - 1, now.month, now.day);
    return [
      for (final l in logs)
        if (_sameDay(l.at, day) &&
            l.moment != GardenMoment.tended &&
            plants[l.plantId] != null)
          (plants[l.plantId]!, l),
    ];
  }

  /// Gardener path, worked out from the garden itself:
  /// 1 Tried: a plant in the garden; 2 Learning: 3 plants across 2 types;
  /// 3 Practising: tended on 20 days; 4 Confident: 5 plants flowered or
  /// harvested. Returns rungs reached (0–4).
  int gardenerLevel() {
    if (plants.isEmpty) return 0;
    var reached = 1;
    final types = {for (final p in plants.values) ?p.type};
    if (plants.length >= 3 && types.length >= 2) reached = 2;
    if (reached == 2 && tendedDays() >= 20) reached = 3;
    if (reached == 3 && plantsThatGaveBack() >= 5) reached = 4;
    return reached;
  }

  Map<String, dynamic> toJson() => {
    'plants': [for (final p in plants.values) p.toJson()],
    'logs': [for (final l in logs) l.toJson()],
  };

  factory MyGarden.fromJson(Map<String, dynamic> json) => MyGarden(
    plants: {
      for (final raw in json['plants'] as List<dynamic>? ?? [])
        (raw as Map<String, dynamic>)['id'] as String: GardenPlant.fromJson(
          raw,
        ),
    },
    logs: [
      for (final raw in json['logs'] as List<dynamic>? ?? [])
        GardenLog.fromJson(raw as Map<String, dynamic>),
    ],
  );
}
