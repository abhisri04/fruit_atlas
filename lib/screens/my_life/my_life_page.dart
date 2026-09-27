import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/achievement.dart';
import '../../models/challenge.dart';
import '../../services/asset_data_service.dart';
import '../../services/district_repository.dart';
import '../../services/experience_repository.dart';
import '../../services/progress_service.dart';
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
  List<Achievement> achievements = [];

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
      final genericProgress = <({Challenge challenge, int count, int total})>[];
      for (final challenge in challenges.where(
        (challenge) =>
            challenge.status == 'active' &&
            challenge.dataAsset != null &&
            challenge.itemType != 'indian_dish' &&
            challenge.itemType != 'indian_drink',
      )) {
        final items = await dataService.loadChallengeItems(challenge);
        final itemIds = items.map((item) => item.id).toSet();
        final completedIds = await ProgressService.getChallengeItemIds(
          challenge.progressKey,
        );
        genericProgress.add((
          challenge: challenge,
          count: completedIds.intersection(itemIds).length,
          total: itemIds.length,
        ));
      }
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
        achievements = [
          ...Achievement.achievedFor('taste_fruits_of_india', validFruitCount),
          ...Achievement.achievedFor('visit_12_jyotirlingas', validSiteCount),
          for (final progress in genericProgress)
            ...Achievement.achievedFor(progress.challenge.id, progress.count),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Life',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'A collection of experiences that make life richer.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover. Do. Collect.',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricCard(
                        label: 'Challenges started',
                        value: '$started',
                        icon: Icons.shield_outlined,
                        accent: AppColors.blue,
                      ),
                      _MetricCard(
                        label: 'Challenges completed',
                        value: '$completed',
                        icon: Icons.verified_outlined,
                      ),
                      _MetricCard(
                        label: 'Fruits explored',
                        value: '$fruitCount',
                        icon: Icons.eco_outlined,
                        accent: AppColors.purple,
                      ),
                      _MetricCard(
                        label: 'Varieties explored',
                        value: '$varietyCount',
                        icon: Icons.local_florist_outlined,
                        accent: AppColors.orange,
                      ),
                      _MetricCard(
                        label: 'Jyotirlingas visited',
                        value: '$jyotirlingaCount',
                        icon: Icons.temple_hindu_outlined,
                        accent: AppColors.blue,
                      ),
                      for (final progress in checklistProgress)
                        _MetricCard(
                          label:
                              progress.challenge.metricLabel ??
                              '${progress.challenge.itemType.replaceAll('_', ' ')} completed',
                          value: '${progress.count}',
                          icon:
                              progress.challenge.itemType ==
                                  'state_or_union_territory'
                              ? Icons.map_outlined
                              : Icons.self_improvement,
                          accent: AppColors.categoryAccent(
                            progress.challenge.categoryId,
                          ),
                        ),
                      _MetricCard(
                        label: 'Experiences completed',
                        value: '$experienceCount',
                        icon: Icons.explore_outlined,
                        accent: AppColors.primary,
                      ),
                      _MetricCard(
                        label: 'Districts explored',
                        value: '$districtCount',
                        icon: Icons.location_city_outlined,
                        accent: AppColors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completed challenges completed. Your collections grow with every explored experience.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Achievements earned',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (achievements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Start a challenge to earn your first achievement.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  else
                    ...achievements.map(
                      (achievement) =>
                          AchievementCard(achievement: achievement),
                    ),
                  for (final entry in <String, int>{
                    'taste_fruits_of_india': fruitCount,
                    'visit_12_jyotirlingas': jyotirlingaCount,
                    for (final progress in checklistProgress)
                      progress.challenge.id: progress.count,
                    'all_experiences': experienceCount,
                  }.entries)
                    if (Achievement.forChallenge(entry.key)
                            .where((a) => !a.isAchieved(entry.value))
                            .firstOrNull
                        case final next?)
                      AchievementCard(achievement: next, unlocked: false),
                  const SizedBox(height: 24),
                  const Text(
                    'Your collections',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ProgressCard(
                    title: 'Taste All Fruits of India',
                    summary: '$fruitCount / $fruitTotal fruits explored',
                    progress: ratio(fruitCount, fruitTotal),
                  ),
                  const SizedBox(height: 12),
                  ProgressCard(
                    title: 'Fruit varieties',
                    summary: '$varietyCount / $varietyTotal varieties explored',
                    progress: ratio(varietyCount, varietyTotal),
                  ),
                  const SizedBox(height: 12),
                  ProgressCard(
                    title: 'Visit 12 Jyotirlingas',
                    summary: '$jyotirlingaCount / $jyotirlingaTotal visited',
                    progress: ratio(jyotirlingaCount, jyotirlingaTotal),
                  ),
                  const SizedBox(height: 12),
                  for (final progress in checklistProgress) ...[
                    ProgressCard(
                      title: progress.challenge.name,
                      summary:
                          '${progress.count} / ${progress.total} ${progress.challenge.collectionUnit ?? progress.challenge.completionVerb}',
                      progress: ratio(progress.count, progress.total),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
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
