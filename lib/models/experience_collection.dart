class ExperienceCollection {
  final String id;
  final String title;
  final String description;
  final String iconIdentifier;
  final String parentSectionId;
  final String contextId;
  final String contextName;
  final String entityType;
  final String? experienceType;
  final List<String> memberEntityIds;
  final int sortOrder;
  final String completionVerb;
  final String emptyMessage;

  const ExperienceCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.iconIdentifier,
    required this.parentSectionId,
    required this.contextId,
    required this.contextName,
    required this.entityType,
    this.experienceType,
    this.memberEntityIds = const [],
    required this.sortOrder,
    required this.completionVerb,
    required this.emptyMessage,
  });

  factory ExperienceCollection.fromJson(Map<String, dynamic> json) {
    return ExperienceCollection(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconIdentifier: json['icon'] as String? ?? 'explore',
      parentSectionId: json['parent_section_id'] as String,
      contextId: json['context_id'] as String,
      contextName: json['context_name'] as String,
      entityType: json['entity_type'] as String,
      experienceType: json['experience_type'] as String?,
      memberEntityIds: (json['member_entity_ids'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      sortOrder: json['sort_order'] as int? ?? 0,
      completionVerb: json['completion_verb'] as String? ?? 'completed',
      emptyMessage:
          json['empty_message'] as String? ??
          'More experiences are coming soon.',
    );
  }
}
