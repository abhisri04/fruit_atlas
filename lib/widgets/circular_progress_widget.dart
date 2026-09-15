import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ProgressSize {
  compact(32, 4),
  small(48, 5),
  medium(80, 7),
  large(116, 10);

  final double diameter, stroke;
  const ProgressSize(this.diameter, this.stroke);
}

/// A determinate, accessible ring shared by every collection summary.
class CircularProgressWidget extends StatelessWidget {
  final double progress;
  final ProgressSize variant;
  const CircularProgressWidget({
    super.key,
    required this.progress,
    this.variant = ProgressSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: 'Collection progress',
      value: '${(value * 100).round()}%',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: variant.diameter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: animated,
                    strokeWidth: variant.stroke,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.ringTrack,
                    color: AppColors.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: FittedBox(
                    child: Text(
                      '${(animated * 100).round()}%',
                      style: TextStyle(
                        fontSize: variant == ProgressSize.large ? 28 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
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
