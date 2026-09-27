import '../models/challenge.dart';
import 'asset_data_service.dart';
import 'indian_dishes_repository.dart';
import 'indian_drinks_repository.dart';
import 'progress_service.dart';

class ChallengeProgressSummary {
  final Challenge challenge;
  final int completed;
  final int total;

  const ChallengeProgressSummary({
    required this.challenge,
    required this.completed,
    required this.total,
  });
}

class AppProgressSummary {
  final Map<String, ChallengeProgressSummary> challenges;
  final int dishesTried;
  final int dishesCooked;
  final int drinksTried;

  const AppProgressSummary({
    required this.challenges,
    required this.dishesTried,
    required this.dishesCooked,
    required this.drinksTried,
  });

  int get experiencesExplored =>
      challenges.values.fold(0, (sum, value) => sum + value.completed);
}

class ProgressSummaryService {
  final AssetDataService data;
  final IndianDishesRepository dishes;
  final IndianDrinksRepository drinks;

  const ProgressSummaryService({
    this.data = const AssetDataService(),
    this.dishes = const IndianDishesRepository(),
    this.drinks = const IndianDrinksRepository(),
  });

  Future<AppProgressSummary> load({List<Challenge>? challenges}) async {
    final loadedChallenges = challenges ?? await data.loadChallenges();
    final active = loadedChallenges.where((item) => item.status == 'active');
    final fruitData = await data.loadFruitData();
    final completedFruits = await ProgressService.getCompletedFruitIds();
    final dishCatalogue = await dishes.load();
    final dishProgress = await ProgressService.getDishProgress(dishCatalogue);
    final drinkCatalogue = await drinks.load();
    final drinkProgress = await ProgressService.getDrinkProgress(
      drinkCatalogue,
    );
    final dishTried = dishCatalogue.dishes
        .where((item) => dishProgress[item.id]?.tried ?? false)
        .length;
    final dishCooked = dishCatalogue.dishes
        .where((item) => dishProgress[item.id]?.cooked ?? false)
        .length;
    final drinkTried = drinkCatalogue.drinks
        .where((item) => drinkProgress[item.id]?.tried ?? false)
        .length;
    final result = <String, ChallengeProgressSummary>{};

    for (final challenge in active) {
      int completed;
      int total;
      switch (challenge.itemType) {
        case 'fruit':
          final valid = fruitData.fruits
              .map((fruit) => fruit.id.isEmpty ? fruit.name : fruit.id)
              .toSet();
          completed = completedFruits.intersection(valid).length;
          total = valid.length;
        case 'indian_dish':
          completed = dishTried;
          total = dishCatalogue.dishes.length;
        case 'indian_drink':
          completed = drinkTried;
          total = drinkCatalogue.drinks.length;
        case 'jyotirlinga':
          final valid = (await data.loadJyotirlingas())
              .map((site) => site.id)
              .toSet();
          completed = (await ProgressService.getCompletedJyotirlingaIds())
              .intersection(valid)
              .length;
          total = valid.length;
        default:
          final valid = (await data.loadChallengeItems(challenge))
              .map((item) => item.id)
              .toSet();
          completed = (await ProgressService.getChallengeItemIds(
            challenge.progressKey,
          )).intersection(valid).length;
          total = valid.length;
      }
      result[challenge.id] = ChallengeProgressSummary(
        challenge: challenge,
        completed: completed,
        total: total,
      );
    }
    return AppProgressSummary(
      challenges: result,
      dishesTried: dishTried,
      dishesCooked: dishCooked,
      drinksTried: drinkTried,
    );
  }
}
