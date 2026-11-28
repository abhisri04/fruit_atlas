import 'package:flutter/material.dart';

class AnimatedProgressValue extends StatefulWidget {
  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double minHeight;
  final Duration duration;

  const AnimatedProgressValue({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.minHeight = 8,
    this.duration = const Duration(milliseconds: 450),
  });

  @override
  State<AnimatedProgressValue> createState() => _AnimatedProgressValueState();
}

class _AnimatedProgressValueState extends State<AnimatedProgressValue> {
  late double previous;

  @override
  void initState() {
    super.initState();
    previous = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    previous = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final target = widget.value.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: reduced ? target : previous.clamp(0.0, 1.0),
        end: target,
      ),
      duration: reduced ? Duration.zero : widget.duration,
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => LinearProgressIndicator(
        value: value,
        color: widget.color,
        backgroundColor: widget.backgroundColor,
        minHeight: widget.minHeight,
        borderRadius: BorderRadius.circular(widget.minHeight),
      ),
    );
  }
}

class AnimatedCount extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount> {
  late int previous;

  @override
  void initState() {
    super.initState();
    previous = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    previous = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: reduced ? widget.value.toDouble() : previous.toDouble(),
        end: widget.value.toDouble(),
      ),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => Text(
        '${widget.prefix}${value.round()}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}

class TactileScale extends StatefulWidget {
  final Widget child;

  const TactileScale({super.key, required this.child});

  @override
  State<TactileScale> createState() => _TactileScaleState();
}

class _TactileScaleState extends State<TactileScale> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Listener(
      onPointerDown: (_) => setState(() => pressed = true),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedScale(
        scale: reduced || !pressed ? 1 : .96,
        duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
