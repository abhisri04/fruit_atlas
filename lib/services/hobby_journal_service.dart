import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hobby_journal.dart';
import 'hobby_repository.dart';
import 'progress_service.dart';

const _levelLabels = ['Tried', 'Learning', 'Practising', 'Confident'];

/// My Hobbies storage: which hobbies someone tracks, their sessions and
/// how far up the skill ladder they are. Local to the device.
abstract final class HobbyJournalService {
  static const _key = 'hobby_journal_v1';

  /// Bumped on every change so open screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static Future<Map<String, HobbyRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map(
      (id, value) =>
          MapEntry(id, HobbyRecord.fromJson(value as Map<String, dynamic>)),
    );
  }

  static Future<HobbyRecord?> get(String hobbyId) async =>
      (await load())[hobbyId];

  static Future<void> _save(Map<String, HobbyRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(records.map((id, record) => MapEntry(id, record.toJson()))),
    );
    changes.value++;
  }

  static Future<HobbyRecord> _update(
    String hobbyId,
    HobbyRecord Function(HobbyRecord) change,
  ) async {
    final records = await load();
    final current = records[hobbyId];
    if (current == null) throw StateError('Not tracking $hobbyId');
    final updated = change(current);
    records[hobbyId] = updated;
    await _save(records);
    return updated;
  }

  /// Starts tracking a hobby with a 7-day starter. Restarting a paused or
  /// dropped hobby keeps its history.
  static Future<HobbyRecord> start({
    required String hobbyId,
    required String name,
    String? group,
    bool custom = false,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toLocal();
    final records = await load();
    final existing = records[hobbyId];
    final record = existing == null
        ? HobbyRecord(
            hobbyId: hobbyId,
            name: name,
            group: group,
            custom: custom,
            startedAt: at,
          )
        : existing.copyWith(
            status: HobbyStatus.active,
            startedAt: existing.status == HobbyStatus.dropped ? at : null,
            starterDecided: existing.status == HobbyStatus.dropped
                ? false
                : null,
          );
    records[hobbyId] = record;
    await _save(records);
    return record;
  }

  /// Adds a hobby the person already does, at their current [level]. No
  /// starter week is needed.
  static Future<HobbyRecord> addExisting({
    required String hobbyId,
    required String name,
    String? group,
    bool custom = false,
    int level = 0,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toLocal();
    final records = await load();
    final previous = records[hobbyId];
    records[hobbyId] = HobbyRecord(
      hobbyId: hobbyId,
      name: name,
      group: group,
      custom: custom,
      startedAt: previous?.startedAt ?? at,
      level: level,
      sessions: previous?.sessions ?? const [],
      starterDecided: true,
    );
    await _save(records);
    if (!custom && level >= 0) await _markTried(hobbyId);
    return records[hobbyId]!;
  }

  static Future<HobbyRecord> logSession(
    String hobbyId, {
    int? minutes,
    String? note,
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toLocal();
    final updated = await _update(
      hobbyId,
      (r) => r.copyWith(
        status: HobbyStatus.active,
        sessions: [
          ...r.sessions,
          HobbySession(at: at, minutes: minutes, note: note?.trim()),
        ],
      ),
    );
    await ProgressService.recordHobbyPractice(hobbyId, updated.name, now: at);
    // Practising a catalogue hobby means you've tried it.
    if (!updated.custom && updated.level < 0) {
      return reachLevel(hobbyId, 0, now: at);
    }
    return updated;
  }

  /// Moves up the ladder to [level] (never down) and rewards each new rung.
  static Future<HobbyRecord> reachLevel(
    String hobbyId,
    int level, {
    DateTime? now,
  }) async {
    final before = await get(hobbyId);
    if (before == null) throw StateError('Not tracking $hobbyId');
    final target = level.clamp(0, _levelLabels.length - 1);
    if (target <= before.level) return before;
    final updated = await _update(hobbyId, (r) => r.copyWith(level: target));
    for (var rung = before.level + 1; rung <= target; rung++) {
      if (rung == 0) {
        if (!updated.custom) await _markTried(hobbyId);
      } else {
        await ProgressService.recordHobbyMilestone(
          hobbyId,
          _levelLabels[rung],
          updated.name,
          now: now,
        );
      }
    }
    return updated;
  }

  static Future<HobbyRecord> decideStarter(
    String hobbyId, {
    required bool keep,
  }) => _update(
    hobbyId,
    (r) => r.copyWith(
      starterDecided: true,
      status: keep ? HobbyStatus.active : HobbyStatus.dropped,
    ),
  );

  static Future<HobbyRecord> setStatus(String hobbyId, HobbyStatus status) =>
      _update(hobbyId, (r) => r.copyWith(status: status));

  static Future<void> remove(String hobbyId) async {
    final records = await load();
    if (records.remove(hobbyId) != null) await _save(records);
  }

  /// Ticks the catalogue "tried" checklist, which also awards completion XP.
  static Future<void> _markTried(String hobbyId) async {
    final key = hobbyId.startsWith('game_')
        ? HobbyRepository.gamesProgressKey
        : HobbyRepository.progressKey;
    final ids = await ProgressService.getChallengeItemIds(key);
    if (ids.contains(hobbyId)) return;
    await ProgressService.setChallengeItemIds(key, {...ids, hobbyId});
  }

  static String levelLabel(int level) =>
      level < 0 ? 'Just starting' : _levelLabels[level.clamp(0, 3)];
}
