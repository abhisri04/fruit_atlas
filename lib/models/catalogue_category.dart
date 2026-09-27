class CategoryActionDefinition {
  final String key;
  final String label;
  final bool countsTowardPrimaryProgress;

  const CategoryActionDefinition({
    required this.key,
    required this.label,
    required this.countsTowardPrimaryProgress,
  });

  factory CategoryActionDefinition.fromJson(Map<String, dynamic> json) =>
      CategoryActionDefinition(
        key: json['key'] as String,
        label: json['label'] as String,
        countsTowardPrimaryProgress:
            json['counts_toward_primary_progress'] as bool? ?? false,
      );
}

class CatalogueCategory {
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String primaryAction;
  final List<CategoryActionDefinition> actions;

  const CatalogueCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.primaryAction,
    required this.actions,
  });

  factory CatalogueCategory.fromJson(Map<String, dynamic> json) =>
      CatalogueCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        subtitle: json['subtitle'] as String,
        description: json['description'] as String,
        primaryAction: json['primary_action'] as String,
        actions: (json['actions'] as List<dynamic>)
            .map(
              (value) => CategoryActionDefinition.fromJson(
                value as Map<String, dynamic>,
              ),
            )
            .toList(growable: false),
      );
}
