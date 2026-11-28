import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/india_location_registry.dart';
import '../models/state_travel_status.dart';
import '../services/india_map_repository.dart';
import '../services/state_travel_service.dart';
import '../theme/app_colors.dart';

Color passportColor(TravelStatus status) => switch (status) {
  TravelStatus.none => AppColors.passportUnmarked,
  TravelStatus.wantToVisit => AppColors.passportWanted,
  TravelStatus.visited => AppColors.passportVisited,
};

/// The interactive India map: pinch or scroll to zoom, drag to pan,
/// double-tap to zoom in, tap a state to select it. Small states are easy
/// to hit: a tap just outside one still selects it.
class IndiaPassportMap extends StatelessWidget {
  final List<IndiaMapRegion> regions;
  final StateTravelService travel;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final TransformationController controller;

  /// Double-tap at a point in map (scene) coordinates.
  final ValueChanged<Offset>? onDoubleTapAt;

  /// Tap on the sea (no state nearby).
  final VoidCallback? onTapEmpty;

  static const maxZoom = 14.0;

  static (DateTime, Offset)? _lastTap;

  /// How far (in screen pixels) a tap may miss a state and still pick it.
  static const tapTolerance = 16.0;

  const IndiaPassportMap({
    super.key,
    required this.regions,
    required this.travel,
    required this.onSelect,
    required this.controller,
    this.selectedId,
    this.onDoubleTapAt,
    this.onTapEmpty,
  });

  static Path fittedPath(IndiaMapRegion region, Size size) {
    final scale = (size.width / 30).clamp(0.0, size.height / 33);
    final matrix = Matrix4.identity()
      ..translateByDouble(
        (size.width - 30 * scale) / 2,
        (size.height - 33 * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    return region.path.transform(matrix.storage);
  }

  /// The state at [point] (map coordinates). Exact hits win, smallest
  /// first so enclaves beat the state around them; otherwise the nearest
  /// state within [tolerance].
  static String? regionAt(
    Map<String, Path> paths,
    Offset point, {
    double tolerance = 0,
  }) {
    final exact = paths.entries.where((e) => e.value.contains(point)).toList()
      ..sort((a, b) => _area(a.value).compareTo(_area(b.value)));
    if (exact.isNotEmpty) return exact.first.key;
    String? best;
    var bestDistance = tolerance;
    for (final e in paths.entries) {
      final d = _distanceToRect(e.value.getBounds(), point);
      if (d <= bestDistance) {
        bestDistance = d;
        best = e.key;
      }
    }
    return best;
  }

  static double _area(Path p) => p.getBounds().width * p.getBounds().height;

  /// Where a state's name goes: the bounds of its largest piece, so
  /// places split into several parts (Puducherry, the Andamans) are
  /// labelled on their main piece, not in the gap between them.
  static Rect labelBounds(Path path) {
    Rect? best;
    for (final metric in path.computeMetrics()) {
      final bounds = metric.extractPath(0, metric.length).getBounds();
      if (best == null ||
          bounds.width * bounds.height > best.width * best.height) {
        best = bounds;
      }
    }
    return best ?? path.getBounds();
  }

  static double _distanceToRect(Rect r, Offset p) {
    final dx = p.dx < r.left
        ? r.left - p.dx
        : (p.dx > r.right ? p.dx - r.right : 0.0);
    final dy = p.dy < r.top
        ? r.top - p.dy
        : (p.dy > r.bottom ? p.dy - r.bottom : 0.0);
    return Offset(dx, dy).distance;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final paths = {for (final r in regions) r.stateId: fittedPath(r, size)};
      final anchors = {
        for (final e in paths.entries) e.key: labelBounds(e.value),
      };
      return ColoredBox(
        color: AppColors.navy,
        child: InteractiveViewer(
          transformationController: controller,
          minScale: 1,
          maxScale: maxZoom,
          boundaryMargin: EdgeInsets.all(size.shortestSide * .35),
          child: GestureDetector(
            key: const ValueKey('india-map'),
            behavior: HitTestBehavior.opaque,
            // Taps select straight away (no waiting to rule out a double
            // tap); a second tap close by, soon after, zooms in.
            onTapUp: (details) {
              final at = details.localPosition;
              final now = DateTime.now();
              final last = _lastTap;
              _lastTap = (now, at);
              if (onDoubleTapAt != null &&
                  last != null &&
                  now.difference(last.$1) < kDoubleTapTimeout &&
                  (at - last.$2).distance < 40) {
                _lastTap = null;
                onDoubleTapAt!(at);
                return;
              }
              final zoom = controller.value.getMaxScaleOnAxis();
              final id = regionAt(paths, at, tolerance: tapTolerance / zoom);
              if (id != null) {
                onSelect(id);
              } else {
                onTapEmpty?.call();
              }
            },
            child: SizedBox.fromSize(
              size: size,
              child: TweenAnimationBuilder<Map<String, Color>>(
                tween: _RegionColorsTween({
                  for (final r in regions)
                    r.stateId: passportColor(travel.statusFor(r.stateId)),
                }),
                duration: const Duration(milliseconds: 220),
                builder: (_, colors, _) => ValueListenableBuilder<Matrix4>(
                  valueListenable: controller,
                  builder: (_, matrix, _) => CustomPaint(
                    painter: _MapPainter(
                      paths,
                      anchors,
                      colors,
                      selectedId,
                      matrix.getMaxScaleOnAxis(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RegionColorsTween extends Tween<Map<String, Color>> {
  _RegionColorsTween(Map<String, Color> colors)
    : super(begin: colors, end: colors);
  @override
  Map<String, Color> lerp(double t) => {
    for (final id in end!.keys) id: Color.lerp(begin![id], end![id], t)!,
  };
}

class _MapPainter extends CustomPainter {
  final Map<String, Path> paths;
  final Map<String, Rect> anchors;
  final Map<String, Color> colors;
  final String? selectedId;

  /// Current zoom, so lines and labels stay the same size on screen.
  final double zoom;

  _MapPainter(
    this.paths,
    this.anchors,
    this.colors,
    this.selectedId,
    this.zoom,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = AppColors.navyRaised
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 / zoom;
    for (final e in paths.entries) {
      final island = e.key == 'lakshadweep';
      canvas.drawPath(
        e.value,
        Paint()
          ..color = island
              ? colors[e.key]!.withValues(alpha: 0.18)
              : colors[e.key]!,
      );
      canvas.drawPath(e.value, border);
      if (island) {
        canvas.drawCircle(
          e.value.getBounds().center,
          4 / zoom,
          Paint()..color = colors[e.key]!,
        );
      }
    }
    if (paths[selectedId] case final selected?) {
      canvas.drawPath(
        selected,
        Paint()
          ..color = AppColors.passportSelected
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 2.5 / zoom,
      );
    }
    _labels(canvas);
  }

  /// State names appear once a state is big enough on screen to hold one,
  /// so zooming in reveals the small ones.
  void _labels(Canvas canvas) {
    for (final e in paths.entries) {
      final bounds = e.key == 'lakshadweep'
          ? e.value.getBounds()
          : anchors[e.key]!;
      final onScreen = bounds.width * zoom;
      final always = e.key == 'lakshadweep';
      if (!always && onScreen < 58) continue;
      final selected = e.key == selectedId;
      final label = TextPainter(
        text: TextSpan(
          text: IndiaLocationRegistry.nameFor(e.key),
          style: TextStyle(
            color: selected ? Colors.white : AppColors.navy,
            fontSize: (selected ? 11.5 : 10) / zoom,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'Roboto',
            shadows: selected
                ? [Shadow(color: AppColors.navy, blurRadius: 3 / zoom)]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (!always && label.width > bounds.width * .95) continue;
      final at = always
          ? bounds.center + Offset(-label.width / 2, 7 / zoom)
          : bounds.center - Offset(label.width / 2, label.height / 2);
      label.paint(canvas, at);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.zoom != zoom ||
      old.selectedId != selectedId ||
      old.colors != colors ||
      old.paths != paths;

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final e in paths.entries)
          CustomPainterSemantics(
            rect: e.value.getBounds(),
            properties: SemanticsProperties(
              label: IndiaLocationRegistry.nameFor(e.key),
              textDirection: TextDirection.ltr,
            ),
          ),
      ];
}
