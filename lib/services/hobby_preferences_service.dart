import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hobby_preferences.dart';

/// Stores the hobby finder answers and the hobbies a person said "not for me"
/// to, so Pick for me stops suggesting them.
abstract final class HobbyPreferencesService {
  static const _preferencesKey = 'hobby_preferences_v1';
  static const _skippedKey = 'hobby_skipped_ids_v1';

  static Future<HobbyPreferences?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferencesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return HobbyPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  static Future<void> save(HobbyPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey, jsonEncode(preferences.toJson()));
  }

  static Future<Set<String>> skippedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_skippedKey) ?? const []).toSet();
  }

  static Future<void> skip(String hobbyId) async {
    final prefs = await SharedPreferences.getInstance();
    final skipped = (prefs.getStringList(_skippedKey) ?? const []).toSet()
      ..add(hobbyId);
    await prefs.setStringList(_skippedKey, skipped.toList());
  }

  static Future<void> clearSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skippedKey);
  }
}
