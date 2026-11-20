import 'package:flutter/material.dart';

/// Fades and lifts its child into place the first time it is built.
///
/// Siblings pass increasing [index] values to get a gentle stagger. The
/// stagger is an [Interval] inside a single controller rather than a timer,
/// so tests that pump until settled never wait on pending timers. Respects
/// the platform "reduce motion" setting.
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;

  /// Stagger step between siblings; capped so long lists stay snappy.
  static const step = Duration(milliseconds: 55);
  static const duration = Duration(milliseconds: 380);
  static const maxStaggered = 8;

  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
  });

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final slot = widget.index.clamp(0, Reveal.maxStaggered);
    final delay = Reveal.step * slot;
    final total = delay + Reveal.duration;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    child: widget.child,
    builder: (context, child) {
      final t = _progress.value;
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * widget.offset),
          child: child,
        ),
      );
    },
  );
}
