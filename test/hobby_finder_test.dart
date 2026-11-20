import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/hobby.dart';
import 'package:fruit_atlas/models/hobby_preferences.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/hobbies/hobby_finder_page.dart';
import 'package:fruit_atlas/screens/hobbies/hobby_quiz_page.dart';
import 'package:fruit_atlas/services/hobby_matcher.dart';
import 'package:fruit_atlas/services/hobby_preferences_service.dart';
import 'package:fruit_atlas/services/hobby_repository.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Hobby _hobby(
  String id, {
  HobbySetting setting = HobbySetting.indoor,
  HobbyCost cost = HobbyCost.free,
  int minutes = 30,
  HobbyEnergy energy = HobbyEnergy.calm,
  HobbySocial social = HobbySocial.solo,
  Set<HobbyGoal> goals = const {HobbyGoal.relax},
}) => Hobby(
  item: Item(id: id, challengeId: 'try_easy_hobbies', name: id),
  setting: setting,
  cost: cost,
  sessionMinutes: minutes,
  energy: energy,
  social: social,
  goals: goals,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const matcher = HobbyMatcher();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HobbyMatcher', () {
    final calmIndoor = _hobby(
      'calm_indoor',
      goals: {HobbyGoal.relax, HobbyGoal.create},
    );
    final activeOutdoor = _hobby(
      'active_outdoor',
      setting: HobbySetting.outdoor,
      cost: HobbyCost.medium,
      minutes: 240,
      energy: HobbyEnergy.active,
      social: HobbySocial.social,
      goals: {HobbyGoal.active, HobbyGoal.connect},
    );
    final hobbies = [activeOutdoor, calmIndoor];

    test('ranks the better fit first and explains why', () {
      const prefs = HobbyPreferences(
        place: HobbySetting.indoor,
        budget: HobbyCost.free,
        maxMinutes: 30,
        energy: HobbyEnergy.calm,
        company: HobbySocial.solo,
        goals: {HobbyGoal.create},
      );
      final ranked = matcher.rank(hobbies, prefs);
      expect(ranked.first.hobby.id, 'calm_indoor');
      expect(ranked.first.score, greaterThan(ranked.last.score));
      expect(ranked.first.reasons.first, 'Be creative');
      expect(
        ranked.first.reasons,
        containsAll([
          'Indoors',
          'Free',
          'Quick to do',
          'Calming',
          'On your own',
          'Be creative',
        ]),
      );
    });

    test('an active, social person gets the outdoor hobby first', () {
      const prefs = HobbyPreferences(
        place: HobbySetting.outdoor,
        budget: HobbyCost.medium,
        maxMinutes: 240,
        energy: HobbyEnergy.active,
        company: HobbySocial.social,
        goals: {HobbyGoal.active},
      );
      expect(matcher.rank(hobbies, prefs).first.hobby.id, 'active_outdoor');
    });

    test('without preferences the catalogue order is kept', () {
      expect(matcher.rank(hobbies, null).map((m) => m.hobby.id), [
        'active_outdoor',
        'calm_indoor',
      ]);
    });

    test('filters narrow the list', () {
      expect(
        matcher
            .rank(hobbies, null, filters: const HobbyFilters(freeOnly: true))
            .map((m) => m.hobby.id),
        ['calm_indoor'],
      );
      expect(
        matcher
            .rank(
              hobbies,
              null,
              filters: const HobbyFilters(goal: HobbyGoal.connect),
            )
            .map((m) => m.hobby.id),
        ['active_outdoor'],
      );
      expect(const HobbyFilters().isEmpty, isTrue);
    });

    test('pick skips excluded hobbies and returns null when none are left', () {
      final pick = matcher.pick(
        hobbies,
        null,
        exclude: {'calm_indoor'},
        random: Random(1),
      );
      expect(pick!.hobby.id, 'active_outdoor');
      expect(
        matcher.pick(hobbies, null, exclude: {'calm_indoor', 'active_outdoor'}),
        isNull,
      );
    });
  });

  test('preferences survive a JSON round trip and storage', () async {
    const prefs = HobbyPreferences(
      place: HobbySetting.outdoor,
      budget: HobbyCost.free,
      maxMinutes: 240,
      energy: HobbyEnergy.active,
      company: HobbySocial.social,
      goals: {HobbyGoal.learn, HobbyGoal.connect},
    );
    await HobbyPreferencesService.save(prefs);
    final loaded = (await HobbyPreferencesService.load())!;
    expect(loaded.toJson(), prefs.toJson());
    expect(loaded.copyWith(clearEnergy: true).energy, isNull);

    await HobbyPreferencesService.skip('hobby_a');
    expect(await HobbyPreferencesService.skippedIds(), {'hobby_a'});
    await HobbyPreferencesService.clearSkipped();
    expect(await HobbyPreferencesService.skippedIds(), isEmpty);
  });

  test(
    'the bundled catalogue parses with attributes for every hobby',
    () async {
      final hobbies = await const HobbyRepository().load();
      expect(hobbies, hasLength(150));
      expect(hobbies.every((h) => h.goals.isNotEmpty), isTrue);
      expect(hobbies.map((h) => h.setting).toSet(), {
        HobbySetting.indoor,
        HobbySetting.outdoor,
        HobbySetting.either,
      });
      expect(hobbies.where((h) => h.cost == HobbyCost.free), isNotEmpty);
      expect(hobbies.where((h) => h.energy == HobbyEnergy.active), isNotEmpty);
    },
  );

  testWidgets('quiz walks through every question and saves preferences', (
    tester,
  ) async {
    HobbyPreferences? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.push<HobbyPreferences>(
                context,
                MaterialPageRoute(builder: (_) => const HobbyQuizPage()),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    for (final answer in [
      'Outdoors',
      'Free only',
      '15–30 minutes',
      'Active',
      'With others',
    ]) {
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }
    expect(find.text('6 of ${HobbyQuizPage.questionCount}'), findsOneWidget);
    await tester.tap(find.text('Get active'));
    await tester.tap(find.text('Meet people'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hobby-quiz-finish')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.place, HobbySetting.outdoor);
    expect(result!.budget, HobbyCost.free);
    expect(result!.maxMinutes, 30);
    expect(result!.energy, HobbyEnergy.active);
    expect(result!.company, HobbySocial.social);
    expect(result!.goals, {HobbyGoal.active, HobbyGoal.connect});
    expect((await HobbyPreferencesService.load())!.toJson(), result!.toJson());
  });

  testWidgets('finder picks a hobby and "Not for me" remembers it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await HobbyPreferencesService.save(
      const HobbyPreferences(
        place: HobbySetting.indoor,
        budget: HobbyCost.free,
        goals: {HobbyGoal.create},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HobbyFinderPage(random: Random(3)),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Not sure what to try?'), findsOneWidget);
    expect(find.textContaining('best matches first'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hobby-finder-pick')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hobby-pick-try')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hobby-pick-skip')));
    await tester.pumpAndSettle();
    expect(await HobbyPreferencesService.skippedIds(), hasLength(1));
    expect(find.byKey(const ValueKey('hobby-pick-try')), findsOneWidget);

    final freeChip = find.widgetWithText(FilterChip, 'Free');
    await tester.scrollUntilVisible(
      freeChip,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(freeChip);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hobby-pick-try')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
