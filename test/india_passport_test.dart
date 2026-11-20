import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/models/india_location_registry.dart';
import 'package:fruit_atlas/models/state_travel_status.dart';
import 'package:fruit_atlas/services/india_map_repository.dart';
import 'package:fruit_atlas/services/state_travel_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/state_exploration_repository.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/services/gamification_service.dart';
import 'package:fruit_atlas/widgets/travel_journeys.dart';
import 'package:fruit_atlas/screens/travel/india_passport_page.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/widgets/india_passport_map.dart';
import 'package:fruit_atlas/theme/app_colors.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget home) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: home));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUp(StateExplorationRepository.clearCacheForTesting);
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final name = utf8.decode(message!.buffer.asUint8List());
          if (name == 'AssetManifest.bin') {
            return const StandardMessageCodec().encodeMessage(
              <String, Object>{},
            );
          }
          final file = File(name);
          return file.existsSync()
              ? ByteData.sublistView(file.readAsBytesSync())
              : null;
        });
  });
  test(
    'statuses, exclusive counts, precedence, clearing, reload and independence',
    () async {
      final travel = StateTravelService();
      await travel.load();
      expect(travel.statusFor('rajasthan'), TravelStatus.none);
      await ProgressService.setCompletedExperienceIds({'rajasthan_test'});
      expect(travel.visitedCount, 0);
      await travel.setStatus('rajasthan', TravelStatus.wantToVisit);
      expect(travel.wantToVisitCount, 1);
      await travel.setStatus('rajasthan', TravelStatus.visited);
      expect(travel.visitedCount, 1);
      expect(travel.wantToVisitCount, 0);
      await travel.setStatus('rajasthan', TravelStatus.wantToVisit);
      expect(travel.statusFor('rajasthan'), TravelStatus.visited);
      await travel.setStatus('goa', TravelStatus.wantToVisit);
      final reloaded = StateTravelService();
      await reloaded.load();
      expect(reloaded.visitedCount, 1);
      expect(reloaded.wantToVisitCount, 1);
      expect(await ProgressService.getCompletedExperienceIds(), {
        'rajasthan_test',
      });
      expect(
        await ProgressService.getChallengeItemIds(
          'completed_india_state_ut_ids',
        ),
        {'rajasthan'},
      );
      await reloaded.setStatus('rajasthan', TravelStatus.none);
      expect(reloaded.visitedCount, 0);
      expect(
        () => travel.setStatus('unknown', TravelStatus.visited),
        throwsArgumentError,
      );
    },
  );
  test('boundary geometry matches all canonical IDs and status tokens', () {
    final regions = IndiaMapRepository.parse(
      jsonDecode(
        File('assets/data/india_passport_boundaries.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    expect(
      regions.map((r) => r.stateId).toSet(),
      IndiaLocationRegistry.allLocationIds,
    );
    for (final region in regions) {
      expect(region.path.getBounds().isEmpty, false);
    }
    expect(passportColor(TravelStatus.none), AppColors.passportUnmarked);
    expect(passportColor(TravelStatus.wantToVisit), AppColors.passportWanted);
    expect(passportColor(TravelStatus.visited), AppColors.passportVisited);
  });
  test('legacy visits migrate once, preserve explicit choices and never fabricate activity', () async {
    SharedPreferences.setMockInitialValues({
      StateTravelService.legacyKey: ['sikkim', 'goa', 'unknown'],
      StateTravelService.storageKey: jsonEncode({
        'goa': {'status': 'none'},
        'delhi': {'status': 'want_to_visit'},
      }),
      'completed_experience_ids': ['sikkim_test'],
    });
    final travel = StateTravelService();
    await travel.load();
    expect(travel.visitedIds, {'sikkim'});
    expect(travel.statusFor('goa'), TravelStatus.none);
    expect(travel.wantToVisitCount, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(StateTravelService.legacyKey), [
      'sikkim',
      'goa',
      'unknown',
    ]);
    expect(prefs.getBool(StateTravelService.migrationKey), true);
    expect(
      await ProgressService.getActivityReferencesForDate(DateTime.now()),
      isEmpty,
    );
    await travel.setStatus('sikkim', TravelStatus.none);
    final reopened = StateTravelService();
    await reopened.load();
    expect(reopened.visitedCount, 0);
    expect(await ProgressService.getCompletedExperienceIds(), {'sikkim_test'});
  });
  test('visited uses canonical reward ledger once; intent has no score, XP or streak', () async {
    final travel = StateTravelService();
    await travel.load();
    await travel.setStatus('sikkim', TravelStatus.wantToVisit);
    expect(await ProgressService.getRewardedXp(), 0);
    expect(
      await ProgressService.getActivityReferencesForDate(DateTime.now()),
      isEmpty,
    );
    final wantedSummary = await const ProgressSummaryService().load();
    expect(wantedSummary.completedReferences.contains('state:sikkim'), false);
    final wantedGame = await const GamificationService().load(wantedSummary);
    expect(wantedGame.totalXp, 0);
    expect(wantedGame.streakDays, 0);
    await travel.setStatus('sikkim', TravelStatus.visited);
    expect(await ProgressService.getRewardedXp(), 10);
    expect(await ProgressService.getActivityReferencesForDate(DateTime.now()), {
      'state:sikkim',
    });
    final summary = await const ProgressSummaryService().load();
    expect(summary.completedReferences, contains('state:sikkim'));
    expect(summary.achievementIds, contains('india_states_first'));
    await const GamificationService().load(summary);
    final xp = await ProgressService.getRewardedXp();
    await travel.setStatus('sikkim', TravelStatus.none);
    await travel.setStatus('sikkim', TravelStatus.wantToVisit);
    await travel.setStatus('sikkim', TravelStatus.visited);
    await const GamificationService().load(
      await const ProgressSummaryService().load(),
    );
    expect(await ProgressService.getRewardedXp(), xp);
    expect(await ProgressService.getCompletedExperienceIds(), isEmpty);
  });
  test(
    'concurrent service instances preserve separate region updates',
    () async {
      final a = StateTravelService();
      final b = StateTravelService();
      await a.load();
      await b.load();
      await Future.wait([
        a.setStatus('goa', TravelStatus.visited),
        b.setStatus('delhi', TravelStatus.wantToVisit),
      ]);
      await a.load();
      expect(a.visitedIds, {'goa'});
      expect(a.wantToVisitCount, 1);
      expect(await ProgressService.getRewardedXp(), 10);
    },
  );
  testWidgets(
    'Sikkim can have seven explored experiences without a visit; list filters share map status',
    (tester) async {
      final state = await tester.runAsync(
        () => const StateExplorationRepository().load('sikkim'),
      );
      final ids = state!.experiences.take(7).map((e) => e.id).toSet();
      expect(ids.length, 7);
      await ProgressService.setCompletedExperienceIds(ids);
      await tester.runAsync(IndiaMapRepository.load);
      await tester.runAsync(
        () => const StateExplorationRepository().loadProgress(),
      );
      final travel = StateTravelService();
      await mount(tester, IndiaPassportPage(travelService: travel));
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('passport-search')),
        'Sikkim',
      );
      await tester.tap(find.byKey(const ValueKey('passport-filter-none')));
      await tester.pumpAndSettle();
      expect(find.text('7 experiences explored'), findsOneWidget);
      expect(travel.visitedCount, 0);
      await tester.tap(find.byKey(const ValueKey('passport-state-sikkim')));
      await tester.pumpAndSettle();
      expect(find.text('7 experiences explored'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('passport-wanted')));
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byKey(const ValueKey('passport-wanted'))),
      ).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('passport-state-sikkim')), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('passport-filter-want_to_visit')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('passport-state-sikkim')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('passport-state-sikkim')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('passport-visited')));
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byKey(const ValueKey('passport-visited'))),
      ).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('passport-filter-visited')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('passport-state-sikkim')),
        findsOneWidget,
      );
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IndiaPassportMap>(find.byType(IndiaPassportMap))
            .travel
            .statusFor('sikkim'),
        TravelStatus.visited,
      );
      expect(await ProgressService.getCompletedExperienceIds(), ids);
    },
  );
  testWidgets(
    'all 36 regions select through search without changing geometry',
    (tester) async {
      await tester.runAsync(IndiaMapRepository.load);
      await tester.runAsync(
        () => const StateExplorationRepository().loadProgress(),
      );
      await mount(tester, const IndiaPassportPage());
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      for (final location in IndiaLocationRegistry.locations) {
        await tester.enterText(
          find.byKey(const ValueKey('passport-search')),
          location.name,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('passport-state-${location.id}')));
        await tester.pumpAndSettle();
        expect(find.text('Explore ${location.name}'), findsOneWidget);
        Navigator.of(
          tester.element(find.byKey(const ValueKey('passport-visited'))),
        ).pop();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'entry cards display runtime visits, intent and independent exploration',
    (tester) async {
      final state = await tester.runAsync(
        () => const StateExplorationRepository().load('sikkim'),
      );
      await ProgressService.setCompletedExperienceIds(
        state!.experiences.take(7).map((e) => e.id).toSet(),
      );
      final travel = StateTravelService();
      await travel.load();
      await travel.setStatus('goa', TravelStatus.visited);
      await travel.setStatus('delhi', TravelStatus.wantToVisit);
      await tester.runAsync(
        () => const StateExplorationRepository().loadProgress(),
      );
      await mount(tester, const Scaffold(body: TravelJourneys()));
      expect(
        find.text('1 of 36 visited\n1 want to visit\nView your map →'),
        findsOneWidget,
      );
      expect(
        find.text('7 experiences explored\nExplore by state →'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'map tap opens Rajasthan, actions update summaries and map colors',
    (tester) async {
      final travel = StateTravelService();
      await tester.runAsync(IndiaMapRepository.load);
      await tester.runAsync(
        () => const StateExplorationRepository().loadProgress(),
      );
      await mount(tester, IndiaPassportPage(travelService: travel));
      final mapFinder = find.byKey(const ValueKey('india-map'));
      final map = tester.widget<IndiaPassportMap>(
        find.byType(IndiaPassportMap),
      );
      final path = IndiaPassportMap.fittedPath(
        map.regions.firstWhere((r) => r.stateId == 'rajasthan'),
        tester.getSize(mapFinder),
      );
      final center = path.getBounds().center;
      expect(path.contains(center), true);
      await tester.tapAt(tester.getTopLeft(mapFinder) + center);
      await tester.pumpAndSettle();
      expect(find.text('Rajasthan'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('passport-wanted')));
      await tester.pumpAndSettle();
      expect(find.text('1 want to visit'), findsOneWidget);
      expect(travel.statusFor('rajasthan'), TravelStatus.wantToVisit);
      await tester.tap(find.byKey(const ValueKey('passport-visited')));
      await tester.pumpAndSettle();
      expect(find.text('1 of 36 visited'), findsOneWidget);
      expect(find.text('0 want to visit'), findsOneWidget);
      expect(
        passportColor(travel.statusFor('rajasthan')),
        AppColors.passportVisited,
      );
      await tester.tap(find.byKey(const ValueKey('passport-clear')));
      await tester.pumpAndSettle();
      expect(find.text('0 of 36 visited'), findsOneWidget);
    },
  );
  testWidgets(
    'small UT list selection and Explore CTA resolve canonical page',
    (tester) async {
      await tester.runAsync(IndiaMapRepository.load);
      await tester.runAsync(
        () => const StateExplorationRepository().loadProgress(),
      );
      await mount(tester, const IndiaPassportPage());
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      for (final id in [
        'goa',
        'chandigarh',
        'delhi',
        'lakshadweep',
        'puducherry',
      ]) {
        await tester.enterText(
          find.byKey(const ValueKey('passport-search')),
          IndiaLocationRegistry.nameFor(id),
        );
        await tester.pumpAndSettle();
        final row = find.byKey(ValueKey('passport-state-$id'));
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(find.text(IndiaLocationRegistry.nameFor(id)), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('passport-visited')));
        await tester.pumpAndSettle();
        Navigator.of(
          tester.element(find.byKey(const ValueKey('passport-visited'))),
        ).pop();
        await tester.pumpAndSettle();
      }
      final row = find.byKey(const ValueKey('passport-state-puducherry'));
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('passport-explore')));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pumpAndSettle();
      expect(find.byType(ChecklistItemDetailsPage), findsOneWidget);
      expect(
        tester
            .widget<ChecklistItemDetailsPage>(
              find.byType(ChecklistItemDetailsPage),
            )
            .item
            .id,
        'puducherry',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
