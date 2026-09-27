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

  static const stateNames = <String, String>{
    'andhra_pradesh': 'Andhra Pradesh',
    'arunachal_pradesh': 'Arunachal Pradesh',
    'assam': 'Assam',
    'bihar': 'Bihar',
    'chhattisgarh': 'Chhattisgarh',
    'goa': 'Goa',
    'gujarat': 'Gujarat',
    'haryana': 'Haryana',
    'himachal_pradesh': 'Himachal Pradesh',
    'jharkhand': 'Jharkhand',
    'karnataka': 'Karnataka',
    'kerala': 'Kerala',
    'madhya_pradesh': 'Madhya Pradesh',
    'maharashtra': 'Maharashtra',
    'manipur': 'Manipur',
    'meghalaya': 'Meghalaya',
    'mizoram': 'Mizoram',
    'nagaland': 'Nagaland',
    'odisha': 'Odisha',
    'punjab': 'Punjab',
    'rajasthan': 'Rajasthan',
    'sikkim': 'Sikkim',
    'tamil_nadu': 'Tamil Nadu',
    'telangana': 'Telangana',
    'tripura': 'Tripura',
    'uttar_pradesh': 'Uttar Pradesh',
    'uttarakhand': 'Uttarakhand',
    'west_bengal': 'West Bengal',
    'andaman_nicobar': 'Andaman and Nicobar Islands',
    'chandigarh': 'Chandigarh',
    'dadra_nagar_haveli_daman_diu': 'Dadra and Nagar Haveli and Daman and Diu',
    'delhi': 'Delhi',
    'jammu_kashmir': 'Jammu and Kashmir',
    'ladakh': 'Ladakh',
    'lakshadweep': 'Lakshadweep',
    'puducherry': 'Puducherry',
  };

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

class ItemActionProgress {
  final bool tried;
  final bool cooked;
  final bool wantToTry;
  final bool favourite;
  final DateTime? updatedAt;

  const ItemActionProgress({
    this.tried = false,
    this.cooked = false,
    this.wantToTry = false,
    this.favourite = false,
    this.updatedAt,
  });

  bool hasAction(String action) => switch (action) {
    'tried' => tried,
    'cooked' => cooked,
    'want_to_try' => wantToTry,
    'favourite' => favourite,
    _ => false,
  };

  ItemActionProgress toggle(String action) {
    var nextTried = tried;
    var nextCooked = cooked;
    var nextWant = wantToTry;
    var nextFavourite = favourite;
    switch (action) {
      case 'tried':
        nextTried = !tried;
        if (nextTried) nextWant = false;
        break;
      case 'cooked':
        nextCooked = !cooked;
        if (nextCooked) {
          nextTried = true;
          nextWant = false;
        }
        break;
      case 'want_to_try':
        nextWant = !wantToTry;
        break;
      case 'favourite':
        nextFavourite = !favourite;
        break;
    }
    return ItemActionProgress(
      tried: nextTried,
      cooked: nextCooked,
      wantToTry: nextWant,
      favourite: nextFavourite,
      updatedAt: DateTime.now(),
    );
  }

  factory ItemActionProgress.fromJson(Map<String, dynamic> json) =>
      ItemActionProgress(
        tried: json['tried'] as bool? ?? false,
        cooked: json['cooked'] as bool? ?? false,
        wantToTry: json['want_to_try'] as bool? ?? false,
        favourite: json['favourite'] as bool? ?? false,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
    'tried': tried,
    'cooked': cooked,
    'want_to_try': wantToTry,
    'favourite': favourite,
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  ItemActionProgress merge(ItemActionProgress other) => ItemActionProgress(
    tried: tried || other.tried,
    cooked: cooked || other.cooked,
    wantToTry: (wantToTry || other.wantToTry) && !(tried || other.tried),
    favourite: favourite || other.favourite,
    updatedAt: switch ((updatedAt, other.updatedAt)) {
      (null, final value) => value,
      (final value, null) => value,
      (final left?, final right?) => left.isAfter(right) ? left : right,
    },
  );
}
