import 'package:flutter/material.dart';

import '../../widgets/filter_chip_group.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/experience_list.dart';

import '../../theme/app_colors.dart';

import '../../models/achievement.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/exploration_hero.dart';
import '../../models/challenge.dart';
import '../../models/jyotirlinga.dart';
import '../../services/asset_data_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/saved_challenge_button.dart';
import '../jyotirlinga/jyotirlinga_details_page.dart';

class JyotirlingaChallengePage extends StatefulWidget {
  final Challenge challenge;

  const JyotirlingaChallengePage({super.key, required this.challenge});

  @override
  State<JyotirlingaChallengePage> createState() =>
      _JyotirlingaChallengePageState();
}

class _JyotirlingaChallengePageState extends State<JyotirlingaChallengePage> {
  static const assetDataService = AssetDataService();

  List<JyotirlingaSite> sites = [];
  Set<String> completedSiteIds = {};
  String section = 'Map';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    try {
      final loadedSites = await assetDataService.loadJyotirlingas();
      final completedIds = await ProgressService.getCompletedJyotirlingaIds();

      if (!mounted) return;

      setState(() {
        sites = loadedSites;
        completedSiteIds = completedIds;
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

  Future<void> updateSiteCompletion(
    JyotirlingaSite site,
    bool isCompleted,
  ) async {
    final before = completedSiteIds.length;
    final updatedIds = Set<String>.from(completedSiteIds);

    if (isCompleted) {
      updatedIds.add(site.id);
    } else {
      updatedIds.remove(site.id);
    }

    setState(() {
      completedSiteIds = updatedIds;
    });

    await ProgressService.setCompletedJyotirlingaIds(updatedIds);
    if (mounted) {
      showCompletionFeedback(
        context,
        before: before,
        after: updatedIds.length,
        total: sites.length,
        challengeId: widget.challenge.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = sites
        .where((site) => completedSiteIds.contains(site.id))
        .length;

    final progress = sites.isEmpty ? 0.0 : completedCount / sites.length;

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
              title: 'Unable to load sites',
              message: errorMessage!,
              actionLabel: 'Try again',
              onAction: loadProgress,
            )
          : SafeArea(
              child: ExperienceList(
                header: [
                  ExplorationHero(
                    title: widget.challenge.name,
                    accent: AppColors.orange,
                    icon: Icons.temple_hindu_outlined,
                    subtitle: widget.challenge.description,
                  ),
                  ProgressCard(
                    prominent: true,
                    title: 'Your progress',
                    summary: '$completedCount / ${sites.length} visited',
                    progress: progress,
                  ),
                  if (Achievement.latestFor(widget.challenge.id, completedCount)
                      case final achievement?) ...[
                    const SizedBox(height: 16),
                    AchievementCard(achievement: achievement),
                  ],
                  const SizedBox(height: 24),
                  FilterChipGroup(
                    options: const ['Map', 'List', 'About'],
                    selected: section,
                    onChanged: (value) => setState(() => section = value),
                  ),
                  if (section == 'About')
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(widget.challenge.description),
                    ),
                  if (section == 'Map') ...[
                    const Text(
                      'Your India map',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap a marker to explore a temple. Mark your visits in the list below.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    buildIndiaMap(),
                    const SizedBox(height: 24),
                  ],
                ],
                itemCount: section == 'About' ? 0 : sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
                  final isCompleted = completedSiteIds.contains(site.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCompleted
                            ? AppColors.primary
                            : AppColors.caution,
                        foregroundColor: isCompleted
                            ? Colors.white
                            : Colors.black87,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(site.name),
                      subtitle: Text(site.location),
                      trailing: Checkbox(
                        value: isCompleted,
                        onChanged: (value) {
                          updateSiteCompletion(site, value ?? false);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                JyotirlingaDetailsPage(site: site),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget buildIndiaMap() {
    return AspectRatio(
      aspectRatio: 1229 / 1280,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const markerSize = 30.0;

          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Image(
                      image: AssetImage('assets/images/india_map_borders.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                ...sites.asMap().entries.map((entry) {
                  final index = entry.key;
                  final site = entry.value;
                  final isCompleted = completedSiteIds.contains(site.id);

                  return Positioned(
                    left:
                        constraints.maxWidth * site.mapPosition.dx -
                        markerSize / 2,
                    top:
                        constraints.maxHeight * site.mapPosition.dy -
                        markerSize / 2,
                    child: Semantics(
                      button: true,
                      label: '${site.name}, ${site.location}',
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  JyotirlingaDetailsPage(site: site),
                            ),
                          );
                        },
                        child: Container(
                          width: markerSize,
                          height: markerSize,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.primary
                                : Colors.deepOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
