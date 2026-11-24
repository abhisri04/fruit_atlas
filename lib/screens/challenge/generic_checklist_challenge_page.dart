import 'package:flutter/material.dart';

import '../../widgets/scent_shelf_buttons.dart';
import '../../widgets/filter_chip_group.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/experience_list.dart';

import '../../widgets/empty_state.dart';

import '../../theme/app_colors.dart';

import '../../models/achievement.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/exploration_hero.dart';
import '../../models/challenge.dart';
import '../../models/item.dart';
import '../../services/asset_data_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/saved_challenge_button.dart';
import '../../widgets/exploration_section_card.dart';
import '../../widgets/yoga_pose_tile.dart';
import '../../widgets/challenge_icon.dart';
import '../../widgets/reveal.dart';
import '../../widgets/hobby_finder_entry.dart';
import '../../theme/app_spacing.dart';
import 'checklist_item_details_page.dart';

class GenericChecklistChallengePage extends StatefulWidget {
  final Challenge challenge;

  const GenericChecklistChallengePage({super.key, required this.challenge});

  @override
  State<GenericChecklistChallengePage> createState() =>
      _GenericChecklistChallengePageState();
}

class _GenericChecklistChallengePageState
    extends State<GenericChecklistChallengePage> {
  static const dataService = AssetDataService();
  List<Item> items = [];
  Set<String> completedIds = {};
  Set<String> savedEntityReferences = {};
  String selectedCategory = 'All';
  String selectedSection = 'List';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadChallenge();
  }

  Future<void> loadChallenge() async {
    try {
      final loadedItems = await dataService.loadChallengeItems(
        widget.challenge,
      );
      final storedIds = await ProgressService.getChallengeItemIds(
        widget.challenge.progressKey,
      );
      final savedReferences = await ProgressService.getSavedEntityReferences();
      final itemIds = loadedItems.map((item) => item.id).toSet();
      if (!mounted) return;
      setState(() {
        items = loadedItems;
        completedIds = storedIds.intersection(itemIds);
        savedEntityReferences = savedReferences;
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

  Future<void> setCompleted(Item item, bool completed) async {
    final before = completedIds.length;
    final updatedIds = Set<String>.from(completedIds);
    completed ? updatedIds.add(item.id) : updatedIds.remove(item.id);
    setState(() => completedIds = updatedIds);
    await ProgressService.setChallengeItemIds(
      widget.challenge.progressKey,
      updatedIds,
    );
    if (mounted) {
      showCompletionFeedback(
        context,
        before: before,
        after: updatedIds.length,
        total: items.length,
        challengeId: widget.challenge.id,
      );
    }
  }

  Future<void> openDetails(Item item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistItemDetailsPage(
          challenge: widget.challenge,
          item: item,
          itemCatalogue: items,
        ),
      ),
    );
    await loadChallenge();
  }

  Future<void> toggleYogaSaved(Item item) async {
    final reference = 'yogaPose:${item.id}';
    final saved = await ProgressService.toggleSavedEntity(reference);
    if (!mounted) return;
    setState(() {
      saved
          ? savedEntityReferences.add(reference)
          : savedEntityReferences.remove(reference);
    });
  }

  bool get _isStates => widget.challenge.itemType == 'state_or_union_territory';

  String get _doneLabel => _isStates
      ? 'Visited'
      : switch (widget.challenge.progressVerb) {
          'tried' => 'Tried',
          'played' => 'Played',
          'smelled' => 'Smelled',
          _ => 'Explored',
        };

  String get _todoLabel => _isStates
      ? 'Not Visited'
      : switch (widget.challenge.progressVerb) {
          'tried' => 'To Try',
          'played' => 'To Play',
          'smelled' => 'To Smell',
          _ => 'To Explore',
        };

  @override
  Widget build(BuildContext context) {
    if (widget.challenge.itemType == 'yoga_pose') {
      return _buildYogaChallenge(context);
    }
    final visibleItems = items
        .where(
          (item) => switch (selectedCategory) {
            'All' => true,
            _ when selectedCategory == _doneLabel => completedIds.contains(
              item.id,
            ),
            _ when selectedCategory == _todoLabel => !completedIds.contains(
              item.id,
            ),
            _ => (item.filterGroup ?? item.category) == selectedCategory,
          },
        )
        .toList();
    final completedCount = completedIds.length;
    final progress = items.isEmpty ? 0.0 : completedCount / items.length;
    final latestAchievement = Achievement.latestFor(
      widget.challenge.id,
      completedCount,
    );
    final sections = widget.challenge.sections;
    final achievements = Achievement.forChallenge(widget.challenge.id);
    final categoryFilters = items
        .map((item) => item.filterGroup ?? item.category)
        .whereType<String>()
        .toSet();
    final listIsVisible = sections.isEmpty || selectedSection == 'List';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        actions: [SavedChallengeButton(challengeId: widget.challenge.id)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load',
              message: 'Could not load this challenge.\n\n$errorMessage',
            )
          : ExperienceList(
              header: [
                ExplorationHero(
                  title: widget.challenge.name,
                  accent: AppColors.categoryAccent(widget.challenge.categoryId),
                  icon: _isStates
                      ? Icons.map_outlined
                      : challengeIcon(widget.challenge.iconIdentifier),
                  subtitle: widget.challenge.description,
                ),
                ProgressCard(
                  prominent: true,
                  title: 'Your progress',
                  summary:
                      '$completedCount of ${items.length} ${widget.challenge.progressVerb}',
                  progress: progress,
                ),
                if (widget.challenge.categoryId == 'scent') ...[
                  const SizedBox(height: 12),
                  const MyCollectionEntry(),
                ],
                if (widget.challenge.itemType == 'hobby' ||
                    widget.challenge.itemType == 'game') ...[
                  const SizedBox(height: 12),
                  HobbyFinderEntry(onReturn: loadChallenge),
                ],
                if (widget.challenge.itemSummary case final summary?) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      summary,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (sections.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FilterChipGroup(
                    options: sections,
                    selected: selectedSection,
                    onChanged: (value) => setState(() {
                      selectedSection = value;
                      selectedCategory = 'All';
                    }),
                  ),
                ] else if (latestAchievement != null) ...[
                  const SizedBox(height: 16),
                  AchievementCard(achievement: latestAchievement),
                ],
                if (listIsVisible) ...[
                  const SizedBox(height: 8),
                  FilterChipGroup(
                    options: [
                      'All',
                      ...categoryFilters,
                      if (widget.challenge.completionFilters) ...[
                        _doneLabel,
                        _todoLabel,
                      ],
                    ],
                    selected: selectedCategory,
                    onChanged: (value) =>
                        setState(() => selectedCategory = value),
                  ),
                ],
                if (listIsVisible && items.isEmpty)
                  const Text('No checklist items are available yet.'),
                if (selectedSection == 'Achievements') ...[
                  const SizedBox(height: 8),
                  ...achievements.map(
                    (achievement) => AchievementCard(
                      achievement: achievement,
                      unlocked: achievement.isAchieved(completedCount),
                    ),
                  ),
                ],
                if (selectedSection == 'About') ...[
                  const SizedBox(height: 8),
                  Text(
                    'About this challenge',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.challenge.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  if (widget.challenge.itemSummary case final summary?) ...[
                    const SizedBox(height: 16),
                    Text(
                      summary,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ],
              ],
              itemCount: listIsVisible ? visibleItems.length : 0,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                final completed = completedIds.contains(item.id);
                final row = AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.completedSurface
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  // Border as a foreground layer so it adds no padding and
                  // rows keep the same height as before.
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    border: Border.all(
                      color: completed
                          ? AppColors.primary.withValues(alpha: .35)
                          : AppColors.outline,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      leading: Icon(
                        _isStates
                            ? Icons.location_on_outlined
                            : challengeIcon(widget.challenge.iconIdentifier),
                      ),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: completed ? AppColors.primary : AppColors.ink,
                        ),
                      ),
                      // Games: players and length say more than the name.
                      subtitle: switch (item.metadata['Players']) {
                        final players? => Text(
                          [
                            '$players players',
                            item.metadata['Time'],
                          ].whereType<String>().join(' · '),
                        ),
                        _ =>
                          item.category == null ? null : Text(item.category!),
                      },
                      onTap:
                          widget.challenge.presentationType ==
                              'checklist_with_details'
                          ? () => openDetails(item)
                          : null,
                      trailing: AnimatedScale(
                        scale: completed ? 1.12 : 1,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Checkbox(
                          value: completed,
                          onChanged: (value) =>
                              setCompleted(item, value ?? false),
                        ),
                      ),
                    ),
                  ),
                );
                // Only the first screenful animates in; rows built later by
                // scrolling appear immediately.
                return index < Reveal.maxStaggered
                    ? Reveal(
                        key: ValueKey('reveal-${item.id}'),
                        index: index,
                        child: row,
                      )
                    : row;
              },
            ),
    );
  }

  Widget _buildYogaChallenge(BuildContext context) {
    const difficulties = ['Beginner', 'Intermediate', 'Difficult', 'Expert'];
    final completedCount = completedIds.length;
    final progress = items.isEmpty ? 0.0 : completedCount / items.length;
    final visibleDifficulties = selectedCategory == 'All'
        ? difficulties
        : [selectedCategory];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoga Poses'),
        actions: [SavedChallengeButton(challengeId: widget.challenge.id)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load',
              message: 'Could not load this challenge.\n\n$errorMessage',
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  sliver: SliverList.list(
                    children: [
                      const Text(
                        'Explore yoga poses and build your practice.',
                        style: TextStyle(color: AppColors.muted, fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      ProgressCard(
                        title: 'Your progress',
                        summary:
                            '$completedCount of ${items.length} ${widget.challenge.progressVerb}',
                        progress: progress,
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final difficulty in ['All', ...difficulties])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(difficulty),
                                  selected: selectedCategory == difficulty,
                                  showCheckmark: false,
                                  backgroundColor: AppColors.surface,
                                  selectedColor: AppColors.primary,
                                  side: BorderSide(
                                    color: selectedCategory == difficulty
                                        ? AppColors.primary
                                        : AppColors.outline,
                                  ),
                                  labelStyle: TextStyle(
                                    color: selectedCategory == difficulty
                                        ? Colors.white
                                        : AppColors.ink,
                                    fontWeight: selectedCategory == difficulty
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  onSelected: (_) => setState(
                                    () => selectedCategory = difficulty,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      for (final difficulty in visibleDifficulties)
                        _buildYogaDifficultySection(
                          difficulty,
                          difficulties.first == difficulty ||
                              selectedCategory != 'All',
                        ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildYogaDifficultySection(
    String difficulty,
    bool initiallyExpanded,
  ) {
    final poses = items
        .where((item) => item.difficulty == difficulty)
        .toList(growable: false);
    final completed = poses
        .where((pose) => completedIds.contains(pose.id))
        .length;
    return ExplorationSectionCard(
      key: ValueKey('yoga-difficulty-$difficulty-$selectedCategory'),
      icon: switch (difficulty) {
        'Beginner' => Icons.spa_outlined,
        'Intermediate' => Icons.self_improvement,
        'Difficult' => Icons.airline_seat_flat_angled_outlined,
        _ => Icons.auto_awesome_outlined,
      },
      title: difficulty,
      subtitle: '${poses.length} ${poses.length == 1 ? 'pose' : 'poses'}',
      completedCount: completed,
      totalCount: poses.length,
      showProgress: false,
      initiallyExpanded: initiallyExpanded && poses.isNotEmpty,
      itemCount: poses.length,
      itemBuilder: (context, index) {
        final pose = poses[index];
        return YogaPoseTile(
          pose: pose,
          saved: savedEntityReferences.contains('yogaPose:${pose.id}'),
          onTap: () => openDetails(pose),
          onToggleSaved: () => toggleYogaSaved(pose),
        );
      },
    );
  }
}
