import 'package:flutter/material.dart';

import '../screens/travel/india_passport_page.dart';
import '../screens/travel/explore_india_page.dart';
import '../services/state_travel_service.dart';
import '../services/state_exploration_repository.dart';
import '../theme/app_colors.dart';

class TravelJourneys extends StatefulWidget {
  /// Set when shown on a dark surface (Explore) so the heading stays legible.
  final bool onDarkBackground;

  const TravelJourneys({super.key, this.onDarkBackground = false});
  @override
  State<TravelJourneys> createState() => _TravelJourneysState();
}

class _TravelJourneysState extends State<TravelJourneys> {
  final travel = StateTravelService();
  int? exploredCount;
  String? loadError;
  Future<void> _load() async {
    try {
      await travel.load();
      final summary = await const StateExplorationRepository().loadProgress();
      if (mounted) {
        setState(() {
          exploredCount = summary.exploredCount;
          loadError = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadError = 'Unable to load travel progress');
    }
  }

  @override
  void initState() {
    super.initState();
    StateTravelService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    StateTravelService.changes.removeListener(_load);
    travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: travel,
    builder: (_, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Travel & Exploration',
          style: TextStyle(
            color: widget.onDarkBackground ? AppColors.gold : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Card(
          child: ListTile(
            key: const ValueKey('india-passport-entry'),
            leading: const Icon(Icons.travel_explore),
            title: const Text('India Passport'),
            subtitle: Text(
              '${travel.visitedCount} of 36 visited\n${travel.wantToVisitCount} want to visit\nView your map →',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const IndiaPassportPage(),
                ),
              );
              await _load();
            },
          ),
        ),
        Card(
          child: ListTile(
            key: const ValueKey('explore-india-entry'),
            leading: const Icon(Icons.explore_outlined),
            title: const Text('Explore India'),
            subtitle: Text(
              '${exploredCount == null ? (loadError ?? 'Loading exploration progress…') : '$exploredCount experiences explored'}\nExplore by state →',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ExploreIndiaPage(),
                ),
              );
              await _load();
            },
          ),
        ),
      ],
    ),
  );
}
