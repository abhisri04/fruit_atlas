import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'circular_progress_widget.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final String summary;
  final double progress;
  final bool isLoading;
  final bool prominent;
  final ProgressSize? variant;

  const ProgressCard({
    super.key,
    required this.title,
    required this.summary,
    required this.progress,
    this.isLoading = false,
    this.prominent = false,
    this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: prominent ? AppColors.accentSurface : AppColors.surface,
        border: Border.all(
          color: prominent ? AppColors.accentSurface : AppColors.outline,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final ring = CircularProgressWidget(
                  progress: progress,
                  variant:
                      variant ??
                      (prominent ? ProgressSize.large : ProgressSize.medium),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress >= 1 ? 'Collection complete' : title,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary.replaceAll(' / ', ' of '),
                      style: TextStyle(
                        fontSize: prominent ? 22 : 16,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (prominent) ...[
                      const SizedBox(height: 8),
                      Text(
                        progress >= 1
                            ? 'Every experience, collected.'
                            : progress > 0
                            ? 'Keep following your curiosity.'
                            : 'Your first experience starts here.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                );
                if (constraints.maxWidth < 270 &&
                    MediaQuery.textScalerOf(context).scale(14) > 18) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: ring),
                      const SizedBox(height: 20),
                      details,
                    ],
                  );
                }
                return Row(
                  children: [
                    ring,
                    const SizedBox(width: 20),
                    Expanded(child: details),
                  ],
                );
              },
            ),
    );
  }
}
