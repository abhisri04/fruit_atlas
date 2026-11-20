import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/challenge.dart';
import '../../models/app_branding.dart';
import '../../services/fruit_search.dart';
import '../../widgets/discovery_search_field.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/empty_state.dart';
import '../../models/fruit.dart';
import '../../models/daily_discovery.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/asset_data_service.dart';
import '../../services/challenge_repository.dart';
import '../../services/progress_service.dart';
import '../../services/daily_discovery_service.dart';
import '../../services/progress_summary_service.dart';
import '../challenge/fruit_challenge_page.dart';
import '../discover/discover_page.dart';
import '../fruit/fruit_details_page.dart';
import '../fruit/variety_details_page.dart';
import '../challenge/checklist_item_details_page.dart';
import '../../widgets/daily_discovery_card.dart';
import '../../widgets/challenge_icon.dart';
import '../../models/gamification_summary.dart';
import '../../services/gamification_service.dart';
import '../../services/celebration_service.dart';
import '../../widgets/gamification_header.dart';
import '../../widgets/quest_card.dart';
import '../../widgets/journey_card.dart';
import '../../widgets/travel_journeys.dart';
import '../../services/indian_dishes_repository.dart';
import '../../services/indian_drinks_repository.dart';
import '../dishes/indian_dishes_page.dart';
import '../drinks/indian_drinks_page.dart';
import '../books/book_detail_page.dart';
import '../jyotirlinga/jyotirlinga_details_page.dart';

// HOME PAGE
// ================================================================

class HomePage extends StatefulWidget {
  final bool isActive;
  final DailyDiscoveryService? dailyDiscoveryService;
  const HomePage({super.key, this.isActive = true, this.dailyDiscoveryService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const assetDataService = AssetDataService();
  static const challengeRepository = ChallengeRepository();
  DailyDiscoveryService get dailyDiscoveryService =>
      widget.dailyDiscoveryService ?? const DailyDiscoveryService();

  List<Fruit> fruits = [];
  List<AtlasState> states = [];
  List<Challenge> challenges = [];
  Set<String> completedFruitIds = {};
  Map<String, ({int completed, int total})> challengeProgress = {};
  int experiencesExplored = 0;
  GamificationSummary? gamification;
  DailyDiscovery? dailyDiscovery;
  bool isDailyDiscoveryLoading = true;
  bool isDailyDiscoverySaved = false;

  bool isShowingFruitExplorer = false;

  String selectedStateId = 'UP';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    await Future.wait([loadFruitAtlasData(), loadDailyDiscovery()]);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      loadFruitAtlasData();
      if (dailyDiscovery == null) loadDailyDiscovery();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------
  // LOAD FRUIT DATA
  // ------------------------------------------------

  Future<void> loadFruitAtlasData() async {
    try {
      final fruitData = await assetDataService.loadFruitData();
      final loadedChallenges = await challengeRepository.loadChallenges();
      final completedIds = await ProgressService.getCompletedFruitIds();

      final summary = await const ProgressSummaryService().load(
        challenges: loadedChallenges,
      );
      final loadedProgress = summary.challenges.map(
        (id, value) =>
            MapEntry(id, (completed: value.completed, total: value.total)),
      );
      final loadedGamification = await const GamificationService().load(
        summary,
      );
      if (!mounted) return;
      CelebrationService.instance.presentSummaryTransition(
        gamification,
        loadedGamification,
      );
      setState(() {
        challengeProgress = loadedProgress;
        experiencesExplored = summary.experiencesExplored;
        gamification = loadedGamification;
        errorMessage = null;
        fruits = fruitData.fruits;
        states = fruitData.states;
        challenges = loadedChallenges;
        completedFruitIds = completedIds;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> loadDailyDiscovery() async {
    if (mounted) setState(() => isDailyDiscoveryLoading = true);
    try {
      final discovery = await dailyDiscoveryService.getToday();
      final saved = discovery == null
          ? false
          : await _isDiscoverySaved(discovery);
      if (!mounted) return;
      setState(() {
        dailyDiscovery = discovery;
        isDailyDiscoverySaved = saved;
        isDailyDiscoveryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        dailyDiscovery = null;
        isDailyDiscoverySaved = false;
        isDailyDiscoveryLoading = false;
      });
    }
  }

  Future<void> showAnotherDiscovery() async {
    final discovery = await dailyDiscoveryService.another();
    final saved = discovery == null
        ? false
        : await _isDiscoverySaved(discovery);
    if (!mounted) return;
    setState(() {
      dailyDiscovery = discovery;
      isDailyDiscoverySaved = saved;
      isDailyDiscoveryLoading = false;
    });
  }

  Future<void> toggleDailyDiscoverySaved() async {
    final discovery = dailyDiscovery;
    if (discovery == null) return;
    final saved = switch (discovery.type) {
      DailyDiscoveryType.indianDish =>
        (await ProgressService.toggleCategoryItemAction(
          categoryId: IndianDishesRepository.categoryId,
          itemId: discovery.canonicalId,
          action: 'want_to_try',
        )).wantToTry,
      DailyDiscoveryType.indianDrink =>
        (await ProgressService.toggleCategoryItemAction(
          categoryId: IndianDrinksRepository.categoryId,
          itemId: discovery.canonicalId,
          action: 'want_to_try',
        )).wantToTry,
      _ => await ProgressService.toggleSavedEntity(discovery.reference),
    };
    if (mounted) setState(() => isDailyDiscoverySaved = saved);
  }

  Future<bool> _isDiscoverySaved(DailyDiscovery discovery) async {
    if (discovery.type == DailyDiscoveryType.indianDish) {
      final catalogue = await const IndianDishesRepository().load();
      return (await ProgressService.getDishProgress(
            catalogue,
          ))[discovery.canonicalId]?.wantToTry ??
          false;
    }
    if (discovery.type == DailyDiscoveryType.indianDrink) {
      final catalogue = await const IndianDrinksRepository().load();
      return (await ProgressService.getDrinkProgress(
            catalogue,
          ))[discovery.canonicalId]?.wantToTry ??
          false;
    }
    return ProgressService.isEntitySaved(discovery.reference);
  }

  Future<void> openDailyDiscovery() async {
    final discovery = dailyDiscovery;
    if (discovery == null) return;
    final dishCatalogue = discovery.type == DailyDiscoveryType.indianDish
        ? await const IndianDishesRepository().load()
        : null;
    final drinkCatalogue = discovery.type == DailyDiscoveryType.indianDrink
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
        catalogue: dishCatalogue!,
        dishes: dishCatalogue.dishes,
        initialIndex: dishCatalogue.dishes.indexWhere(
          (dish) => dish.id == discovery.canonicalId,
        ),
      ),
      DailyDiscoveryType.indianDrink => DrinkDetailPage(
        catalogue: drinkCatalogue!,
        drink: discovery.drink!,
      ),
      DailyDiscoveryType.indiaLocation => ChecklistItemDetailsPage(
        challenge: discovery.locationChallenge!,
        item: discovery.location!,
      ),
      DailyDiscoveryType.hobby => ChecklistItemDetailsPage(
        challenge: discovery.hobbyChallenge!,
        item: discovery.hobby!,
      ),
      DailyDiscoveryType.jyotirlinga => JyotirlingaDetailsPage(
        site: discovery.jyotirlinga!,
      ),
      DailyDiscoveryType.book => BookDetailPage(book: discovery.book!),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    await loadFruitAtlasData();
    await loadDailyDiscovery();
  }

  // ------------------------------------------------
  // SELECTED STATE NAME
  // ------------------------------------------------

  String get selectedStateName {
    final matchingStates = states.where((state) => state.id == selectedStateId);

    if (matchingStates.isNotEmpty) {
      return matchingStates.first.name;
    }

    return 'Selected State';
  }

  // ------------------------------------------------
  // STATE FILTER
  // ------------------------------------------------

  List<Fruit> get fruitsForSelectedState {
    return fruits.where((fruit) {
      final fruitStates = fruit.states;

      return fruitStates.any((state) {
        return state.stateId == selectedStateId;
      });
    }).toList();
  }

  // ------------------------------------------------
  // SEARCH
  // ------------------------------------------------

  List<Fruit> get searchResults {
    return filterFruits(fruits, query: searchQuery);
  }

  // ------------------------------------------------
  // OPEN FRUIT DETAILS
  // ------------------------------------------------

  void openFruitDetails(Fruit fruit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FruitDetailsPage(fruit: fruit, states: states),
      ),
    );
  }

  Future<void> openFruitChallenge(Challenge challenge) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FruitChallengePage(challenge: challenge),
      ),
    );

    if (!mounted) return;

    final completedIds = await ProgressService.getCompletedFruitIds();

    if (!mounted) return;

    setState(() {
      completedFruitIds = completedIds;
    });
  }

  // ------------------------------------------------
  // BUILD
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load',
          message: 'Could not load fruit data.\n\n$errorMessage',
        ),
      );
    }

    if (!isShowingFruitExplorer) {
      return buildDashboard(context);
    }

    final isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isShowingFruitExplorer = false;
            });
          },
        ),
        title: const Text(
          'Browse fruits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text(
                'Discover India, one fruit at a time',
                style: TextStyle(fontSize: 16, color: AppColors.muted),
              ),

              const SizedBox(height: 20),

              // SEARCH BAR
              DiscoverySearchField(
                hintText: 'Search fruits or varieties',
                debounce: Duration.zero,
                controller: searchController,
                onChanged: (value) => setState(() => searchQuery = value),
              ),

              const SizedBox(height: 24),

              // =================================================
              // SEARCH RESULTS
              // =================================================
              if (isSearching) ...[
                Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  '${searchResults.length} fruit${searchResults.length == 1 ? '' : 's'} found',
                  style: const TextStyle(color: AppColors.muted),
                ),

                const SizedBox(height: 16),

                if (searchResults.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off,
                    title: 'No fruits found',
                    message: 'Try another fruit, scientific name or variety.',
                  )
                else
                  ...searchResults.map((fruit) => buildFruitCard(fruit)),
              ]
              // =================================================
              // STATE DISCOVERY
              // =================================================
              else ...[
                const Text(
                  'Explore by State',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedStateId,
                  decoration: InputDecoration(
                    labelText: 'Select State / UT',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: states.map<DropdownMenuItem<String>>((state) {
                    return DropdownMenuItem<String>(
                      value: state.id,
                      child: Text(state.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedStateId = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Fruits of $selectedStateName',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${fruitsForSelectedState.length}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${fruitsForSelectedState.length} currently verified fruit mappings',
                  style: const TextStyle(color: AppColors.muted),
                ),

                const SizedBox(height: 16),

                if (fruitsForSelectedState.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No verified fruit mappings found for this location yet.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...fruitsForSelectedState.map(
                    (fruit) => buildFruitCard(fruit),
                  ),

                const SizedBox(height: 24),

                // EXPLORE INDIA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.accentSurface,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.map_outlined, size: 42),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore India',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Discover fruits across all Indian states and UTs.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // STATS
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard('${fruits.length}', 'Fruits'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard('${states.length}', 'States & UTs'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // HOME DASHBOARD
  // =============================================================

  Widget buildDashboard(BuildContext context) {
    final activeChallenges = challenges
        .where((challenge) => challenge.status == 'active')
        .toList();
    activeChallenges.sort((a, b) {
      final aStarted = (challengeProgress[a.id]?.completed ?? 0) > 0;
      final bStarted = (challengeProgress[b.id]?.completed ?? 0) > 0;
      if (aStarted != bStarted) return aStarted ? -1 : 1;
      return challenges.indexOf(a).compareTo(challenges.indexOf(b));
    });
    final quickExplore =
        challenges
            .where(
              (challenge) =>
                  challenge.status == 'active' && challenge.showInQuickExplore,
            )
            .toList()
          ..sort(
            (a, b) => a.quickExplorePriority.compareTo(b.quickExplorePriority),
          );
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final game = gamification;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (game != null)
                GamificationHeader(
                  summary: game,
                  eyebrow: greeting,
                  title: AppBranding.appName,
                ),
              const SizedBox(height: 18),
              if (game != null) QuestCard(quest: game.quest),
              const SizedBox(height: 16),
              const TravelJourneys(),
              const SizedBox(height: 24),
              DailyDiscoveryCard(
                discovery: dailyDiscovery,
                isLoading: isDailyDiscoveryLoading,
                isSaved: isDailyDiscoverySaved,
                onDiscover: openDailyDiscovery,
                onSave: toggleDailyDiscoverySaved,
                onAnother: showAnotherDiscovery,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Continue Your Journeys',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiscoverPage()),
                    ),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (activeChallenges.isEmpty)
                const Text(
                  'No active journeys are available yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                SizedBox(
                  height: 235,
                  child: ListView.separated(
                    key: const ValueKey('continue-journeys'),
                    scrollDirection: Axis.horizontal,
                    itemCount: activeChallenges.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final challenge = activeChallenges[index];
                      final progress = challengeProgress[challenge.id];
                      return JourneyCard(
                        challenge: challenge,
                        completed: progress?.completed ?? 0,
                        total: progress?.total ?? challenge.totalItems,
                        onTap: () async {
                          if (challenge.id == 'taste_fruits_of_india') {
                            await openFruitChallenge(challenge);
                          } else {
                            await openChallenge(context, challenge);
                          }
                          if (mounted) await loadFruitAtlasData();
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Quick Explore',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth < 340 ? 2 : 3;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: quickExplore.take(6).map((challenge) {
                      final accent = AppColors.categoryAccent(
                        challenge.categoryId,
                      );
                      return SizedBox(
                        key: ValueKey('quick-explore-${challenge.id}'),
                        width: width,
                        child: Material(
                          color: accent.withValues(alpha: .11),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await openChallenge(context, challenge);
                              if (mounted) await loadFruitAtlasData();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    challengeIcon(challenge.iconIdentifier),
                                    color: accent,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 9),
                                  Text(
                                    challenge.compactTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.travel_explore_outlined),
                  title: const Text('Browse fruits'),
                  subtitle: const Text(
                    'Search fruits and explore them by state or UT.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => isShowingFruitExplorer = true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDashboardChallengeCard(Challenge challenge) {
    final isFruitChallenge = challenge.id == 'taste_fruits_of_india';

    return ChallengeCard(
      challenge: challenge,
      isActive: true,
      completedCount: challengeProgress[challenge.id]?.completed,
      totalCount: challengeProgress[challenge.id]?.total,
      onTap: () async {
        if (isFruitChallenge) {
          await openFruitChallenge(challenge);
        } else {
          await openChallenge(context, challenge);
        }
        if (mounted) await loadFruitAtlasData();
      },
    );
  }

  // =============================================================
  // FRUIT CARD
  // =============================================================

  Widget buildFruitCard(Fruit fruit) {
    final varieties = fruit.varieties;

    final varietyNames = varieties
        .map((variety) => variety.name)
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openFruitDetails(fruit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // TEMPORARY IMAGE
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.eco_outlined, size: 34),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fruit.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      fruit.scientificName.isEmpty
                          ? 'Scientific name unavailable'
                          : fruit.scientificName,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.muted,
                      ),
                    ),

                    if (varietyNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Varieties: ${varietyNames.join(', ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isShowingFruitExplorer && searchQuery.trim().isEmpty
                            ? selectedStateName
                            : '${fruit.states.length} verified growing regions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // STAT CARD
  // =============================================================

  Widget buildStatCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.background,
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

// =================================================================
