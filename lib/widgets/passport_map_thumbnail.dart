import 'package:flutter/material.dart';

import '../models/india_passport_share_data.dart';
import '../services/india_map_repository.dart';
import '../services/state_travel_service.dart';
import '../theme/app_colors.dart';
import 'india_passport_map.dart';
import 'india_passport_share_card.dart';

/// A small live map of India Passport for the top of a journey card:
/// stamped states in green, states you want to visit in orange.
class PassportMapThumbnail extends StatefulWidget {
  final double height;
  final BorderRadius borderRadius;

  const PassportMapThumbnail({
    super.key,
    this.height = 106,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<PassportMapThumbnail> createState() => _PassportMapThumbnailState();
}

class _PassportMapThumbnailState extends State<PassportMapThumbnail> {
  final travel = StateTravelService();
  List<IndiaMapRegion>? regions;

  @override
  void initState() {
    super.initState();
    StateTravelService.changes.addListener(_reload);
    _load();
  }

  @override
  void dispose() {
    StateTravelService.changes.removeListener(_reload);
    travel.dispose();
    super.dispose();
  }

  void _reload() => travel.load();

  Future<void> _load() async {
    try {
      final loaded = await IndiaMapRepository.load();
      await travel.load();
      if (mounted) setState(() => regions = loaded);
    } catch (_) {
      // The card still works without the map; it keeps the plain header.
    }
  }

  @override
  Widget build(BuildContext context) {
    const tint = Color(0xFFE8F1EE);
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        key: const ValueKey('passport-map-thumbnail'),
        height: widget.height,
        width: double.infinity,
        color: tint,
        child: regions == null
            ? const Icon(Icons.map_outlined, color: AppColors.primary, size: 36)
            : ListenableBuilder(
                listenable: travel,
                builder: (_, _) => Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(80, 8, 80, 8),
                        child: CustomPaint(
                          painter: PassportShareMapPainter(
                            regions!,
                            IndiaPassportShareData(travel),
                          ),
                          foregroundPainter: _SmallStampDots(
                            regions!,
                            travel.visitedIds,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          travel.visitedCount == 1
                              ? '1 state stamped'
                              : '${travel.visitedCount} states stamped',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Tiny stamped places would be invisible at this size; give them a dot.
class _SmallStampDots extends CustomPainter {
  final List<IndiaMapRegion> regions;
  final Set<String> visited;
  _SmallStampDots(this.regions, this.visited);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.passportVisited;
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final region in regions) {
      if (!visited.contains(region.stateId)) continue;
      final bounds = IndiaPassportMap.fittedPath(region, size).getBounds();
      if (bounds.width > 5 && bounds.height > 5) continue;
      canvas.drawCircle(bounds.center, 3, paint);
      canvas.drawCircle(bounds.center, 3, ring);
    }
  }

  @override
  bool shouldRepaint(_SmallStampDots old) => old.visited != visited;
}
