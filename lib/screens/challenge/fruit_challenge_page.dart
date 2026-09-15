import 'package:flutter/material.dart';

import '../../widgets/completion_feedback.dart';
import '../../widgets/experience_list.dart';

import '../../theme/app_colors.dart';

import '../../models/achievement.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/exploration_hero.dart';
import '../../services/fruit_search.dart';
import '../../widgets/discovery_search_field.dart';
import '../../widgets/empty_state.dart';
import '../../models/challenge.dart';
import '../../models/fruit.dart';
import '../../services/asset_data_service.dart';
import '../../services/progress_service.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/saved_challenge_button.dart';
import '../fruit/fruit_details_page.dart';

// FRUIT CHALLENGE PAGE
// =================================================================

class FruitChallengePage extends StatefulWidget {
  final Challenge challenge;

  const FruitChallengePage({super.key, required this.challenge});

  @override
  State<FruitChallengePage> createState() => _FruitChallengePageState();
}

class _FruitChallengePageState extends State<FruitChallengePage> {
  static const assetDataService = AssetDataService();

  final searchController = TextEditingController();
  String searchQuery = '';
  String? selectedStateId;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Fruit> get filteredFruits =>
      filterFruits(fruits, query: searchQuery, stateId: selectedStateId);

  List<Fruit> fruits = [];
  List<AtlasState> states = [];
  bool isLoading = true;
  String? errorMessage;

  // Fruits completed by the user.
  final Set<String> completedFruitIds = {};

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final savedIds = await ProgressService.getCompletedFruitIds();

    if (!mounted) return;

    setState(() {
      completedFruitIds.addAll(savedIds);
    });

    await loadFruits();
  }

  Future<void> loadFruits() async {
    try {
      final data = await assetDataService.loadFruitData();

      if (!mounted) return;

      setState(() {
        fruits = data.fruits;
        states = data.states;
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

  int get completedCount => fruits
      .where(
        (fruit) => completedFruitIds.contains(
          fruit.id.isEmpty ? fruit.name : fruit.id,
        ),
      )
      .length;

  double get progress {
    if (fruits.isEmpty) {
      return 0;
    }

    return completedCount / fruits.length;
  }

  Achievement? get currentAchievement {
    return Achievement.latestFor(widget.challenge.id, completedFruitIds.length);
  }

  List<Widget> get appBarActions => [
    SavedChallengeButton(challengeId: widget.challenge.id),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Taste All Fruits of India'),
          actions: appBarActions,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Taste All Fruits of India'),
          actions: appBarActions,
        ),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load',
          message: 'Could not load fruits.\n\n$errorMessage',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taste All Fruits of India'),
        actions: appBarActions,
      ),

      body: SafeArea(
        child: ExperienceList(
          header: [
            // ------------------------------------------------
            // PROGRESS
            // ------------------------------------------------

            ExplorationHero(
              title: widget.challenge.name,
              accent: AppColors.orange,
              icon: Icons.eco_outlined,
              subtitle: widget.challenge.description,
            ),
            ProgressCard(
              prominent: true,
              title: 'Your progress',
              summary: '$completedCount / ${fruits.length} fruits explored',
              progress: progress,
            ),
            const SizedBox(height: 8),

            if (currentAchievement != null)
              AchievementCard(achievement: currentAchievement!),

            const SizedBox(height: 16),

            const Text(
              'Your Fruits',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              'Taste a fruit and mark it as completed.',
              style: TextStyle(color: AppColors.muted),
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------
            // FRUIT CHECKLIST
            // ------------------------------------------------
            DiscoverySearchField(
              hintText: 'Search fruits or varieties',
              debounce: Duration.zero,
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Growing state / UT',
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('All India')),
                ...states.map(
                  (state) => DropdownMenuItem(
                    value: state.id,
                    child: Text(state.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() {
                selectedStateId = value == '' ? null : value;
              }),
            ),
            const SizedBox(height: 12),
            Text('${filteredFruits.length} of ${fruits.length} fruits'),
            const SizedBox(height: 12),
            if (filteredFruits.isEmpty)
              const EmptyState(
                icon: Icons.search_off,
                message: 'Try another fruit, scientific name or variety, or choose All India.',
              ),
          ],
          itemCount: filteredFruits.length,
          itemBuilder: (context, index) {
            final fruit = filteredFruits[index];
            final fruitId = fruit.id.isEmpty ? fruit.name : fruit.id;

            final isCompleted = completedFruitIds.contains(fruitId);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isCompleted
                  ? AppColors.completedSurface
                  : AppColors.surface,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                minVerticalPadding: 14,
                leading: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : Icons.eco_outlined,
                    color: AppColors.primary,
                  ),
                ),

                title: Text(
                  fruit.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isCompleted ? AppColors.primary : AppColors.ink,
                  ),
                ),

                subtitle: Text(
                  fruit.scientificName,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.muted,
                  ),
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FruitDetailsPage(fruit: fruit, states: states),
                    ),
                  );
                },

                trailing: Checkbox(
                  value: isCompleted,
                  onChanged: (value) async {
                    final before = completedFruitIds.length;
                    setState(() {
                      if (value == true) {
                        completedFruitIds.add(fruitId);
                      } else {
                        completedFruitIds.remove(fruitId);
                      }
                    });

                    await ProgressService.setCompletedFruitIds(
                      completedFruitIds,
                    );
                    if (context.mounted) {
                      showCompletionFeedback(
                        context,
                        before: before,
                        after: completedFruitIds.length,
                        total: fruits.length,
                        challengeId: widget.challenge.id,
                      );
                    }
                  },
                ),
              ),
            );
          },
          footer: [
            const SizedBox(height: 20),

            // ------------------------------------------------
            // DEEPER EXPLORATION MESSAGE
            // ------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Want to go deeper?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Some fruits have many varieties. Once you have tasted a fruit, you can explore its varieties and track those separately.',
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Variety tracking is now available from each fruit\'s details.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// =================================================================
