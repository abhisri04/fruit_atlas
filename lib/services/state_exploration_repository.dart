import '../models/district.dart';
import '../models/experience.dart';
import '../models/experience_collection.dart';
import '../models/state_exploration.dart';
import 'asset_data_service.dart';
import 'progress_service.dart';
import '../models/india_location_registry.dart';

class IndiaExplorationSummary {
  final Map<String, int> counts;
  final Map<String, int> totals;
  final Set<String> completedIds;
  const IndiaExplorationSummary(this.counts, this.totals, this.completedIds);
  int get exploredCount => completedIds.length;
}

class StateExplorationRepository {
  final AssetDataService data;

  const StateExplorationRepository({this.data = const AssetDataService()});

  static Future<Map<String, String>>? _indexFuture;
  static final Map<String, Future<StateExplorationData?>> _stateCache = {};

  Future<StateExplorationData?> load(String stateId) {
    return _stateCache.putIfAbsent(stateId, () => _load(stateId));
  }

  Future<IndiaExplorationSummary> loadProgress() async {
    final completed = await ProgressService.getCompletedExperienceIds();
    final counts = <String, int>{};
    final totals = <String, int>{};
    final all = <String>{};
    final locations = IndiaLocationRegistry.locations;
    final states = await Future.wait(
      locations.map((location) => load(location.id)),
    );
    for (var index = 0; index < locations.length; index++) {
      final location = locations[index];
      final state = states[index];
      final ids = (state?.experiences ?? []).map((e) => e.id).toSet();
      final done = ids.intersection(completed);
      counts[location.id] = done.length;
      totals[location.id] = ids.length;
      all.addAll(done);
    }
    return IndiaExplorationSummary(counts, totals, all);
  }

  Future<StateExplorationData?> _load(String stateId) async {
    final index = await (_indexFuture ??= _loadIndex());
    final configAsset = index[stateId];
    if (configAsset == null) return null;

    final config = StateExplorationConfig.fromJson(
      await data.loadStateExplorationConfig(configAsset),
    );
    final Future<List<District>> districtsFuture = config.districtAsset == null
        ? Future.value(const <District>[])
        : data.loadDistrictsFromAsset(config.districtAsset!);
    final Future<List<Experience>> experiencesFuture =
        config.experienceAsset == null
        ? Future.value(const <Experience>[])
        : data.loadExperiencesFromAsset(config.experienceAsset!);
    final Future<List<ExperienceCollection>> collectionsFuture =
        config.collectionsAsset == null
        ? Future.value(config.collections)
        : data.loadExperienceCollectionsFromAsset(config.collectionsAsset!);

    final districts = await districtsFuture;
    final experiences = await experiencesFuture;
    final collections = await collectionsFuture;
    collections.sort((a, b) {
      final section = a.parentSectionId.compareTo(b.parentSectionId);
      return section != 0 ? section : a.sortOrder.compareTo(b.sortOrder);
    });
    return StateExplorationData(
      config: config,
      districts: districts,
      experiences: experiences,
      collections: List.unmodifiable(collections),
    );
  }

  Future<Map<String, String>> _loadIndex() async {
    final raw = await data.loadStateExplorationIndex();
    final states = raw['states'] as Map<String, dynamic>? ?? const {};
    return states.map((id, asset) => MapEntry(id, asset.toString()));
  }

  static void clearCacheForTesting() {
    _indexFuture = null;
    _stateCache.clear();
  }
}
