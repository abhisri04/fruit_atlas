import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class IndiaPassportRing extends StatefulWidget {
  final double ratio;
  final double size;
  const IndiaPassportRing({super.key, required this.ratio, this.size = 96});
  @override
  State<IndiaPassportRing> createState() => _IndiaPassportRingState();
}

class _IndiaPassportRingState extends State<IndiaPassportRing> {
  late double previous = widget.ratio;
  @override
  void didUpdateWidget(IndiaPassportRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    previous = oldWidget.ratio;
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: previous, end: widget.ratio),
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
    builder: (_, value, _) => SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFFE5E2D5),
              color: AppColors.primary,
            ),
          ),
          Padding(
            // Text scales down to fit smaller rings.
            padding: EdgeInsets.all(widget.size * .16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      inherit: false,
                      fontFamily: 'Roboto',
                      height: 1.2,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const Text(
                    'of India',
                    style: TextStyle(
                      inherit: false,
                      fontFamily: 'Roboto',
                      height: 1.2,
                      fontSize: 12,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
