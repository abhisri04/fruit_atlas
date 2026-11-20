import 'package:flutter/material.dart';

import '../models/gamification_summary.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'reward_animations.dart';

class QuestCard extends StatefulWidget {
  final DailyQuestSummary quest;

  const QuestCard({super.key, required this.quest});

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.quest.justRewarded) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant QuestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.quest.justRewarded && widget.quest.justRewarded) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final complete = quest.isComplete && quest.rewardClaimed;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 1 + .012 * (1 - (_controller.value * 2 - 1).abs());
        return Transform.scale(scale: reduced ? 1 : pulse, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: complete ? const Color(0xFF123D3A) : AppColors.navy,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(
            color: complete
                ? AppColors.success.withValues(alpha: .7)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: (complete ? AppColors.success : AppColors.navy).withValues(
                alpha: .18,
              ),
              blurRadius: complete ? 26 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  complete ? Icons.check_circle : Icons.flag_outlined,
                  color: complete ? AppColors.success : AppColors.gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    complete ? 'QUEST COMPLETE' : "TODAY'S QUEST",
                    style: TextStyle(
                      color: complete ? AppColors.success : AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (!complete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${quest.completed} / ${quest.tasks.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              quest.title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontFamily: 'Roboto'),
            ),
            const SizedBox(height: 4),
            Text(
              quest.description,
              style: TextStyle(color: Colors.white.withValues(alpha: .72)),
            ),
            const SizedBox(height: 14),
            for (final task in quest.tasks)
              AnimatedContainer(
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: task.completed
                      ? AppColors.success.withValues(alpha: .12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        task.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        key: ValueKey('${task.id}:${task.completed}'),
                        size: 20,
                        color: task.completed
                            ? AppColors.success
                            : Colors.white54,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        task.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            AnimatedProgressValue(
              value: quest.tasks.isEmpty
                  ? 0
                  : quest.completed / quest.tasks.length,
              color: complete ? AppColors.success : AppColors.gold,
              backgroundColor: Colors.white24,
              minHeight: 7,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: (complete ? AppColors.success : AppColors.gold)
                    .withValues(alpha: .14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (complete ? AppColors.success : AppColors.gold)
                      .withValues(alpha: .45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt,
                    color: complete ? AppColors.success : AppColors.gold,
                    size: 17,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complete
                        ? '+${quest.rewardXp} XP earned'
                        : '+${quest.rewardXp} XP reward',
                    style: TextStyle(
                      color: complete ? AppColors.success : AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
