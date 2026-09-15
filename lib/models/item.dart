class Item {
  final List<String> keywords;
  final String id;
  final String challengeId;
  final String name;
  final String? description;
  final String? scientificName;
  final String? imageUrl;
  final String? category;
  final String? difficulty;
  final String? filterGroup;
  final Map<String, String> metadata;
  final List<SubItem> subItems;

  const Item({
    this.keywords = const [],
    required this.id,
    required this.challengeId,
    required this.name,
    this.description,
    this.scientificName,
    this.imageUrl,
    this.category,
    this.difficulty,
    this.filterGroup,
    this.metadata = const {},
    this.subItems = const [],
  });

  bool get hasSubItems => subItems.isNotEmpty;

  factory Item.fromJson(Map<String, dynamic> json) {
    final rawSubItems = json['sub_items'] as List<dynamic>? ?? [];

    return Item(
      keywords: [
        for (final key in ['keywords', 'aliases', 'tags'])
          ...(json[key] as List<dynamic>? ?? []).map(
            (value) => value.toString(),
          ),
      ],
      id: json['id'] as String,
      challengeId: json['challenge_id']?.toString() ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      scientificName: json['scientific_name'] as String?,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      difficulty: json['difficulty'] as String?,
      filterGroup: json['filter_group'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      subItems: rawSubItems
          .map((subItem) => SubItem.fromJson(subItem as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubItem {
  final List<String> keywords;
  final String id;
  final String name;
  final String? description;

  const SubItem({
    required this.id,
    required this.name,
    this.description,
    this.keywords = const [],
  });

  factory SubItem.fromJson(Map<String, dynamic> json) {
    return SubItem(
      keywords: [
        for (final key in ['keywords', 'aliases', 'tags'])
          ...(json[key] as List<dynamic>? ?? []).map(
            (value) => value.toString(),
          ),
      ],
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}
