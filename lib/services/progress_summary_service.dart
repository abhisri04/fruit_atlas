import '../models/achievement.dart';
import '../models/challenge.dart';
import 'asset_data_service.dart';
import 'indian_dishes_repository.dart';
import 'indian_drinks_repository.dart';
import 'progress_service.dart';
import 'books_repository.dart';
import 'district_repository.dart';
import 'state_exploration_repository.dart';
import '../models/book.dart';

class ChallengeProgressSummary {
  final Challenge challenge;
  final int completed;
  final int total;
  final Set<String> completedReferences;
  final Set<String> eligibleReferences;

  const ChallengeProgressSummary({
    required this.challenge,
    required this.completed,
    required this.total,
    this.completedReferences = const {},
    this.eligibleReferences = const {},
  });
}

class AppProgressSummary {
  final Map<String, ChallengeProgressSummary> challenges;
  final int dishesTried;
  final int dishesCooked;
  final int drinksTried;
  final int achievementCount;
  final Set<String> achievementIds;

  /// Completed items that live outside the challenge catalogue: State/UT
  /// experiences (`experience:`), districts (`district:`) and fruit
  /// varieties (`variety:`).
  final Set<String> explorationReferences;

  const AppProgressSummary({
    required this.challenges,
    required this.dishesTried,
    required this.dishesCooked,
    required this.drinksTried,
    required this.achievementCount,
    this.achievementIds = const {},
    this.explorationReferences = const {},
  });

  Set<String> get completedReferences => {
    for (final value in challenges.values) ...value.completedReferences,
    ...explorationReferences,
  };

  Set<String> get eligibleReferences => {
    for (final value in challenges.values) ...value.eligibleReferences,
  };

  int get experiencesExplored => completedReferences.length;
}

class ProgressSummaryService {
  final AssetDataService data;
  final IndianDishesRepository dishes;
  final IndianDrinksRepository drinks;
  final BooksRepository books;
  final StateExplorationRepository exploration;
  final DistrictRepository districts;

  const ProgressSummaryService({
    this.data = const AssetDataService(),
    this.dishes = const IndianDishesRepository(),
    this.drinks = const IndianDrinksRepository(),
    this.books = const BooksRepository(),
    this.exploration = const StateExplorationRepository(),
    this.districts = const DistrictRepository(),
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
      late Set<String> eligibleReferences;
      late Set<String> completedReferences;
      switch (challenge.itemType) {
        case 'fruit':
          final valid = fruitData.fruits
              .map((fruit) => fruit.id.isEmpty ? fruit.name : fruit.id)
              .toSet();
          eligibleReferences = _typed('fruit', valid);
          completedReferences = _typed(
            'fruit',
            completedFruits.intersection(valid),
          );
        case 'indian_dish':
          final valid = dishCatalogue.dishes.map((item) => item.id).toSet();
          eligibleReferences = _typed('dish', valid);
          completedReferences = _typed(
            'dish',
            dishCatalogue.dishes
                .where((item) => dishProgress[item.id]?.tried ?? false)
                .map((item) => item.id)
                .toSet(),
          );
        case 'indian_drink':
          final valid = drinkCatalogue.drinks.map((item) => item.id).toSet();
          eligibleReferences = _typed('drink', valid);
          completedReferences = _typed(
            'drink',
            drinkCatalogue.drinks
                .where((item) => drinkProgress[item.id]?.tried ?? false)
                .map((item) => item.id)
                .toSet(),
          );
        case 'jyotirlinga':
          final valid = (await data.loadJyotirlingas())
              .map((site) => site.id)
              .toSet();
          eligibleReferences = _typed('jyotirlinga', valid);
          completedReferences = _typed(
            'jyotirlinga',
            (await ProgressService.getCompletedJyotirlingaIds()).intersection(
              valid,
            ),
          );
        case 'book':
          final valid = await books.loadCanonicalIds();
          final progress = await ProgressService.getBookProgress();
          eligibleReferences = _typed('book', valid);
          completedReferences = _typed('book', {
            for (final id in valid)
              if (progress[id]?.isRead ?? false) id,
          });
        default:
          final valid = (await data.loadChallengeItems(challenge))
              .map((item) => item.id)
              .toSet();
          final completed = (await ProgressService.getChallengeItemIds(
            challenge.progressKey,
          )).intersection(valid);
          final prefix = _referencePrefix(challenge.itemType);
          eligibleReferences = _typed(prefix, valid);
          completedReferences = _typed(prefix, completed);
      }
      result[challenge.id] = ChallengeProgressSummary(
        challenge: challenge,
        completed: completedReferences.length,
        total: eligibleReferences.length,
        completedReferences: completedReferences,
        eligibleReferences: eligibleReferences,
      );
    }

    final earnedStatic = result.values.expand(
      (value) => Achievement.achievedFor(value.challenge.id, value.completed),
    );
    final uniqueStatesTried = IndianDishesRepository.triedStateIds(
      dishCatalogue.dishes,
      dishProgress,
    ).length;
    final earnedDish = dishCatalogue.achievements.where((achievement) {
      final metric = switch (achievement.metric) {
        'tried_count' => dishTried,
        'cooked_count' => dishCooked,
        'unique_states_tried' => uniqueStatesTried,
        _ => 0,
      };
      return metric >= achievement.threshold;
    });
    final validVarieties = {
      for (final fruit in fruitData.fruits)
        for (final variety in fruit.varieties)
          if (variety.id != null && variety.id!.isNotEmpty) variety.id!,
    };
    final validDistricts = (await districts.loadDistricts())
        .map((district) => district.id)
        .toSet();
    final explorationReferences = {
      ..._typed('experience', (await exploration.loadProgress()).completedIds),
      ..._typed(
        'district',
        (await ProgressService.getCompletedDistrictIds()).intersection(
          validDistricts,
        ),
      ),
      ..._typed(
        'variety',
        (await ProgressService.getCompletedVarietyIds()).intersection(
          validVarieties,
        ),
      ),
    };
    final uniqueCompleted = {
      for (final value in result.values) ...value.completedReferences,
      ...explorationReferences,
    };
    final earnedGlobal = Achievement.achievedFor(
      'all_experiences',
      uniqueCompleted.length,
    );
    final bookProgress = await ProgressService.getBookProgress();
    final readBookLanguages = bookProgress.values
        .where((item) => item.isRead)
        .expand((item) => item.readLanguages)
        .toSet();
    final achievementIds = {
      ...earnedStatic.map((item) => item.id),
      ...earnedDish.map((item) => item.id),
      ...earnedGlobal.map((item) => item.id),
      if (readBookLanguages.contains(BookLanguage.english) &&
          readBookLanguages.contains(BookLanguage.hindi))
        'book_language_explorer',
    };
    return AppProgressSummary(
      challenges: result,
      dishesTried: dishTried,
      dishesCooked: dishCooked,
      drinksTried: drinkTried,
      achievementCount: achievementIds.length,
      achievementIds: achievementIds,
      explorationReferences: explorationReferences,
    );
  }

  static Set<String> _typed(String prefix, Set<String> ids) =>
      ids.map((id) => '$prefix:$id').toSet();

  static String _referencePrefix(String itemType) => switch (itemType) {
    'yoga_pose' => 'yoga',
    'state_or_union_territory' => 'state',
    _ => itemType,
  };
}
