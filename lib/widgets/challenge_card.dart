import 'dart:async';

import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../theme/app_colors.dart';
import 'saved_challenge_button.dart';
import 'compact_progress.dart';
import '../services/asset_data_service.dart';
import '../services/progress_service.dart';
import '../services/indian_dishes_repository.dart';
import '../services/indian_drinks_repository.dart';

class ChallengeCard extends StatefulWidget {
  final Challenge challenge;
  final bool isActive;
  final FutureOr<void> Function()? onTap;
  final int? completedCount;
  final int? totalCount;
  final ValueChanged<bool>? onSavedChanged;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.isActive,
    this.onTap,
    this.completedCount,
    this.totalCount,
    this.onSavedChanged,
  });

  @override
  State<ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<ChallengeCard> {
  ({int completed, int total})? loaded;
  Challenge get challenge => widget.challenge;
  bool get isActive => widget.isActive;
  int? get completedCount => widget.completedCount ?? loaded?.completed;
  int? get totalCount => widget.totalCount ?? loaded?.total;
  ValueChanged<bool>? get onSavedChanged => widget.onSavedChanged;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  @override
  void didUpdateWidget(covariant ChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challenge != challenge) {
      loaded = null;
      loadProgress();
    }
  }

  Future<void> loadProgress() async {
    if (!isActive || widget.completedCount != null) return;
    try {
      const data = AssetDataService();
      Set<String> ids;
      Set<String> saved;
      if (challenge.itemType == 'fruit') {
        ids = (await data.loadFruitData()).fruits
            .map((f) => f.id.isEmpty ? f.name : f.id)
            .toSet();
        saved = await ProgressService.getCompletedFruitIds();
      } else if (challenge.itemType == 'indian_dish') {
        final catalogue = await const IndianDishesRepository().load();
        ids = catalogue.dishes.map((dish) => dish.id).toSet();
        final progress = await ProgressService.getDishProgress(catalogue);
        saved = IndianDishesRepository.triedDishIds(catalogue, progress);
      } else if (challenge.itemType == 'indian_drink') {
        final catalogue = await const IndianDrinksRepository().load();
        ids = catalogue.drinks.map((drink) => drink.id).toSet();
        final progress = await ProgressService.getDrinkProgress(catalogue);
        saved = IndianDrinksRepository.triedDrinkIds(catalogue, progress);
      } else if (challenge.itemType == 'jyotirlinga') {
        ids = (await data.loadJyotirlingas()).map((s) => s.id).toSet();
        saved = await ProgressService.getCompletedJyotirlingaIds();
      } else {
        ids = (await data.loadChallengeItems(challenge))
            .map((i) => i.id)
            .toSet();
        saved = await ProgressService.getChallengeItemIds(
          challenge.progressKey,
        );
      }
      if (mounted) {
        setState(
          () => loaded = (
            completed: saved.intersection(ids).length,
            total: ids.length,
          ),
        );
      }
    } catch (_) {
      /* Keep navigation usable if a summary cannot load. */
    }
  }

  Future<void> open() async {
    await widget.onTap?.call();
    if (mounted) await loadProgress();
  }

  IconData get icon {
    return switch (challenge.itemType) {
      'fruit' => Icons.eco_outlined,
      'indian_dish' => Icons.ramen_dining_outlined,
      'indian_drink' => Icons.local_cafe_outlined,
      'jyotirlinga' => Icons.temple_hindu_outlined,
      'yoga_pose' => Icons.self_improvement,
      'nut' => Icons.spa_outlined,
      'state' => Icons.map_outlined,
      'perfume' => Icons.local_florist_outlined,
      _ => Icons.emoji_events_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final total = totalCount ?? challenge.totalItems;
    final category = switch (challenge.categoryId) {
      'food_drink' => 'Food & Drink',
      'fitness_wellness' => 'Fitness & Wellness',
      'travel_exploration' => 'Travel & Exploration',
      'culture_learning' => 'Culture & Learning',
      'faith_pilgrimage' => 'Faith & Pilgrimage',
      'collecting' => 'Collecting',
      'life_experiences' => 'Life Experiences',
      _ => 'Explore',
    };
    return Card(
      color: Color.lerp(
        AppColors.categoryAccent(challenge.categoryId),
        Colors.white,
        .96,
      ),
      child: InkWell(
        onTap: isActive ? open : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.categoryAccent(challenge.categoryId)
                              .withValues(alpha: .35),
                          AppColors.categoryAccent(challenge.categoryId)
                              .withValues(alpha: .12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.categoryAccent(challenge.categoryId),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SavedChallengeButton(
                    key: ValueKey(challenge.id),
                    challengeId: challenge.id,
                    onChanged: onSavedChanged,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (completedCount != null) ...[
                CompactProgress(completed: completedCount!, total: total),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isActive
                          ? (completedCount == null
                                ? 'Start exploring'
                                : completedCount! >= total && total > 0
                                ? 'Completed - revisit collection'
                                : completedCount! > 0
                                ? 'Continue your journey'
                                : 'Start exploring')
                          : 'Coming soon',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isActive)
                    const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
