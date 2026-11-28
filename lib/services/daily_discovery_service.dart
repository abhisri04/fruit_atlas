import 'package:shared_preferences/shared_preferences.dart';

import '../models/challenge.dart';
import '../models/daily_discovery.dart';
import '../models/item.dart';
import 'asset_data_service.dart';
import 'challenge_repository.dart';
import 'progress_service.dart';
import 'indian_dishes_repository.dart';
import 'indian_drinks_repository.dart';
import 'books_repository.dart';

class DailyDiscoveryService {
  static const _dateKey = 'daily_discovery_date';
  static const _currentKey = 'daily_discovery_current_ref';
  static const _shownKey = 'daily_discovery_shown_today';

  final AssetDataService data;
  final ChallengeRepository challenges;
  final DateTime Function() now;

  const DailyDiscoveryService({
    this.data = const AssetDataService(),
    this.challenges = const ChallengeRepository(),
    this.now = DateTime.now,
  });

  Future<List<DailyDiscovery>> buildEligiblePool() =>
      _buildPool(excludeCompleted: true);

  Future<List<DailyDiscovery>> buildCanonicalPool() =>
      _buildPool(excludeCompleted: false);

  Future<List<DailyDiscovery>> _buildPool({
    required bool excludeCompleted,
  }) async {
    final fruitData = await data.loadFruitData();
    final loadedChallenges = await challenges.loadChallenges();
    final fruitChallenge = loadedChallenges
        .where((challenge) => challenge.itemType == 'fruit')
        .firstOrNull;
    final yogaChallenge = loadedChallenges
        .where((challenge) => challenge.itemType == 'yoga_pose')
        .firstOrNull;
    final yogaItems = yogaChallenge == null
        ? const []
        : await data.loadChallengeItems(yogaChallenge);
    final locationChallenge = loadedChallenges
        .where((challenge) => challenge.itemType == 'state_or_union_territory')
        .firstOrNull;
    final jyotirlingaChallenge = loadedChallenges
        .where((challenge) => challenge.itemType == 'jyotirlinga')
        .firstOrNull;
    final locationItems = locationChallenge == null
        ? const []
        : await data.loadChallengeItems(locationChallenge);
    final hobbyChallenge = loadedChallenges
        .where((challenge) => challenge.itemType == 'hobby')
        .firstOrNull;
    final hobbyItems = hobbyChallenge == null
        ? const <Item>[]
        : await data.loadChallengeItems(hobbyChallenge);
    final completedHobbies = hobbyChallenge == null
        ? <String>{}
        : await ProgressService.getChallengeItemIds(hobbyChallenge.progressKey);
    final gameChallenge = loadedChallenges
        .where((challenge) => challenge.itemType == 'game')
        .firstOrNull;
    final gameItems = gameChallenge == null
        ? const <Item>[]
        : await data.loadChallengeItems(gameChallenge);
    final completedGames = gameChallenge == null
        ? <String>{}
        : await ProgressService.getChallengeItemIds(gameChallenge.progressKey);
    Future<List<({Challenge challenge, List<Item> items, Set<String> done})>>
    poolsFor(String categoryId) async => [
      for (final challenge in loadedChallenges.where(
        (challenge) => challenge.categoryId == categoryId,
      ))
        (
          challenge: challenge,
          items: await data.loadChallengeItems(challenge),
          done: await ProgressService.getChallengeItemIds(
            challenge.progressKey,
          ),
        ),
    ];
    final scentPools = await poolsFor('scent');
    final gardenPools = await poolsFor('garden');
    final collectingPools = [
      ...await poolsFor('collecting'),
      ...await poolsFor('making'),
    ];
    final jyotirlingas = await data.loadJyotirlingas();
    final dishCatalogue = await const IndianDishesRepository().load();
    final dishProgress = await ProgressService.getDishProgress(dishCatalogue);
    final drinkCatalogue = await const IndianDrinksRepository().load();
    final drinkProgress = await ProgressService.getDrinkProgress(
      drinkCatalogue,
    );
    final completedFruits = await ProgressService.getCompletedFruitIds();
    final completedVarieties = await ProgressService.getCompletedVarietyIds();
    final completedYoga = await ProgressService.getCompletedYogaPoseIds();
    final completedLocations = locationChallenge == null
        ? <String>{}
        : await ProgressService.getChallengeItemIds(
            locationChallenge.progressKey,
          );
    final completedJyotirlingas =
        await ProgressService.getCompletedJyotirlingaIds();
    final bookCatalogue = await const BooksRepository().load();
    final bookProgress = await ProgressService.getBookProgress();
    final recommendations = <DailyDiscovery>[];

    for (final fruit in fruitData.fruits) {
      final fruitId = fruit.id.isEmpty ? fruit.name : fruit.id;
      if (!excludeCompleted || !completedFruits.contains(fruitId)) {
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.fruit,
            canonicalId: fruitId,
            title: fruit.name,
            subtitle: fruit.scientificName.isEmpty
                ? 'Fruit to discover'
                : fruit.scientificName,
            categoryId: fruitChallenge?.categoryId ?? 'food_drink',
            fruit: fruit,
          ),
        );
      }
      // Varieties are for people already on that fruit's journey; for
      // everyone else a rare cultivar is just a confusing name.
      final varietiesWelcome = completedFruits.contains(fruitId);
      for (final variety in fruit.varieties) {
        if (!varietiesWelcome) continue;
        final varietyId = variety.id;
        if (varietyId == null ||
            varietyId.isEmpty ||
            (excludeCompleted && completedVarieties.contains(varietyId))) {
          continue;
        }
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.variety,
            canonicalId: varietyId,
            title: variety.name,
            subtitle: 'Variety of ${fruit.name}',
            categoryId: fruitChallenge?.categoryId ?? 'food_drink',
            fruit: fruit,
            variety: variety,
          ),
        );
      }
    }

    if (yogaChallenge != null) {
      for (final pose in yogaItems) {
        final difficulty = pose.difficulty?.toLowerCase();
        if (difficulty != 'beginner' && difficulty != 'intermediate') continue;
        if (excludeCompleted && completedYoga.contains(pose.id)) continue;
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.yogaPose,
            canonicalId: pose.id,
            title: pose.name,
            subtitle: [
              pose.category,
              pose.difficulty,
            ].whereType<String>().join(' · '),
            categoryId: yogaChallenge.categoryId,
            yogaPose: pose,
            yogaChallenge: yogaChallenge,
          ),
        );
      }
    }

    for (final dish in dishCatalogue.dishes) {
      if (excludeCompleted && (dishProgress[dish.id]?.tried ?? false)) continue;
      recommendations.add(
        DailyDiscovery(
          type: DailyDiscoveryType.indianDish,
          canonicalId: dish.id,
          title: dish.name,
          subtitle: '${dish.primaryState} · Indian dish',
          categoryId: 'food_drink',
          dish: dish,
        ),
      );
    }
    for (final drink in drinkCatalogue.drinks) {
      if (excludeCompleted && (drinkProgress[drink.id]?.tried ?? false)) {
        continue;
      }
      recommendations.add(
        DailyDiscovery(
          type: DailyDiscoveryType.indianDrink,
          canonicalId: drink.id,
          title: drink.name,
          subtitle: '${drink.primaryState} · Indian drink',
          categoryId: 'food_drink',
          drink: drink,
        ),
      );
    }
    if (locationChallenge != null) {
      for (final location in locationItems) {
        if (excludeCompleted && completedLocations.contains(location.id)) {
          continue;
        }
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.indiaLocation,
            canonicalId: location.id,
            title: location.name,
            subtitle: location.category ?? 'State or Union Territory',
            categoryId: locationChallenge.categoryId,
            location: location,
            locationChallenge: locationChallenge,
          ),
        );
      }
    }
    for (final site in jyotirlingas) {
      if (excludeCompleted && completedJyotirlingas.contains(site.id)) continue;
      recommendations.add(
        DailyDiscovery(
          type: DailyDiscoveryType.jyotirlinga,
          canonicalId: site.id,
          title: site.name,
          subtitle: site.location,
          categoryId: jyotirlingaChallenge?.categoryId ?? 'faith_pilgrimage',
          jyotirlinga: site,
        ),
      );
    }
    if (hobbyChallenge != null) {
      for (final hobby in hobbyItems) {
        if (excludeCompleted && completedHobbies.contains(hobby.id)) continue;
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.hobby,
            canonicalId: hobby.id,
            title: hobby.name,
            subtitle: hobby.category ?? 'Hobby',
            categoryId: hobbyChallenge.categoryId,
            hobby: hobby,
            hobbyChallenge: hobbyChallenge,
          ),
        );
      }
    }
    if (gameChallenge != null) {
      for (final game in gameItems) {
        if (excludeCompleted && completedGames.contains(game.id)) continue;
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.game,
            canonicalId: game.id,
            title: game.name,
            subtitle: game.category ?? 'Game',
            categoryId: gameChallenge.categoryId,
            hobby: game,
            hobbyChallenge: gameChallenge,
          ),
        );
      }
    }
    for (final pool in scentPools) {
      for (final scent in pool.items) {
        if (excludeCompleted && pool.done.contains(scent.id)) continue;
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.scent,
            canonicalId: scent.id,
            title: scent.name,
            subtitle: scent.filterGroup ?? 'Scent',
            categoryId: pool.challenge.categoryId,
            hobby: scent,
            hobbyChallenge: pool.challenge,
          ),
        );
      }
    }
    for (final pool in collectingPools) {
      for (final item in pool.items) {
        if (excludeCompleted && pool.done.contains(item.id)) continue;
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.hobby,
            canonicalId: item.id,
            title: item.name,
            subtitle: item.filterGroup ?? 'Collecting',
            categoryId: pool.challenge.categoryId,
            hobby: item,
            hobbyChallenge: pool.challenge,
          ),
        );
      }
    }
    for (final pool in gardenPools) {
      for (final item in pool.items) {
        if (excludeCompleted && pool.done.contains(item.id)) continue;
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.garden,
            canonicalId: item.id,
            title: item.name,
            subtitle: item.filterGroup ?? 'Garden',
            categoryId: pool.challenge.categoryId,
            hobby: item,
            hobbyChallenge: pool.challenge,
          ),
        );
      }
    }
    for (final book in bookCatalogue.books) {
      if (excludeCompleted && (bookProgress[book.id]?.isRead ?? false)) {
        continue;
      }
      recommendations.add(
        DailyDiscovery(
          type: DailyDiscoveryType.book,
          canonicalId: book.id,
          title: book.canonicalTitle,
          subtitle: '${book.primaryAuthorDisplay} · ${book.primaryGenre}',
          categoryId: 'culture_learning',
          book: book,
        ),
      );
    }

    final unique = <String, DailyDiscovery>{
      for (final recommendation in recommendations)
        recommendation.reference: recommendation,
    };
    final result = unique.values.toList()
      ..sort((a, b) => a.reference.compareTo(b.reference));
    return result;
  }

  /// Today's Home pick, if one has been chosen today (without choosing).
  Future<String?> todaysReference() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_dateKey) == _localDate(now())
        ? preferences.getString(_currentKey)
        : null;
  }

  Future<DailyDiscovery?> getToday() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _localDate(now());
    final storedDate = preferences.getString(_dateKey);
    final storedReference = preferences.getString(_currentKey);
    final eligible = await buildEligiblePool();
    if (eligible.isEmpty) {
      await preferences.setString(_dateKey, today);
      await preferences.remove(_currentKey);
      await preferences.setStringList(_shownKey, const []);
      return null;
    }

    if (storedDate == today && storedReference != null) {
      final existing = eligible.where(
        (item) => item.reference == storedReference,
      );
      if (existing.isNotEmpty) return existing.first;
    }

    final yesterdayReference = storedDate == today ? null : storedReference;
    final candidates = eligible.length > 1 && yesterdayReference != null
        ? eligible
              .where((item) => item.reference != yesterdayReference)
              .toList()
        : eligible;
    final selected = _pick(candidates, _dayNumber(now()));
    await _persist(preferences, today, selected.reference, [
      selected.reference,
    ]);
    return selected;
  }

  Future<DailyDiscovery?> another() async {
    final current = await getToday();
    if (current == null) return null;
    final preferences = await SharedPreferences.getInstance();
    final eligible = await buildEligiblePool();
    if (eligible.length == 1) return current;
    final shown = preferences.getStringList(_shownKey)?.toSet() ?? <String>{};
    var candidates = eligible
        .where(
          (item) =>
              item.reference != current.reference &&
              !shown.contains(item.reference),
        )
        .toList();
    if (candidates.isEmpty) {
      candidates = eligible
          .where((item) => item.reference != current.reference)
          .toList();
      shown
        ..clear()
        ..add(current.reference);
    }
    final selected = _pick(candidates, _dayNumber(now()) + shown.length);
    shown.add(selected.reference);
    await _persist(
      preferences,
      _localDate(now()),
      selected.reference,
      shown.toList()..sort(),
    );
    return selected;
  }

  /// Takes turns across kinds (hobby, dish, place, book…) so one big
  /// collection doesn't fill every day, then picks within the kind.
  DailyDiscovery _pick(List<DailyDiscovery> candidates, int n) {
    final byType = <DailyDiscoveryType, List<DailyDiscovery>>{};
    for (final c in candidates) {
      byType.putIfAbsent(c.type, () => []).add(c);
    }
    final types = byType.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final items = byType[types[n % types.length]]!;
    return items[(n ~/ types.length) % items.length];
  }

  Future<void> _persist(
    SharedPreferences preferences,
    String date,
    String reference,
    List<String> shown,
  ) async {
    await preferences.setString(_dateKey, date);
    await preferences.setString(_currentKey, reference);
    await preferences.setStringList(_shownKey, shown);
  }

  String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  int _dayNumber(DateTime value) => DateTime(
    value.year,
    value.month,
    value.day,
  ).difference(DateTime(2000)).inDays;
}
