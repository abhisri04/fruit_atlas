import 'package:flutter/material.dart';

import '../../models/india_location_registry.dart';
import '../../services/asset_data_service.dart';
import '../../services/challenge_repository.dart';
import '../../services/state_exploration_repository.dart';
import '../challenge/checklist_item_details_page.dart';
import 'travel_theme_page.dart';

Future<void> openStateExploration(BuildContext context, String id) async {
  final challenge = await const ChallengeRepository().getChallengeById(
    'explore_indian_states',
  );
  if (challenge == null) return;
  final items = await const AssetDataService().loadChallengeItems(challenge);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChecklistItemDetailsPage(
        challenge: challenge,
        item: items.firstWhere((item) => item.id == id),
      ),
    ),
  );
}

/// Canonical linked experiences determine depth, independently of travel status.
class ExploreIndiaPage extends StatefulWidget {
  const ExploreIndiaPage({super.key});
  @override
  State<ExploreIndiaPage> createState() => _ExploreIndiaPageState();
}

class _ExploreIndiaPageState extends State<ExploreIndiaPage> {
  Map<String, int>? counts;
  Map<String, int> totals = {};
  Set<String> completed = {};
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final summary = await const StateExplorationRepository().loadProgress();
      if (mounted) {
        setState(() {
          counts = summary.counts;
          totals = summary.totals;
          completed = summary.completedIds;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to load exploration.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Explore India')),
    body: counts == null
        ? Center(
            child: error == null
                ? const CircularProgressIndicator()
                : TextButton(onPressed: _load, child: Text('$error Retry')),
          )
        : ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '${completed.length} experiences explored\nDiscover deeper experiences in every State & UT.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  'Explore by travel theme',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: TravelThemeGrid(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'By state',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final location in IndiaLocationRegistry.locations)
                ListTile(
                  title: Text(location.name),
                  subtitle: Text(
                    '${counts![location.id]} / ${totals[location.id]} experiences explored',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await openStateExploration(context, location.id);
                    await _load();
                  },
                ),
            ],
          ),
  );
}
