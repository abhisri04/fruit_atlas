import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/challenge.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'challenge_icon.dart';
import 'experience_artwork.dart';
import 'reward_animations.dart';

class JourneyCard extends StatelessWidget {
  final Challenge challenge;
  final int completed;
  final int total;
  final VoidCallback onTap;
  final double? width;

  /// Replaces the default artwork header, e.g. a live map.
  final Widget? artwork;

  const JourneyCard({
    super.key,
    required this.challenge,
    required this.completed,
    required this.total,
    required this.onTap,
    this.width,
    this.artwork,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent(challenge.categoryId);
    Achievement? nextMilestone;
    for (final achievement in Achievement.forChallenge(challenge.id)) {
      if (achievement.threshold > completed) {
        nextMilestone = achievement;
        break;
      }
    }
    // Show the next step, not the whole mountain: "3 of 10 to your next
    // badge" reads better than "3 of 1000".
    final goal = nextMilestone?.threshold ?? total;
    final progress = goal <= 0 ? 0.0 : (completed / goal).clamp(0.0, 1.0);
    return SizedBox(
      width:
          width ?? (MediaQuery.sizeOf(context).width * .78).clamp(232.0, 520.0),
      child: TactileScale(
        child: Card(
          elevation: AppSpacing.cardElevation,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                artwork ??
                    ExperienceArtwork(
                      assetPath: challenge.heroImageAsset,
                      icon: challengeIcon(challenge.iconIdentifier),
                      accent: accent,
                      height: 106,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radius),
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.compactTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedProgressValue(
                        value: progress,
                        color: accent,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: AnimatedCount(
                                value: completed,
                                suffix: nextMilestone == null
                                    ? ' of $total ${challenge.progressVerb}'
                                    : ' of $goal to next badge',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(progress * 100).round()}%',
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      if (nextMilestone != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          '$completed ${challenge.progressVerb} · $total in all',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
