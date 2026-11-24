import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/models/my_garden.dart';
import 'package:fruit_atlas/models/share_highlight.dart';
import 'package:fruit_atlas/screens/garden/garden_plant_page.dart';
import 'package:fruit_atlas/screens/garden/garden_sheets.dart';
import 'package:fruit_atlas/screens/garden/my_garden_page.dart';
import 'package:fruit_atlas/screens/garden/my_garden_share_page.dart';
import 'package:fruit_atlas/services/my_garden_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Item> _plants() =>
    ((jsonDecode(File('assets/data/garden_plants.json').readAsStringSync())
                as Map<String, dynamic>)['items']
            as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Item.fromJson)
        .toList();

Future<void> _settle(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 80; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (ready.evaluate().isNotEmpty) break;
  }
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final plants = _plants();
  final tomato = plants.firstWhere((p) => p.id == 'plant_tomato');
  final tulsi = plants.firstWhere((p) => p.filterGroup == 'Herbs');

  setUpAll(() => GardenCatalogue.raw());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('MyGarden model', () {
    final added = DateTime(2025, 11, 2);
    MyGarden build() => MyGarden(
      plants: {
        'a': GardenPlant(
          id: 'a',
          catalogueId: 'plant_tomato',
          name: 'Tomato',
          type: 'Vegetables',
          addedAt: added,
        ),
        'b': GardenPlant(
          id: 'b',
          name: 'Rose',
          type: 'Flowers',
          addedAt: added,
        ).letGo(DateTime(2026, 1, 3), 'Too much water'),
      },
      logs: [
        GardenLog(id: '1', plantId: 'a', moment: GardenMoment.added, at: added),
        GardenLog(
          id: '2',
          plantId: 'a',
          moment: GardenMoment.sprouted,
          at: DateTime(2025, 11, 24),
          photoId: 'p1',
        ),
        GardenLog(
          id: '3',
          plantId: 'a',
          moment: GardenMoment.harvested,
          at: DateTime(2026, 11, 20),
        ),
        GardenLog(
          id: '4',
          plantId: 'a',
          moment: GardenMoment.harvested,
          at: DateTime(2026, 11, 22),
        ),
        GardenLog(
          id: '5',
          plantId: 'a',
          moment: GardenMoment.tended,
          at: DateTime(2026, 11, 22, 8),
        ),
      ],
    );

    test('round-trips through JSON', () {
      final garden = build();
      final again = MyGarden.fromJson(
        jsonDecode(jsonEncode(garden.toJson())) as Map<String, dynamic>,
      );
      expect(again.plants.keys, garden.plants.keys);
      expect(again.logs, hasLength(garden.logs.length));
      expect(again.plants['b']!.lesson, 'Too much water');
      expect(again.plants['b']!.growing, isFalse);
    });

    test('firsts, lessons, photos and counts', () {
      final garden = build();
      expect(garden.growing.map((p) => p.id), ['a']);
      expect(garden.lessons.map((p) => p.id), ['b']);
      expect(garden.harvestsFor('a'), 2);
      expect(
        garden.firstsFor('a')[GardenMoment.harvested],
        DateTime(2026, 11, 20),
      );
      expect(garden.coverPhotoFor('a'), 'p1');
      expect(garden.typeCounts(), {'Vegetables': 1});
      expect(garden.plantsThatGaveBack(), 1);
      expect(garden.milestones().first.$2, GardenMoment.harvested);
      expect(garden.tendedOn('a', DateTime(2026, 11, 22)), isTrue);
      expect(garden.activeMonths(2026), {11});
    });

    test('monthly recap and this day last year only count what was added', () {
      final garden = build();
      final recap = garden.recap(DateTime(2026, 11, 24));
      expect(recap.harvests, 2);
      expect(recap.tendedDays, 1);
      expect(recap.firsts.single.$2, GardenMoment.harvested);
      expect(garden.recap(DateTime(2026, 2)).isEmpty, isTrue);
      final lastYear = garden.onThisDayLastYear(DateTime(2026, 11, 24));
      expect(lastYear.single.$2.moment, GardenMoment.sprouted);
    });
  });

  group('MyGardenService', () {
    test('adding a catalogue plant marks it grown and rewards once', () async {
      final now = DateTime(2026, 11, 24, 9);
      await MyGardenService.addCatalogue(tomato, now: now);
      expect(
        await ProgressService.getChallengeItemIds('completed_garden_plant_ids'),
        contains('plant_tomato'),
      );
      final rewards = await ProgressService.getRewardedEventIds();
      expect(rewards, contains('completion:plant:plant_tomato'));
      expect(rewards, contains('collection:garden_first_plant'));
      expect(rewards, contains('practice:my_garden:2026-11-24'));
    });

    test('firsts happen once, tending once a day, harvests repeat', () async {
      final now = DateTime(2026, 11, 24, 9);
      final plant = await MyGardenService.addCatalogue(tomato, now: now);
      expect(
        await MyGardenService.log(plant.id, GardenMoment.sprouted, now: now),
        isNotNull,
      );
      expect(
        await MyGardenService.log(plant.id, GardenMoment.sprouted, now: now),
        isNull,
      );
      expect(
        await MyGardenService.log(plant.id, GardenMoment.tended, now: now),
        isNotNull,
      );
      expect(
        await MyGardenService.log(plant.id, GardenMoment.tended, now: now),
        isNull,
      );
      expect(
        await MyGardenService.log(
          plant.id,
          GardenMoment.tended,
          now: now.add(const Duration(days: 1)),
        ),
        isNotNull,
      );
      await MyGardenService.log(plant.id, GardenMoment.harvested, now: now);
      await MyGardenService.log(plant.id, GardenMoment.harvested, now: now);
      final garden = await MyGardenService.load();
      expect(garden.harvestsFor(plant.id), 2);
      final rewards = await ProgressService.getRewardedEventIds();
      expect(rewards, contains('collection:garden_first_sprouted'));
      expect(rewards, contains('collection:garden_first_harvested'));
    });

    test('photos are stored on the device and cleaned up on remove', () async {
      final plant = await MyGardenService.addCustom('Rose', type: 'Flowers');
      final log = await MyGardenService.log(plant.id, GardenMoment.flowered);
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      await MyGardenService.attachPhoto(log!.id, bytes);
      final garden = await MyGardenService.load();
      final photoId = garden.coverPhotoFor(plant.id)!;
      expect(await MyGardenService.photo(photoId), bytes);

      await MyGardenService.remove(plant.id);
      expect((await MyGardenService.load()).plants, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((k) => k.contains('photo')), isEmpty);
    });

    test('let it go keeps the story; grow again starts fresh', () async {
      final plant = await MyGardenService.addCatalogue(tulsi);
      await MyGardenService.log(plant.id, GardenMoment.sown);
      await MyGardenService.letGo(plant.id, lesson: 'Not enough sun');
      var garden = await MyGardenService.load();
      expect(garden.growing, isEmpty);
      expect(garden.lessons.single.lesson, 'Not enough sun');
      expect(garden.logsFor(plant.id), hasLength(2));

      final fresh = await MyGardenService.growAgain(plant.id);
      garden = await MyGardenService.load();
      expect(fresh.id, isNot(plant.id));
      expect(garden.growing.single.catalogueId, tulsi.id);
      expect(garden.lessons, hasLength(1));
    });

    test('custom plants need a name', () {
      expect(() => MyGardenService.addCustom('  '), throwsArgumentError);
    });
  });

  test('share text celebrates what grows', () {
    final garden = MyGarden(
      plants: {
        'a': GardenPlant(
          id: 'a',
          name: 'Chilli',
          type: 'Vegetables',
          addedAt: DateTime(2026, 10),
        ),
      },
      logs: [
        GardenLog(
          id: '1',
          plantId: 'a',
          moment: GardenMoment.harvested,
          at: DateTime(2026, 11, 2),
        ),
      ],
    );
    expect(
      gardenShareText(garden),
      'My garden: 1 plant growing, first harvest from my Chilli. '
      'Made with UPLYFA.',
    );
  });

  testWidgets('empty garden invites a first plant', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MyGardenPage(clock: () => DateTime(2026, 11, 24)),
      ),
    );
    await _settle(tester, find.byKey(const ValueKey('garden-empty-add')));
    expect(find.text('Start your garden'), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-empty-add')), findsOneWidget);
  });

  testWidgets(
    'My Garden shows plants, recap, map and lessons; tend is one tap',
    (tester) async {
      tester.view.physicalSize = const Size(420, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final now = DateTime(2026, 11, 24, 9);
      late GardenPlant plant;
      await tester.runAsync(() async {
        plant = await MyGardenService.addCatalogue(tomato, now: now);
        await MyGardenService.log(plant.id, GardenMoment.harvested, now: now);
        final rose = await MyGardenService.addCustom('Rose', type: 'Flowers');
        await MyGardenService.letGo(rose.id, lesson: 'Pests');
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: MyGardenPage(clock: () => now)),
        ),
      );
      await _settle(tester, find.byKey(ValueKey('garden-plant-${plant.id}')));
      expect(find.text('Tomato'), findsWidgets);
      expect(find.byKey(const ValueKey('garden-recap')), findsOneWidget);
      expect(find.textContaining('first harvest from Tomato'), findsOneWidget);
      expect(find.text('Lessons learned'), findsOneWidget);
      expect(find.text('Pests'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('garden-tend-${plant.id}')));
      await _settle(tester, find.textContaining('Tended Tomato'));
      expect(find.textContaining('Tended Tomato'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);
      await tester.runAsync(() async {
        expect(
          (await MyGardenService.load()).tendedOn(plant.id, DateTime.now()),
          isTrue,
        );
      });
    },
  );

  testWidgets('a plant page logs a first with one tap', (tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late GardenPlant plant;
    await tester.runAsync(() async {
      plant = await MyGardenService.addCatalogue(tomato);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GardenPlantPage(plantId: plant.id),
      ),
    );
    final sprout = find.byKey(const ValueKey('garden-log-sprouted'));
    await _settle(tester, sprout);
    await tester.tap(sprout);
    await _settle(tester, find.text('First sprout ✓'));
    expect(find.text('First sprout ✓'), findsOneWidget);
    expect(find.textContaining('First sprout ·'), findsOneWidget);
  });

  testWidgets('share card renders in both formats', (tester) async {
    final garden = MyGarden(
      plants: {
        'a': GardenPlant(
          id: 'a',
          name: 'Tomato',
          type: 'Vegetables',
          addedAt: DateTime(2026, 10),
        ),
      },
      logs: [
        for (final (i, m) in [
          GardenMoment.sprouted,
          GardenMoment.flowered,
          GardenMoment.harvested,
        ].indexed)
          GardenLog(
            id: '$i',
            plantId: 'a',
            moment: m,
            at: DateTime(2026, 11, i + 1),
          ),
      ],
    );
    for (final format in ShareCardFormat.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: MyGardenShareCard(garden: garden, format: format),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('1 plant growing'), findsOneWidget);
      expect(find.textContaining('Made with'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
