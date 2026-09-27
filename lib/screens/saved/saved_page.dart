import 'package:flutter/material.dart';

import '../../models/challenge.dart';
import '../../models/daily_discovery.dart';
import '../../models/fruit.dart';
import '../../models/indian_dish.dart';
import '../../models/indian_drink.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/challenge_repository.dart';
import '../../services/progress_service.dart';
import '../../services/daily_discovery_service.dart';
import '../../services/asset_data_service.dart';
import '../../services/indian_dishes_repository.dart';
import '../../services/indian_drinks_repository.dart';
import '../../services/progress_summary_service.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/empty_state.dart';
import '../discover/discover_page.dart';
import '../fruit/fruit_details_page.dart';
import '../fruit/variety_details_page.dart';
import '../../widgets/fruit_image.dart';
import '../challenge/checklist_item_details_page.dart';
import '../dishes/indian_dishes_page.dart';
import '../drinks/indian_drinks_page.dart';
import '../jyotirlinga/jyotirlinga_details_page.dart';

// SAVED PAGE
// =================================================================

class SavedPage extends StatefulWidget {
  final DailyDiscoveryService? dailyDiscoveryService;
  const SavedPage({super.key, this.dailyDiscoveryService});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  static const repository = ChallengeRepository();
  static const dataService = AssetDataService();
  DailyDiscoveryService get dailyService =>
      widget.dailyDiscoveryService ?? const DailyDiscoveryService();
  List<Challenge> savedChallenges = [];
  List<DailyDiscovery> savedEntities = [];
  Map<String, ChallengeProgressSummary> challengeProgress = {};
  List<_SavedCatalogueItem> wantToTry = [];
  List<_SavedCatalogueItem> favourites = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSavedChallenges();
  }

  Future<void> loadSavedChallenges() async {
    try {
      final challenges = await repository.loadChallenges();
      final savedIds = await ProgressService.getSavedChallengeIds();
      final savedReferences = await ProgressService.getSavedEntityReferences();
      final canonicalPool = savedReferences.isEmpty
          ? const <DailyDiscovery>[]
          : await dailyService.buildCanonicalPool();
      final dishes = await const IndianDishesRepository().load();
      final dishProgress = await ProgressService.getDishProgress(dishes);
      final drinks = await const IndianDrinksRepository().load();
      final drinkProgress = await ProgressService.getDrinkProgress(drinks);
      final catalogueItems = <_SavedCatalogueItem>[
        for (final dish in dishes.dishes)
          _SavedCatalogueItem.dish(
            dish,
            dishes,
            dishProgress[dish.id]?.wantToTry ?? false,
            dishProgress[dish.id]?.favourite ?? false,
          ),
        for (final drink in drinks.drinks)
          _SavedCatalogueItem.drink(
            drink,
            drinks,
            drinkProgress[drink.id]?.wantToTry ?? false,
            drinkProgress[drink.id]?.favourite ?? false,
          ),
      ];
      final summary = savedIds.isEmpty
          ? null
          : await const ProgressSummaryService().load(challenges: challenges);
      if (!mounted) return;
      setState(() {
        savedChallenges = challenges
            .where((challenge) => savedIds.contains(challenge.id))
            .toList();
        savedEntities = canonicalPool
            .where((entity) => savedReferences.contains(entity.reference))
            .toList(growable: false);
        wantToTry = catalogueItems.where((item) => item.wanted).toList();
        favourites = catalogueItems.where((item) => item.favourite).toList();
        challengeProgress = summary?.challenges ?? {};
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> openCatalogueItem(_SavedCatalogueItem item) async {
    final page = item.dish != null
        ? DishDetailPage(
            catalogue: item.dishes!,
            dishes: item.dishes!.dishes,
            initialIndex: item.dishes!.dishes.indexWhere(
              (dish) => dish.id == item.dish!.id,
            ),
          )
        : DrinkDetailPage(catalogue: item.drinks!, drink: item.drink!);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await loadSavedChallenges();
  }

  Future<void> openSavedChallenge(Challenge challenge) async {
    await openChallenge(context, challenge);
    await loadSavedChallenges();
  }

  Future<void> openSavedEntity(DailyDiscovery discovery) async {
    final states = discovery.type == DailyDiscoveryType.yogaPose
        ? const <AtlasState>[]
        : (await dataService.loadFruitData()).states;
    if (!mounted) return;
    final dishes = discovery.type == DailyDiscoveryType.indianDish
        ? await const IndianDishesRepository().load()
        : null;
    final drinks = discovery.type == DailyDiscoveryType.indianDrink
        ? await const IndianDrinksRepository().load()
        : null;
    if (!mounted) return;
    final page = switch (discovery.type) {
      DailyDiscoveryType.fruit => FruitDetailsPage(
        fruit: discovery.fruit!,
        states: states,
      ),
      DailyDiscoveryType.variety => VarietyDetailsPage(
        variety: discovery.variety!,
        fruit: discovery.fruit!,
        states: states,
      ),
      DailyDiscoveryType.yogaPose => ChecklistItemDetailsPage(
        challenge: discovery.yogaChallenge!,
        item: discovery.yogaPose!,
      ),
      DailyDiscoveryType.indianDish => DishDetailPage(
        catalogue: dishes!,
        dishes: dishes.dishes,
        initialIndex: dishes.dishes.indexWhere(
          (dish) => dish.id == discovery.canonicalId,
        ),
      ),
      DailyDiscoveryType.indianDrink => DrinkDetailPage(
        catalogue: drinks!,
        drink: discovery.drink!,
      ),
      DailyDiscoveryType.indiaLocation => ChecklistItemDetailsPage(
        challenge: discovery.locationChallenge!,
        item: discovery.location!,
      ),
      DailyDiscoveryType.jyotirlinga => JyotirlingaDetailsPage(
        site: discovery.jyotirlinga!,
      ),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await loadSavedChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load',
              message: 'Could not load saved challenges.\n\n$errorMessage',
            )
          : savedChallenges.isEmpty &&
                savedEntities.isEmpty &&
                wantToTry.isEmpty &&
                favourites.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border,
              title: 'Keep your next adventure close',
              message: 'Save challenges to access them quickly.',
              actionLabel: 'Discover challenges',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscoverPage()),
                );
                await loadSavedChallenges();
              },
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (wantToTry.isNotEmpty) ...[
                  _CatalogueSection(
                    title: 'Want to Try',
                    items: wantToTry,
                    onTap: openCatalogueItem,
                  ),
                  const SizedBox(height: 18),
                ],
                if (favourites.isNotEmpty) ...[
                  _CatalogueSection(
                    title: 'Favourites',
                    items: favourites,
                    onTap: openCatalogueItem,
                  ),
                  const SizedBox(height: 18),
                ],
                if (savedEntities.isNotEmpty) ...[
                  Text(
                    'Saved discoveries',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final discovery in savedEntities)
                    Card(
                      child: ListTile(
                        leading: discovery.fruit == null
                            ? const Icon(Icons.self_improvement_outlined)
                            : FruitImage(
                                fruit: discovery.fruit!,
                                width: 42,
                                height: 42,
                              ),
                        title: Text(discovery.title),
                        subtitle: Text(discovery.subtitle),
                        trailing: IconButton(
                          tooltip: 'Remove from Saved',
                          icon: const Icon(Icons.bookmark),
                          onPressed: () async {
                            await ProgressService.toggleSavedEntity(
                              discovery.reference,
                            );
                            await loadSavedChallenges();
                          },
                        ),
                        onTap: () => openSavedEntity(discovery),
                      ),
                    ),
                  const SizedBox(height: 18),
                ],
                if (savedChallenges.isNotEmpty) ...[
                  Text(
                    'Saved challenges',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final challenge in savedChallenges)
                    ChallengeCard(
                      challenge: challenge,
                      isActive: challenge.status == 'active',
                      completedCount:
                          challengeProgress[challenge.id]?.completed,
                      totalCount: challengeProgress[challenge.id]?.total,
                      onSavedChanged: (_) => loadSavedChallenges(),
                      onTap: () => openSavedChallenge(challenge),
                    ),
                ],
              ],
            ),
    );
  }
}

class _SavedCatalogueItem {
  final IndianDish? dish;
  final IndianDrink? drink;
  final IndianDishesCatalogue? dishes;
  final IndianDrinksCatalogue? drinks;
  final bool wanted;
  final bool favourite;

  const _SavedCatalogueItem._({
    this.dish,
    this.drink,
    this.dishes,
    this.drinks,
    required this.wanted,
    required this.favourite,
  });

  factory _SavedCatalogueItem.dish(
    IndianDish dish,
    IndianDishesCatalogue catalogue,
    bool wanted,
    bool favourite,
  ) => _SavedCatalogueItem._(
    dish: dish,
    dishes: catalogue,
    wanted: wanted,
    favourite: favourite,
  );

  factory _SavedCatalogueItem.drink(
    IndianDrink drink,
    IndianDrinksCatalogue catalogue,
    bool wanted,
    bool favourite,
  ) => _SavedCatalogueItem._(
    drink: drink,
    drinks: catalogue,
    wanted: wanted,
    favourite: favourite,
  );

  String get name => dish?.name ?? drink!.name;
  String get kind => dish == null ? 'Drink' : 'Dish';
}

class _CatalogueSection extends StatelessWidget {
  final String title;
  final List<_SavedCatalogueItem> items;
  final Future<void> Function(_SavedCatalogueItem) onTap;

  const _CatalogueSection({
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      for (final item in items)
        Card(
          child: ListTile(
            leading: Icon(
              item.dish == null
                  ? Icons.local_cafe_outlined
                  : Icons.ramen_dining_outlined,
            ),
            title: Text(item.name),
            subtitle: Text(item.kind),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTap(item),
          ),
        ),
    ],
  );
}

// =================================================================
