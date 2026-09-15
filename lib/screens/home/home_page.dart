import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/challenge.dart';
import '../../services/fruit_search.dart';
import '../../widgets/discovery_search_field.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/exploration_hero.dart';
import '../saved/saved_page.dart';
import '../my_life/my_life_page.dart';
import '../../models/fruit.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/asset_data_service.dart';
import '../../services/challenge_repository.dart';
import '../../services/progress_service.dart';
import '../challenge/fruit_challenge_page.dart';
import '../discover/discover_page.dart';
import '../fruit/fruit_details_page.dart';
import '../search/discovery_search_page.dart';
import '../../services/global_search_service.dart';
import '../../navigation/search_navigation.dart';
import '../../widgets/search_result_tile.dart';

// HOME PAGE
// ================================================================

class HomePage extends StatefulWidget {
  final bool isActive;
  const HomePage({super.key, this.isActive = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const assetDataService = AssetDataService();
  static const challengeRepository = ChallengeRepository();

  List<Fruit> fruits = [];
  List<AtlasState> states = [];
  List<Challenge> challenges = [];
  Set<String> completedFruitIds = {};
  Map<String, ({int completed, int total})> challengeProgress = {};

  bool isShowingFruitExplorer = false;

  String selectedStateId = 'UP';
  String searchQuery = '';
  final globalSearch = GlobalSearchService();
  bool globalSearchLoading = true;
  bool globalSearchFailed = false;
  String discoveryQuery = '';
  final discoveryController = TextEditingController();
  Future<void> loadGlobalSearch() async {
    setState(() {
      globalSearchLoading = true;
      globalSearchFailed = false;
    });
    try {
      await globalSearch.load();
      if (mounted) setState(() => globalSearchLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          globalSearchLoading = false;
          globalSearchFailed = true;
        });
      }
    }
  }

  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadFruitAtlasData();
    loadGlobalSearch();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) loadFruitAtlasData();
  }

  @override
  void dispose() {
    searchController.dispose();
    discoveryController.dispose();
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

      final loadedProgress = <String, ({int completed, int total})>{};
      for (final challenge in loadedChallenges.where(
        (c) => c.status == 'active',
      )) {
        Set<String> validIds;
        Set<String> savedIds;
        if (challenge.itemType == 'fruit') {
          validIds = fruitData.fruits
              .map((fruit) => fruit.id.isEmpty ? fruit.name : fruit.id)
              .toSet();
          savedIds = completedIds;
        } else if (challenge.itemType == 'jyotirlinga') {
          validIds = (await assetDataService.loadJyotirlingas())
              .map((site) => site.id)
              .toSet();
          savedIds = await ProgressService.getCompletedJyotirlingaIds();
        } else {
          validIds = (await assetDataService.loadChallengeItems(challenge))
              .map((item) => item.id)
              .toSet();
          savedIds = await ProgressService.getChallengeItemIds(
            challenge.progressKey,
          );
        }
        loadedProgress[challenge.id] = (
          completed: savedIds.intersection(validIds).length,
          total: validIds.length,
        );
      }
      if (!mounted) return;
      setState(() {
        challengeProgress = loadedProgress;
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
          'Browse Fruit Atlas',
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
                  value: selectedStateId,
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

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Search discovery',
            icon: const Icon(Icons.search),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiscoverySearchPage(service: globalSearch),
                ),
              );
              if (mounted) await loadFruitAtlasData();
            },
          ),
        ],
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello, explorer',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const ExplorationHero(
                title: 'Make room for discovery',
                immersive: true,
                subtitle: 'Small experiences. A richer you.',
              ),
              DiscoverySearchField(
                controller: discoveryController,
                onChanged: (value) => setState(() => discoveryQuery = value),
              ),
              const SizedBox(height: 14),
              if (discoveryQuery.trim().isNotEmpty) ...[
                if (globalSearchLoading)
                  const LinearProgressIndicator()
                else if (globalSearchFailed)
                  EmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Unable to load search',
                    message: 'Please try again.',
                    actionLabel: 'Retry',
                    onAction: loadGlobalSearch,
                  )
                else ...[
                  Text(
                    discoveryQuery.trim().length == 1
                        ? 'Type at least 2 characters'
                        : 'Top results',
                  ),
                  if (discoveryQuery.trim().length > 1 &&
                      globalSearch.search(discoveryQuery).isEmpty)
                    const EmptyState(
                      icon: Icons.search_off,
                      title: 'No results found',
                      message:
                          'Try an experience, challenge, place or variety.',
                    ),
                  ...globalSearch
                      .search(discoveryQuery)
                      .take(5)
                      .map(
                        (result) => SearchResultTile(
                          result: result,
                          onTap: () async {
                            await openSearchResult(
                              context,
                              result,
                              globalSearch,
                            );
                            if (mounted) await loadFruitAtlasData();
                          },
                        ),
                      ),
                  if (globalSearch.search(discoveryQuery).length > 5)
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('See all results'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DiscoverySearchPage(
                              service: globalSearch,
                              initialQuery: discoveryQuery,
                            ),
                          ),
                        );
                        if (mounted) await loadFruitAtlasData();
                      },
                    ),
                ],
              ],
              Row(
                children: [
                  _quickAction(
                    'Explore',
                    Icons.explore,
                    AppColors.primary,
                    () => setState(() => isShowingFruitExplorer = true),
                  ),
                  _quickAction(
                    'Challenges',
                    Icons.emoji_events,
                    AppColors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiscoverPage()),
                    ),
                  ),
                  _quickAction(
                    'Saved',
                    Icons.bookmark,
                    AppColors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SavedPage()),
                    ),
                  ),
                  _quickAction(
                    'My Life',
                    Icons.person,
                    AppColors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyLifePage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${challengeProgress.values.fold<int>(0, (sum, entry) => sum + entry.completed)} experiences explored',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Continue Your Journey',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (activeChallenges.isEmpty)
                const Text(
                  'No active challenges are available yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...activeChallenges.map(
                  (challenge) => buildDashboardChallengeCard(challenge),
                ),
              const SizedBox(height: 24),
              const Text(
                'Quick Explore',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: activeChallenges
                      .map(
                        (challenge) => SizedBox(
                          width: (constraints.maxWidth - 20) / 3,
                          child: Card(
                            color: AppColors.categoryAccent(
                              challenge.categoryId,
                            ).withValues(alpha: .13),
                            child: InkWell(
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
                                      challenge.itemType == 'fruit'
                                          ? Icons.eco
                                          : challenge.itemType == 'jyotirlinga'
                                          ? Icons.temple_hindu
                                          : Icons.self_improvement,
                                      color: AppColors.categoryAccent(
                                        challenge.categoryId,
                                      ),
                                      size: 34,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      challenge.name.replaceFirst(
                                        RegExp(
                                          r'^(Taste All |Visit All |Learn )',
                                        ),
                                        '',
                                      ),
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
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.travel_explore_outlined),
                  title: const Text('Browse Fruit Atlas'),
                  subtitle: const Text(
                    'Search fruits and explore them by state or UT.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      isShowingFruitExplorer = true;
                    });
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.explore_outlined),
                  title: const Text('Discover more challenges'),
                  subtitle: const Text('See active and upcoming challenges.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiscoverPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color color,
    FutureOr<void> Function() onTap,
  ) => Expanded(
    child: InkWell(
      onTap: () async {
        await onTap();
        if (mounted) await loadFruitAtlasData();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 7),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    ),
  );

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
