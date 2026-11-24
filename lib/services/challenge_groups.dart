import '../models/challenge.dart';
import 'progress_summary_service.dart';

/// The Scent & Perfume collections are shown as one tile that opens a hub,
/// rather than four separate tiles.
const scentHubId = 'scent_hub';
const scentCategoryId = 'scent';

bool isScentChallenge(Challenge challenge) =>
    challenge.categoryId == scentCategoryId && challenge.id != scentHubId;

Challenge scentHub(Iterable<Challenge> scent) => Challenge(
  id: scentHubId,
  categoryId: scentCategoryId,
  name: 'Scent & Perfume',
  description:
      'Scent families, famous perfumes, notes, Indian attars and your own '
      'collection.',
  itemType: 'scent_hub',
  totalItems: scent.fold(0, (sum, c) => sum + c.totalItems),
  hasSubItems: false,
  status: 'active',
  presentationType: 'scent_hub',
  shortTitle: 'Scent & Perfume',
  categoryName: 'Scent & Perfume',
  primaryAction: 'smelled',
  primaryActionLabel: 'Smelled',
  progressVerb: 'smelled',
  startLabel: 'Start smelling',
  continueLabel: 'Smell another',
  singularNoun: 'scent',
  pluralNoun: 'scents',
  iconIdentifier: 'perfume',
);

/// Replaces the scent collections in [challenges] with a single hub, placed
/// where the first one was.
List<Challenge> groupScentChallenges(Iterable<Challenge> challenges) {
  final list = challenges.toList();
  final scent = list.where(isScentChallenge).toList();
  if (scent.isEmpty) return list;
  final grouped = <Challenge>[];
  var hubAdded = false;
  for (final challenge in list) {
    if (!isScentChallenge(challenge)) {
      grouped.add(challenge);
    } else if (!hubAdded) {
      grouped.add(scentHub(scent));
      hubAdded = true;
    }
  }
  return grouped;
}

typedef ProgressLookup = ({int completed, int total})? Function(String id);

/// Adapts the summary map Explore and the hub use.
ProgressLookup summaryLookup(Map<String, ChallengeProgressSummary> progress) =>
    (id) {
      final p = progress[id];
      return p == null ? null : (completed: p.completed, total: p.total);
    };

/// Completed and total for a challenge, summing the scent collections for
/// the hub.
({int completed, int total}) groupedProgress(
  Challenge challenge,
  ProgressLookup progress,
  Iterable<Challenge> allChallenges,
) {
  if (challenge.id != scentHubId) {
    final p = progress(challenge.id);
    return (
      completed: p?.completed ?? 0,
      total: p?.total ?? challenge.totalItems,
    );
  }
  var completed = 0;
  var total = 0;
  for (final c in allChallenges.where(isScentChallenge)) {
    completed += progress(c.id)?.completed ?? 0;
    total += progress(c.id)?.total ?? c.totalItems;
  }
  return (completed: completed, total: total);
}
