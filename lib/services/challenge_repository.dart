import '../models/category.dart';
import '../models/challenge.dart';
import 'asset_data_service.dart';

class ChallengeRepository {
  final AssetDataService assetDataService;

  const ChallengeRepository({this.assetDataService = const AssetDataService()});

  Future<List<Category>> loadCategories() {
    return assetDataService.loadCategories();
  }

  Future<List<Challenge>> loadChallenges() {
    return assetDataService.loadChallenges();
  }

  Future<Challenge?> getChallengeById(String id) async {
    final challenges = await loadChallenges();
    for (final challenge in challenges) {
      if (challenge.id == id) {
        return challenge;
      }
    }
    return null;
  }

  Future<List<Challenge>> getChallengesForCategory(String categoryId) async {
    final challenges = await loadChallenges();
    return challenges
        .where((challenge) => challenge.categoryId == categoryId)
        .toList();
  }
}
