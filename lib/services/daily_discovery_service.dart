import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_discovery.dart';
import 'asset_data_service.dart';
import 'challenge_repository.dart';
import 'progress_service.dart';

class DailyDiscoveryService {
  static const _dateKey = 'daily_discovery_date';
  static const _currentKey = 'daily_discovery_current_ref';
  static const _shownKey = 'daily_discovery_shown_today';

  final AssetDataService data;
  final ChallengeRepository challenges;
  final DateTime Function() now;

  const DailyDiscoveryService({
    this.data = const AssetDataService(),
    this.challenges = const ChallengeRepository(),
    this.now = DateTime.now,
  });

  Future<List<DailyDiscovery>> buildEligiblePool() =>
      _buildPool(excludeCompleted: true);

  Future<List<DailyDiscovery>> buildCanonicalPool() =>
      _buildPool(excludeCompleted: false);

  Future<List<DailyDiscovery>> _buildPool({
    required bool excludeCompleted,
  }) async {
    final fruitData = await data.loadFruitData();
    final loadedChallenges = await challenges.loadChallenges();
    final yogaChallenge = loadedChallenges
        .where((challenge) => challenge.itemType == 'yoga_pose')
        .firstOrNull;
    final yogaItems = yogaChallenge == null
        ? const []
        : await data.loadChallengeItems(yogaChallenge);
    final completedFruits = await ProgressService.getCompletedFruitIds();
    final completedVarieties = await ProgressService.getCompletedVarietyIds();
    final completedYoga = await ProgressService.getCompletedYogaPoseIds();
    final recommendations = <DailyDiscovery>[];

    for (final fruit in fruitData.fruits) {
      final fruitId = fruit.id.isEmpty ? fruit.name : fruit.id;
      if (!excludeCompleted || !completedFruits.contains(fruitId)) {
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.fruit,
            canonicalId: fruitId,
            title: fruit.name,
            subtitle: fruit.scientificName.isEmpty
                ? 'Fruit to discover'
                : fruit.scientificName,
            fruit: fruit,
          ),
        );
      }
      for (final variety in fruit.varieties) {
        final varietyId = variety.id;
        if (varietyId == null ||
            varietyId.isEmpty ||
            (excludeCompleted && completedVarieties.contains(varietyId))) {
          continue;
        }
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.variety,
            canonicalId: varietyId,
            title: variety.name,
            subtitle: 'Variety of ${fruit.name}',
            fruit: fruit,
            variety: variety,
          ),
        );
      }
    }

    if (yogaChallenge != null) {
      for (final pose in yogaItems) {
        if (excludeCompleted && completedYoga.contains(pose.id)) continue;
        recommendations.add(
          DailyDiscovery(
            type: DailyDiscoveryType.yogaPose,
            canonicalId: pose.id,
            title: pose.name,
            subtitle: [
              pose.category,
              pose.difficulty,
            ].whereType<String>().join(' · '),
            yogaPose: pose,
            yogaChallenge: yogaChallenge,
          ),
        );
      }
    }

    final unique = <String, DailyDiscovery>{
      for (final recommendation in recommendations)
        recommendation.reference: recommendation,
    };
    final result = unique.values.toList()
      ..sort((a, b) => a.reference.compareTo(b.reference));
    return result;
  }

  Future<DailyDiscovery?> getToday() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _localDate(now());
    final storedDate = preferences.getString(_dateKey);
    final storedReference = preferences.getString(_currentKey);
    final eligible = await buildEligiblePool();
    if (eligible.isEmpty) {
      await preferences.setString(_dateKey, today);
      await preferences.remove(_currentKey);
      await preferences.setStringList(_shownKey, const []);
      return null;
    }

    if (storedDate == today && storedReference != null) {
      final existing = eligible.where(
        (item) => item.reference == storedReference,
      );
      if (existing.isNotEmpty) return existing.first;
    }

    final yesterdayReference = storedDate == today ? null : storedReference;
    final candidates = eligible.length > 1 && yesterdayReference != null
        ? eligible
              .where((item) => item.reference != yesterdayReference)
              .toList()
        : eligible;
    final selected = candidates[_dayNumber(now()) % candidates.length];
    await _persist(preferences, today, selected.reference, [
      selected.reference,
    ]);
    return selected;
  }

  Future<DailyDiscovery?> another() async {
    final current = await getToday();
    if (current == null) return null;
    final preferences = await SharedPreferences.getInstance();
    final eligible = await buildEligiblePool();
    if (eligible.length == 1) return current;
    final shown = preferences.getStringList(_shownKey)?.toSet() ?? <String>{};
    var candidates = eligible
        .where(
          (item) =>
              item.reference != current.reference &&
              !shown.contains(item.reference),
        )
        .toList();
    if (candidates.isEmpty) {
      candidates = eligible
          .where((item) => item.reference != current.reference)
          .toList();
      shown
        ..clear()
        ..add(current.reference);
    }
    final selected =
        candidates[(_dayNumber(now()) + shown.length) % candidates.length];
    shown.add(selected.reference);
    await _persist(
      preferences,
      _localDate(now()),
      selected.reference,
      shown.toList()..sort(),
    );
    return selected;
  }

  Future<void> _persist(
    SharedPreferences preferences,
    String date,
    String reference,
    List<String> shown,
  ) async {
    await preferences.setString(_dateKey, date);
    await preferences.setString(_currentKey, reference);
    await preferences.setStringList(_shownKey, shown);
  }

  String _localDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  int _dayNumber(DateTime value) => DateTime(
    value.year,
    value.month,
    value.day,
  ).difference(DateTime(2000)).inDays;
}
