import 'india_location_registry.dart';
import 'item_action_progress.dart';

class DrinkCategory {
  final String id;
  final String name;
  final String subtitle;
  final String description;

  const DrinkCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
  });

  factory DrinkCategory.fromJson(Map<String, dynamic> json) => DrinkCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    subtitle: json['subtitle'] as String,
    description: json['description'] as String,
  );
}

class DrinkTypeDefinition {
  final String id;
  final String label;

  const DrinkTypeDefinition({required this.id, required this.label});

  factory DrinkTypeDefinition.fromJson(Map<String, dynamic> json) =>
      DrinkTypeDefinition(
        id: json['id'] as String,
        label: json['label'] as String,
      );
}

class IndianDrink {
  final String id;
  final String name;
  final List<String> aliases;
  final List<String> originStateIds;
  final List<String> associatedStateIds;
  final List<String> regions;
  final String drinkType;
  final String alcoholContent;
  final String servingStyle;
  final bool containsCannabis;
  final String shortDescription;
  final List<String> tags;
  final String imageAsset;
  final List<String> legacyIds;
  final List<String> sourceRefs;

  const IndianDrink({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.originStateIds,
    required this.associatedStateIds,
    required this.regions,
    required this.drinkType,
    required this.alcoholContent,
    required this.servingStyle,
    this.containsCannabis = false,
    required this.shortDescription,
    required this.tags,
    required this.imageAsset,
    this.legacyIds = const [],
    this.sourceRefs = const [],
  });

  static final stateNames = IndiaLocationRegistry.names;

  List<String> get states => associatedStateIds
      .map((id) => stateNames[id] ?? id)
      .toList(growable: false);

  String get primaryState => states.isEmpty ? 'India' : states.first;

  factory IndianDrink.fromJson(Map<String, dynamic> json) => IndianDrink(
    id: json['id'] as String,
    name: json['name'] as String,
    aliases: List<String>.from(json['aliases'] as List<dynamic>? ?? const []),
    originStateIds: List<String>.from(
      json['origin_state_ids'] as List<dynamic>? ?? const [],
    ),
    associatedStateIds: List<String>.from(
      json['associated_state_ids'] as List<dynamic>? ?? const [],
    ),
    regions: List<String>.from(json['regions'] as List<dynamic>? ?? const []),
    drinkType: json['drink_type'] as String,
    alcoholContent: json['alcohol_content'] as String,
    servingStyle: json['serving_style'] as String,
    containsCannabis: json['contains_cannabis'] as bool? ?? false,
    shortDescription: json['short_description'] as String,
    tags: List<String>.from(json['tags'] as List<dynamic>? ?? const []),
    imageAsset: json['image_asset'] as String,
    legacyIds: List<String>.from(
      json['legacy_ids'] as List<dynamic>? ?? const [],
    ),
    sourceRefs: List<String>.from(
      json['source_refs'] as List<dynamic>? ?? const [],
    ),
  );
}

class IndianDrinksCatalogue {
  final DrinkCategory category;
  final List<DrinkTypeDefinition> drinkTypes;
  final List<IndianDrink> drinks;

  const IndianDrinksCatalogue({
    required this.category,
    required this.drinkTypes,
    required this.drinks,
  });
}

typedef DrinkProgress = Map<String, ItemActionProgress>;
