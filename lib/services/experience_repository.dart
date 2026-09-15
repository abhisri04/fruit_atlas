import '../models/experience.dart';
import 'asset_data_service.dart';

class ExperienceRepository {
  final AssetDataService data;

  const ExperienceRepository({this.data = const AssetDataService()});

  static List<Experience>? _cachedExperiences;

  Future<List<Experience>> loadExperiences() async {
    final cached = _cachedExperiences;
    if (cached != null) return cached;
    final loaded = await _loadExperiences();
    return _cachedExperiences ??= loaded;
  }

  Future<List<Experience>> _loadExperiences() async {
    final sources = await data.loadExperienceSources();
    final collections = await Future.wait(
      sources.map(data.loadExperiencesFromAsset),
    );
    return collections
        .expand((experiences) => experiences)
        .where((experience) => experience.status == 'active')
        .toList(growable: false);
  }

  Future<List<Experience>> getForLocation(String locationId) async {
    final experiences = await loadExperiences();
    return experiences
        .where(
          (experience) =>
              experience.parentLocationId == locationId ||
              experience.stateId == locationId,
        )
        .toList(growable: false);
  }

  static void clearCacheForTesting() => _cachedExperiences = null;
}
