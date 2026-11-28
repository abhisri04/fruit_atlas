enum HobbyStatus { active, paused, dropped }

DateTime _day(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// One logged practice session.
class HobbySession {
  final DateTime at;
  final int? minutes;
  final String? note;

  const HobbySession({required this.at, this.minutes, this.note});

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    if (minutes != null) 'minutes': minutes,
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  factory HobbySession.fromJson(Map<String, dynamic> json) => HobbySession(
    at: DateTime.parse(json['at'] as String).toLocal(),
    minutes: (json['minutes'] as num?)?.toInt(),
    note: json['note'] as String?,
  );
}

/// A hobby someone is tracking in My Hobbies.
class HobbyRecord {
  /// Catalogue hobby item id, or `custom_…` for a hobby the person added.
  final String hobbyId;

  /// Display name (catalogue hobby name, or the custom name).
  final String name;

  /// Catalogue group, for the icon. Null for custom hobbies.
  final String? group;
  final bool custom;
  final HobbyStatus status;
  final DateTime startedAt;

  /// Highest ladder rung reached: -1 none, 0 tried, 1 learning,
  /// 2 practising, 3 confident.
  final int level;
  final List<HobbySession> sessions;

  /// True once the person has answered "keep it or drop it" after the
  /// 7-day starter, or added a hobby they already do.
  final bool starterDecided;

  static const starterDays = 7;
  static const starterGoal = 4;

  const HobbyRecord({
    required this.hobbyId,
    required this.name,
    this.group,
    this.custom = false,
    this.status = HobbyStatus.active,
    required this.startedAt,
    this.level = -1,
    this.sessions = const [],
    this.starterDecided = false,
  });

  HobbyRecord copyWith({
    HobbyStatus? status,
    DateTime? startedAt,
    int? level,
    List<HobbySession>? sessions,
    bool? starterDecided,
  }) => HobbyRecord(
    hobbyId: hobbyId,
    name: name,
    group: group,
    custom: custom,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    level: level ?? this.level,
    sessions: sessions ?? this.sessions,
    starterDecided: starterDecided ?? this.starterDecided,
  );

  int get totalMinutes =>
      sessions.fold(0, (sum, session) => sum + (session.minutes ?? 0));

  DateTime? get lastSessionAt => sessions.isEmpty
      ? null
      : sessions.map((s) => s.at).reduce((a, b) => a.isAfter(b) ? a : b);

  Set<DateTime> get _practiceDays => {for (final s in sessions) _day(s.at)};

  /// Sessions in the Monday–Sunday week containing [now].
  Iterable<HobbySession> _inWeekOf(DateTime now) {
    final today = _day(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final nextMonday = monday.add(const Duration(days: 7));
    return sessions.where((s) {
      final day = _day(s.at);
      return !day.isBefore(monday) && day.isBefore(nextMonday);
    });
  }

  int sessionsThisWeek(DateTime now) => _inWeekOf(now).length;

  int minutesThisWeek(DateTime now) =>
      _inWeekOf(now).fold(0, (sum, s) => sum + (s.minutes ?? 0));

  /// Consecutive practice days ending today, or yesterday if today has no
  /// session yet.
  int currentStreak(DateTime now) {
    final days = _practiceDays;
    final today = _day(now);
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool practisedOn(DateTime day) => _practiceDays.contains(_day(day));

  int _daysSinceStart(DateTime now) =>
      _day(now).difference(_day(startedAt)).inDays;

  /// Whether the 7-day starter is still running.
  bool inStarter(DateTime now) =>
      !starterDecided &&
      status == HobbyStatus.active &&
      _daysSinceStart(now) < starterDays;

  /// The starter is over and the person should choose to keep or drop it.
  bool needsStarterDecision(DateTime now) =>
      !starterDecided &&
      status == HobbyStatus.active &&
      _daysSinceStart(now) >= starterDays;

  /// For each starter day (0–6): did they practise that day?
  List<bool> starterProgress() => [
    for (var i = 0; i < starterDays; i++)
      practisedOn(_day(startedAt).add(Duration(days: i))),
  ];

  /// Starter day number (1–7) for [now].
  int starterDay(DateTime now) =>
      (_daysSinceStart(now) + 1).clamp(1, starterDays);

  Map<String, dynamic> toJson() => {
    'hobby_id': hobbyId,
    'name': name,
    if (group != null) 'group': group,
    if (custom) 'custom': true,
    'status': status.name,
    'started_at': startedAt.toUtc().toIso8601String(),
    'level': level,
    'starter_decided': starterDecided,
    'sessions': [for (final s in sessions) s.toJson()],
  };

  factory HobbyRecord.fromJson(Map<String, dynamic> json) => HobbyRecord(
    hobbyId: json['hobby_id'] as String,
    name: json['name'] as String,
    group: json['group'] as String?,
    custom: json['custom'] as bool? ?? false,
    status:
        HobbyStatus.values.where((s) => s.name == json['status']).firstOrNull ??
        HobbyStatus.active,
    startedAt: DateTime.parse(json['started_at'] as String).toLocal(),
    level: (json['level'] as num?)?.toInt() ?? -1,
    starterDecided: json['starter_decided'] as bool? ?? false,
    sessions: [
      for (final s in json['sessions'] as List<dynamic>? ?? [])
        HobbySession.fromJson(s as Map<String, dynamic>),
    ],
  );
}
