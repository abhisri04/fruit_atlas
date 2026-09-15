import '../models/district.dart';
import 'asset_data_service.dart';

class DistrictRepository {
  final AssetDataService data;

  const DistrictRepository({this.data = const AssetDataService()});

  static List<District>? _cachedDistricts;

  Future<List<District>> loadDistricts() async {
    final cached = _cachedDistricts;
    if (cached != null) return cached;
    final loaded = await _loadDistricts();
    return _cachedDistricts ??= loaded;
  }

  Future<List<District>> _loadDistricts() async {
    final sources = await data.loadDistrictSources();
    final collections = await Future.wait(
      sources.map(data.loadDistrictsFromAsset),
    );
    return collections
        .expand((districts) => districts)
        .where((district) => district.status == 'active')
        .toList(growable: false);
  }

  Future<List<District>> getForState(String stateId) async {
    final districts = await loadDistricts();
    return districts
        .where((district) => district.stateId == stateId)
        .toList(growable: false);
  }

  static void clearCacheForTesting() => _cachedDistricts = null;
}
