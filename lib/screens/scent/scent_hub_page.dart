import 'package:flutter/material.dart';

import '../../models/challenge.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/asset_data_service.dart';
import '../../services/challenge_groups.dart';
import '../../services/progress_summary_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/challenge_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../../widgets/scent_shelf_buttons.dart';

/// One home for everything scent: the four collections and My Collection.
class ScentHubPage extends StatefulWidget {
  const ScentHubPage({super.key});

  @override
  State<ScentHubPage> createState() => _ScentHubPageState();
}

class _ScentHubPageState extends State<ScentHubPage> {
  List<Challenge> collections = [];
  Map<String, ChallengeProgressSummary> progress = {};
  bool loading = true;
  String? error;

  Color get accent => AppColors.categoryAccent(scentCategoryId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final challenges = await const AssetDataService().loadChallenges();
      final summary = await const ProgressSummaryService().load(
        challenges: challenges,
      );
      if (!mounted) return;
      setState(() {
        collections = challenges
            .where((c) => c.status == 'active' && isScentChallenge(c))
            .toList();
        progress = summary.challenges;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _open(Challenge challenge) async {
    await openChallenge(context, challenge);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scent & Perfume')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load',
            message: 'Could not load scent collections.\n\n$error',
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              Reveal(child: _hero(context)),
              const SizedBox(height: 14),
              const Reveal(index: 1, child: MyCollectionEntry()),
              const SizedBox(height: 22),
              Text('Explore', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text(
                'New to perfume? Start with Scent Families.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              for (final (index, challenge) in collections.indexed)
                Reveal(
                  index: index + 2,
                  child: _CollectionCard(
                    challenge: challenge,
                    progress: groupedProgress(
                      challenge,
                      summaryLookup(progress),
                      collections,
                    ),
                    accent: accent,
                    onTap: () => _open(challenge),
                  ),
                ),
            ],
          ),
  );

  Widget _hero(BuildContext context) {
    final hub = scentHub(collections);
    final total = groupedProgress(hub, summaryLookup(progress), collections);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.category(accent),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_florist_outlined,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            'Scent & Perfume',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Learn the families, smell famous perfumes and real ingredients, '
            'try Indian attars, and build your own collection.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .92),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AnimatedProgressValue(
              value: total.total == 0 ? 0 : total.completed / total.total,
              minHeight: 8,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: .25),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${total.completed} of ${total.total} smelled',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final Challenge challenge;
  final ({int completed, int total}) progress;
  final Color accent;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.challenge,
    required this.progress,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TactileScale(
      child: Material(
        key: ValueKey('scent-hub-${challenge.id}'),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    challengeIcon(challenge.iconIdentifier),
                    color: accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.compactTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AnimatedProgressValue(
                          value: progress.total == 0
                              ? 0
                              : progress.completed / progress.total,
                          minHeight: 5,
                          color: accent,
                          backgroundColor: accent.withValues(alpha: .12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${progress.completed} of ${progress.total} '
                        '${challenge.progressVerb}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
