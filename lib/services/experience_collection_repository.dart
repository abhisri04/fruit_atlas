import '../models/experience_collection.dart';
import 'asset_data_service.dart';

class ExperienceCollectionRepository {
  final AssetDataService data;

  const ExperienceCollectionRepository({this.data = const AssetDataService()});

  static List<ExperienceCollection>? _cache;

  Future<List<ExperienceCollection>> loadCollections() async {
    final cached = _cache;
    if (cached != null) return cached;
    final loaded = await data.loadExperienceCollections();
    loaded.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _cache ??= List.unmodifiable(loaded);
  }

  Future<List<ExperienceCollection>> getForSection(
    String contextId,
    String sectionId,
  ) async {
    final collections = await loadCollections();
    return collections
        .where(
          (collection) =>
              collection.contextId == contextId &&
              collection.parentSectionId == sectionId,
        )
        .toList(growable: false);
  }

  static void clearCacheForTesting() => _cache = null;
}
