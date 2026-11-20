import 'package:flutter/material.dart';

import '../models/gamification_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_spacing.dart';
import 'reward_animations.dart';

class GamificationHeader extends StatefulWidget {
  final GamificationSummary summary;
  final String eyebrow;
  final String title;
  final bool showStats;

  const GamificationHeader({
    super.key,
    required this.summary,
    required this.eyebrow,
    required this.title,
    this.showStats = true,
  });

  @override
  State<GamificationHeader> createState() => _GamificationHeaderState();
}

class _GamificationHeaderState extends State<GamificationHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse;

  @override
  void initState() {
    super.initState();
    pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void didUpdateWidget(covariant GamificationHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.summary.totalXp > oldWidget.summary.totalXp ||
        widget.summary.streakDays > oldWidget.summary.streakDays) {
      pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) {
        final wave = 1 - (pulse.value * 2 - 1).abs();
        return Transform.scale(
          scale: reduced ? 1 : 1 + wave * .008,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.page),
        decoration: BoxDecoration(
          gradient: AppGradients.gamificationHero,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(color: Colors.white.withValues(alpha: .16)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .24),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.eyebrow,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: .22),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'LEVEL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      AnimatedCount(
                        value: summary.level,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.levelTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedProgressValue(
                        value: summary.levelProgress,
                        color: AppColors.gold,
                        backgroundColor: Colors.white24,
                        minHeight: 9,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedCount(
                              value: summary.currentLevelXp,
                              suffix: ' / ${summary.nextLevelXp} XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${summary.xpToNextLevel} to next level',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.showStats) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  _HeaderStat(
                    icon: Icons.local_fire_department,
                    value: summary.streakDays,
                    label: 'day streak',
                    accent: AppColors.rose,
                    emphasize: true,
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    icon: Icons.emoji_events,
                    value: summary.achievementCount,
                    label: 'achievements',
                    accent: AppColors.gold,
                  ),
                  const SizedBox(width: 8),
                  _HeaderStat(
                    icon: Icons.auto_awesome,
                    value: summary.experienceCount,
                    label: 'experiences',
                    accent: Colors.white,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color accent;
  final bool emphasize;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: emphasize ? 23 : 20),
          const SizedBox(height: 4),
          AnimatedCount(
            value: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}
