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
  final String? cropGroup;
  final String? imageStatus;
  final List<FruitStateRecord> states;
  final List<FruitVariety> varieties;

  const Fruit({
    required this.id,
    required this.name,
    required this.scientificName,
    this.cropGroup,
    this.imageStatus,
    required this.states,
    required this.varieties,
  });

  factory Fruit.fromJson(Map<String, dynamic> json) {
    final rawStates = json['states'] as List<dynamic>? ?? [];
    final rawVarieties = json['varieties'] as List<dynamic>? ?? [];

    return Fruit(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Fruit',
      scientificName: json['scientific_name']?.toString() ?? '',
      cropGroup: json['crop_group']?.toString(),
      imageStatus: json['image_status']?.toString(),
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
