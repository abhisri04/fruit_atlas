class District {
  final String id;
  final String name;
  final String stateId;
  final String stateName;
  final String description;
  final List<String> keywords;
  final String status;

  const District({
    required this.id,
    required this.name,
    required this.stateId,
    required this.stateName,
    required this.description,
    this.keywords = const [],
    this.status = 'active',
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as String,
      name: json['name'] as String,
      stateId: json['state_id'] as String,
      stateName: json['state_name'] as String,
      description: json['description'] as String,
      keywords: (json['keywords'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      status: json['status'] as String? ?? 'active',
    );
  }
}
