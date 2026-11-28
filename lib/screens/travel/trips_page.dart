import 'package:flutter/material.dart';

import '../../models/india_location_registry.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import 'trip_detail_page.dart';
import 'trip_edit_page.dart';

/// A trip photo, or a soft placeholder.
class TripPhoto extends StatelessWidget {
  final String? photoId;
  final double width;
  final double height;
  final double radius;
  const TripPhoto({
    super.key,
    required this.photoId,
    this.width = 64,
    this.height = 64,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('travel_exploration');
    final empty = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.luggage_outlined, color: accent, size: height * .42),
    );
    if (photoId == null) return empty;
    return FutureBuilder(
      future: TripService.photo(photoId!),
      builder: (context, snapshot) => snapshot.data == null
          ? empty
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Image.memory(
                snapshot.data!,
                width: width,
                height: height,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
    );
  }
}

/// My trips: every trip, the days on the road and the places it covered.
class TripsPage extends StatefulWidget {
  final DateTime Function()? clock;
  const TripsPage({super.key, this.clock});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  TripLog? log;

  DateTime get now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    TripService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    TripService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await TripService.load();
    if (mounted) setState(() => log = loaded);
  }

  Future<void> _add() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => TripEditPage(clock: widget.clock)),
    );
    if (id != null && mounted) _open(id);
  }

  void _open(String id) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TripDetailPage(tripId: id)),
  );

  @override
  Widget build(BuildContext context) {
    final l = log;
    return Scaffold(
      appBar: AppBar(title: const Text('My trips')),
      floatingActionButton: l == null || l.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('trips-add'),
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add trip'),
            ),
      body: l == null
          ? const Center(child: CircularProgressIndicator())
          : l.isEmpty
          ? _empty(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Reveal(child: _header(l)),
                for (final memory in l.onThisDay(now)) ...[
                  const SizedBox(height: 12),
                  _MemoryCard(
                    trip: memory,
                    years: now.year - memory.start.year,
                    onTap: () => _open(memory.id),
                  ),
                ],
                const SizedBox(height: 18),
                for (final (i, trip) in l.trips.indexed)
                  Reveal(
                    index: i + 1,
                    child: _TripCard(
                      key: ValueKey('trip-card-${trip.id}'),
                      trip: trip,
                      onTap: () => _open(trip.id),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _header(TripLog l) {
    final accent = AppColors.categoryAccent('travel_exploration');
    final stats = [
      (l.trips.length, l.trips.length == 1 ? 'trip' : 'trips'),
      (l.daysTravelled, 'days travelling'),
      (l.statesCovered.length, 'states & UTs'),
    ];
    return Container(
      key: const ValueKey('trips-header'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.category(accent),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final (value, label) in stats)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedCount(
                        value: value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (l.longest case final longest? when l.trips.length > 1) ...[
            const SizedBox(height: 10),
            Text(
              'Longest: ${longest.title} · ${longest.days} days',
              style: TextStyle(color: Colors.white.withValues(alpha: .92)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
    children: [
      Icon(
        Icons.luggage_outlined,
        size: 64,
        color: AppColors.categoryAccent('travel_exploration'),
      ),
      const SizedBox(height: 14),
      Text(
        "Let's trip somewhere",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Log trips you have taken, even old ones. Each trip stamps your '
        'India Passport and builds your travel story.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, height: 1.4),
      ),
      const SizedBox(height: 18),
      Center(
        child: FilledButton.icon(
          key: const ValueKey('trips-empty-add'),
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Add your first trip'),
        ),
      ),
    ],
  );
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TactileScale(
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TripPhoto(photoId: trip.photoId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tripRange(trip)} · '
                        '${trip.days == 1 ? '1 day' : '${trip.days} days'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trip.stateIds
                            .map(IndiaLocationRegistry.nameFor)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MemoryCard extends StatelessWidget {
  final Trip trip;
  final int years;
  final VoidCallback onTap;
  const _MemoryCard({
    required this.trip,
    required this.years,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
    key: ValueKey('trip-memory-${trip.id}'),
    color: AppColors.caution,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      leading: const Icon(Icons.history, color: AppColors.orange),
      title: Text(
        years == 1 ? 'A year ago today' : '$years years ago today',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${trip.title} began'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
