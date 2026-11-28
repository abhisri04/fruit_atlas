import 'package:flutter/material.dart';

import '../models/india_passport_share_data.dart';
import '../models/share_branding_config.dart';
import '../models/share_highlight.dart';
import '../services/india_map_repository.dart';
import '../theme/app_colors.dart';
import 'india_passport_map.dart';
import 'india_passport_ring.dart';

class IndiaPassportShareCard extends StatelessWidget {
  final IndiaPassportShareData data;
  final List<IndiaMapRegion> regions;
  final ShareCardFormat format;
  final ShareBrandingConfig branding;
  final String? displayName;
  const IndiaPassportShareCard({
    super.key,
    required this.data,
    required this.regions,
    this.format = ShareCardFormat.story,
    this.branding = const ShareBrandingConfig(),
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final story = format == ShareCardFormat.story;
    Widget text(
      String value,
      double size, {
      FontWeight weight = FontWeight.w500,
    }) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        style: TextStyle(
          inherit: false,
          fontFamily: 'Roboto',
          height: 1.2,
          fontSize: size,
          fontWeight: weight,
          color: AppColors.navy,
        ),
        textAlign: TextAlign.center,
      ),
    );
    final progress = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IndiaPassportRing(ratio: data.ratio, size: story ? 106 : 90),
        const SizedBox(width: 25),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(
                '${data.visited} of ${data.total} visited',
                16,
                weight: FontWeight.w800,
              ),
              const SizedBox(height: 8),
              text('${data.wanted} want to visit', 13),
            ],
          ),
        ),
      ],
    );
    final map = CustomPaint(
      painter: PassportShareMapPainter(regions, data),
      child: const SizedBox.expand(),
    );
    return AspectRatio(
      aspectRatio: story ? 9 / 16 : 1,
      child: LayoutBuilder(
        builder: (_, constraints) => FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 360,
            height: story ? 640 : 360,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF9EC), Color(0xFFF1E6D2)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (branding.logoAsset != null)
                            Image.asset(
                              branding.logoAsset!,
                              width: 20,
                              height: 20,
                            )
                          else
                            const Icon(
                              Icons.explore_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          const SizedBox(width: 6),
                          text(branding.appName, 10, weight: FontWeight.w800),
                          const Spacer(),
                          if (displayName?.trim().isNotEmpty == true)
                            Flexible(
                              child: Text(
                                displayName!.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  inherit: false,
                                  fontFamily: 'Roboto',
                                  height: 1.2,
                                  fontSize: 10,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: story ? 24 : 9),
                      text(
                        'India Passport',
                        story ? 32 : 25,
                        weight: FontWeight.w800,
                      ),
                      const SizedBox(height: 4),
                      text("My journey across India's 36 States & UTs", 11),
                      if (story) ...[
                        const SizedBox(height: 22),
                        progress,
                        const SizedBox(height: 12),
                        Expanded(child: map),
                        const SizedBox(height: 6),
                        const SizedBox(
                          height: 65,
                          width: double.infinity,
                          child: CustomPaint(painter: _SceneryPainter()),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IndiaPassportRing(
                                      ratio: data.ratio,
                                      size: 82,
                                    ),
                                    const SizedBox(height: 8),
                                    text(
                                      '${data.visited} of ${data.total} visited',
                                      11,
                                      weight: FontWeight.w800,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(flex: 4, child: map),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                          width: double.infinity,
                          child: CustomPaint(painter: _SceneryPainter()),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            for (final stat in [
                              (data.visited, 'Visited'),
                              (data.wanted, 'Want to visit'),
                              (data.notMarked, 'Not marked'),
                            ])
                              Expanded(
                                child: Column(
                                  children: [
                                    text(
                                      '${stat.$1}',
                                      19,
                                      weight: FontWeight.w800,
                                    ),
                                    text(stat.$2, 9),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: story ? 16 : 6),
                      text(branding.appName, 10, weight: FontWeight.w800),
                      text(branding.tagline, 9),
                      const SizedBox(height: 3),
                      text('Map © OpenStreetMap contributors · ODbL', 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PassportShareMapPainter extends CustomPainter {
  final List<IndiaMapRegion> regions;
  final IndiaPassportShareData data;
  PassportShareMapPainter(this.regions, this.data);
  Color colorFor(String id) => passportColor(data.statuses[id]!);
  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final path = IndiaPassportMap.fittedPath(region, size);
      final island = region.stateId == 'lakshadweep';
      canvas.drawPath(
        path,
        Paint()
          ..color = colorFor(region.stateId)
              .withValues(alpha: island ? .18 : 1),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFF9EC)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .65,
      );
      if (island) {
        canvas.drawCircle(
          path.getBounds().center,
          2,
          Paint()..color = colorFor(region.stateId),
        );
      }
    }
  }

  @override
  bool shouldRepaint(PassportShareMapPainter oldDelegate) => true;
}

class _SceneryPainter extends CustomPainter {
  const _SceneryPainter();
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawCircle(
      Offset(s.width * .77, s.height * .27),
      s.height * .2,
      Paint()..color = const Color(0xFFE8AD51),
    );
    final mountains = Path()
      ..moveTo(0, s.height)
      ..lineTo(s.width * .18, s.height * .2)
      ..lineTo(s.width * .32, s.height * .65)
      ..lineTo(s.width * .48, s.height * .05)
      ..lineTo(s.width * .7, s.height * .8)
      ..lineTo(s.width, s.height * .4)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(mountains, Paint()..color = const Color(0xFFB4C8BA));
    final hills = Path()
      ..moveTo(0, s.height * .8)
      ..quadraticBezierTo(
        s.width * .3,
        s.height * .4,
        s.width * .5,
        s.height * .9,
      )
      ..quadraticBezierTo(s.width * .8, s.height * .5, s.width, s.height * .75)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF5C9587));
    final river = Path()
      ..moveTo(s.width * .55, s.height * .7)
      ..quadraticBezierTo(s.width * .35, s.height * .85, s.width * .6, s.height)
      ..lineTo(s.width * .77, s.height)
      ..quadraticBezierTo(
        s.width * .47,
        s.height * .85,
        s.width * .55,
        s.height * .7,
      );
    canvas.drawPath(river, Paint()..color = const Color(0xFFF8EDD6));
  }

  @override
  bool shouldRepaint(_SceneryPainter oldDelegate) => false;
}
