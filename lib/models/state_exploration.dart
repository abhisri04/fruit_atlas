import 'district.dart';
import 'experience.dart';
import 'experience_collection.dart';

class StateExplorationConfig {
  final String stateId;
  final String stateName;
  final String? districtAsset;
  final String? experienceAsset;
  final String? collectionsAsset;
  final List<ExperienceCollection> collections;

  const StateExplorationConfig({
    required this.stateId,
    required this.stateName,
    this.districtAsset,
    this.experienceAsset,
    this.collectionsAsset,
    this.collections = const [],
  });

  factory StateExplorationConfig.fromJson(Map<String, dynamic> json) {
    return StateExplorationConfig(
      stateId: json['state_id'] as String,
      stateName: json['state_name'] as String,
      districtAsset: json['district_asset'] as String?,
      experienceAsset: json['experience_asset'] as String?,
      collectionsAsset: json['collections_asset'] as String?,
      collections: (json['collections'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                ExperienceCollection.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

class StateExplorationData {
  final StateExplorationConfig config;
  final List<District> districts;
  final List<Experience> experiences;
  final List<ExperienceCollection> collections;

  const StateExplorationData({
    required this.config,
    this.districts = const [],
    this.experiences = const [],
    this.collections = const [],
  });
}
