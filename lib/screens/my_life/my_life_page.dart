import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/achievement.dart';
import '../../models/challenge.dart';
import '../../services/asset_data_service.dart';
import '../../services/district_repository.dart';
import '../../services/experience_repository.dart';
import '../../services/progress_service.dart';
import '../../services/progress_summary_service.dart';
import '../../services/state_travel_service.dart';
import '../../services/state_exploration_repository.dart';
import '../../services/indian_dishes_repository.dart';
import '../../services/indian_drinks_repository.dart';
import '../../models/gamification_summary.dart';
import '../../models/book.dart';
import '../../services/gamification_service.dart';
import '../../services/celebration_service.dart';
import '../../widgets/gamification_header.dart';
import '../../widgets/category_progress_ring.dart';
import '../../widgets/category_icon.dart';
import '../saved/saved_page.dart';
import '../share/share_studio_page.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/empty_state.dart';

class MyLifePage extends StatefulWidget {
  const MyLifePage({super.key});

  @override
  State<MyLifePage> createState() => _MyLifePageState();
}

class _MyLifePageState extends State<MyLifePage> {
  static const dataService = AssetDataService();
  static const experienceRepository = ExperienceRepository();
  static const districtRepository = DistrictRepository();
  bool isLoading = true;
  String? errorMessage;
  int fruitCount = 0;
  int fruitTotal = 0;
  int varietyCount = 0;
  int varietyTotal = 0;
  int jyotirlingaCount = 0;
  int jyotirlingaTotal = 0;
  List<({Challenge challenge, int count, int total})> checklistProgress = [];
  int experienceCount = 0;
  int districtCount = 0;
  int dishTriedCount = 0;
  int dishCookedCount = 0;
  int drinkTriedCount = 0;
  List<Achievement> achievements = [];
  GamificationSummary? gamification;
  int savedCount = 0;
  int selectedTab = 0;
  int statesVisited = 0;
  int statesWanted = 0;
  int indiaExplored = 0;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  Future<void> loadSummary() async {
    try {
      final fruitData = await dataService.loadFruitData();
      final sites = await dataService.loadJyotirlingas();
      final challenges = await dataService.loadChallenges();
      final completedFruits = await ProgressService.getCompletedFruitIds();
      final completedVarieties = await ProgressService.getCompletedVarietyIds();
      final completedSites = await ProgressService.getCompletedJyotirlingaIds();
      final experiences = await experienceRepository.loadExperiences();
      final districts = await districtRepository.loadDistricts();
      final completedExperiences =
          await ProgressService.getCompletedExperienceIds();
      final completedDistricts =
          await ProgressService.getCompletedDistrictIds();
      final summary = await const ProgressSummaryService().load(
        challenges: challenges,
      );
      final loadedGamification = await const GamificationService().load(
        summary,
      );
      final travel = StateTravelService();
      await travel.load();
      final visited = travel.visitedCount;
      final wanted = travel.wantToVisitCount;
      travel.dispose();
      final india = await const StateExplorationRepository().loadProgress();
      final bookProgress = await ProgressService.getBookProgress();
      final readBookLanguages = bookProgress.values
          .where((item) => item.isRead)
          .expand((item) => item.readLanguages)
          .toSet();
      final genericProgress = summary.challenges.values
          .where(
            (value) =>
                value.challenge.itemType != 'fruit' &&
                value.challenge.itemType != 'jyotirlinga',
          )
          .map(
            (value) => (
              challenge: value.challenge,
              count: value.completed,
              total: value.total,
            ),
          )
          .toList();
      final dishCatalogue = await const IndianDishesRepository().load();
      final dishProgress = await ProgressService.getDishProgress(dishCatalogue);
      final drinkCatalogue = await const IndianDrinksRepository().load();
      final drinkProgress = await ProgressService.getDrinkProgress(
        drinkCatalogue,
      );
      final savedChallenges = await ProgressService.getSavedChallengeIds();
      final savedEntities = await ProgressService.getSavedEntityReferences();
      final savedCatalogueItems =
          dishProgress.values
              .where((value) => value.wantToTry || value.favourite)
              .length +
          drinkProgress.values
              .where((value) => value.wantToTry || value.favourite)
              .length;
      int dishMetric(String metric) => switch (metric) {
        'tried_count' => summary.dishesTried,
        'cooked_count' => summary.dishesCooked,
        'unique_states_tried' => IndianDishesRepository.triedStateIds(
          dishCatalogue.dishes,
          dishProgress,
        ).length,
        _ => 0,
      };
      final fruitIds = fruitData.fruits
          .map((fruit) => fruit.id)
          .where((id) => id.isNotEmpty)
          .toSet();
      final varietyIds = fruitData.fruits
          .expand((fruit) => fruit.varieties)
          .map((variety) => variety.id)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      final siteIds = sites
          .map((site) => site.id)
          .where((id) => id.isNotEmpty)
          .toSet();
      final validFruitCount = completedFruits.intersection(fruitIds).length;
      final validVarietyCount = completedVarieties
          .intersection(varietyIds)
          .length;
      final validSiteCount = completedSites.intersection(siteIds).length;
      final validExperienceCount = completedExperiences
          .intersection(experiences.map((experience) => experience.id).toSet())
          .length;
      final validDistrictCount = completedDistricts
          .intersection(districts.map((district) => district.id).toSet())
          .length;
      if (!mounted) return;
      CelebrationService.instance.presentSummaryTransition(
        gamification,
        loadedGamification,
      );
      setState(() {
        fruitCount = validFruitCount;
        fruitTotal = fruitIds.length;
        varietyCount = validVarietyCount;
        varietyTotal = varietyIds.length;
        jyotirlingaCount = validSiteCount;
        jyotirlingaTotal = siteIds.length;
        checklistProgress = genericProgress;
        experienceCount = validExperienceCount;
        districtCount = validDistrictCount;
        dishTriedCount = summary.dishesTried;
        dishCookedCount = summary.dishesCooked;
        drinkTriedCount = summary.drinksTried;
        gamification = loadedGamification;
        statesVisited = visited;
        statesWanted = wanted;
        indiaExplored = india.exploredCount;
        savedCount =
            savedChallenges.length + savedEntities.length + savedCatalogueItems;
        achievements = [
          ...Achievement.achievedFor('taste_fruits_of_india', validFruitCount),
          ...Achievement.achievedFor('visit_12_jyotirlingas', validSiteCount),
          for (final progress in genericProgress)
            ...Achievement.achievedFor(progress.challenge.id, progress.count),
          if (readBookLanguages.contains(BookLanguage.english) &&
              readBookLanguages.contains(BookLanguage.hindi))
            const Achievement(
              id: 'book_language_explorer',
              title: 'Language Explorer',
              description: 'Read at least one English and one Hindi book.',
              threshold: 2,
              challengeId: 'explore_great_books',
              iconIdentifier: 'book',
            ),
          for (final item in dishCatalogue.achievements)
            if (dishMetric(item.metric) >= item.threshold)
              Achievement(
                id: item.id,
                title: item.name,
                description: item.description,
                threshold: item.threshold,
                challengeId: 'explore_indian_dishes',
                iconIdentifier: 'food',
              ),
          ...Achievement.achievedFor('all_experiences', validExperienceCount),
        ];
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

  double ratio(int value, int total) => total == 0 ? 0 : value / total;

  @override
  Widget build(BuildContext context) {
    final game = gamification;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Life'),
        actions: [
          IconButton(
            key: const ValueKey('open-share-studio'),
            tooltip: 'Share Studio',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShareStudioPage()),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load',
              message: 'Could not load your progress.\n\n$errorMessage',
            )
          : RefreshIndicator(
              onRefresh: loadSummary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  if (game != null)
                    GamificationHeader(
                      summary: game,
                      eyebrow: 'YOUR LIFE PROFILE',
                      title: 'Your journey so far',
                    ),
                  const SizedBox(height: 18),
                  _LifeTabs(
                    selected: selectedTab,
                    onChanged: (value) => setState(() => selectedTab = value),
                  ),
                  const SizedBox(height: 20),
                  if (selectedTab == 0) _buildOverview(game),
                  if (selectedTab == 1) _buildStats(),
                  if (selectedTab == 2) _buildAchievements(),
                  if (selectedTab == 3)
                    const EmptyState(
                      icon: Icons.calendar_month_outlined,
                      title: 'Your timeline starts here',
                      message: 'Activity history will appear when completion dates are available.',
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview(GamificationSummary? game) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            const Text(
              'Life Experience Score',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${game?.experienceCount ?? 0}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Experiences completed',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Progress by category',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 380
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final category in game?.categories ?? const [])
                if (category.categoryId != 'travel_exploration')
                  SizedBox(
                    width: width,
                    child: CategoryProgressRing(
                      icon: categoryIcon(category.categoryId),
                      label: category.label,
                      completed: category.completed,
                      total: category.total,
                      accent: AppColors.categoryAccent(category.categoryId),
                    ),
                  ),
            ],
          );
        },
      ),
      Card(
        child: ListTile(
          key: const ValueKey('my-life-share-studio-entry'),
          leading: const Icon(Icons.auto_awesome_outlined),
          title: const Text('Share Studio'),
          subtitle: const Text('Create a My Journey highlights card'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShareStudioPage()),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Card(
        child: ListTile(
          key: const ValueKey('my-life-saved-entry'),
          leading: const Icon(Icons.bookmark_outline),
          title: const Text('Saved Experiences'),
          subtitle: Text('$savedCount saved'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedPage()),
            );
            if (mounted) await loadSummary();
          },
        ),
      ),
      const SizedBox(height: 12),
      const Card(
        key: ValueKey('my-life-friends-soon'),
        child: ListTile(
          leading: Icon(Icons.people_outline),
          title: Text('Friends are coming'),
          subtitle: Text(
            'Soon you can cheer each other on, plan trips together and share '
            'challenges. Your record stays private until you choose.',
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Weekly progress',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.information,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Weekly activity will appear as you explore.',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      const SizedBox(height: 24),
      const Text(
        'Your collections',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      if (fruitCount == 0 &&
          varietyCount == 0 &&
          jyotirlingaCount == 0 &&
          checklistProgress.every((progress) => progress.count == 0))
        const Text(
          'Collections you start will show here.',
          key: ValueKey('my-life-no-collections'),
          style: TextStyle(color: AppColors.muted),
        ),
      if (fruitCount > 0 || varietyCount > 0)
        ProgressCard(
          title: 'Fruits of India',
          summary:
              '$fruitCount of $fruitTotal fruits tried'
              '${varietyCount > 0 ? ' · $varietyCount varieties' : ''}',
          progress: ratio(fruitCount, fruitTotal),
        ),
      if (jyotirlingaCount > 0)
        ProgressCard(
          title: '12 Jyotirlingas',
          summary: '$jyotirlingaCount of $jyotirlingaTotal visited',
          progress: ratio(jyotirlingaCount, jyotirlingaTotal),
        ),
      for (final progress in checklistProgress.where((p) => p.count > 0))
        ProgressCard(
          title: progress.challenge.name,
          summary:
              '${progress.count} of ${progress.total} ${progress.challenge.collectionUnit ?? progress.challenge.progressVerb}',
          progress: ratio(progress.count, progress.total),
        ),
      const SizedBox(height: 12),
      _buildStats(),
    ],
  );

  Widget _buildStats() {
    final started =
        (fruitCount > 0 || varietyCount > 0 ? 1 : 0) +
        (jyotirlingaCount > 0 ? 1 : 0) +
        checklistProgress.where((progress) => progress.count > 0).length;
    final completed =
        (fruitTotal > 0 && fruitCount == fruitTotal ? 1 : 0) +
        (jyotirlingaTotal > 0 && jyotirlingaCount == jyotirlingaTotal ? 1 : 0) +
        checklistProgress
            .where(
              (progress) =>
                  progress.total > 0 && progress.count == progress.total,
            )
            .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stats',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              label: 'Indian dishes tried',
              value: '$dishTriedCount',
              icon: Icons.ramen_dining_outlined,
              accent: AppColors.orange,
            ),
            _MetricCard(
              label: 'Indian dishes cooked',
              value: '$dishCookedCount',
              icon: Icons.kitchen_outlined,
              accent: AppColors.orange,
            ),
            _MetricCard(
              label: 'Indian drinks tried',
              value: '$drinkTriedCount',
              icon: Icons.local_cafe_outlined,
              accent: AppColors.blue,
            ),
            _MetricCard(
              label: 'Collections started',
              value: '$started',
              icon: Icons.shield_outlined,
              accent: AppColors.blue,
            ),
            _MetricCard(
              label: 'Collections completed',
              value: '$completed',
              icon: Icons.verified_outlined,
            ),
            _MetricCard(
              label: 'Things done in India',
              value: '${gamification?.experienceCount ?? 0}',
              icon: Icons.explore_outlined,
              accent: AppColors.primary,
            ),
            _MetricCard(
              label: 'Places visited',
              value: '$districtCount',
              icon: Icons.location_city_outlined,
              accent: AppColors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievements() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Achievements earned',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      if (achievements.isEmpty)
        const EmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'Your first badge awaits',
          message: 'Start a journey to earn an achievement.',
        )
      else
        for (final achievement in achievements)
          AchievementCard(achievement: achievement),
    ],
  );
}

class _LifeTabs extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _LifeTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Overview', 'Stats', 'Achievements', 'Timeline'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final active = selected == index;
          return Material(
            key: ValueKey('my-life-tab-$index'),
            color: active ? AppColors.primary : AppColors.surface,
            shape: StadiumBorder(
              side: BorderSide(
                color: active ? AppColors.primary : AppColors.outline,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onChanged(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.primary,
  });
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32;
    final columns =
        width >= 340 && MediaQuery.textScalerOf(context).scale(14) <= 18
        ? 3
        : 2;
    return SizedBox(
      width: (width - (columns - 1) * 10) / columns,
      child: Container(
        constraints: const BoxConstraints(minHeight: 138),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: .20),
              accent.withValues(alpha: .06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 26),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
