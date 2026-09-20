import 'package:shared_preferences/shared_preferences.dart';

import '../models/fruit_identity.dart';

class ProgressService {
  static const String _completedFruitIdsKey = 'completed_fruit_ids';
  static const String _completedVarietyIdsKey = 'completed_variety_ids';
  static const String _completedJyotirlingaIdsKey = 'completed_jyotirlinga_ids';
  static const String _savedChallengeIdsKey = 'saved_challenge_ids';
  static const String _savedEntityReferencesKey = 'saved_entity_references';
  static const String _completedYogaPoseIdsKey = 'completed_yoga_pose_ids';
  static const String _completedExperienceIdsKey = 'completed_experience_ids';
  static const String _completedDistrictIdsKey = 'completed_district_ids';

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
    return _setCompletedIds(_completedYogaPoseIdsKey, ids);
  }

  static Future<Set<String>> getCompletedExperienceIds() {
    return _getCompletedIds(_completedExperienceIdsKey);
  }

  static Future<void> setCompletedExperienceIds(Set<String> ids) {
    return _setCompletedIds(_completedExperienceIdsKey, ids);
  }

  static Future<bool> toggleExperience(String experienceId) async {
    final completedIds = await getCompletedExperienceIds();
    if (!completedIds.remove(experienceId)) completedIds.add(experienceId);
    await setCompletedExperienceIds(completedIds);
    return completedIds.contains(experienceId);
  }

  static Future<Set<String>> getCompletedDistrictIds() {
    return _getCompletedIds(_completedDistrictIdsKey);
  }

  static Future<void> setCompletedDistrictIds(Set<String> ids) {
    return _setCompletedIds(_completedDistrictIdsKey, ids);
  }

  static Future<bool> toggleDistrict(String districtId) async {
    final completedIds = await getCompletedDistrictIds();
    if (!completedIds.remove(districtId)) completedIds.add(districtId);
    await setCompletedDistrictIds(completedIds);
    return completedIds.contains(districtId);
  }

  static Future<Set<String>> getChallengeItemIds(String? progressKey) {
    if (progressKey == null || progressKey.isEmpty) return Future.value({});
    return _getCompletedIds(progressKey);
  }

  static Future<void> setChallengeItemIds(
    String? progressKey,
    Set<String> ids,
  ) {
    if (progressKey == null || progressKey.isEmpty) return Future.value();
    return _setCompletedIds(progressKey, ids);
  }

  static Future<bool> toggleChallengeItem(
    String? progressKey,
    String itemId,
  ) async {
    if (progressKey == null || progressKey.isEmpty) return false;
    final completedIds = await getChallengeItemIds(progressKey);
    if (!completedIds.remove(itemId)) completedIds.add(itemId);
    await setChallengeItemIds(progressKey, completedIds);
    return completedIds.contains(itemId);
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

  static Future<void> setCompletedFruitIds(Set<String> ids) {
    return _setCompletedIds(
      _completedFruitIdsKey,
      ids.map(FruitIdentity.canonicalId).toSet(),
    );
  }

  static Future<void> setCompletedVarietyIds(Set<String> ids) {
    return _setCompletedIds(_completedVarietyIdsKey, ids);
  }

  static Future<void> setCompletedJyotirlingaIds(Set<String> ids) {
    return _setCompletedIds(_completedJyotirlingaIdsKey, ids);
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

  static Future<Set<String>> _getCompletedIds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? []).toSet();
  }

  static Future<void> _setCompletedIds(String key, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, ids.toList());
  }
}
