import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'circular_progress_widget.dart';

class CategoryProgressRing extends StatelessWidget {
  final IconData icon;
  final String label;
  final int completed;
  final int total;
  final Color accent;

  const CategoryProgressRing({
    super.key,
    required this.icon,
    required this.label,
    required this.completed,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          CircularProgressWidget(
            progress: progress,
            variant: ProgressSize.medium,
            center: Icon(icon, color: accent, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '$completed / $total',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
