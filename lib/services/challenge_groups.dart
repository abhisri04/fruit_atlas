import '../models/challenge.dart';
import 'progress_summary_service.dart';

/// A category whose collections show as one tile that opens a hub page,
/// rather than as separate tiles.
class CategoryHub {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String intro;
  final String iconIdentifier;
  final String progressVerb;

  const CategoryHub({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.intro,
    required this.iconIdentifier,
    required this.progressVerb,
  });
}

const scentHubId = 'scent_hub';
const scentCategoryId = 'scent';
const gardenHubId = 'garden_hub';
const gardenCategoryId = 'garden';

const categoryHubs = <String, CategoryHub>{
  scentCategoryId: CategoryHub(
    id: scentHubId,
    categoryId: scentCategoryId,
    name: 'Scent & Perfume',
    description:
        'Learn the families, smell famous perfumes and real ingredients, try '
        'Indian attars, and build your own collection.',
    intro: 'New to perfume? Start with Scent Families.',
    iconIdentifier: 'perfume',
    progressVerb: 'smelled',
  ),
  gardenCategoryId: CategoryHub(
    id: gardenHubId,
    categoryId: gardenCategoryId,
    name: 'Garden & Plants',
    description:
        'Find a way to garden that fits your space, grow plants through the '
        'Indian seasons, learn the skills and visit famous gardens.',
    intro: 'New to gardening? Start with Ways to Garden.',
    iconIdentifier: 'garden',
    progressVerb: 'done',
  ),
};

bool isHubId(String id) => categoryHubs.values.any((hub) => hub.id == id);

CategoryHub? hubForId(String id) =>
    categoryHubs.values.where((hub) => hub.id == id).firstOrNull;

/// A collection that belongs to a hub (not the hub tile itself).
bool isHubbedChallenge(Challenge challenge) =>
    categoryHubs.containsKey(challenge.categoryId) && !isHubId(challenge.id);

bool isScentChallenge(Challenge challenge) =>
    challenge.categoryId == scentCategoryId && !isHubId(challenge.id);

/// The hub tile for [hub], summarising its member collections.
Challenge hubChallenge(CategoryHub hub, Iterable<Challenge> members) =>
    Challenge(
      id: hub.id,
      categoryId: hub.categoryId,
      name: hub.name,
      description: hub.description,
      itemType: 'category_hub',
      totalItems: members.fold(0, (sum, c) => sum + c.totalItems),
      hasSubItems: false,
      status: 'active',
      presentationType: 'category_hub',
      shortTitle: hub.name,
      categoryName: hub.name,
      progressVerb: hub.progressVerb,
      iconIdentifier: hub.iconIdentifier,
    );

Challenge scentHub(Iterable<Challenge> scent) =>
    hubChallenge(categoryHubs[scentCategoryId]!, scent);

/// Replaces each hub category's collections with a single hub tile, placed
/// where the first of them was.
List<Challenge> groupHubChallenges(Iterable<Challenge> challenges) {
  final list = challenges.toList();
  final added = <String>{};
  final grouped = <Challenge>[];
  for (final challenge in list) {
    if (!isHubbedChallenge(challenge)) {
      grouped.add(challenge);
      continue;
    }
    final hub = categoryHubs[challenge.categoryId]!;
    if (added.add(hub.id)) {
      grouped.add(
        hubChallenge(
          hub,
          list.where((c) => c.categoryId == hub.categoryId && !isHubId(c.id)),
        ),
      );
    }
  }
  return grouped;
}

/// Older name, kept for callers written when only Scent had a hub.
List<Challenge> groupScentChallenges(Iterable<Challenge> challenges) =>
    groupHubChallenges(challenges);

typedef ProgressLookup = ({int completed, int total})? Function(String id);

/// Adapts the summary map Explore and the hubs use.
ProgressLookup summaryLookup(Map<String, ChallengeProgressSummary> progress) =>
    (id) {
      final p = progress[id];
      return p == null ? null : (completed: p.completed, total: p.total);
    };

/// Completed and total for a challenge, summing a hub's collections.
({int completed, int total}) groupedProgress(
  Challenge challenge,
  ProgressLookup progress,
  Iterable<Challenge> allChallenges,
) {
  final hub = hubForId(challenge.id);
  if (hub == null) {
    final p = progress(challenge.id);
    return (
      completed: p?.completed ?? 0,
      total: p?.total ?? challenge.totalItems,
    );
  }
  var completed = 0;
  var total = 0;
  for (final c in allChallenges.where(
    (c) => c.categoryId == hub.categoryId && !isHubId(c.id),
  )) {
    completed += progress(c.id)?.completed ?? 0;
    total += progress(c.id)?.total ?? c.totalItems;
  }
  return (completed: completed, total: total);
}
