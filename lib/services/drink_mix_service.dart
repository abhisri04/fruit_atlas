import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mixed_drink.dart';
import 'progress_service.dart';

/// When you made a drink, and an optional note ("for Diwali night").
class DrinkMade {
  final DateTime at;
  final String? note;
  const DrinkMade(this.at, {this.note});

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  factory DrinkMade.fromJson(Map<String, dynamic> json) => DrinkMade(
    DateTime.parse(json['at'] as String).toLocal(),
    note: json['note'] as String?,
  );
}

/// The drink book, what you've made, and what's on your shelf. All of it stays
/// on this device.
abstract final class DrinkMixService {
  static const progressKey = 'completed_mixed_drink_ids';
  static const asset = 'assets/data/mixed_drinks.json';
  static const _madeKey = 'mixed_drinks_made_v1';
  static const _shelfKey = 'mixed_drinks_shelf_v1';
  static const _cocktailsKey = 'mixed_drinks_show_cocktails_v1';
  static final changes = ValueNotifier<int>(0);
  static DrinkBook? _book;

  static Future<DrinkBook> book() async => _book ??= DrinkBook.fromJson(
    jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>,
  );

  @visibleForTesting
  static void resetCache() => _book = null;

  static Future<Set<String>> madeIds() =>
      ProgressService.getChallengeItemIds(progressKey);

  static Future<Map<String, DrinkMade>> made() async {
    final raw = (await SharedPreferences.getInstance()).getString(_madeKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, DrinkMade.fromJson(v as Map<String, dynamic>)),
    );
  }

  static Future<void> _saveMade(Map<String, DrinkMade> all) async {
    await (await SharedPreferences.getInstance()).setString(
      _madeKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// One tap: mark a drink made, or untick it.
  static Future<void> setMade(String id, bool isMade, {DateTime? at}) async {
    final ids = await madeIds();
    final all = await made();
    if (isMade) {
      ids.add(id);
      all[id] = DrinkMade(
        at ?? all[id]?.at ?? DateTime.now(),
        note: all[id]?.note,
      );
    } else {
      ids.remove(id);
      all.remove(id);
    }
    await ProgressService.setChallengeItemIds(progressKey, ids);
    await _saveMade(all);
    changes.value++;
  }

  static Future<void> setNote(String id, String note) async {
    final all = await made();
    final current = all[id];
    if (current == null) return;
    all[id] = DrinkMade(current.at, note: note.trim());
    await _saveMade(all);
    changes.value++;
  }

  /// Ingredients you have at home.
  static Future<Set<String>> shelf() async =>
      ((await SharedPreferences.getInstance()).getStringList(_shelfKey) ??
              const [])
          .toSet();

  static Future<void> setOnShelf(String ingredientId, bool have) async {
    final s = await shelf();
    have ? s.add(ingredientId) : s.remove(ingredientId);
    await (await SharedPreferences.getInstance()).setStringList(
      _shelfKey,
      s.toList()..sort(),
    );
    changes.value++;
  }

  /// null until asked: cocktails stay hidden until you choose to see them.
  static Future<bool?> showCocktails() async =>
      (await SharedPreferences.getInstance()).getBool(_cocktailsKey);

  static Future<void> setShowCocktails(bool show) async {
    await (await SharedPreferences.getInstance()).setBool(_cocktailsKey, show);
    changes.value++;
  }
}
