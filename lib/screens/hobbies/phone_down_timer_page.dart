import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/reward_animations.dart';

/// "Phone down" timer: start it, put the phone away and do the hobby; come
/// back and tap Done. Returns the whole minutes spent (at least 1).
class PhoneDownTimerPage extends StatefulWidget {
  final String hobbyName;
  final DateTime Function()? clock;
  const PhoneDownTimerPage({super.key, required this.hobbyName, this.clock});

  @override
  State<PhoneDownTimerPage> createState() => _PhoneDownTimerPageState();
}

class _PhoneDownTimerPageState extends State<PhoneDownTimerPage> {
  late final DateTime started = now;
  Timer? ticker;

  DateTime get now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  Duration get elapsed => now.difference(started);

  String get clockText {
    final e = elapsed;
    final h = e.inHours;
    final m = e.inMinutes % 60;
    final s = e.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppGradients.gamificationHero),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Cancel',
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              const Icon(Icons.phone_iphone, color: AppColors.gold, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Phone down, hands busy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enjoy ${widget.hobbyName}. Come back and tap Done when '
                "you're finished.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: .85)),
              ),
              const SizedBox(height: 28),
              Text(
                clockText,
                key: const ValueKey('phone-down-clock'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: TactileScale(
                  child: FilledButton.icon(
                    key: const ValueKey('phone-down-done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: () => Navigator.pop(
                      context,
                      elapsed.inMinutes < 1 ? 1 : elapsed.inMinutes,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
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
