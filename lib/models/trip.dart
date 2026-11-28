import 'india_location_registry.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A trip someone took: where, when and for how long, with an optional
/// note, companions and photo. Saving one stamps India Passport.
class Trip {
  final String id;
  final String title;
  final List<String> stateIds;
  final DateTime start;
  final int days;
  final String? note;
  final String? companions;
  final String? photoId;

  const Trip({
    required this.id,
    required this.title,
    required this.stateIds,
    required this.start,
    this.days = 1,
    this.note,
    this.companions,
    this.photoId,
  });

  DateTime get end => DateTime(start.year, start.month, start.day + days - 1);

  /// A friendly default name, e.g. "Goa trip" or "Kerala & Goa trip".
  static String defaultTitle(List<String> stateIds) {
    final names = stateIds.map(IndiaLocationRegistry.nameFor).toList();
    return switch (names.length) {
      0 => 'A trip',
      1 => '${names.first} trip',
      2 => '${names[0]} & ${names[1]} trip',
      _ => '${names.first} and ${names.length - 1} more',
    };
  }

  Trip copyWith({
    String? title,
    List<String>? stateIds,
    DateTime? start,
    int? days,
    String? note,
    String? companions,
    String? photoId,
    bool clearPhoto = false,
  }) => Trip(
    id: id,
    title: title ?? this.title,
    stateIds: stateIds ?? this.stateIds,
    start: start ?? this.start,
    days: days ?? this.days,
    note: note ?? this.note,
    companions: companions ?? this.companions,
    photoId: clearPhoto ? null : (photoId ?? this.photoId),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'state_ids': stateIds,
    'start': DateTime(start.year, start.month, start.day).toIso8601String(),
    'days': days,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (companions != null && companions!.isNotEmpty) 'companions': companions,
    if (photoId != null) 'photo_id': photoId,
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    title: json['title'] as String,
    stateIds: (json['state_ids'] as List<dynamic>).cast<String>(),
    start: DateTime.parse(json['start'] as String),
    days: (json['days'] as num?)?.toInt() ?? 1,
    note: json['note'] as String?,
    companions: json['companions'] as String?,
    photoId: json['photo_id'] as String?,
  );
}

/// All trips, newest first, with the numbers the Trips page shows.
class TripLog {
  final List<Trip> trips;

  TripLog(Iterable<Trip> trips)
    : trips = trips.toList()..sort((a, b) => b.start.compareTo(a.start));

  bool get isEmpty => trips.isEmpty;

  int get daysTravelled => trips.fold(0, (sum, t) => sum + t.days);

  Set<String> get statesCovered => {for (final t in trips) ...t.stateIds};

  int tripsIn(int year) => trips.where((t) => t.start.year == year).length;

  /// Trips that started on this date in an earlier year.
  List<Trip> onThisDay(DateTime now) => [
    for (final t in trips)
      if (t.start.year < now.year &&
          _sameDay(DateTime(now.year, t.start.month, t.start.day), now))
        t,
  ];

  /// The longest trip, if any.
  Trip? get longest =>
      trips.isEmpty ? null : trips.reduce((a, b) => b.days > a.days ? b : a);
}
