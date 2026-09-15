class Experience {
  final String id;
  final String title;
  final String description;
  final String type;
  final String section;
  final String parentLocationId;
  final String categoryId;
  final List<String> keywords;
  final String? city;
  final String? cityId;
  final String stateId;
  final String stateName;
  final String status;

  const Experience({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.section,
    required this.parentLocationId,
    required this.categoryId,
    this.keywords = const [],
    this.city,
    this.cityId,
    required this.stateId,
    required this.stateName,
    this.status = 'active',
  });

  String get typeLabel => switch (type) {
    'place' => 'Place',
    'activity' => 'Things to Do',
    'food' => 'Food & Drink',
    'culture' => 'Culture',
    _ => 'Experience',
  };

  String get locationLabel => [
    if (city != null && city != stateName) city,
    stateName,
  ].whereType<String>().join(', ');

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      section: json['section'] as String,
      parentLocationId: json['parent_location_id'] as String,
      categoryId: json['category_id'] as String,
      keywords: (json['keywords'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      city: json['city'] as String?,
      cityId: json['city_id'] as String?,
      stateId: json['state_id'] as String,
      stateName: json['state_name'] as String,
      status: json['status'] as String? ?? 'active',
    );
  }
}
