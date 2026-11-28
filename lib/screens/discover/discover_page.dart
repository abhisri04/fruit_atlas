import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/challenge.dart';
import '../../models/daily_discovery.dart';
import '../../navigation/challenge_navigation.dart';
import '../../navigation/daily_discovery_navigation.dart';
import '../../services/challenge_groups.dart';
import '../../services/challenge_repository.dart';
import '../../services/daily_discovery_service.dart';
import '../../services/discovery_saved_service.dart';
import '../../services/progress_summary_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/hobby_finder_entry.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/challenge_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/experience_artwork.dart';
import '../../widgets/journey_card.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../search/discovery_search_page.dart';

class DiscoverPage extends StatefulWidget {
  final DailyDiscoveryService? dailyDiscoveryService;
  const DiscoverPage({super.key, this.dailyDiscoveryService});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const _repository = ChallengeRepository();
  static const _savedService = DiscoverySavedService();
  DailyDiscoveryService get _daily =>
      widget.dailyDiscoveryService ?? const DailyDiscoveryService();
  List<Category> categories = [];
  List<Challenge> challenges = [];
  List<DailyDiscovery> recommendations = [];
  List<DailyDiscovery> _pool = [];
  Set<String> savedReferences = {};
  Map<String, ChallengeProgressSummary> challengeProgress = {};
  String selectedCategoryId = 'all';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loadedCategories = await _repository.loadCategories();
      final loadedChallenges = await _repository.loadChallenges();
      final pool = await _daily.buildEligiblePool();
      final progress = await const ProgressSummaryService().load(
        challenges: loadedChallenges,
      );
      final diverse = <DailyDiscovery>[];
      final seenTypes = <DailyDiscoveryType>{};
      for (final item in pool) {
        if (seenTypes.add(item.type)) diverse.add(item);
      }
      for (final item in pool) {
        if (diverse.length >= 12) break;
        if (!diverse.contains(item)) diverse.add(item);
      }
      final saved = <String>{};
      for (final item in diverse) {
        if (await _savedService.isSaved(item)) saved.add(item.reference);
      }
      if (!mounted) return;
      setState(() {
        categories = loadedCategories;
        challenges = loadedChallenges;
        recommendations = diverse;
        _pool = pool;
        savedReferences = saved;
        challengeProgress = progress.challenges;
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

  /// "For You" shows the diverse mix; a category shows up to 12 items from
  /// the whole eligible pool so smaller categories aren't limited to one.
  List<DailyDiscovery> get _filtered => selectedCategoryId == 'all'
      ? recommendations
      : _pool
            .where((item) => item.categoryId == selectedCategoryId)
            .take(12)
            .toList(growable: false);

  Future<void> _toggleSaved(DailyDiscovery item) async {
    final saved = await _savedService.toggle(item);
    if (!mounted) return;
    setState(
      () => saved
          ? savedReferences.add(item.reference)
          : savedReferences.remove(item.reference),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.navy,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explore')),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load',
          message: 'Could not load Explore.\n\n$errorMessage',
          actionLabel: 'Retry',
          onAction: _load,
        ),
      );
    }
    // Scent's four collections appear as one Scent & Perfume tile.
    final active = groupHubChallenges(
      challenges.where((challenge) => challenge.status == 'active'),
    );
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              sliver: SliverList.list(
                children: [
                  const Text(
                    'Explore',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    key: const ValueKey('explore-search'),
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiscoverySearchPage(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.muted),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search experiences, places, dishes...',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 82,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryShortcut(
                          id: 'all',
                          label: 'For You',
                          icon: Icons.auto_awesome,
                          selected: selectedCategoryId == 'all',
                          onTap: _selectCategory,
                        ),
                        for (final category in categories)
                          _CategoryShortcut(
                            id: category.id,
                            label: _shortCategoryName(category),
                            icon: categoryIcon(category.id),
                            selected: selectedCategoryId == category.id,
                            onTap: _selectCategory,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Recommended for you'),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _filtered.isEmpty
                        ? const _DarkEmpty(
                            key: ValueKey('empty-recommendations'),
                          )
                        : SizedBox(
                            key: ValueKey(selectedCategoryId),
                            height: 270,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, index) {
                                final item = _filtered[index];
                                return Reveal(
                                  index: index,
                                  child: TactileScale(
                                    child: _RecommendationCard(
                                      item: item,
                                      isSaved: savedReferences.contains(
                                        item.reference,
                                      ),
                                      onSave: () => _toggleSaved(item),
                                      onTap: () async {
                                        await openDailyDiscoveryItem(
                                          context,
                                          item,
                                        );
                                        if (mounted) await _load();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  HobbyFinderEntry(onReturn: _load),
                  const SizedBox(height: 24),
                  _sectionTitle('Collections'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 235,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: active.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, index) => JourneyCard(
                        challenge: active[index],
                        completed: groupedProgress(
                          active[index],
                          summaryLookup(challengeProgress),
                          challenges,
                        ).completed,
                        total: groupedProgress(
                          active[index],
                          summaryLookup(challengeProgress),
                          challenges,
                        ).total,
                        onTap: () => openChallenge(context, active[index]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Explore by category'),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisExtent: 132,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final challenge = active[index];
                  final accent = AppColors.categoryAccent(challenge.categoryId);
                  final progress = groupedProgress(
                    challenge,
                    summaryLookup(challengeProgress),
                    challenges,
                  );
                  final done = progress.completed;
                  final total = progress.total;
                  return Reveal(
                    index: index,
                    child: TactileScale(
                      child: Material(
                        key: ValueKey('explore-category-${challenge.id}'),
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppGradients.category(accent),
                          ),
                          child: InkWell(
                            onTap: () => openChallenge(context, challenge),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -14,
                                  bottom: -18,
                                  child: Icon(
                                    challengeIcon(challenge.iconIdentifier),
                                    size: 92,
                                    color: Colors.white.withValues(alpha: .14),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(
                                        challengeIcon(challenge.iconIdentifier),
                                        color: Colors.white,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            challenge.compactTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: AnimatedProgressValue(
                                              value: total <= 0
                                                  ? 0
                                                  : done / total,
                                              minHeight: 4,
                                              color: Colors.white,
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: .25),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$done of $total',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: .85,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }, childCount: active.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCategory(String value) async {
    setState(() => selectedCategoryId = value);
    // Category views draw from the full pool, so load saved state for any
    // cards that were not part of the initial "For You" mix.
    final unchecked = _filtered
        .where((item) => !recommendations.contains(item))
        .toList(growable: false);
    final saved = <String>{};
    for (final item in unchecked) {
      if (await _savedService.isSaved(item)) saved.add(item.reference);
    }
    if (!mounted || saved.isEmpty) return;
    setState(() => savedReferences.addAll(saved));
  }

  String _shortCategoryName(Category category) => switch (category.id) {
    'food_drink' => 'Food',
    'fitness_wellness' => 'Wellness',
    'travel_exploration' => 'Travel',
    'culture_learning' => 'Learning',
    'faith_pilgrimage' => 'Faith',
    'life_experiences' => 'Life',
    'games_play' => 'Games',
    'scent' => 'Scent',
    'garden' => 'Garden',
    _ => category.name.split(' & ').first,
  };
  Widget _sectionTitle(String value) => Text(
    value,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _CategoryShortcut extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final ValueChanged<String> onTap;
  const _CategoryShortcut({
    required this.id,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72,
    child: InkWell(
      key: ValueKey('explore-shortcut-$id'),
      onTap: () => onTap(id),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : AppColors.navyRaised,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: selected ? AppColors.navy : Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.gold : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RecommendationCard extends StatelessWidget {
  final DailyDiscovery item;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onTap;
  const _RecommendationCard({
    required this.item,
    required this.isSaved,
    required this.onSave,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 232,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ExperienceArtwork(
                  discovery: item,
                  height: 154,
                  borderRadius: BorderRadius.zero,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filled(
                    tooltip: isSaved ? 'Remove from Saved' : 'Save',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .9),
                      foregroundColor: AppColors.navy,
                    ),
                    onPressed: onSave,
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DarkEmpty extends StatelessWidget {
  const _DarkEmpty({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 130,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.navyRaised,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'More recommendations will appear as this collection grows.',
      style: TextStyle(color: Colors.white70),
    ),
  );
}
