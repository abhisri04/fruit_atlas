import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/india_location_registry.dart';
import '../models/state_travel_status.dart';
import 'progress_service.dart';

/// Physical visits reuse state completion identities; experiences stay separate.
class StateTravelService extends ChangeNotifier {
  static const storageKey = 'india_passport_status_v1';
  static const legacyKey = 'completed_india_state_ut_ids';
  static const migrationKey = 'india_passport_legacy_migrated_v1';
  static final changes = ValueNotifier<int>(0);
  static Future<void>? _operations;
  final Map<String, StateTravelStatus> _states = {};
  bool _disposed = false;
  TravelStatus statusFor(String id) => _states[id]?.status ?? TravelStatus.none;
  Set<String> get visitedIds => {
    for (final s in _states.values)
      if (s.status == TravelStatus.visited) s.stateId,
  };
  int get visitedCount => visitedIds.length;
  Set<String> get wantToVisitIds => {
    for (final s in _states.values)
      if (s.status == TravelStatus.wantToVisit) s.stateId,
  };

  /// When a state's status was last set (for visited states, when it was
  /// stamped), if known.
  DateTime? markedAt(String id) => _states[id]?.updatedAt;
  int get wantToVisitCount =>
      _states.values.where((s) => s.status == TravelStatus.wantToVisit).length;

  static Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _operations == null
        ? action()
        : _operations!.then((_) => action());
    late final Future<void> pending;
    void release() {
      if (identical(_operations, pending)) _operations = null;
    }

    pending = result.then<void>(
      (_) => release(),
      onError: (Object _, StackTrace _) => release(),
    );
    _operations = pending;
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static Future<Map<String, StateTravelStatus>> _read(
    SharedPreferences prefs,
  ) async {
    final states = <String, StateTravelStatus>{};
    final encoded = prefs.getString(storageKey);
    if (encoded != null) {
      try {
        final data = jsonDecode(encoded);
        if (data is Map) {
          for (final entry in data.entries) {
            if (!IndiaLocationRegistry.allLocationIds.contains(entry.key) ||
                entry.value is! Map) {
              continue;
            }
            final value = entry.value as Map;
            states[entry.key as String] = StateTravelStatus(
              stateId: entry.key as String,
              status: TravelStatus.parse(value['status']),
              updatedAt: DateTime.tryParse('${value['updatedAt']}')?.toLocal(),
            );
          }
        }
      } on FormatException {
        /* Recover invalid JSON without touching other progress. */
      }
    }
    if (!(prefs.getBool(migrationKey) ?? false)) {
      final legacy = (prefs.getStringList(legacyKey) ?? [])
          .toSet()
          .intersection(IndiaLocationRegistry.allLocationIds);
      for (final id in legacy) {
        // Explicit new choices, including none, win over historical visits.
        states.putIfAbsent(
          id,
          () => StateTravelStatus(stateId: id, status: TravelStatus.visited),
        );
      }
      await _save(prefs, states);
      // Historical rewards don't fabricate today's streak activity.
      await ProgressService.ensureRewardEvents(
        legacy.map((id) => 'completion:state:$id'),
      );
      if (!await prefs.setBool(migrationKey, true)) {
        throw StateError('Could not save passport migration');
      }
      // Retain the original legacy list as a historical backup.
    }
    return states;
  }

  static Future<void> _save(
    SharedPreferences prefs,
    Map<String, StateTravelStatus> states,
  ) async {
    if (!await prefs.setString(
      storageKey,
      jsonEncode(states.map((id, state) => MapEntry(id, state.toJson()))),
    )) {
      throw StateError('Could not save passport');
    }
  }

  Future<void> load() => _enqueue(() async {
    final states = await _read(await SharedPreferences.getInstance());
    _states
      ..clear()
      ..addAll(states);
    _notify();
  });

  /// [at] backdates the change, e.g. to a trip's start date.
  Future<void> setStatus(String id, TravelStatus status, {DateTime? at}) {
    if (!IndiaLocationRegistry.allLocationIds.contains(id)) {
      throw ArgumentError.value(id, 'stateId');
    }
    if (status == TravelStatus.wantToVisit &&
        statusFor(id) == TravelStatus.visited) {
      return Future.value();
    }
    _states[id] = StateTravelStatus(
      stateId: id,
      status: status,
      updatedAt: at ?? DateTime.now(),
    );
    _notify();
    return _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      final states = await _read(prefs);
      // Recheck precedence against persisted state for concurrent callers.
      if (status != TravelStatus.wantToVisit ||
          states[id]?.status != TravelStatus.visited) {
        states[id] = StateTravelStatus(
          stateId: id,
          status: status,
          updatedAt: at ?? DateTime.now(),
        );
        await _save(prefs, states);
        if (status == TravelStatus.visited &&
            !(await ProgressService.getRewardedEventIds()).contains(
              'completion:state:$id',
            )) {
          await ProgressService.recordMeaningfulCompletion('state:$id');
        }
        changes.value++;
      }
      _states
        ..clear()
        ..addAll(states);
      _notify();
    });
  }
}
