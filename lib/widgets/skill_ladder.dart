import 'package:flutter/material.dart';

import '../models/item.dart';
import '../theme/app_colors.dart';

/// A vertical path from first try to confident. The first [reached] steps
/// are drawn as done.
class SkillLadder extends StatelessWidget {
  final List<LadderStep> steps;
  final int reached;

  const SkillLadder({super.key, required this.steps, this.reached = 0});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        for (final (index, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: reduced
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < reached
                              ? AppColors.primary
                              : AppColors.surface,
                          border: Border.all(
                            color: index < reached
                                ? AppColors.primary
                                : AppColors.outline,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: index < reached
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: index < reached - 1
                                ? AppColors.primary
                                : AppColors.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 3,
                      bottom: index < steps.length - 1 ? 18 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.levelLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: .8,
                            fontWeight: FontWeight.w800,
                            color: index < reached
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.milestone,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
