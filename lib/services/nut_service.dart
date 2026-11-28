import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/nut.dart';
import 'progress_service.dart';

/// When and where you tasted a nut.
class NutTasting {
  final DateTime at;
  final String? note;
  const NutTasting(this.at, {this.note});

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    if (note != null && note!.isNotEmpty) 'note': note,
  };

  factory NutTasting.fromJson(Map<String, dynamic> json) => NutTasting(
    DateTime.parse(json['at'] as String).toLocal(),
    note: json['note'] as String?,
  );
}

/// Loads the nut atlas and keeps the record of what you've tasted, on this
/// device only.
abstract final class NutService {
  static const progressKey = 'completed_nut_ids';
  static const kindsKey = 'completed_nut_kind_ids';
  static const asset = 'assets/data/nuts.json';
  static const _tastingsKey = 'nut_tastings_v1';
  static final changes = ValueNotifier<int>(0);
  static NutAtlas? _atlas;

  static Future<NutAtlas> atlas() async => _atlas ??= NutAtlas.fromJson(
    jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>,
  );

  @visibleForTesting
  static void resetCache() => _atlas = null;

  static Future<Set<String>> triedIds() =>
      ProgressService.getChallengeItemIds(progressKey);

  static Future<Map<String, NutTasting>> tastings() async {
    final raw = (await SharedPreferences.getInstance()).getString(_tastingsKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, NutTasting.fromJson(v as Map<String, dynamic>)),
    );
  }

  static Future<void> _saveTastings(Map<String, NutTasting> all) async {
    await (await SharedPreferences.getInstance()).setString(
      _tastingsKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// One tap: mark a nut tasted (with an optional note), or untick it.
  static Future<void> setTried(
    String id,
    bool tried, {
    String? note,
    DateTime? at,
  }) async {
    final ids = await triedIds();
    final all = await tastings();
    if (tried) {
      ids.add(id);
      all[id] = NutTasting(
        at ?? all[id]?.at ?? DateTime.now(),
        note: note ?? all[id]?.note,
      );
    } else {
      ids.remove(id);
      all.remove(id);
    }
    await ProgressService.setChallengeItemIds(progressKey, ids);
    await _saveTastings(all);
    changes.value++;
  }

  static Future<Set<String>> triedKindIds() =>
      ProgressService.getChallengeItemIds(kindsKey);

  /// Tick a kind (Mamra, W180…). Tasting a kind counts as tasting the nut.
  static Future<void> setKindTried(
    String nutId,
    String kindId,
    bool tried,
  ) async {
    final ids = await triedKindIds();
    tried ? ids.add(kindId) : ids.remove(kindId);
    await ProgressService.setChallengeItemIds(kindsKey, ids);
    if (tried && !(await triedIds()).contains(nutId)) {
      await setTried(nutId, true);
    } else {
      changes.value++;
    }
  }

  static Future<void> setNote(String id, String note) async {
    final all = await tastings();
    final current = all[id];
    if (current == null) return;
    all[id] = NutTasting(current.at, note: note.trim());
    await _saveTastings(all);
    changes.value++;
  }
}
