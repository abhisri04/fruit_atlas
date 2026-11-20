import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/celebration_event.dart';
import '../models/gamification_summary.dart';

/// A presentation event stream. Progress and reward services decide when an
/// event occurred; widgets decide how strongly to present it.
class CelebrationService {
  static const _seenKey = 'celebration_seen_v1';
  static final CelebrationService instance = CelebrationService._();

  final _events = StreamController<CelebrationEvent>.broadcast(sync: true);
  final Set<String> _sessionEvents = {};

  CelebrationService._();

  Stream<CelebrationEvent> get events => _events.stream;

  void emit(CelebrationEvent event) {
    if (!_sessionEvents.add(event.id)) return;
    _events.add(event);
  }

  Future<bool> emitOnce(CelebrationEvent event) async {
    final preferences = await SharedPreferences.getInstance();
    final seen = preferences.getStringList(_seenKey)?.toSet() ?? <String>{};
    if (!seen.add(event.id)) return false;
    await preferences.setStringList(_seenKey, seen.toList()..sort());
    emit(event);
    return true;
  }

  void presentSummaryTransition(
    GamificationSummary? previous,
    GamificationSummary current,
  ) {
    if (previous == null) return;
    if (current.level > previous.level) {
      emit(
        CelebrationEvent(
          id: 'level:${current.level}',
          kind: CelebrationKind.levelUp,
          intensity: CelebrationIntensity.large,
          title: 'Level up!',
          message: '${previous.levelTitle} → ${current.levelTitle}',
          previousLevel: previous.level,
          newLevel: current.level,
        ),
      );
    }
    const streakMilestones = {7, 14, 30, 50, 100};
    if (current.streakDays > previous.streakDays &&
        streakMilestones.contains(current.streakDays)) {
      emit(
        CelebrationEvent(
          id: 'streak:${current.streakDays}',
          kind: CelebrationKind.streakMilestone,
          intensity: CelebrationIntensity.medium,
          title: 'Streak milestone',
          message: '${current.streakDays} days of exploring your Life.',
        ),
      );
    }
  }

  void resetSessionForTest() => _sessionEvents.clear();
}
