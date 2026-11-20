import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/indian_dish.dart';
import '../models/dish_visual_style.dart';

enum DishArtworkVariant { compact, list, hero, thumbnail }

class DishArtwork extends StatelessWidget {
  final IndianDish dish;
  final DishArtworkVariant variant;
  final double? width, height;
  final BorderRadius borderRadius;
  final bool showMetadata;
  static Future<Map<String, String>>? _approvedAssets;
  const DishArtwork({
    super.key,
    required this.dish,
    this.variant = DishArtworkVariant.compact,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.showMetadata = true,
  });
  static Future<Map<String, String>> _loadApprovedAssets() async {
    final data = jsonDecode(
      await rootBundle.loadString('assets/data/dish_image_manifest.json'),
    ) as Map<String, dynamic>;
    final assets = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets()
        .toSet();
    return approvedPhotoPaths(data, assets);
  }

  static Map<String, String> approvedPhotoPaths(
    Map<String, dynamic> data,
    Set<String> bundledAssets,
  ) => {
    for (final row in data['items'] as List)
      if (const [
            'pexels_approved',
            'pixabay_approved',
            'manual_approved',
            'existing_approved',
          ].contains(row['status']) &&
          row['imageFile'] is String &&
          bundledAssets.contains(row['imageFile']))
        row['dishId'] as String: row['imageFile'] as String,
  };

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${dish.name}, ${DishVisualResolver.location(dish)}, ${DishVisualResolver.dietaryLabel(dish) ?? ''}',
    image: true,
    child: ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: FutureBuilder<Map<String, String>>(
          future: _approvedAssets ??= _loadApprovedAssets(),
          builder: (context, snapshot) {
            if (snapshot.data?[dish.id] == dish.imageAsset) {
              return Image.asset(
                dish.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(context),
              );
            }
            return _placeholder(context);
          },
        ),
      ),
    ),
  );
  Widget _placeholder(BuildContext context) {
    final style = DishVisualStyle.styles[DishVisualResolver.resolve(dish)]!;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.backgroundStart, style.backgroundEnd],
        ),
      ),
      child: CustomPaint(
        painter: DishOrnamentPainter(style.accent),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final thumbnail =
                variant == DishArtworkVariant.thumbnail || !showMetadata;
            final horizontal =
                variant == DishArtworkVariant.list ||
                (variant == DishArtworkVariant.hero &&
                    constraints.maxWidth > 440) ||
                (constraints.maxHeight < 210 && constraints.maxWidth > 220);
            final illustration = RepaintBoundary(
              child: CustomPaint(
                painter: DishFoodPainter(style),
                child: const SizedBox.expand(),
              ),
            );
            if (thumbnail) {
              return Padding(
                padding: const EdgeInsets.all(6),
                child: illustration,
              );
            }
            final metadata = _metadata(context, style);
            if (horizontal) {
              return Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    if (variant == DishArtworkVariant.list)
                      Expanded(flex: 2, child: illustration),
                    if (variant == DishArtworkVariant.list)
                      const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(child: metadata),
                    ),
                    const SizedBox(width: 12),
                    if (variant != DishArtworkVariant.list)
                      Expanded(flex: 2, child: illustration),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(flex: 3, child: illustration),
                  const SizedBox(height: 6),
                  Flexible(
                    flex: 4,
                    child: SingleChildScrollView(child: metadata),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _metadata(BuildContext context, DishVisualStyle style) {
    final dietary = DishVisualResolver.dietaryLabel(dish);
    final hero = variant == DishArtworkVariant.hero;
    Widget chip(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: hero
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          dish.name,
          maxLines: hero ? null : 2,
          overflow: hero ? null : TextOverflow.ellipsis,
          textAlign: hero ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: style.foreground,
            fontSize: hero ? 24 : 17,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: style.foreground),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                DishVisualResolver.location(dish),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: style.foreground, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (dietary != null)
              chip(
                dietary,
                dietary == 'Non-Veg'
                    ? const Color(0xFF933D32)
                    : const Color(0xFF356337),
              ),
            chip(style.label, style.foreground),
          ],
        ),
      ],
    );
  }
}

class DishOrnamentPainter extends CustomPainter {
  final Color accent;
  const DishOrnamentPainter(this.accent);
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = accent.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final center in [Offset(0, 0), Offset(size.width, size.height)]) {
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        final offset =
            center + Offset(math.cos(angle) * 42, math.sin(angle) * 42);
        canvas.drawOval(
          Rect.fromCenter(center: offset, width: 28, height: 48),
          pen,
        );
      }
      canvas.drawCircle(center, 74, pen);
      canvas.drawCircle(center, 83, pen);
    }
  }

  @override
  bool shouldRepaint(DishOrnamentPainter oldDelegate) =>
      accent != oldDelegate.accent;
}

class DishFoodPainter extends CustomPainter {
  final DishVisualStyle style;
  const DishFoodPainter(this.style);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 180, size.height / 130);
    canvas.save();
    canvas.translate(
      (size.width - 180 * scale) / 2,
      (size.height - 130 * scale) / 2,
    );
    canvas.scale(scale);
    final ink = Paint()..color = style.accent;
    final cream = Paint()..color = const Color(0xFFFFF6DE);
    final line = Paint()
      ..color = style.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(
      const Rect.fromLTWH(22, 100, 136, 16),
      Paint()..color = style.accent.withValues(alpha: .13),
    );
    final category = style.category;
    if (category == DishVisualCategory.breadFlatbread) {
      for (var i = 2; i >= 0; i--) {
        final rect = Rect.fromLTWH(34, 44 + i * 13, 112, 43);
        canvas.drawOval(rect, ink);
        canvas.drawOval(rect.deflate(3), cream);
      }
      for (final point in [
        const Offset(65, 59),
        const Offset(98, 65),
        const Offset(116, 57),
        const Offset(84, 73),
      ]) {
        canvas.drawCircle(point, 3, ink);
      }
    } else if (category == DishVisualCategory.snack) {
      canvas.drawOval(const Rect.fromLTWH(25, 82, 130, 25), cream);
      for (final x in [42.0, 83.0]) {
        final path = Path()
          ..moveTo(x, 84)
          ..quadraticBezierTo(x + 20, 24, x + 43, 84)
          ..close();
        canvas.drawPath(path, ink);
        canvas.drawPath(path, line);
        canvas.drawLine(
          Offset(x + 13, 74),
          Offset(x + 23, 50),
          Paint()
            ..color = style.backgroundStart
            ..strokeWidth = 3,
        );
      }
    } else if (category == DishVisualCategory.seafood) {
      canvas.drawOval(const Rect.fromLTWH(29, 45, 109, 52), ink);
      canvas.drawPath(
        Path()
          ..moveTo(129, 70)
          ..lineTo(160, 44)
          ..lineTo(160, 96)
          ..close(),
        ink,
      );
      canvas.drawCircle(const Offset(52, 64), 4, cream);
      canvas.drawArc(
        const Rect.fromLTWH(64, 46, 25, 47),
        -1.2,
        2.4,
        false,
        Paint()
          ..color = style.backgroundStart
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else {
      final bowl = Path()
        ..moveTo(30, 64)
        ..quadraticBezierTo(38, 110, 90, 110)
        ..quadraticBezierTo(142, 110, 150, 64)
        ..close();
      canvas.drawPath(bowl, ink);
      canvas.drawOval(const Rect.fromLTWH(30, 52, 120, 25), cream);
      canvas.drawOval(
        const Rect.fromLTWH(38, 57, 104, 15),
        Paint()..color = style.accent.withValues(alpha: .45),
      );
      if (category == DishVisualCategory.leafyVeg) {
        for (var i = 0; i < 5; i++) {
          canvas.drawOval(
            Rect.fromLTWH(49 + i * 16, 28 - (i % 2) * 10, 17, 40),
            ink,
          );
        }
      } else if (category == DishVisualCategory.rice) {
        for (var i = 0; i < 18; i++) {
          canvas.drawLine(
            Offset(51 + (i % 6) * 14, 43 + (i ~/ 6) * 8),
            Offset(56 + (i % 6) * 14, 40 + (i ~/ 6) * 8),
            line,
          );
        }
      } else if (category == DishVisualCategory.dessert) {
        for (final x in [60.0, 89.0, 117.0]) {
          canvas.drawCircle(Offset(x, 51), 13, ink);
        }
      } else if (category == DishVisualCategory.defaultFood ||
          category == DishVisualCategory.regionalSpeciality) {
        canvas.drawArc(
          const Rect.fromLTWH(38, 15, 104, 80),
          math.pi,
          math.pi,
          true,
          ink,
        );
        canvas.drawCircle(const Offset(90, 15), 6, ink);
      } else {
        for (final x in [65.0, 89.0, 113.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x, 42)
              ..cubicTo(x - 12, 28, x + 10, 25, x, 12),
            line,
          );
        }
      }
      canvas.drawLine(
        const Offset(59, 88),
        const Offset(121, 88),
        Paint()
          ..color = style.backgroundStart
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DishFoodPainter oldDelegate) => style != oldDelegate.style;
}
