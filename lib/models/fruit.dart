class FruitAtlasData {
  final List<Fruit> fruits;
  final List<AtlasState> states;

  const FruitAtlasData({required this.fruits, required this.states});

  factory FruitAtlasData.fromJson(Map<String, dynamic> json) {
    final rawFruits = json['fruits'] as List<dynamic>? ?? [];
    final rawStates = json['states'] as List<dynamic>? ?? [];

    return FruitAtlasData(
      fruits: rawFruits
          .map((fruit) => Fruit.fromJson(fruit as Map<String, dynamic>))
          .toList(),
      states: rawStates
          .map((state) => AtlasState.fromJson(state as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Fruit {
  final String id;
  final String name;
  final String scientificName;
  final List<String> aliases;
  final String shortDescription;
  final String? cropGroup;
  final List<String> tags;
  final String imageAsset;
  final List<String> sourceRefs;
  final String researchStatus;
  final List<FruitStateRecord> states;
  final List<FruitVariety> varieties;

  const Fruit({
    required this.id,
    required this.name,
    required this.scientificName,
    this.aliases = const [],
    this.shortDescription = '',
    this.cropGroup,
    this.tags = const [],
    this.imageAsset = '',
    this.sourceRefs = const [],
    this.researchStatus = 'legacy_review_needed',
    required this.states,
    required this.varieties,
  });

  String get canonicalImageAsset =>
      imageAsset.isNotEmpty ? imageAsset : 'assets/images/fruits/$id.webp';

  factory Fruit.fromJson(Map<String, dynamic> json) {
    final rawStates = json['states'] as List<dynamic>? ?? [];
    final rawVarieties = json['varieties'] as List<dynamic>? ?? [];

    return Fruit(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Fruit',
      scientificName:
          (json['scientificName'] ?? json['scientific_name'])?.toString() ?? '',
      aliases: (json['aliases'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      shortDescription: json['shortDescription']?.toString() ?? '',
      cropGroup: (json['cropGroup'] ?? json['crop_group'])?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      imageAsset: json['imageAsset']?.toString() ?? '',
      sourceRefs: (json['sourceRefs'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      researchStatus:
          json['researchStatus']?.toString() ?? 'legacy_review_needed',
      states: rawStates
          .map(
            (state) => FruitStateRecord.fromJson(state as Map<String, dynamic>),
          )
          .toList(),
      varieties: rawVarieties
          .map(
            (variety) => FruitVariety.fromJson(variety as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class FruitVariety {
  final String? id;
  final String name;
  final String? notes;

  const FruitVariety({required this.id, required this.name, this.notes});

  factory FruitVariety.fromJson(Map<String, dynamic> json) {
    return FruitVariety(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Unknown variety',
      notes: json['notes']?.toString(),
    );
  }
}

class FruitStateRecord {
  final String stateId;
  final String? status;
  final String? evidence;
  final String? dataYear;

  const FruitStateRecord({
    required this.stateId,
    this.status,
    this.evidence,
    this.dataYear,
  });

  factory FruitStateRecord.fromJson(Map<String, dynamic> json) {
    return FruitStateRecord(
      stateId: json['state_id']?.toString() ?? '',
      status: json['status']?.toString(),
      evidence: json['evidence']?.toString(),
      dataYear: json['data_year']?.toString(),
    );
  }
}

class AtlasState {
  final String id;
  final String name;
  final String? region;
  final String? type;

  const AtlasState({
    required this.id,
    required this.name,
    this.region,
    this.type,
  });

  factory AtlasState.fromJson(Map<String, dynamic> json) {
    return AtlasState(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      region: json['region']?.toString(),
      type: json['type']?.toString(),
    );
  }
}
