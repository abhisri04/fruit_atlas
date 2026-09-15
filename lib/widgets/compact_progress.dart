import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'circular_progress_widget.dart';

/// A lightweight progress treatment for cards and collection summaries.
class CompactProgress extends StatelessWidget {
  final int? completed;
  final int? total;
  final double? progress;
  final String? summary;
  const CompactProgress({
    super.key,
    this.completed,
    this.total,
    this.progress,
    this.summary,
  }) : assert(
         (completed != null && total != null) ||
             (progress != null && summary != null),
       );

  @override
  Widget build(BuildContext context) {
    final value =
        (completed != null && total != null
                ? (total! <= 0 ? 0.0 : completed! / total!)
                : progress!)
            .clamp(0.0, 1.0);
    final label = summary ?? '$completed of $total explored';
    return Row(
      children: [
        CircularProgressWidget(progress: value, variant: ProgressSize.small),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
