import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Lightweight painted landscape; no images, blur or perpetual animations.
class ExplorationHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool immersive;
  const ExplorationHero({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.explore_outlined,
    this.accent = AppColors.primary,
    this.immersive = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: AppSpacing.medium),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: immersive
            ? const [Color(0xFF164E46), AppColors.primary]
            : [
                Color.lerp(accent, Colors.white, .70)!,
                Color.lerp(accent, Colors.white, .94)!,
              ],
      ),
    ),
    child: CustomPaint(
      painter: _Landscape(accent: accent, immersive: immersive),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 36,
              color: immersive
                  ? const Color(0xFFD8EDBC)
                  : Color.lerp(accent, Colors.black, .3),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: immersive ? Colors.white : AppColors.ink,
                fontSize: immersive ? 32 : 27,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  color: immersive
                      ? Colors.white.withValues(alpha: .9)
                      : AppColors.ink,
                  height: 1.4,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Landscape extends CustomPainter {
  final Color accent;
  final bool immersive;
  const _Landscape({required this.accent, required this.immersive});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (immersive ? const Color(0xFFEACD8F) : accent).withValues(
        alpha: .19,
      );
    canvas.drawCircle(Offset(size.width * .88, 35), 45, paint);
    for (var i = 0; i < 3; i++) {
      paint.color = (immersive ? Colors.white : accent).withValues(
        alpha: .05 + i * .025,
      );
      final path = Path()
        ..moveTo(size.width * .45, size.height)
        ..lineTo(size.width * (.72 + i * .04), size.height * (.35 + i * .12))
        ..lineTo(size.width * .88, size.height * .65)
        ..lineTo(size.width, size.height * (.28 + i * .17))
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Landscape oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.immersive != immersive;
}
