import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/fruit_identity.dart';
import '../models/indian_dish.dart';
import '../models/indian_drink.dart';
import '../models/item_action_progress.dart';
import '../models/book.dart';
import '../models/celebration_event.dart';
import 'celebration_service.dart';
import 'indian_dishes_repository.dart';
import 'indian_drinks_repository.dart';
import 'state_travel_service.dart';
import '../models/state_travel_status.dart';
import '../models/india_location_registry.dart';

class ProgressService {
  static const String _categoryProgressPrefix = 'category_item_progress_v1_';
  static const String _completedFruitIdsKey = 'completed_fruit_ids';
  static const String _completedVarietyIdsKey = 'completed_variety_ids';
  static const String _completedJyotirlingaIdsKey = 'completed_jyotirlinga_ids';
  static const String _savedChallengeIdsKey = 'saved_challenge_ids';
  static const String _savedEntityReferencesKey = 'saved_entity_references';
  static const String _completedYogaPoseIdsKey = 'completed_yoga_pose_ids';
  static const String _completedExperienceIdsKey = 'completed_experience_ids';
  static const String _completedDistrictIdsKey = 'completed_district_ids';
  static const String _rewardedEventIdsKey = 'rewarded_event_ids_v1';
  static const String _activityDatesKey = 'meaningful_activity_dates_v1';
  static const String _activityEventsKey = 'meaningful_activity_events_v1';
  static const String _bookProgressKey = 'book_progress_v1';

  static Future<Map<String, BookProgress>> getBookProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_bookProgressKey);
    if (encoded == null || encoded.isEmpty) return {};
    final data = jsonDecode(encoded) as Map<String, dynamic>;
    return data.map(
      (id, value) =>
          MapEntry(id, BookProgress.fromJson(value as Map<String, dynamic>)),
    );
  }

  static Future<BookProgress> setBookStatus({
    required Book book,
    required BookStatus status,
    BookLanguage? language,
    DateTime? now,
  }) async {
    final all = await getBookProgress();
    final previous = all[book.id] ?? BookProgress(bookId: book.id);
    final timestamp = (now ?? DateTime.now()).toLocal();
    final languages = {...previous.readLanguages};
    var selected = language;
    if (status == BookStatus.read) {
      selected ??= book.availableLanguages.length == 1
          ? book.availableLanguages.single
          : null;
      if (selected != null) languages.add(selected);
    }
    final updated = BookProgress(
      bookId: book.id,
      status: status,
      readLanguages: languages,
      currentLanguage: status == BookStatus.currentlyReading ? selected : null,
      firstReadAt:
          previous.firstReadAt ??
          (status == BookStatus.read ? timestamp : null),
      lastUpdatedAt: timestamp,
    );
    all[book.id] = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _bookProgressKey,
      jsonEncode(all.map((id, value) => MapEntry(id, value.toJson()))),
    );
    final saved = await getSavedEntityReferences();
    final reference = 'book:${book.id}';
    if (status == BookStatus.wantToRead) {
      saved.add(reference);
    } else {
      saved.remove(reference);
    }
    await _setCompletedIds(_savedEntityReferencesKey, saved);
    if (!previous.isRead && updated.isRead) {
      await recordMeaningfulCompletion('book:${book.id}', now: timestamp);
    }
    return updated;
  }

  static Future<BookProgress> addReadLanguage(
    Book book,
    BookLanguage language, {
    DateTime? now,
  }) => setBookStatus(
    book: book,
    status: BookStatus.read,
    language: language,
    now: now,
  );

  static Future<Set<String>> getCompletedFruitIds() async {
    final saved = await _getCompletedIds(_completedFruitIdsKey);
    final canonical = saved.map(FruitIdentity.canonicalId).toSet();
    if (canonical.length != saved.length || !canonical.containsAll(saved)) {
      await _setCompletedIds(_completedFruitIdsKey, canonical);
    }
    return canonical;
  }

  static Future<Set<String>> getCompletedVarietyIds() {
    return _getCompletedIds(_completedVarietyIdsKey);
  }

  static Future<Set<String>> getCompletedJyotirlingaIds() {
    return _getCompletedIds(_completedJyotirlingaIdsKey);
  }

  static Future<Set<String>> getSavedChallengeIds() {
    return _getCompletedIds(_savedChallengeIdsKey);
  }

  static Future<Set<String>> getSavedEntityReferences() async {
    final saved = await _getCompletedIds(_savedEntityReferencesKey);
    final canonical = saved.map(FruitIdentity.canonicalReference).toSet();
    if (canonical.length != saved.length || !canonical.containsAll(saved)) {
      await _setCompletedIds(_savedEntityReferencesKey, canonical);
    }
    return canonical;
  }

  static Future<bool> isEntitySaved(String reference) async {
    return (await getSavedEntityReferences()).contains(
      FruitIdentity.canonicalReference(reference),
    );
  }

  static Future<bool> toggleSavedEntity(String reference) async {
    reference = FruitIdentity.canonicalReference(reference);
    final saved = await getSavedEntityReferences();
    if (!saved.remove(reference)) saved.add(reference);
    await _setCompletedIds(_savedEntityReferencesKey, saved);
    return saved.contains(reference);
  }

  static Future<Set<String>> getCompletedYogaPoseIds() {
    return _getCompletedIds(_completedYogaPoseIdsKey);
  }

  static Future<void> setCompletedYogaPoseIds(Set<String> ids) {
    return setChallengeItemIds(_completedYogaPoseIdsKey, ids);
  }

  static Future<Set<String>> getCompletedExperienceIds() {
    return _getCompletedIds(_completedExperienceIdsKey);
  }

  static Future<void> setCompletedExperienceIds(Set<String> ids) =>
      _setCompletedIdsAndRecord(_completedExperienceIdsKey, ids, 'experience');

  static Future<bool> toggleExperience(String experienceId) async {
    final completedIds = await getCompletedExperienceIds();
    if (!completedIds.remove(experienceId)) completedIds.add(experienceId);
    await setCompletedExperienceIds(completedIds);
    return completedIds.contains(experienceId);
  }

  static Future<Set<String>> getCompletedDistrictIds() {
    return _getCompletedIds(_completedDistrictIdsKey);
  }

  static Future<void> setCompletedDistrictIds(Set<String> ids) =>
      _setCompletedIdsAndRecord(_completedDistrictIdsKey, ids, 'district');

  static Future<bool> toggleDistrict(String districtId) async {
    final completedIds = await getCompletedDistrictIds();
    if (!completedIds.remove(districtId)) completedIds.add(districtId);
    await setCompletedDistrictIds(completedIds);
    return completedIds.contains(districtId);
  }

  static Future<Set<String>> getChallengeItemIds(String? progressKey) async {
    if (progressKey == null || progressKey.isEmpty) return Future.value({});
    if (progressKey == StateTravelService.legacyKey) {
      final travel = StateTravelService();
      try {
        await travel.load();
        return travel.visitedIds;
      } finally {
        travel.dispose();
      }
    }
    return _getCompletedIds(progressKey);
  }

  static Future<void> setChallengeItemIds(
    String? progressKey,
    Set<String> ids,
  ) async {
    if (progressKey == null || progressKey.isEmpty) return;
    if (progressKey == StateTravelService.legacyKey) {
      final travel = StateTravelService();
      try {
        await travel.load();
        final valid = ids.intersection(IndiaLocationRegistry.allLocationIds);
        for (final id in travel.visitedIds.difference(valid)) {
          await travel.setStatus(id, TravelStatus.none);
        }
        for (final id in valid) {
          await travel.setStatus(id, TravelStatus.visited);
        }
      } finally {
        travel.dispose();
      }
      return;
    }
    final previous = await _getCompletedIds(progressKey);
    await _setCompletedIds(progressKey, ids);
    final prefix = _completionPrefixForProgressKey(progressKey);
    if (prefix != null) {
      for (final id in ids.difference(previous)) {
        await recordMeaningfulCompletion('$prefix:$id');
      }
    }
    if (progressKey == gardenVisitProgressKey) {
      await _stampPassportForGardenVisits(ids.difference(previous));
    }
  }

  static const gardenVisitProgressKey = 'completed_garden_visit_ids';

  /// The state a garden visit id (`visit_<stateId>_<garden>`) belongs to.
  static String? stateForGardenVisit(String visitId) {
    if (!visitId.startsWith('visit_')) return null;
    final rest = visitId.substring('visit_'.length);
    String? best;
    for (final id in IndiaLocationRegistry.allLocationIds) {
      if (rest.startsWith('${id}_') && id.length > (best?.length ?? 0)) {
        best = id;
      }
    }
    return best;
  }

  /// Visiting a garden stamps its state. Unmarking a garden leaves the stamp:
  /// the user was still there, and the passport is theirs to edit.
  static Future<void> _stampPassportForGardenVisits(Set<String> added) async {
    final states = added.map(stateForGardenVisit).whereType<String>().toSet();
    if (states.isEmpty) return;
    final travel = StateTravelService();
    try {
      await travel.load();
      for (final id in states) {
        if (travel.statusFor(id) != TravelStatus.visited) {
          await travel.setStatus(id, TravelStatus.visited);
        }
      }
    } finally {
      travel.dispose();
    }
  }

  static Future<bool> toggleChallengeItem(
    String? progressKey,
    String itemId,
  ) async {
    if (progressKey == null || progressKey.isEmpty) return false;
    final completedIds = await getChallengeItemIds(progressKey);
    if (!completedIds.remove(itemId)) completedIds.add(itemId);
    await setChallengeItemIds(progressKey, completedIds);
    return (await getChallengeItemIds(progressKey)).contains(itemId);
  }

  static Future<bool> isChallengeSaved(String challengeId) async {
    return (await getSavedChallengeIds()).contains(challengeId);
  }

  static Future<bool> toggleSavedChallenge(String challengeId) async {
    final savedIds = await getSavedChallengeIds();
    if (!savedIds.remove(challengeId)) {
      savedIds.add(challengeId);
    }
    await _setCompletedIds(_savedChallengeIdsKey, savedIds);
    return savedIds.contains(challengeId);
  }

  static Future<Map<String, ItemActionProgress>> getCategoryItemProgress(
    String categoryId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('$_categoryProgressPrefix$categoryId');
    if (encoded == null || encoded.isEmpty) return {};
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    return json.map(
      (id, value) => MapEntry(
        id,
        ItemActionProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  /// Returns the single canonical dish progress store and safely folds in
  /// progress saved under legacy state-experience or seed IDs.
  static Future<Map<String, ItemActionProgress>> getDishProgress(
    IndianDishesCatalogue catalogue,
  ) async {
    final saved = await getCategoryItemProgress(catalogue.category.id);
    final completedExperiences = await getCompletedExperienceIds();
    final canonicalByLegacyId = <String, String>{
      for (final dish in catalogue.dishes)
        for (final legacyId in {dish.id, ...dish.legacyIds}) legacyId: dish.id,
    };
    final migrated = <String, ItemActionProgress>{};
    var changed = false;

    for (final entry in saved.entries) {
      final canonicalId = canonicalByLegacyId[entry.key] ?? entry.key;
      final previous = migrated[canonicalId];
      migrated[canonicalId] = previous == null
          ? entry.value
          : previous.merge(entry.value);
      if (canonicalId != entry.key || previous != null) changed = true;
    }
    for (final legacyId in completedExperiences) {
      final canonicalId = canonicalByLegacyId[legacyId];
      if (canonicalId == null) continue;
      final previous = migrated[canonicalId] ?? const ItemActionProgress();
      if (!previous.tried) {
        migrated[canonicalId] = previous.merge(
          const ItemActionProgress(tried: true),
        );
        changed = true;
      }
    }

    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_categoryProgressPrefix${catalogue.category.id}',
        jsonEncode(migrated.map((id, value) => MapEntry(id, value.toJson()))),
      );
    }
    return migrated;
  }

  /// Returns canonical drink progress and folds in completion saved against
  /// the former State/UT experience records.
  static Future<DrinkProgress> getDrinkProgress(
    IndianDrinksCatalogue catalogue,
  ) async {
    final saved = await getCategoryItemProgress(catalogue.category.id);
    final completedExperiences = await getCompletedExperienceIds();
    final canonicalByLegacyId = <String, String>{
      for (final drink in catalogue.drinks)
        for (final legacyId in {drink.id, ...drink.legacyIds})
          legacyId: drink.id,
    };
    final migrated = <String, ItemActionProgress>{};
    var changed = false;
    for (final entry in saved.entries) {
      final canonicalId = canonicalByLegacyId[entry.key] ?? entry.key;
      final previous = migrated[canonicalId];
      migrated[canonicalId] = previous == null
          ? entry.value
          : previous.merge(entry.value);
      if (canonicalId != entry.key || previous != null) changed = true;
    }
    for (final legacyId in completedExperiences) {
      final canonicalId = canonicalByLegacyId[legacyId];
      if (canonicalId == null) continue;
      final previous = migrated[canonicalId] ?? const ItemActionProgress();
      if (!previous.tried) {
        migrated[canonicalId] = previous.merge(
          const ItemActionProgress(tried: true),
        );
        changed = true;
      }
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_categoryProgressPrefix${catalogue.category.id}',
        jsonEncode(migrated.map((id, value) => MapEntry(id, value.toJson()))),
      );
    }
    return migrated;
  }

  static Future<ItemActionProgress> toggleCategoryItemAction({
    required String categoryId,
    required String itemId,
    required String action,
  }) async {
    final progress = await getCategoryItemProgress(categoryId);
    final previous = progress[itemId] ?? const ItemActionProgress();
    final updated = previous.toggle(action);
    progress[itemId] = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_categoryProgressPrefix$categoryId',
      jsonEncode(progress.map((id, value) => MapEntry(id, value.toJson()))),
    );
    if (!previous.tried && updated.tried) {
      final prefix = switch (categoryId) {
        IndianDishesRepository.categoryId => 'dish',
        IndianDrinksRepository.categoryId => 'drink',
        _ => null,
      };
      if (prefix != null) {
        await recordMeaningfulCompletion('$prefix:$itemId');
      }
    }
    return updated;
  }

  static Future<void> setCompletedFruitIds(Set<String> ids) async {
    final previous = await getCompletedFruitIds();
    final canonical = ids.map(FruitIdentity.canonicalId).toSet();
    await _setCompletedIds(_completedFruitIdsKey, canonical);
    for (final id in canonical.difference(previous)) {
      await recordMeaningfulCompletion('fruit:$id');
    }
  }

  static Future<void> setCompletedVarietyIds(Set<String> ids) =>
      _setCompletedIdsAndRecord(_completedVarietyIdsKey, ids, 'variety');

  static Future<void> setCompletedJyotirlingaIds(Set<String> ids) async {
    final previous = await getCompletedJyotirlingaIds();
    await _setCompletedIds(_completedJyotirlingaIdsKey, ids);
    for (final id in ids.difference(previous)) {
      await recordMeaningfulCompletion('jyotirlinga:$id');
    }
  }

  static Future<bool> isVarietyCompleted(String varietyId) async {
    final completedIds = await getCompletedVarietyIds();
    return completedIds.contains(varietyId);
  }

  static Future<bool> toggleVariety(String varietyId) async {
    final completedIds = await getCompletedVarietyIds();

    if (completedIds.contains(varietyId)) {
      completedIds.remove(varietyId);
    } else {
      completedIds.add(varietyId);
    }

    await setCompletedVarietyIds(completedIds);
    return completedIds.contains(varietyId);
  }

  static Future<Set<String>> getRewardedEventIds() =>
      _getCompletedIds(_rewardedEventIdsKey);

  static Future<Set<String>> ensureRewardEvents(
    Iterable<String> eventIds,
  ) async {
    final rewarded = await getRewardedEventIds();
    final added = eventIds.where(rewarded.add).toSet();
    if (added.isNotEmpty) {
      await _setCompletedIds(_rewardedEventIdsKey, rewarded);
    }
    return added;
  }

  static Future<bool> claimReward(String eventId) async =>
      (await ensureRewardEvents([eventId])).isNotEmpty;

  static Future<int> getRewardedXp() async {
    final rewarded = await getRewardedEventIds();
    return rewarded.fold<int>(0, (sum, event) {
      if (event.startsWith('completion:')) return sum + 10;
      if (event.startsWith('achievement:')) return sum + 25;
      if (event.startsWith('dailyQuest:')) return sum + 50;
      if (event.startsWith('practice:')) return sum + practiceXp;
      if (event.startsWith('milestone:')) return sum + milestoneXp;
      if (event.startsWith('collection:')) return sum + milestoneXp;
      return sum;
    });
  }

  static const practiceXp = 5;
  static const milestoneXp = 25;

  /// Records a logged hobby session: up to [practiceXp] once per hobby per
  /// day, plus activity for streaks and the daily quest.
  static Future<bool> recordHobbyPractice(
    String hobbyId,
    String hobbyName, {
    DateTime? now,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final date = _dateKey(localNow);
    final rewardId = 'practice:$hobbyId:$date';
    final added = await ensureRewardEvents([rewardId]);
    if (added.isNotEmpty) {
      CelebrationService.instance.emit(
        CelebrationEvent(
          id: rewardId,
          kind: CelebrationKind.canonicalCompletion,
          intensity: CelebrationIntensity.small,
          title: 'Practice logged',
          message: 'Another session of $hobbyName.',
          xp: practiceXp,
        ),
      );
    }
    await _recordActivity(localNow, 'hobby:$hobbyId');
    return added.isNotEmpty;
  }

  /// Records reaching a rung of a hobby's skill ladder, once per rung.
  static Future<bool> recordHobbyMilestone(
    String hobbyId,
    String levelLabel,
    String hobbyName, {
    DateTime? now,
  }) async {
    final rewardId = 'milestone:$hobbyId:$levelLabel';
    final added = await ensureRewardEvents([rewardId]);
    if (added.isNotEmpty) {
      CelebrationService.instance.emit(
        CelebrationEvent(
          id: rewardId,
          kind: CelebrationKind.milestone,
          intensity: CelebrationIntensity.medium,
          title: '$levelLabel!',
          message: 'You levelled up in $hobbyName.',
          xp: milestoneXp,
        ),
      );
      await _recordActivity(
        (now ?? DateTime.now()).toLocal(),
        'hobby:$hobbyId',
      );
    }
    return added.isNotEmpty;
  }

  /// Records wearing a perfume from My Collection: up to [practiceXp] once
  /// per day, plus activity for streaks and the daily quest.
  static Future<bool> recordScentWear(
    String perfumeName, {
    DateTime? now,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final rewardId = 'practice:perfume_collection:${_dateKey(localNow)}';
    final added = await ensureRewardEvents([rewardId]);
    if (added.isNotEmpty) {
      CelebrationService.instance.emit(
        CelebrationEvent(
          id: rewardId,
          kind: CelebrationKind.canonicalCompletion,
          intensity: CelebrationIntensity.small,
          title: 'Scent of the day',
          message: 'You wore $perfumeName today.',
          xp: practiceXp,
        ),
      );
    }
    await _recordActivity(localNow, 'hobby:perfume_collection');
    return added.isNotEmpty;
  }

  /// Any gardening logged today earns practice XP once a day and counts
  /// towards the day's activity.
  static Future<bool> recordGardenCare(
    String plantName, {
    DateTime? now,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final rewardId = 'practice:my_garden:${_dateKey(localNow)}';
    final added = await ensureRewardEvents([rewardId]);
    if (added.isNotEmpty) {
      CelebrationService.instance.emit(
        CelebrationEvent(
          id: rewardId,
          kind: CelebrationKind.canonicalCompletion,
          intensity: CelebrationIntensity.small,
          title: 'Garden time',
          message: 'You spent time with your $plantName today.',
          xp: practiceXp,
        ),
      );
    }
    await _recordActivity(localNow, 'hobby:my_garden');
    return added.isNotEmpty;
  }

  /// Rewards a collection milestone (perfume or garden) once.
  static Future<bool> recordCollectionMilestone(
    String milestoneId,
    String title,
    String message,
  ) async {
    final rewardId = 'collection:$milestoneId';
    final added = await ensureRewardEvents([rewardId]);
    if (added.isNotEmpty) {
      CelebrationService.instance.emit(
        CelebrationEvent(
          id: rewardId,
          kind: CelebrationKind.milestone,
          intensity: CelebrationIntensity.medium,
          title: title,
          message: message,
          xp: milestoneXp,
        ),
      );
    }
    return added.isNotEmpty;
  }

  /// Counts a day as active (for streaks and the activity calendar).
  static Future<void> recordActivity(DateTime at, String ref) =>
      _recordActivity(at.toLocal(), ref);

  static Future<void> _recordActivity(DateTime localNow, String ref) async {
    final date = _dateKey(localNow);
    final dates = await _getCompletedIds(_activityDatesKey);
    if (dates.add(date)) await _setCompletedIds(_activityDatesKey, dates);
    final events = await _getCompletedIds(_activityEventsKey);
    if (events.add('$date|$ref')) {
      await _setCompletedIds(_activityEventsKey, events);
    }
  }

  static Future<void> recordMeaningfulCompletion(
    String typedReference, {
    DateTime? now,
  }) async {
    final localNow = (now ?? DateTime.now()).toLocal();
    final date = _dateKey(localNow);
    final rewardId = 'completion:$typedReference';
    final added = await ensureRewardEvents([rewardId]);
    if (added.isNotEmpty) {
      CelebrationService.instance.emit(
        CelebrationEvent(
          id: rewardId,
          kind: CelebrationKind.canonicalCompletion,
          intensity: CelebrationIntensity.small,
          title: 'Experience complete',
          message: 'Another experience added to your Life.',
          xp: 10,
        ),
      );
    }
    final dates = await _getCompletedIds(_activityDatesKey);
    if (dates.add(date)) await _setCompletedIds(_activityDatesKey, dates);
    final events = await _getCompletedIds(_activityEventsKey);
    if (events.add('$date|$typedReference')) {
      await _setCompletedIds(_activityEventsKey, events);
    }
  }

  static Future<Set<String>> getActivityReferencesForDate(DateTime date) async {
    final key = _dateKey(date.toLocal());
    return (await _getCompletedIds(_activityEventsKey))
        .where((event) => event.startsWith('$key|'))
        .map((event) => event.substring(key.length + 1))
        .toSet();
  }

  /// Days with any activity, ever. Only grows, so it never feels like a loss.
  static Future<int> getActiveDayCount() async =>
      (await _getCompletedIds(_activityDatesKey)).length;

  static Future<({int current, int longest})> getStreak({DateTime? now}) async {
    final dates = (await _getCompletedIds(_activityDatesKey))
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    if (dates.isEmpty) return (current: 0, longest: 0);
    final ordered = dates.toList()..sort();
    var longest = 1;
    var run = 1;
    for (var index = 1; index < ordered.length; index++) {
      if (ordered[index].difference(ordered[index - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    var cursor = dates.contains(today)
        ? today
        : dates.contains(today.subtract(const Duration(days: 1)))
        ? today.subtract(const Duration(days: 1))
        : null;
    var current = 0;
    while (cursor != null && dates.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return (current: current, longest: longest);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String? _completionPrefixForProgressKey(String progressKey) =>
      switch (progressKey) {
        _completedYogaPoseIdsKey => 'yoga',
        'completed_india_state_ut_ids' => 'state',
        'completed_hobby_ids' => 'hobby',
        'completed_game_ids' => 'game',
        'completed_scent_family_ids' => 'scent',
        'completed_perfume_ids' => 'perfume',
        'completed_scent_note_ids' => 'note',
        'completed_attar_ids' => 'attar',
        'completed_garden_plant_ids' => 'plant',
        'completed_collection_type_ids' => 'collecting',
        'completed_make_ids' => 'make',
        'completed_garden_skill_ids' => 'gardenskill',
        'completed_garden_visit_ids' => 'gardenvisit',
        _ => null,
      };

  static Future<Set<String>> _getCompletedIds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? []).toSet();
  }

  /// Persists [ids] and records a meaningful completion (XP, streak and quest
  /// activity) for every newly added id. Removals never revoke rewards.
  static Future<void> _setCompletedIdsAndRecord(
    String key,
    Set<String> ids,
    String referencePrefix,
  ) async {
    final previous = await _getCompletedIds(key);
    await _setCompletedIds(key, ids);
    for (final id in ids.difference(previous)) {
      await recordMeaningfulCompletion('$referencePrefix:$id');
    }
  }

  static Future<void> _setCompletedIds(String key, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, ids.toList());
  }
}
