enum TravelStatus {
  none('none', 'Not Marked'),
  wantToVisit('want_to_visit', 'Want to Visit'),
  visited('visited', 'Visited');

  final String value;
  final String label;
  const TravelStatus(this.value, this.label);
  static TravelStatus parse(Object? value) =>
      values.firstWhere((status) => status.value == value, orElse: () => none);
}

class StateTravelStatus {
  final String stateId;
  final TravelStatus status;
  final DateTime? updatedAt;
  const StateTravelStatus({
    required this.stateId,
    this.status = TravelStatus.none,
    this.updatedAt,
  });
  Map<String, dynamic> toJson() => {
    'status': status.value,
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };
}
