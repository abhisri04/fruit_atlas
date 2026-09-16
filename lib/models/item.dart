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
  final String? sanskritName;
  final List<String> aliases;
  final String? primaryFamily;
  final List<String> tags;
  final List<String> howToSteps;
  final String? practiceSafety;
  final List<String> sourceRefs;
  final String? researchStatus;
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
    this.sanskritName,
    this.aliases = const [],
    this.primaryFamily,
    this.tags = const [],
    this.howToSteps = const [],
    this.practiceSafety,
    this.sourceRefs = const [],
    this.researchStatus,
    this.metadata = const {},
    this.subItems = const [],
  });

  bool get hasSubItems => subItems.isNotEmpty;

  factory Item.fromJson(Map<String, dynamic> json) {
    final rawSubItems = json['sub_items'] as List<dynamic>? ?? [];
    final aliases = (json['aliases'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList(growable: false);
    final tags = (json['tags'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList(growable: false);
    final rawDifficulty = json['difficulty'] as String?;
    final difficulty = rawDifficulty == null || rawDifficulty.isEmpty
        ? null
        : '${rawDifficulty[0].toUpperCase()}${rawDifficulty.substring(1).toLowerCase()}';
    final primaryFamily = json['primaryFamily'] as String?;

    return Item(
      keywords: [
        ...(json['keywords'] as List<dynamic>? ?? []).map(
          (value) => value.toString(),
        ),
        ...aliases,
        ...tags,
        if (json['sanskritName'] case final String sanskritName) sanskritName,
      ],
      id: json['id'] as String,
      challengeId: json['challenge_id']?.toString() ?? '',
      name: json['name'] as String,
      description: (json['about'] ?? json['description']) as String?,
      scientificName: json['scientific_name'] as String?,
      imageUrl: (json['imageAsset'] ?? json['image_url']) as String?,
      category:
          json['category'] as String? ??
          primaryFamily?.split('_').map(_capitalize).join(' '),
      difficulty: difficulty,
      filterGroup: json['filter_group'] as String?,
      sanskritName: json['sanskritName'] as String?,
      aliases: aliases,
      primaryFamily: primaryFamily,
      tags: tags,
      howToSteps: (json['howToSteps'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(growable: false),
      practiceSafety: json['practiceSafety'] as String?,
      sourceRefs: (json['sourceRefs'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(growable: false),
      researchStatus: json['researchStatus'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      subItems: rawSubItems
          .map((subItem) => SubItem.fromJson(subItem as Map<String, dynamic>))
          .toList(),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
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
