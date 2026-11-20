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

class IndiaPassportMap extends StatelessWidget {
  final List<IndiaMapRegion> regions;
  final StateTravelService travel;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final TransformationController controller;
  const IndiaPassportMap({
    super.key,
    required this.regions,
    required this.travel,
    required this.onSelect,
    required this.controller,
    this.selectedId,
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

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final paths = {for (final r in regions) r.stateId: fittedPath(r, size)};
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: AppColors.navy,
          child: InteractiveViewer(
            transformationController: controller,
            minScale: 1,
            maxScale: 8,
            child: GestureDetector(
              key: const ValueKey('india-map'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                // Small enclaves take precedence over larger enclosing regions.
                final hits =
                    paths.entries
                        .where((e) => e.value.contains(details.localPosition))
                        .toList()
                      ..sort(
                        (a, b) =>
                            (a.value.getBounds().width *
                                    a.value.getBounds().height)
                                .compareTo(
                                  b.value.getBounds().width *
                                      b.value.getBounds().height,
                                ),
                      );
                if (hits.isNotEmpty) onSelect(hits.first.key);
              },
              child: SizedBox.fromSize(
                size: size,
                child: TweenAnimationBuilder<Map<String, Color>>(
                  tween: _RegionColorsTween({
                    for (final r in regions)
                      r.stateId: passportColor(travel.statusFor(r.stateId)),
                  }),
                  duration: const Duration(milliseconds: 180),
                  builder: (_, value, _) => CustomPaint(
                    painter: _MapPainter(paths, value, selectedId),
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
  final Map<String, Color> colors;
  final String? selectedId;
  _MapPainter(this.paths, this.colors, this.selectedId);
  @override
  void paint(Canvas canvas, Size size) {
    for (final e in paths.entries) {
      canvas.drawPath(
        e.value,
        Paint()
          ..color = e.key == 'lakshadweep'
              ? colors[e.key]!.withValues(alpha: 0.18)
              : colors[e.key]!,
      );
      canvas.drawPath(
        e.value,
        Paint()
          ..color = AppColors.navyRaised
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      if (e.key == 'lakshadweep') {
        final center = e.value.getBounds().center;
        canvas.drawCircle(center, 4, Paint()..color = colors[e.key]!);
        final label = TextPainter(
          text: const TextSpan(
            text: 'Lakshadweep',
            style: TextStyle(
              color: AppColors.passportUnmarked,
              fontSize: 9,
              fontFamily: 'Roboto',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, center + Offset(-label.width / 2, 8));
      }
    }
    if (paths[selectedId] case final selected?) {
      canvas.drawPath(
        selected,
        Paint()
          ..color = AppColors.passportSelected
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => true;
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
