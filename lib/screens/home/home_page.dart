import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/challenge.dart';
import '../../models/app_branding.dart';
import '../../services/challenge_groups.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/passport_map_thumbnail.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/reward_animations.dart';
import '../../widgets/reveal.dart';
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

const _suggestionOrder = [
  'try_easy_hobbies',
  'explore_indian_states',
  'garden_hub',
  'explore_indian_dishes',
  'learn_yoga_poses',
  'explore_great_books',
  'play_great_games',
  'start_a_collection',
  'make_something',
  'scent_hub',
  'taste_fruits_of_india',
  'taste_world_nuts',
  'visit_12_jyotirlingas',
  'explore_indian_drinks',
];

class _HomePageState extends State<HomePage> {
  List<String> interests = Interests.defaults;
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
    super.dispose();
  }

  // ------------------------------------------------
  // LOAD FRUIT DATA
  // ------------------------------------------------

  Future<void> loadFruitAtlasData() async {
    final saved = await UserProfileService.interests();
    if (mounted) setState(() => interests = saved);
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
      DailyDiscoveryType.hobby ||
      DailyDiscoveryType.game ||
      DailyDiscoveryType.scent ||
      DailyDiscoveryType.garden => ChecklistItemDetailsPage(
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
          message: 'Could not load your app data.\n\n$errorMessage',
        ),
      );
    }

    return buildDashboard(context);
  }

  // =============================================================
  // HOME DASHBOARD
  // =============================================================

  Widget buildDashboard(BuildContext context) {
    final activeChallenges = groupHubChallenges(
      challenges.where((challenge) => challenge.status == 'active'),
    );
    int doneFor(Challenge c) =>
        groupedProgress(c, (id) => challengeProgress[id], challenges).completed;
    // Your journeys: only what you've started, most recent order.
    final started = [
      for (final c in activeChallenges)
        if (doneFor(c) > 0) c,
    ];
    // Something new: from what you said you're into, then a mix of areas.
    final byId = {for (final c in activeChallenges) c.id: c};
    final suggestions = <Challenge>[
      for (final id in {
        ...Interests.challengeIdsFor(interests),
        ..._suggestionOrder,
      })
        if (byId[id] case final c? when doneFor(c) == 0) c,
    ].take(6).toList();
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
                Reveal(
                  child: GamificationHeader(
                    summary: game,
                    eyebrow: greeting,
                    title: AppBranding.appName,
                  ),
                ),
              const SizedBox(height: 18),
              if (game != null)
                Reveal(index: 1, child: QuestCard(quest: game.quest)),
              const SizedBox(height: 24),
              Reveal(
                index: 3,
                child: DailyDiscoveryCard(
                  discovery: dailyDiscovery,
                  isLoading: isDailyDiscoveryLoading,
                  isSaved: isDailyDiscoverySaved,
                  onDiscover: openDailyDiscovery,
                  onSave: toggleDailyDiscoverySaved,
                  onAnother: showAnotherDiscovery,
                ),
              ),
              if (started.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your journeys',
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
                SizedBox(
                  height: 235,
                  child: ListView.separated(
                    key: const ValueKey('continue-journeys'),
                    scrollDirection: Axis.horizontal,
                    itemCount: started.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final challenge = started[index];
                      final progress = groupedProgress(
                        challenge,
                        (id) => challengeProgress[id],
                        challenges,
                      );
                      return JourneyCard(
                        challenge: challenge,
                        completed: progress.completed,
                        total: progress.total,
                        artwork:
                            challenge.itemType == 'state_or_union_territory'
                            ? const PassportMapThumbnail(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(AppSpacing.radius),
                                ),
                              )
                            : null,
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
              ],
              const SizedBox(height: 24),
              Text(
                started.isEmpty ? 'Start here' : 'Try something new',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                started.isEmpty
                    ? 'Picked from what you are into. Tap one to begin.'
                    : 'Something you haven\'t started yet.',
                style: const TextStyle(color: AppColors.muted),
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
                    children: suggestions.map((challenge) {
                      final accent = AppColors.categoryAccent(
                        challenge.categoryId,
                      );
                      return SizedBox(
                        key: ValueKey('quick-explore-${challenge.id}'),
                        width: width,
                        child: TactileScale(
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
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
