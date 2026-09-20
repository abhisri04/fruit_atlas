import 'package:flutter/material.dart';

import '../../models/challenge.dart';
import '../../models/daily_discovery.dart';
import '../../models/fruit.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/challenge_repository.dart';
import '../../services/progress_service.dart';
import '../../services/daily_discovery_service.dart';
import '../../services/asset_data_service.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/empty_state.dart';
import '../discover/discover_page.dart';
import '../fruit/fruit_details_page.dart';
import '../fruit/variety_details_page.dart';
import '../../widgets/fruit_image.dart';
import '../challenge/checklist_item_details_page.dart';

// SAVED PAGE
// =================================================================

class SavedPage extends StatefulWidget {
  final DailyDiscoveryService? dailyDiscoveryService;
  const SavedPage({super.key, this.dailyDiscoveryService});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  static const repository = ChallengeRepository();
  static const dataService = AssetDataService();
  DailyDiscoveryService get dailyService =>
      widget.dailyDiscoveryService ?? const DailyDiscoveryService();
  List<Challenge> savedChallenges = [];
  List<DailyDiscovery> savedEntities = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSavedChallenges();
  }

  Future<void> loadSavedChallenges() async {
    try {
      final challenges = await repository.loadChallenges();
      final savedIds = await ProgressService.getSavedChallengeIds();
      final savedReferences = await ProgressService.getSavedEntityReferences();
      final canonicalPool = await dailyService.buildCanonicalPool();
      if (!mounted) return;
      setState(() {
        savedChallenges = challenges
            .where((challenge) => savedIds.contains(challenge.id))
            .toList();
        savedEntities = canonicalPool
            .where((entity) => savedReferences.contains(entity.reference))
            .toList(growable: false);
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> openSavedChallenge(Challenge challenge) async {
    await openChallenge(context, challenge);
    await loadSavedChallenges();
  }

  Future<void> openSavedEntity(DailyDiscovery discovery) async {
    final states = discovery.type == DailyDiscoveryType.yogaPose
        ? const <AtlasState>[]
        : (await dataService.loadFruitData()).states;
    if (!mounted) return;
    final page = switch (discovery.type) {
      DailyDiscoveryType.fruit => FruitDetailsPage(
        fruit: discovery.fruit!,
        states: states,
      ),
      DailyDiscoveryType.variety => VarietyDetailsPage(
        variety: discovery.variety!,
        fruit: discovery.fruit!,
        states: states,
      ),
      DailyDiscoveryType.yogaPose => ChecklistItemDetailsPage(
        challenge: discovery.yogaChallenge!,
        item: discovery.yogaPose!,
      ),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await loadSavedChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load',
              message: 'Could not load saved challenges.\n\n$errorMessage',
            )
          : savedChallenges.isEmpty && savedEntities.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border,
              title: 'Keep your next adventure close',
              message: 'Save challenges to access them quickly.',
              actionLabel: 'Discover challenges',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscoverPage()),
                );
                await loadSavedChallenges();
              },
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (savedEntities.isNotEmpty) ...[
                  Text(
                    'Saved discoveries',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final discovery in savedEntities)
                    Card(
                      child: ListTile(
                        leading: discovery.fruit == null
                            ? const Icon(Icons.self_improvement_outlined)
                            : FruitImage(
                                fruit: discovery.fruit!,
                                width: 42,
                                height: 42,
                              ),
                        title: Text(discovery.title),
                        subtitle: Text(discovery.subtitle),
                        trailing: IconButton(
                          tooltip: 'Remove from Saved',
                          icon: const Icon(Icons.bookmark),
                          onPressed: () async {
                            await ProgressService.toggleSavedEntity(
                              discovery.reference,
                            );
                            await loadSavedChallenges();
                          },
                        ),
                        onTap: () => openSavedEntity(discovery),
                      ),
                    ),
                  const SizedBox(height: 18),
                ],
                if (savedChallenges.isNotEmpty) ...[
                  Text(
                    'Saved challenges',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final challenge in savedChallenges)
                    ChallengeCard(
                      challenge: challenge,
                      isActive: challenge.status == 'active',
                      onSavedChanged: (_) => loadSavedChallenges(),
                      onTap: () => openSavedChallenge(challenge),
                    ),
                ],
              ],
            ),
    );
  }
}

// =================================================================
