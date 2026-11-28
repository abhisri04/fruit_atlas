import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/experience.dart';
import 'package:fruit_atlas/models/india_location_registry.dart';
import 'package:fruit_atlas/models/india_regions.dart';
import 'package:fruit_atlas/models/state_travel_status.dart';
import 'package:fruit_atlas/models/travel_theme.dart';
import 'package:fruit_atlas/models/trip.dart';
import 'package:fruit_atlas/screens/travel/passport_stats_page.dart';
import 'package:fruit_atlas/screens/travel/state_places_sheet.dart';
import 'package:fruit_atlas/screens/travel/travel_theme_page.dart';
import 'package:fruit_atlas/screens/travel/trip_edit_page.dart';
import 'package:fruit_atlas/screens/travel/trips_page.dart';
import 'package:fruit_atlas/services/district_repository.dart';
import 'package:fruit_atlas/services/experience_repository.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/state_travel_service.dart';
import 'package:fruit_atlas/services/travel_extras.dart';
import 'package:fruit_atlas/services/trip_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Experience _exp(String title, {String type = 'place', String desc = ''}) =>
    Experience(
      id: title,
      title: title,
      description: desc,
      type: type,
      section: 'Things to Do',
      parentLocationId: 'goa',
      categoryId: 'travel_exploration',
      stateId: 'goa',
      stateName: 'Goa',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester tester, Finder ready) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (ready.evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> host(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: home));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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

  group('My India in numbers', () {
    test('regions cover every State and UT exactly once', () {
      final ids = [for (final r in IndiaRegions.all) ...r.locationIds];
      expect(ids.toSet(), IndiaLocationRegistry.allLocationIds);
      expect(ids, hasLength(IndiaLocationRegistry.allLocationIds.length));
    });

    testWidgets('shows totals, the state/UT split, regions and stamps', (
      tester,
    ) async {
      final travel = StateTravelService();
      await tester.runAsync(() async {
        await travel.load();
        await travel.setStatus(
          'goa',
          TravelStatus.visited,
          at: DateTime(2024, 3, 2),
        );
        await travel.setStatus(
          'delhi',
          TravelStatus.visited,
          at: DateTime(2025, 6, 9),
        );
        await travel.setStatus('kerala', TravelStatus.wantToVisit);
      });
      await host(
        tester,
        PassportStatsPage(
          travel: travel,
          extras: () async => const PassportExtraStats(
            trips: 2,
            daysTravelled: 7,
            placesVisited: 3,
          ),
        ),
      );
      await settle(tester, find.byKey(const ValueKey('stats-hero')));
      expect(find.text('6%'), findsOneWidget);
      expect(
        find.text('1 of 28 states · 1 of 8 union territories'),
        findsOneWidget,
      );
      expect(find.text('1/4'), findsWidgets); // West: Goa
      expect(find.text('1/8'), findsWidgets); // North: Delhi
      expect(find.textContaining('Goa · 2 Mar 2024'), findsOneWidget);
      expect(find.textContaining('Delhi · 9 Jun 2025'), findsOneWidget);
      expect(find.text('Kerala'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('trips'), findsOneWidget);
      travel.dispose();
    });
  });

  group('Trips', () {
    test('trip names, dates and log numbers', () {
      expect(Trip.defaultTitle(['goa']), 'Goa trip');
      expect(Trip.defaultTitle(['goa', 'kerala']), 'Goa & Kerala trip');
      expect(Trip.defaultTitle(['goa', 'kerala', 'delhi']), 'Goa and 2 more');
      final a = Trip(
        id: 'a',
        title: 'Goa trip',
        stateIds: const ['goa'],
        start: DateTime(2025, 11, 28),
        days: 4,
      );
      final b = Trip(
        id: 'b',
        title: 'Delhi trip',
        stateIds: const ['delhi', 'goa'],
        start: DateTime(2026, 2, 1),
        days: 2,
      );
      expect(a.end, DateTime(2025, 12, 1));
      expect(tripRange(a), '28 Nov – 1 Dec 2025');
      final log = TripLog([a, b]);
      expect(log.trips.first.id, 'b');
      expect(log.daysTravelled, 6);
      expect(log.statesCovered, {'goa', 'delhi'});
      expect(log.longest?.id, 'a');
      expect(log.onThisDay(DateTime(2026, 11, 28)).single.id, 'a');
      final round = Trip.fromJson(
        jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>,
      );
      expect(round.stateIds, b.stateIds);
      expect(round.days, 2);
    });

    test('saving a trip stamps its places on the trip date, once', () async {
      final start = DateTime(2025, 1, 10);
      final trip = Trip(
        id: 'trip_1',
        title: 'Kerala & Goa trip',
        stateIds: const ['kerala', 'goa'],
        start: start,
        days: 5,
      );
      await TripService.save(trip);
      final travel = StateTravelService();
      await travel.load();
      expect(travel.statusFor('kerala'), TravelStatus.visited);
      expect(travel.markedAt('goa'), start);
      final rewards = await ProgressService.getRewardedEventIds();
      expect(rewards, contains('collection:trip_trip_1'));

      // Editing doesn't reward again; deleting keeps the stamps.
      await TripService.save(trip.copyWith(days: 6));
      expect(
        (await ProgressService.getRewardedEventIds())
            .where((r) => r.startsWith('collection:trip_'))
            .length,
        1,
      );
      expect((await TripService.load()).trips.single.days, 6);
      await TripService.delete('trip_1');
      expect((await TripService.load()).isEmpty, isTrue);
      await travel.load();
      expect(travel.statusFor('goa'), TravelStatus.visited);
      travel.dispose();
    });

    testWidgets('logging a trip takes one place and a tap', (tester) async {
      await host(
        tester,
        TripEditPage(
          initialStates: const ['goa'],
          clock: () => DateTime(2026, 11, 28),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('trip-state-goa')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('trip-search')), 'Ker');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('trip-add-kerala')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('trip-days-more')));
      await tester.tap(find.byKey(const ValueKey('trip-days-more')));
      await tester.pump();
      expect(find.text('3 days'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('trip-save')));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      final log = await tester.runAsync(TripService.load);
      expect(log!.trips.single.title, 'Goa & Kerala trip');
      expect(log.trips.single.days, 3);
      expect(log.trips.single.start, DateTime(2026, 11, 28));
    });

    testWidgets('the trips page shows totals and trips', (tester) async {
      await tester.runAsync(
        () => TripService.save(
          Trip(
            id: 'trip_x',
            title: 'Goa trip',
            stateIds: const ['goa'],
            start: DateTime(2025, 11, 28),
            days: 4,
          ),
        ),
      );
      await host(tester, TripsPage(clock: () => DateTime(2026, 11, 28)));
      await settle(tester, find.byKey(const ValueKey('trip-card-trip_x')));
      expect(find.byKey(const ValueKey('trips-header')), findsOneWidget);
      expect(find.text('A year ago today'), findsOneWidget);
      expect(find.text('Goa trip'), findsOneWidget);
    });
  });

  group('Places within a state', () {
    testWidgets('ticking a place also stamps its state', (tester) async {
      final travel = StateTravelService();
      await tester.runAsync(travel.load);
      final goa = await tester.runAsync(
        () => const DistrictRepository().getForState('goa'),
      );
      expect(goa, isNotEmpty);
      await host(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showStatePlacesSheet(
                  context,
                  stateId: 'goa',
                  travel: travel,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      final toggle = find.byKey(ValueKey('place-toggle-${goa!.first.id}'));
      await settle(tester, toggle);
      expect(find.text('0 of ${goa.length} districts visited'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(toggle);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await settle(tester, find.text('1 of ${goa.length} districts visited'));
      expect(find.text('1 of ${goa.length} districts visited'), findsOneWidget);
      expect(travel.statusFor('goa'), TravelStatus.visited);
      travel.dispose();
    });

    test('passport extras count trips and places', () async {
      final goa = await const DistrictRepository().getForState('goa');
      await ProgressService.toggleDistrict(goa.first.id);
      await TripService.save(
        Trip(
          id: 'trip_e',
          title: 'Goa trip',
          stateIds: const ['goa'],
          start: DateTime(2025, 5, 1),
          days: 3,
        ),
      );
      final extras = await loadPassportExtras();
      expect(extras.trips, 1);
      expect(extras.daysTravelled, 3);
      expect(extras.placesVisited, 1);
      expect(extras.placesTotal, greaterThan(700));
    });
  });

  group('Explore by travel theme', () {
    test('themes match by whole words', () {
      expect(TravelTheme.beach.matches(_exp('Palolem Beach')), isTrue);
      expect(TravelTheme.adventure.matches(_exp('Scuba Dive off Goa')), isTrue);
      // "dive" inside "biodiversity" is not adventure.
      expect(
        TravelTheme.adventure.matches(_exp('Yamuna Biodiversity Park')),
        isFalse,
      );
      expect(TravelTheme.food.matches(_exp('Tagore Theatre')), isFalse);
      expect(
        TravelTheme.culture.matches(_exp('Dekhni', type: 'culture')),
        isTrue,
      );
      expect(TravelTheme.of(_exp('Aguada Fort by the beach')), {
        TravelTheme.heritage,
        TravelTheme.beach,
      });
    });

    test('every theme has experiences across several states', () async {
      final all = await const ExperienceRepository().loadExperiences();
      for (final theme in TravelTheme.values) {
        final matched = all.where(theme.matches);
        expect(matched.length, greaterThanOrEqualTo(20), reason: theme.name);
        expect(
          {for (final e in matched) e.stateId}.length,
          greaterThanOrEqualTo(5),
          reason: theme.name,
        );
      }
    });

    testWidgets('a theme page filters by your wish list', (tester) async {
      final travel = StateTravelService();
      await tester.runAsync(() async {
        await travel.load();
        await travel.setStatus('goa', TravelStatus.wantToVisit);
      });
      await host(
        tester,
        TravelThemePage(theme: TravelTheme.beach, travelService: travel),
      );
      await settle(tester, find.byKey(const ValueKey('theme-count')));
      expect(find.byKey(const ValueKey('theme-state-goa')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('theme-scope-wishList')));
      await tester.pump();
      expect(find.byKey(const ValueKey('theme-state-goa')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('theme-state-andaman_nicobar')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('theme-scope-beenThere')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('theme-scope-beenThere')));
      await tester.pump();
      expect(find.byKey(const ValueKey('theme-state-goa')), findsNothing);
      travel.dispose();
    });
  });
}
