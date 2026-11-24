import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/models/scent_collection.dart';
import 'package:fruit_atlas/screens/scent/my_collection_page.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/scent_collection_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/scent_shelf_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _june = DateTime(2026, 6, 10, 9);

ScentEntry _entry(
  String id,
  String family, {
  ScentShelf shelf = ScentShelf.own,
  DateTime? added,
}) => ScentEntry(
  id: id,
  name: id,
  family: family,
  shelf: shelf,
  addedAt: added ?? _june,
);

const _perfume = Item(
  id: 'perfume_guerlain_mitsouko',
  challengeId: 'explore_iconic_perfumes',
  name: 'Mitsouko',
  category: 'Guerlain',
  filterGroup: 'Chypre',
  metadata: {'Family': 'Chypre'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => ScentCatalogue.load());

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ScentCollectionService.changes.value = 0;
  });

  group('ScentCollection', () {
    test('family map counts owned and tried, not the wish list', () {
      final c = ScentCollection(
        entries: {
          'a': _entry('a', 'Woody'),
          'b': _entry('b', 'Woody', shelf: ScentShelf.tried),
          'c': _entry('c', 'Floral', shelf: ScentShelf.wantToSmell),
        },
      );
      expect(c.familyCounts(), {'Woody': 2});
      expect(c.shelf(ScentShelf.wantToSmell).single.id, 'c');
    });

    test('most worn, seasonal signatures and gathering dust', () {
      final c = ScentCollection(
        entries: {
          'a': _entry('a', 'Woody'),
          'b': _entry('b', 'Fresh'),
          'c': _entry('c', 'Floral', added: DateTime(2026, 1, 1)),
        },
        wears: [
          ScentWear(entryId: 'b', at: _june),
          ScentWear(entryId: 'b', at: _june.add(const Duration(days: 1))),
          ScentWear(entryId: 'a', at: DateTime(2026, 8, 2)),
          ScentWear(entryId: 'a', at: DateTime(2026, 12, 2)),
        ],
      );
      expect(c.mostWorn().first.$1.id, isIn(['a', 'b']));
      expect(c.mostWorn().first.$2, 2);
      final signatures = c.signatures();
      expect(signatures[ScentSeason.summer]!.id, 'b');
      expect(signatures[ScentSeason.monsoon]!.id, 'a');
      expect(signatures[ScentSeason.winter]!.id, 'a');
      expect(
        c.gatheringDust(DateTime(2026, 12, 10)).map((e) => e.id),
        unorderedEquals(['b', 'c']),
      );
      expect(c.distinctWornThisMonth(_june), 1);
      expect(c.woreOn('b', _june), isTrue);
    });

    test('collector path climbs with the collection', () {
      expect(const ScentCollection().collectorLevel(), 0);
      final families = [
        'Fresh',
        'Floral',
        'Woody',
        'Amber (Oriental)',
        'Chypre',
      ];
      final five = ScentCollection(
        entries: {
          for (var i = 0; i < 5; i++) 'p$i': _entry('p$i', families[i % 3]),
        },
      );
      expect(five.collectorLevel(), 2);
      final worn = ScentCollection(
        entries: five.entries,
        wears: [
          for (var d = 0; d < 20; d++)
            ScentWear(
              entryId: 'p0',
              at: _june.add(Duration(days: d)),
            ),
        ],
      );
      expect(worn.collectorLevel(), 3);
      // All nine families but no wear diary yet: still Learning.
      final allFamilies = {
        for (var i = 0; i < 9; i++) 'f$i': _entry('f$i', 'Family $i'),
      };
      expect(ScentCollection(entries: allFamilies).collectorLevel(), 2);
      // Wears for a perfume no longer in the collection don't count.
      expect(
        ScentCollection(
          entries: allFamilies,
          wears: worn.wears,
        ).collectorLevel(),
        2,
      );
      expect(
        ScentCollection(
          entries: allFamilies,
          wears: [
            for (final w in worn.wears) ScentWear(entryId: 'f0', at: w.at),
          ],
        ).collectorLevel(),
        4,
      );
    });

    test('survives a JSON round trip', () {
      final c = ScentCollection(
        entries: {'a': _entry('a', 'Woody')},
        wears: [ScentWear(entryId: 'a', at: _june, occasion: 'Work')],
      );
      expect(ScentCollection.fromJson(c.toJson()).toJson(), c.toJson());
    });
  });

  group('ScentCollectionService', () {
    test(
      'owning a catalogue perfume marks it smelled and rewards it',
      () async {
        await ScentCollectionService.addItem(_perfume, ScentShelf.own);
        final collection = await ScentCollectionService.load();
        expect(collection.entries[_perfume.id]!.family, 'Chypre');
        expect(collection.entries[_perfume.id]!.maker, 'Guerlain');
        expect(
          await ProgressService.getChallengeItemIds('completed_perfume_ids'),
          {_perfume.id},
        );
        expect(
          await ProgressService.getRewardedEventIds(),
          containsAll([
            'completion:perfume:${_perfume.id}',
            'collection:first_own',
          ]),
        );
      },
    );

    test('the wish list does not count as smelled', () async {
      await ScentCollectionService.addItem(_perfume, ScentShelf.wantToSmell);
      expect(
        await ProgressService.getChallengeItemIds('completed_perfume_ids'),
        isEmpty,
      );
    });

    test('wearing rewards once a day and moves it to Own', () async {
      await ScentCollectionService.addItem(_perfume, ScentShelf.tried);
      await ScentCollectionService.logWear(_perfume.id, now: _june);
      await ScentCollectionService.logWear(_perfume.id, now: _june);
      final collection = await ScentCollectionService.load();
      expect(collection.wears, hasLength(2));
      expect(collection.entries[_perfume.id]!.shelf, ScentShelf.own);
      final rewards = await ProgressService.getRewardedEventIds();
      expect(
        rewards.where((r) => r.startsWith('practice:perfume_collection')),
        hasLength(1),
      );
    });

    test('move and remove', () async {
      await ScentCollectionService.addItem(_perfume, ScentShelf.own);
      await ScentCollectionService.logWear(_perfume.id, now: _june);
      await ScentCollectionService.move(_perfume.id, ScentShelf.tried);
      expect(
        (await ScentCollectionService.load()).entries[_perfume.id]!.shelf,
        ScentShelf.tried,
      );
      await ScentCollectionService.remove(_perfume.id);
      final collection = await ScentCollectionService.load();
      expect(collection.isEmpty, isTrue);
      expect(collection.wears, isEmpty);
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: child));
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle();
    }

    testWidgets('empty collection invites you to start', (tester) async {
      await pump(tester, const MyCollectionPage());
      expect(find.text('Start your perfume collection'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collection-empty-add')),
        findsOneWidget,
      );
    });

    testWidgets('collection shows the map, a suggestion and wear button', (
      tester,
    ) async {
      await ScentCollectionService.addItem(_perfume, ScentShelf.own);
      await pump(tester, MyCollectionPage(clock: () => _june));
      expect(find.text('Collector path'), findsOneWidget);
      expect(find.text('Your scent map'), findsOneWidget);
      expect(find.textContaining('Next time, smell'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('wear-${_perfume.id}')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(ValueKey('wear-${_perfume.id}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shelf chips on a perfume page add it to a shelf', (
      tester,
    ) async {
      await pump(
        tester,
        const Scaffold(body: ScentShelfButtons(item: _perfume)),
      );
      await tester.tap(find.byKey(const ValueKey('shelf-chip-tried')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(
        (await ScentCollectionService.load()).entries[_perfume.id]!.shelf,
        ScentShelf.tried,
      );
      final chip = tester.widget<ChoiceChip>(
        find.byKey(const ValueKey('shelf-chip-tried')),
      );
      expect(chip.selected, isTrue);
    });
  });
}
