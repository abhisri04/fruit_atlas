import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'circular_progress_widget.dart';

import '../models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final double? progress;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.unlocked = true,
    this.progress,
  });

  IconData get icon => switch (achievement.iconIdentifier) {
    'eco' => Icons.eco_outlined,
    'start' => Icons.play_circle_outline,
    'explore' => Icons.explore_outlined,
    'flag' => Icons.flag_outlined,
    'map' => Icons.map_outlined,
    'temple' => Icons.temple_hindu_outlined,
    'yoga' => Icons.self_improvement,
    _ => Icons.emoji_events_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: unlocked ? AppColors.caution : AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 60,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppColors.orange.withValues(alpha: .2)
                    : AppColors.outline,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: unlocked
                      ? AppColors.orange.withValues(alpha: .4)
                      : AppColors.outline,
                ),
              ),
              child: Icon(
                unlocked ? icon : Icons.lock_outline,
                size: 28,
                color: unlocked ? const Color(0xFF94600C) : AppColors.muted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked ? 'EARNED' : 'NEXT TO COLLECT',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: unlocked
                          ? const Color(0xFF94600C)
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    achievement.description,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (progress != null) ...[
              const SizedBox(width: 10),
              CircularProgressWidget(
                progress: progress!,
                variant: ProgressSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
