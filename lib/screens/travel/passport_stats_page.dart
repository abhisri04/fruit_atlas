import 'package:flutter/material.dart';

import '../../models/india_location_registry.dart';
import '../../models/india_regions.dart';
import '../../services/india_map_repository.dart';
import '../../services/state_travel_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../share/india_passport_share_page.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Extra numbers other travel features contribute (trips, places).
class PassportExtraStats {
  final int trips;
  final int daysTravelled;
  final int placesVisited;
  final int placesTotal;

  const PassportExtraStats({
    this.trips = 0,
    this.daysTravelled = 0,
    this.placesVisited = 0,
    this.placesTotal = 0,
  });
}

/// Loads [PassportExtraStats]; swapped in tests.
typedef PassportExtraLoader = Future<PassportExtraStats> Function();

/// "My India in numbers": how much of India you've seen, by region, with
/// your first and latest stamps. Only what you've added, never a ranking.
class PassportStatsPage extends StatefulWidget {
  final StateTravelService travel;
  final PassportExtraLoader? extras;
  const PassportStatsPage({super.key, required this.travel, this.extras});

  @override
  State<PassportStatsPage> createState() => _PassportStatsPageState();
}

class _PassportStatsPageState extends State<PassportStatsPage> {
  PassportExtraStats extra = const PassportExtraStats();

  StateTravelService get travel => widget.travel;

  @override
  void initState() {
    super.initState();
    StateTravelService.changes.addListener(_reload);
    TripService.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    StateTravelService.changes.removeListener(_reload);
    TripService.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final loaded = await (widget.extras?.call() ?? Future.value(extra));
    if (mounted) setState(() => extra = loaded);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My India in numbers'),
      actions: [
        IconButton(
          key: const ValueKey('stats-share'),
          tooltip: 'Share India Passport',
          icon: const Icon(Icons.ios_share),
          onPressed: () async {
            final regions = await IndiaMapRepository.load();
            if (!context.mounted) return;
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    IndiaPassportSharePage(travel: travel, regions: regions),
              ),
            );
          },
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: travel,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          Reveal(child: _hero()),
          const SizedBox(height: 14),
          Reveal(index: 1, child: _tiles()),
          const SizedBox(height: 22),
          Reveal(index: 2, child: _regions(context)),
          const SizedBox(height: 22),
          Reveal(index: 3, child: _journey(context)),
        ],
      ),
    ),
  );

  Widget _hero() {
    final visited = travel.visitedIds;
    final total = IndiaLocationRegistry.allLocationIds.length;
    final states = visited.where(IndiaLocationRegistry.stateIds.contains);
    final uts = visited.where(IndiaLocationRegistry.isUnionTerritory);
    final percent = total == 0 ? 0 : (visited.length * 100 / total).round();
    final accent = AppColors.categoryAccent('travel_exploration');
    return Container(
      key: const ValueKey('stats-hero'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.category(accent),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedCount(
                          value: visited.length,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ' / $total',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .85),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'States & UTs visited',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percent%',
                    key: const ValueKey('stats-percent'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'of India',
                    style: TextStyle(color: Colors.white.withValues(alpha: .9)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressValue(
            value: total == 0 ? 0 : visited.length / total,
            color: Colors.white,
            minHeight: 8,
          ),
          const SizedBox(height: 10),
          Text(
            '${states.length} of ${IndiaLocationRegistry.stateIds.length} '
            'states · ${uts.length} of '
            '${IndiaLocationRegistry.unionTerritoryIds.length} union '
            'territories',
            key: const ValueKey('stats-split'),
            style: TextStyle(color: Colors.white.withValues(alpha: .92)),
          ),
        ],
      ),
    );
  }

  Widget _tiles() {
    final regionsTouched = IndiaRegions.all
        .where((r) => r.locationIds.any(travel.visitedIds.contains))
        .length;
    final tiles = [
      (
        '$regionsTouched / ${IndiaRegions.all.length}',
        'regions',
        Icons.explore,
      ),
      ('${travel.wantToVisitCount}', 'want to visit', Icons.favorite_border),
      ('${extra.trips}', extra.trips == 1 ? 'trip' : 'trips', Icons.luggage),
      ('${extra.daysTravelled}', 'days travelling', Icons.calendar_month),
      (
        '${extra.placesVisited}',
        extra.placesVisited == 1 ? 'place' : 'places',
        Icons.place_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (value, label, icon) in tiles)
              Container(
                key: ValueKey('stats-tile-$label'),
                width: width,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _regions(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('By region', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          children: [
            for (final region in IndiaRegions.all)
              _RegionRow(
                key: ValueKey('stats-region-${region.id}'),
                region: region,
                visited: region.locationIds
                    .where(travel.visitedIds.contains)
                    .toList(),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _journey(BuildContext context) {
    final stamped = [
      for (final id in travel.visitedIds)
        if (travel.markedAt(id) case final at?) (id, at),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final wanted = travel.wantToVisitIds.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your journey', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (stamped.isEmpty)
          const Text(
            'Your first stamp will show here. Tap any state on the map to '
            'mark it.',
            style: TextStyle(color: AppColors.muted),
          )
        else ...[
          _JourneyRow(
            key: const ValueKey('stats-first'),
            icon: Icons.flag_outlined,
            label: 'First stamp',
            value:
                '${IndiaLocationRegistry.nameFor(stamped.first.$1)} · '
                '${_date(stamped.first.$2)}',
          ),
          if (stamped.length > 1)
            _JourneyRow(
              key: const ValueKey('stats-latest'),
              icon: Icons.new_releases_outlined,
              label: 'Latest stamp',
              value:
                  '${IndiaLocationRegistry.nameFor(stamped.last.$1)} · '
                  '${_date(stamped.last.$2)}',
            ),
        ],
        if (wanted.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Next on your list',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in wanted)
                Chip(
                  avatar: const Icon(
                    Icons.favorite,
                    size: 16,
                    color: AppColors.passportWanted,
                  ),
                  label: Text(IndiaLocationRegistry.nameFor(id)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RegionRow extends StatelessWidget {
  final IndiaRegion region;
  final List<String> visited;
  const _RegionRow({super.key, required this.region, required this.visited});

  @override
  Widget build(BuildContext context) {
    final total = region.locationIds.length;
    final ratio = visited.length / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              region.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: AnimatedProgressValue(
              value: ratio,
              color: AppColors.passportVisited,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${visited.length}/$total',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(ratio * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _JourneyRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(color: AppColors.muted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
