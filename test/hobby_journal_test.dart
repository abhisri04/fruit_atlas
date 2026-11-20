import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/hobby_journal.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/hobbies/my_hobbies_page.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/services/hobby_journal_service.dart';
import 'package:fruit_atlas/services/hobby_repository.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/hobby_start_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _id = 'hobby_origami_crane';
// A Wednesday.
final _day1 = DateTime(2026, 11, 18, 9);

HobbyRecord _record(List<int> sessionDayOffsets, {DateTime? started}) =>
    HobbyRecord(
      hobbyId: _id,
      name: 'Origami',
      startedAt: started ?? _day1,
      sessions: [
        for (final offset in sessionDayOffsets)
          HobbySession(at: _day1.add(Duration(days: offset)), minutes: 20),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HobbyJournalService.changes.value = 0;
  });

  group('HobbyRecord', () {
    test('streak counts consecutive days ending today or yesterday', () {
      final record = _record([0, 1, 2, 4]);
      expect(record.currentStreak(_day1.add(const Duration(days: 4))), 1);
      expect(record.currentStreak(_day1.add(const Duration(days: 3))), 3);
      expect(record.currentStreak(_day1.add(const Duration(days: 6))), 0);
    });

    test('weekly totals start on Monday', () {
      // Sessions Wed, Thu (week 1) and next Mon (week 2).
      final record = _record([0, 1, 5]);
      final monday = _day1.add(const Duration(days: 5));
      expect(record.sessionsThisWeek(_day1.add(const Duration(days: 1))), 2);
      expect(record.sessionsThisWeek(monday), 1);
      expect(record.minutesThisWeek(monday), 20);
      expect(record.totalMinutes, 60);
    });

    test('starter week tracks days and asks for a decision after 7 days', () {
      final record = _record([0, 2, 3]);
      expect(record.starterProgress(), [
        true,
        false,
        true,
        true,
        false,
        false,
        false,
      ]);
      final day3 = _day1.add(const Duration(days: 2));
      expect(record.inStarter(day3), isTrue);
      expect(record.starterDay(day3), 3);
      final day8 = _day1.add(const Duration(days: 7));
      expect(record.inStarter(day8), isFalse);
      expect(record.needsStarterDecision(day8), isTrue);
      expect(
        record.copyWith(starterDecided: true).needsStarterDecision(day8),
        isFalse,
      );
    });

    test('survives a JSON round trip', () {
      final record = _record([0, 1])
          .copyWith(level: 2, status: HobbyStatus.paused);
      final copy = HobbyRecord.fromJson(record.toJson());
      expect(copy.toJson(), record.toJson());
    });
  });

  group('HobbyJournalService', () {
    test(
      'logging practice rewards once per day and marks the hobby tried',
      () async {
        await HobbyJournalService.start(
          hobbyId: _id,
          name: 'Origami',
          group: 'Creative & Crafts',
          now: _day1,
        );
        expect(HobbyJournalService.changes.value, greaterThan(0));

        var record = await HobbyJournalService.logSession(
          _id,
          minutes: 20,
          now: _day1,
        );
        record = await HobbyJournalService.logSession(_id, now: _day1);
        expect(record.sessions, hasLength(2));
        expect(record.level, 0);

        final rewards = await ProgressService.getRewardedEventIds();
        expect(rewards, contains('practice:$_id:2026-11-18'));
        expect(rewards, contains('completion:hobby:$_id'));
        expect(
          await ProgressService.getChallengeItemIds(
            HobbyRepository.progressKey,
          ),
          {_id},
        );
        // 5 practice + 10 tried completion.
        expect(await ProgressService.getRewardedXp(), 15);

        await HobbyJournalService.logSession(
          _id,
          now: _day1.add(const Duration(days: 1)),
        );
        expect(await ProgressService.getRewardedXp(), 20);
      },
    );

    test(
      'climbing the ladder rewards each new rung and never goes down',
      () async {
        await HobbyJournalService.start(hobbyId: _id, name: 'Origami');
        var record = await HobbyJournalService.reachLevel(_id, 2);
        expect(record.level, 2);
        final rewards = await ProgressService.getRewardedEventIds();
        expect(
          rewards,
          containsAll([
            'completion:hobby:$_id',
            'milestone:$_id:Learning',
            'milestone:$_id:Practising',
          ]),
        );
        record = await HobbyJournalService.reachLevel(_id, 1);
        expect(record.level, 2);
        // 10 tried + 2 × 25 milestones.
        expect(await ProgressService.getRewardedXp(), 60);
      },
    );

    test(
      'adding an existing hobby skips the starter and keeps its level',
      () async {
        final record = await HobbyJournalService.addExisting(
          hobbyId: _id,
          name: 'Origami',
          level: 2,
        );
        expect(record.starterDecided, isTrue);
        expect(record.level, 2);
        expect(record.needsStarterDecision(DateTime(2030)), isFalse);

        final custom = await HobbyJournalService.addExisting(
          hobbyId: 'custom_guitar',
          name: 'Guitar',
          custom: true,
          level: 1,
        );
        expect(custom.custom, isTrue);
        expect(
          await ProgressService.getChallengeItemIds(
            HobbyRepository.progressKey,
          ),
          {_id},
        );
      },
    );

    test('keep, drop, restart and remove', () async {
      await HobbyJournalService.start(
        hobbyId: _id,
        name: 'Origami',
        now: _day1,
      );
      await HobbyJournalService.logSession(_id, now: _day1);
      var record = await HobbyJournalService.decideStarter(_id, keep: false);
      expect(record.status, HobbyStatus.dropped);

      final later = _day1.add(const Duration(days: 30));
      record = await HobbyJournalService.start(
        hobbyId: _id,
        name: 'Origami',
        now: later,
      );
      expect(record.status, HobbyStatus.active);
      expect(record.starterDecided, isFalse);
      expect(record.startedAt, later);
      expect(record.sessions, hasLength(1));

      record = await HobbyJournalService.decideStarter(_id, keep: true);
      expect(record.starterDecided, isTrue);
      expect(record.status, HobbyStatus.active);

      await HobbyJournalService.remove(_id);
      expect(await HobbyJournalService.get(_id), isNull);
    });

    test('a practice session completes the quest\'s world path', () async {
      final now = DateTime(2026, 11, 20, 12);
      await HobbyJournalService.start(hobbyId: _id, name: 'Origami', now: now);
      await HobbyJournalService.logSession(_id, now: now);
      final summary = await const ProgressSummaryService().load();
      final quest = (await const GamificationService().load(
        summary,
        now: now,
      )).quest;
      expect(quest.tasks.singleWhere((t) => t.id == 'world').completed, isTrue);
    });
  });

  group('screens', () {
    Future<void> pumpScreen(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    }

    testWidgets('My Hobbies shows an inviting empty state', (tester) async {
      await pumpScreen(tester, const MyHobbiesPage());
      expect(find.text('Your hobbies live here'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('my-hobbies-empty-find')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('my-hobbies-empty-add')),
        findsOneWidget,
      );
    });

    testWidgets('My Hobbies logs a session from the card', (tester) async {
      await HobbyJournalService.start(
        hobbyId: _id,
        name: 'Origami',
        group: 'Creative & Crafts',
      );
      await pumpScreen(tester, const MyHobbiesPage());
      expect(find.text('Origami'), findsOneWidget);
      expect(find.textContaining('Starter week'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('log-$_id')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('45 min'));
      await tester.tap(find.byKey(const ValueKey('log-session-save')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      final record = (await HobbyJournalService.get(_id))!;
      expect(record.sessions.single.minutes, 45);
      expect(find.text('Practised today · log another'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Start this hobby adds it to My Hobbies', (tester) async {
      await pumpScreen(
        tester,
        const Scaffold(
          body: HobbyStartButton(
            item: Item(
              id: _id,
              challengeId: 'try_easy_hobbies',
              name: 'Fold a paper crane',
              category: 'Origami',
              filterGroup: 'Creative & Crafts',
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('hobby-start-button')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('In My Hobbies'), findsOneWidget);
      final record = (await HobbyJournalService.get(_id))!;
      expect(record.name, 'Origami');
      expect(record.status, HobbyStatus.active);
    });
  });
}
