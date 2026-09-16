import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/metadata_chip.dart';

import '../../models/challenge.dart';
import '../../models/district.dart';
import '../../models/experience.dart';
import '../../models/experience_collection.dart';
import '../../models/fruit.dart';
import '../../models/item.dart';
import '../../screens/district/district_details_page.dart';
import '../../screens/experience/experience_details_page.dart';
import '../../screens/experience/experience_collection_page.dart';
import '../../screens/fruit/fruit_details_page.dart';
import '../../services/asset_data_service.dart';
import '../../services/district_repository.dart';
import '../../services/experience_repository.dart';
import '../../services/experience_collection_repository.dart';
import '../../services/progress_service.dart';
import '../../widgets/circular_progress_widget.dart';
import '../../widgets/district_tile.dart';
import '../../widgets/exploration_section_card.dart';
import '../../widgets/experience_tile.dart';
import '../../widgets/experience_collection_tile.dart';
import '../../widgets/yoga_pose_tile.dart';

class ChecklistItemDetailsPage extends StatefulWidget {
  final Challenge challenge;
  final Item item;
  final List<Item>? itemCatalogue;

  const ChecklistItemDetailsPage({
    super.key,
    required this.challenge,
    required this.item,
    this.itemCatalogue,
  });

  @override
  State<ChecklistItemDetailsPage> createState() =>
      _ChecklistItemDetailsPageState();
}

class _ChecklistItemDetailsPageState extends State<ChecklistItemDetailsPage> {
  static const experienceRepository = ExperienceRepository();
  static const districtRepository = DistrictRepository();
  static const collectionRepository = ExperienceCollectionRepository();
  static const dataService = AssetDataService();
  bool isCompleted = false;
  bool isLoading = true;
  bool isExperiencesLoading = true;
  bool isYogaSaved = false;
  bool isYogaPagerLoading = false;
  List<Item> yogaCatalogue = const [];
  Set<String> completedYogaPoseIds = {};
  Set<String> savedYogaPoseReferences = {};
  PageController? yogaPageController;
  int yogaPageIndex = 0;
  List<Experience> experiences = [];
  List<District> districts = [];
  List<Fruit> fruits = [];
  List<AtlasState> atlasStates = [];
  List<ExperienceCollection> collections = [];
  Set<String> completedExperienceIds = {};
  Set<String> completedDistrictIds = {};
  Set<String> completedFruitIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.challenge.itemType == 'yoga_pose') {
      isExperiencesLoading = false;
      isYogaPagerLoading = true;
      _loadYogaPager();
    } else {
      loadCompletion();
      loadExploration();
    }
  }

  @override
  void dispose() {
    yogaPageController?.dispose();
    super.dispose();
  }

  Item get _currentYogaPose =>
      yogaCatalogue.isEmpty ? widget.item : yogaCatalogue[yogaPageIndex];

  Future<void> _loadYogaPager() async {
    final source =
        widget.itemCatalogue ??
        await dataService.loadChallengeItems(widget.challenge);
    const difficultyOrder = ['Beginner', 'Intermediate', 'Difficult', 'Expert'];
    final ordered = <Item>[
      for (final difficulty in difficultyOrder)
        ...source.where((pose) => pose.difficulty == difficulty),
      ...source.where((pose) => !difficultyOrder.contains(pose.difficulty)),
    ];
    final initialIndex = ordered.indexWhere(
      (pose) => pose.id == widget.item.id,
    );
    final completed = await ProgressService.getChallengeItemIds(
      widget.challenge.progressKey,
    );
    final saved = await ProgressService.getSavedEntityReferences();
    if (!mounted) return;
    final resolvedIndex = initialIndex < 0 ? 0 : initialIndex;
    setState(() {
      yogaCatalogue = ordered.isEmpty ? [widget.item] : ordered;
      yogaPageIndex = resolvedIndex;
      completedYogaPoseIds = completed;
      savedYogaPoseReferences = saved;
      isCompleted = completed.contains(_currentYogaPose.id);
      isYogaSaved = saved.contains('yogaPose:${_currentYogaPose.id}');
      yogaPageController = PageController(initialPage: resolvedIndex);
      isLoading = false;
      isYogaPagerLoading = false;
    });
  }

  Future<void> toggleYogaSaved() async {
    final pose = _currentYogaPose;
    final saved = await ProgressService.toggleSavedEntity(
      'yogaPose:${pose.id}',
    );
    if (!mounted) return;
    setState(() {
      final reference = 'yogaPose:${pose.id}';
      saved
          ? savedYogaPoseReferences.add(reference)
          : savedYogaPoseReferences.remove(reference);
      isYogaSaved = savedYogaPoseReferences.contains(
        'yogaPose:${_currentYogaPose.id}',
      );
    });
  }

  Future<void> loadExploration() async {
    try {
      final experiencesFuture = experienceRepository.getForLocation(
        widget.item.id,
      );
      final districtsFuture = districtRepository.getForState(widget.item.id);
      final fruitDataFuture = dataService.loadFruitData();
      final collectionsFuture = collectionRepository.loadCollections();
      final completedExperiencesFuture =
          ProgressService.getCompletedExperienceIds();
      final completedDistrictsFuture =
          ProgressService.getCompletedDistrictIds();
      final completedFruitsFuture = ProgressService.getCompletedFruitIds();
      final loaded = await experiencesFuture;
      final loadedDistricts = await districtsFuture;
      final fruitData = await fruitDataFuture;
      final loadedCollections = await collectionsFuture;
      final matchingStates = fruitData.states.where(
        (state) => state.name.toLowerCase() == widget.item.name.toLowerCase(),
      );
      final atlasStateId = matchingStates.firstOrNull?.id;
      final loadedFruits = atlasStateId == null
          ? const <Fruit>[]
          : fruitData.fruits
                .where(
                  (fruit) => fruit.states.any(
                    (record) => record.stateId == atlasStateId,
                  ),
                )
                .toList();
      final completedExperiences = await completedExperiencesFuture;
      final completedDistricts = await completedDistrictsFuture;
      final completedFruits = await completedFruitsFuture;
      if (!mounted) return;
      setState(() {
        experiences = loaded;
        districts = loadedDistricts;
        fruits = loadedFruits;
        atlasStates = fruitData.states;
        collections = loadedCollections
            .where((collection) => collection.contextId == widget.item.id)
            .toList(growable: false);
        completedExperienceIds = completedExperiences.intersection(
          loaded.map((experience) => experience.id).toSet(),
        );
        completedDistrictIds = completedDistricts.intersection(
          loadedDistricts.map((district) => district.id).toSet(),
        );
        completedFruitIds = completedFruits.intersection(
          loadedFruits.map((fruit) => fruit.id).toSet(),
        );
        isExperiencesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isExperiencesLoading = false);
    }
  }

  Future<void> loadCompletion() async {
    final completedIds = await ProgressService.getChallengeItemIds(
      widget.challenge.progressKey,
    );
    if (!mounted) return;
    setState(() {
      isCompleted = completedIds.contains(widget.item.id);
      isLoading = false;
    });
  }

  Future<void> toggleCompletion() async {
    final item = widget.challenge.itemType == 'yoga_pose'
        ? _currentYogaPose
        : widget.item;
    final completed = await ProgressService.toggleChallengeItem(
      widget.challenge.progressKey,
      item.id,
    );
    if (!mounted) return;
    setState(() {
      if (widget.challenge.itemType == 'yoga_pose') {
        completed
            ? completedYogaPoseIds.add(item.id)
            : completedYogaPoseIds.remove(item.id);
        isCompleted = completedYogaPoseIds.contains(_currentYogaPose.id);
      } else {
        isCompleted = completed;
      }
    });
    if (completed) showCompletionFeedback(context, before: 0, after: 1);
  }

  Future<void> setExperienceCompleted(
    Experience experience,
    bool completed,
  ) async {
    final updated = Set<String>.from(completedExperienceIds);
    completed ? updated.add(experience.id) : updated.remove(experience.id);
    setState(() => completedExperienceIds = updated);
    final allCompleted = await ProgressService.getCompletedExperienceIds();
    final before = allCompleted.length;
    completed
        ? allCompleted.add(experience.id)
        : allCompleted.remove(experience.id);
    await ProgressService.setCompletedExperienceIds(allCompleted);
    if (!mounted) return;
    showCompletionFeedback(
      context,
      before: before,
      after: allCompleted.length,
      challengeId: 'all_experiences',
    );
  }

  Future<void> openExperience(Experience experience) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExperienceDetailsPage(experience: experience),
      ),
    );
    await loadExploration();
  }

  Future<void> setDistrictCompleted(District district, bool completed) async {
    final updated = Set<String>.from(completedDistrictIds);
    completed ? updated.add(district.id) : updated.remove(district.id);
    setState(() => completedDistrictIds = updated);
    final allCompleted = await ProgressService.getCompletedDistrictIds();
    final before = allCompleted.length;
    completed
        ? allCompleted.add(district.id)
        : allCompleted.remove(district.id);
    await ProgressService.setCompletedDistrictIds(allCompleted);
    if (mounted) {
      showCompletionFeedback(
        context,
        before: before,
        after: allCompleted.length,
      );
    }
  }

  Future<void> setFruitCompleted(Fruit fruit, bool completed) async {
    final updated = Set<String>.from(completedFruitIds);
    completed ? updated.add(fruit.id) : updated.remove(fruit.id);
    setState(() => completedFruitIds = updated);
    final allCompleted = await ProgressService.getCompletedFruitIds();
    final before = allCompleted.length;
    completed ? allCompleted.add(fruit.id) : allCompleted.remove(fruit.id);
    await ProgressService.setCompletedFruitIds(allCompleted);
    if (mounted) {
      showCompletionFeedback(
        context,
        before: before,
        after: allCompleted.length,
        challengeId: 'taste_fruits_of_india',
      );
    }
  }

  Future<void> openDistrict(District district) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DistrictDetailsPage(district: district),
      ),
    );
    await loadExploration();
  }

  Future<void> openFruit(Fruit fruit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FruitDetailsPage(fruit: fruit, states: atlasStates),
      ),
    );
    await loadExploration();
  }

  IconData sectionIcon(String section) => switch (section) {
    'Places' => Icons.place_outlined,
    'Things to Do' => Icons.directions_walk_outlined,
    'Food & Drink' => Icons.restaurant_outlined,
    'Culture' => Icons.theater_comedy_outlined,
    _ => Icons.explore_outlined,
  };

  List<Widget> buildExperienceExplorerSlivers(BuildContext context) {
    final visibleExperiences = districts.isEmpty
        ? experiences
        : experiences
              .where((experience) => experience.section != 'Places')
              .toList();
    final totalCount =
        districts.length + visibleExperiences.length + fruits.length;
    final completedCount =
        completedDistrictIds.length +
        visibleExperiences
            .where(
              (experience) => completedExperienceIds.contains(experience.id),
            )
            .length +
        completedFruitIds.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final sections = <String>[
      if (districts.isNotEmpty ||
          visibleExperiences.any((item) => item.section == 'Places'))
        'Places',
      for (final section in ['Food & Drink', 'Things to Do', 'Culture'])
        if (visibleExperiences.any((item) => item.section == section) ||
            _collectionsForSection(section).isNotEmpty)
          section,
    ];
    return [
      SliverPadding(
        padding: const EdgeInsets.only(top: 28, bottom: 16),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EXPLORE ${widget.item.name.toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircularProgressWidget(
                    progress: progress,
                    variant: ProgressSize.medium,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount of $totalCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'explorations',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      for (final section in sections)
        _buildSectionSliver(section, sections, visibleExperiences),
    ];
  }

  Widget _buildSectionSliver(
    String section,
    List<String> sections,
    List<Experience> visibleExperiences,
  ) {
    final sectionExperiences = visibleExperiences
        .where((item) => item.section == section)
        .toList(growable: false);
    final isPlaces = section == 'Places' && districts.isNotEmpty;
    final sectionCollections = _collectionsForSection(section);
    final usesCollections = sectionCollections.isNotEmpty;
    final collectionMemberKeys = <String>{};
    final completedCollectionKeys = <String>{};
    if (usesCollections) {
      for (final collection in sectionCollections) {
        if (collection.entityType == 'fruit') {
          for (final fruit in fruits) {
            collectionMemberKeys.add('fruit:${fruit.id}');
            if (completedFruitIds.contains(fruit.id)) {
              completedCollectionKeys.add('fruit:${fruit.id}');
            }
          }
        } else {
          for (final experience in _experiencesForCollection(collection)) {
            collectionMemberKeys.add('experience:${experience.id}');
            if (completedExperienceIds.contains(experience.id)) {
              completedCollectionKeys.add('experience:${experience.id}');
            }
          }
        }
      }
    }
    final total = isPlaces
        ? districts.length
        : usesCollections
        ? collectionMemberKeys.length
        : sectionExperiences.length;
    final completed = isPlaces
        ? completedDistrictIds.length
        : usesCollections
        ? completedCollectionKeys.length
        : sectionExperiences
              .where((item) => completedExperienceIds.contains(item.id))
              .length;
    return ExplorationSectionCard(
      key: ValueKey('exploration-section-$section'),
      icon: sectionIcon(section),
      title: section,
      subtitle: isPlaces
          ? 'Explore ${widget.item.name} district by district'
          : null,
      completedCount: completed,
      totalCount: total,
      initiallyExpanded: section == sections.first && districts.length <= 10,
      itemCount: isPlaces
          ? districts.length
          : usesCollections
          ? sectionCollections.length
          : sectionExperiences.length,
      itemBuilder: (context, index) {
        if (isPlaces) {
          final district = districts[index];
          return DistrictTile(
            district: district,
            completed: completedDistrictIds.contains(district.id),
            onTap: () => openDistrict(district),
            onCompletionChanged: (value) =>
                setDistrictCompleted(district, value),
          );
        }
        if (usesCollections) {
          final collection = sectionCollections[index];
          final collectionFruits = collection.entityType == 'fruit'
              ? fruits
              : const <Fruit>[];
          final collectionExperiences = collection.entityType == 'experience'
              ? _experiencesForCollection(collection)
              : const <Experience>[];
          final memberIds = collection.entityType == 'fruit'
              ? collectionFruits.map((item) => item.id).toSet()
              : collectionExperiences.map((item) => item.id).toSet();
          final collectionCompleted =
              (collection.entityType == 'fruit'
                      ? completedFruitIds
                      : completedExperienceIds)
                  .intersection(memberIds)
                  .length;
          return ExperienceCollectionTile(
            collection: collection,
            completedCount: collectionCompleted,
            totalCount: memberIds.length,
            onTap: () => openCollection(
              collection,
              collectionFruits,
              collectionExperiences,
            ),
          );
        }
        final experience = sectionExperiences[index];
        return ExperienceTile(
          experience: experience,
          completed: completedExperienceIds.contains(experience.id),
          onTap: () => openExperience(experience),
          onCompletionChanged: (value) =>
              setExperienceCompleted(experience, value),
        );
      },
    );
  }

  String _sectionId(String section) => switch (section) {
    'Food & Drink' => 'food_drink',
    'Things to Do' => 'things_to_do',
    'Culture' => 'culture',
    _ => section.toLowerCase().replaceAll(' ', '_'),
  };

  List<ExperienceCollection> _collectionsForSection(String section) =>
      collections
          .where(
            (collection) => collection.parentSectionId == _sectionId(section),
          )
          .toList(growable: false);

  List<Experience> _experiencesForCollection(ExperienceCollection collection) {
    final ids = collection.memberEntityIds.toSet();
    return experiences
        .where((experience) => ids.contains(experience.id))
        .toList(growable: false);
  }

  Future<void> openCollection(
    ExperienceCollection collection,
    List<Fruit> collectionFruits,
    List<Experience> collectionExperiences,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExperienceCollectionPage(
          collection: collection,
          fruits: collectionFruits,
          experiences: collectionExperiences,
          atlasStates: atlasStates,
        ),
      ),
    );
    await loadExploration();
  }

  // Kept as the canonical fruit-row builder for other contextual sections.
  // ignore: unused_element
  Widget _buildFruitTile(Fruit fruit) {
    final completed = completedFruitIds.contains(fruit.id);
    return Card(
      color: completed ? AppColors.completedSurface : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.eco_outlined,
          color: completed ? AppColors.primary : null,
        ),
        title: Text(
          fruit.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: completed ? AppColors.primary : AppColors.ink,
          ),
        ),
        subtitle: const Text('Fruit · Verified in this state'),
        trailing: Checkbox(
          value: completed,
          onChanged: (value) => setFruitCompleted(fruit, value ?? false),
        ),
        onTap: () => openFruit(fruit),
      ),
    );
  }

  String expandName(String template) =>
      template.replaceAll('{name}', widget.item.name);

  void _handleYogaPageChanged(int index) {
    final previousDifficulty = _currentYogaPose.difficulty;
    final nextPose = yogaCatalogue[index];
    setState(() {
      yogaPageIndex = index;
      isCompleted = completedYogaPoseIds.contains(nextPose.id);
      isYogaSaved = savedYogaPoseReferences.contains('yogaPose:${nextPose.id}');
    });
    final nextDifficulty = nextPose.difficulty;
    if (nextDifficulty == null || nextDifficulty == previousDifficulty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text("You're now exploring $nextDifficulty poses"),
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildYogaDetails(BuildContext context) {
    final heroHeight = ((MediaQuery.sizeOf(context).width - 40) * 1.15).clamp(
      300.0,
      420.0,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yoga Pose'),
        actions: [
          IconButton(
            tooltip: isYogaSaved ? 'Remove pose from Saved' : 'Save pose',
            onPressed: toggleYogaSaved,
            icon: Icon(isYogaSaved ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: isYogaPagerLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView.builder(
                      controller: yogaPageController,
                      itemCount: yogaCatalogue.length,
                      onPageChanged: _handleYogaPageChanged,
                      itemBuilder: (context, index) {
                        final item = yogaCatalogue[index];
                        return SingleChildScrollView(
                          key: PageStorageKey('yoga-pose-${item.id}'),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: YogaPoseImage(
                                  imagePath: item.imageUrl,
                                  width: double.infinity,
                                  height: heroHeight,
                                  iconSize: 96,
                                  fit: BoxFit.contain,
                                  backgroundColor: AppColors.accentSurface,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  if (item.difficulty case final difficulty?)
                                    MetadataChip(label: difficulty),
                                ],
                              ),
                              if (item.sanskritName
                                  case final sanskritName?) ...[
                                const SizedBox(height: 4),
                                Text(
                                  sanskritName,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (item.category case final category?) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.self_improvement,
                                      size: 19,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      category,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.tags
                                  .where((tag) => tag != item.primaryFamily)
                                  .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: item.tags
                                      .where((tag) => tag != item.primaryFamily)
                                      .map(
                                        (tag) => MetadataChip(
                                          label: tag
                                              .split('_')
                                              .map(
                                                (part) => part.isEmpty
                                                    ? part
                                                    : '${part[0].toUpperCase()}${part.substring(1)}',
                                              )
                                              .join(' '),
                                        ),
                                      )
                                      .toList(growable: false),
                                ),
                              ],
                              if (item.description case final description?) ...[
                                const SizedBox(height: 22),
                                Text(
                                  'About this pose',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSurface,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                              if (item.howToSteps.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'How to do it',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                for (final (index, step)
                                    in item.howToSteps.indexed)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 13,
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            step,
                                            style: const TextStyle(height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              if (item.practiceSafety case final safety?) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Practice safely',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.caution,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.health_and_safety_outlined,
                                        color: AppColors.orange,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          safety,
                                          style: const TextStyle(height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (item.metadata.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                ...item.metadata.entries.map(
                                  (entry) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.key),
                                    subtitle: Text(entry.value),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : toggleCompletion,
                  icon: Icon(isCompleted ? Icons.check_circle : Icons.check),
                  label: Text(isCompleted ? 'Completed' : 'Mark as Completed'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.challenge.itemType == 'yoga_pose') {
      return _buildYogaDetails(context);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList.list(
              children: [
                Icon(
                  widget.challenge.itemType == 'state_or_union_territory'
                      ? Icons.location_on_outlined
                      : Icons.checklist_outlined,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  widget.item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.item.category != null ||
                    widget.item.difficulty != null)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      if (widget.item.category case final category?)
                        MetadataChip(
                          label: widget.challenge.geography == null
                              ? category
                              : '$category · ${widget.challenge.geography}',
                        ),
                      if (widget.item.difficulty case final difficulty?)
                        MetadataChip(label: difficulty),
                    ],
                  ),
                const SizedBox(height: 20),
                Card(
                  child: CheckboxListTile(
                    value: isCompleted,
                    onChanged: isLoading ? null : (_) => toggleCompletion(),
                    title: Text(
                      isCompleted
                          ? widget.challenge.itemType ==
                                    'state_or_union_territory'
                                ? 'Visited'
                                : 'Explored'
                          : widget.challenge.itemType ==
                                'state_or_union_territory'
                          ? 'Mark as Visited'
                          : 'Mark as ${widget.challenge.completionVerb}',
                    ),
                    subtitle: Text(
                      isCompleted ? 'This item is included in your progress.' : 'Use the checkbox when you have completed this item.',
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'About ${widget.item.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.item.description ?? 'No description is available yet.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                if (widget.item.metadata.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ...widget.item.metadata.entries.map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.key),
                        subtitle: Text(entry.value),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isExperiencesLoading)
            const SliverPadding(
              padding: EdgeInsets.all(28),
              sliver: SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (experiences.isNotEmpty ||
              districts.isNotEmpty ||
              fruits.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverMainAxisGroup(
                slivers: buildExperienceExplorerSlivers(context),
              ),
            )
          else if (widget.challenge.detailFutureSection case final title?)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expandName(title),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.information,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        expandName(
                          widget.challenge.detailFutureMessage ??
                              'More experiences are coming soon.',
                        ),
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
