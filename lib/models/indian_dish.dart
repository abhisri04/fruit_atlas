import 'catalogue_category.dart';
import 'india_location_registry.dart';

class IndianDish {
  final String id;
  final String name;
  final List<String> aliases;
  final List<String> originStateIds;
  final List<String> associatedStateIds;
  final List<String> regions;
  final String dietaryType;
  final String dishType;
  final String shortDescription;
  final List<String> tags;
  final String imageAsset;
  final List<String> legacyIds;

  const IndianDish({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.originStateIds,
    required this.associatedStateIds,
    required this.regions,
    required this.dietaryType,
    required this.dishType,
    required this.shortDescription,
    required this.tags,
    required this.imageAsset,
    this.legacyIds = const [],
  });

  static final stateNames = IndiaLocationRegistry.names;

  String get primaryState {
    final ids = originStateIds.isEmpty ? associatedStateIds : originStateIds;
    return ids.isEmpty ? 'India' : stateNames[ids.first] ?? ids.first;
  }

  List<String> get states => associatedStateIds
      .map((id) => stateNames[id] ?? id)
      .toList(growable: false);

  String get region => regions.isEmpty ? 'India' : regions.first;

  factory IndianDish.fromJson(Map<String, dynamic> json) {
    final legacyPrimaryState = json['primary_state'] as String?;
    final stateIdsByName = {
      for (final entry in stateNames.entries) entry.value: entry.key,
    };
    final associatedStateIds = List<String>.from(
      json['associated_state_ids'] as List<dynamic>? ??
          (json['states'] as List<dynamic>? ?? const []).map(
            (name) => stateIdsByName[name.toString()] ?? name.toString(),
          ),
    );
    if (legacyPrimaryState != null) {
      final id = stateIdsByName[legacyPrimaryState] ?? legacyPrimaryState;
      if (!associatedStateIds.contains(id)) associatedStateIds.insert(0, id);
    }
    return IndianDish(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: List<String>.from(json['aliases'] as List<dynamic>? ?? const []),
      originStateIds: List<String>.from(
        json['origin_state_ids'] as List<dynamic>? ??
            [
              if (legacyPrimaryState != null)
                stateIdsByName[legacyPrimaryState] ?? legacyPrimaryState,
            ],
      ),
      associatedStateIds: List.unmodifiable(associatedStateIds),
      regions: List<String>.from(
        json['regions'] as List<dynamic>? ??
            [if (json['region'] case final String region) region],
      ),
      dietaryType: json['dietary_type'] as String? ?? 'unknown',
      dishType: json['dish_type'] as String? ?? 'unknown',
      shortDescription: json['short_description'] as String,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
      imageAsset: json['image_asset'] as String,
      legacyIds: List<String>.from(
        json['legacy_ids'] as List<dynamic>? ?? [json['id'] as String],
      ),
    );
  }

  String valueFor(String field) => switch (field) {
    'primary_state' => primaryState,
    'region' => region,
    'dietary_type' => dietaryType,
    'dish_type' => dishType,
    _ => '',
  };

  bool matchesField(String field, String expected) => switch (field) {
    'primary_state' => states.contains(expected),
    'region' => regions.contains(expected),
    'dietary_type' => dietaryType == expected,
    'dish_type' => dishType == expected,
    _ => false,
  };
}

class DishCollection {
  final String id;
  final String name;
  final String type;
  final String description;
  final Map<String, dynamic> rule;

  const DishCollection({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.rule,
  });

  factory DishCollection.fromJson(Map<String, dynamic> json) => DishCollection(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    description: json['description'] as String,
    rule: Map<String, dynamic>.from(json['rule'] as Map),
  );
}

class DishAchievement {
  final String id;
  final String name;
  final String metric;
  final int threshold;
  final String description;

  const DishAchievement({
    required this.id,
    required this.name,
    required this.metric,
    required this.threshold,
    required this.description,
  });

  factory DishAchievement.fromJson(Map<String, dynamic> json) =>
      DishAchievement(
        id: json['id'] as String,
        name: json['name'] as String,
        metric: json['metric'] as String,
        threshold: json['threshold'] as int,
        description: json['description'] as String,
      );
}

class IndianDishesCatalogue {
  final CatalogueCategory category;
  final List<IndianDish> dishes;
  final List<DishCollection> collections;
  final List<DishAchievement> achievements;

  const IndianDishesCatalogue({
    required this.category,
    required this.dishes,
    required this.collections,
    required this.achievements,
  });
}
