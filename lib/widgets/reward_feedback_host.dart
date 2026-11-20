import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/celebration_event.dart';
import '../services/celebration_service.dart';
import '../theme/app_colors.dart';

class RewardFeedbackHost extends StatefulWidget {
  final Widget child;
  final CelebrationService? service;

  const RewardFeedbackHost({super.key, required this.child, this.service});

  @override
  State<RewardFeedbackHost> createState() => _RewardFeedbackHostState();
}

class _RewardFeedbackHostState extends State<RewardFeedbackHost>
    with SingleTickerProviderStateMixin {
  final List<CelebrationEvent> queue = [];
  StreamSubscription<CelebrationEvent>? subscription;
  late final AnimationController controller;
  CelebrationEvent? current;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    subscription = (widget.service ?? CelebrationService.instance).events
        .listen(_enqueue);
  }

  void _enqueue(CelebrationEvent event) {
    queue.add(event);
    if (current == null) _showNext();
  }

  void _showNext() {
    timer?.cancel();
    if (queue.isEmpty) {
      if (mounted) setState(() => current = null);
      return;
    }
    final event = queue.removeAt(0);
    setState(() => current = event);
    controller.forward(from: 0);
    switch (event.intensity) {
      case CelebrationIntensity.small:
        HapticFeedback.lightImpact();
        break;
      case CelebrationIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case CelebrationIntensity.large:
        HapticFeedback.heavyImpact();
        break;
    }
    final duration = switch (event.intensity) {
      CelebrationIntensity.small => const Duration(milliseconds: 1100),
      CelebrationIntensity.medium => const Duration(milliseconds: 1900),
      CelebrationIntensity.large => const Duration(milliseconds: 3000),
    };
    timer = Timer(duration, _showNext);
  }

  @override
  void dispose() {
    timer?.cancel();
    subscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = current;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      children: [
        widget.child,
        if (event != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: event.intensity != CelebrationIntensity.large,
              child: AnimatedBuilder(
                animation: controller,
                builder: (_, _) => _CelebrationPresentation(
                  event: event,
                  progress: reduced ? 1 : controller.value,
                  reducedMotion: reduced,
                  onContinue: _showNext,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CelebrationPresentation extends StatelessWidget {
  final CelebrationEvent event;
  final double progress;
  final bool reducedMotion;
  final VoidCallback onContinue;

  const _CelebrationPresentation({
    required this.event,
    required this.progress,
    required this.reducedMotion,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final entrance = Curves.easeOutBack.transform(progress.clamp(0, 1));
    if (event.intensity == CelebrationIntensity.small) {
      return Stack(
        children: [
          if (!reducedMotion)
            CustomPaint(
              key: const ValueKey('celebration-particles'),
              painter: _ParticlePainter(progress: progress, count: 12),
              size: Size.infinite,
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 116 + (reducedMotion ? 0 : 24 * progress),
            child: Opacity(
              opacity: reducedMotion
                  ? 1
                  : math.sin(math.pi * progress).clamp(0, 1).toDouble(),
              child: Center(
                child: Transform.scale(
                  scale: reducedMotion ? 1 : .9 + .1 * entrance,
                  child: _XpPill(event: event),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Stack(
      children: [
        if (event.intensity == CelebrationIntensity.large)
          ColoredBox(color: AppColors.ink.withValues(alpha: .42 * progress)),
        if (!reducedMotion)
          CustomPaint(
            key: const ValueKey('celebration-particles'),
            painter: _ParticlePainter(
              progress: progress,
              count: event.intensity == CelebrationIntensity.large ? 46 : 26,
            ),
            size: Size.infinite,
          ),
        Center(
          child: Opacity(
            opacity: progress.clamp(0, 1),
            child: Transform.scale(
              scale: reducedMotion ? 1 : .82 + .18 * entrance,
              child: Container(
                key: const ValueKey('celebration-card'),
                constraints: const BoxConstraints(maxWidth: 330),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: .8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: .24),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      event.kind == CelebrationKind.levelUp
                          ? Icons.workspace_premium
                          : Icons.emoji_events,
                      color: AppColors.gold,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (event.previousLevel != null &&
                        event.newLevel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${event.previousLevel}  →  ${event.newLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      event.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    if (event.xp > 0) ...[
                      const SizedBox(height: 12),
                      _XpPill(event: event),
                    ],
                    if (event.intensity == CelebrationIntensity.large) ...[
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: onContinue,
                        child: const Text('Continue exploring'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _XpPill extends StatelessWidget {
  final CelebrationEvent event;

  const _XpPill({required this.event});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.gold,
    borderRadius: BorderRadius.circular(30),
    elevation: 5,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(
        event.xp > 0 ? '+${event.xp} XP' : event.title,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final int count;

  const _ParticlePainter({required this.progress, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const colors = [
      AppColors.gold,
      AppColors.success,
      AppColors.rose,
      AppColors.blue,
    ];
    for (var index = 0; index < count; index++) {
      final seed = index * 2.399;
      final horizontal = (.08 + ((index * 37) % 84) / 100) * size.width;
      final startY = size.height * (.38 + .12 * math.sin(seed));
      final travel = size.height * (.18 + ((index * 17) % 18) / 100);
      final y = startY + travel * progress;
      final x = horizontal + math.sin(seed + progress * 5) * 24;
      paint.color = colors[index % colors.length].withValues(
        alpha: (1 - progress * .72).clamp(0, 1).toDouble(),
      );
      final radius = 2.5 + index % 3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(seed + progress * 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * 2.4,
            height: radius,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.count != count;
}
