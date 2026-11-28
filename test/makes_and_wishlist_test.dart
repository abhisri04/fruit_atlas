import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/screens/hobbies/phone_down_timer_page.dart';
import 'package:fruit_atlas/screens/making/my_makes_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/my_collections_service.dart';
import 'package:fruit_atlas/services/my_makes_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Map<String, dynamic>> _raw(String file) =>
    ((jsonDecode(File('assets/data/$file').readAsStringSync())
                as Map<String, dynamic>)['items']
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('Make Something', () {
    final items = _raw('making.json');

    test(
      'the catalogue is complete, Indian folk art included, no prices',
      () async {
        expect(items, hasLength(26));
        expect(items.map((i) => i['id']).toSet(), hasLength(26));
        expect(
          items.map((i) => i['filter_group']).toSet(),
          containsAll(['Crochet & knitting', 'Journaling', 'Indian folk art']),
        );
        for (final item in items) {
          expect(item['metadata'], contains("You'll need"));
          expect((item['howToSteps'] as List), hasLength(4));
        }
        final text = File('assets/data/making.json').readAsStringSync();
        expect(text, isNot(contains('₹')));
        expect(text.toLowerCase(), isNot(contains('price')));
        final challenge = (await const AssetDataService().loadChallenges())
            .singleWhere((c) => c.id == 'make_something');
        expect(challenge.categoryId, 'making');
        expect(
          File('pubspec.yaml').readAsStringSync(),
          contains('- ${challenge.dataAsset}'),
        );
      },
    );

    test(
      'start, add progress, finish: counted as made and celebrated',
      () async {
        final id = items.first['id'] as String;
        await MyMakesService.start(id, items.first['name'] as String);
        await MyMakesService.addUpdate(
          id,
          note: 'First round done',
          minutes: 30,
          photo: Uint8List.fromList([7, 7]),
        );
        await MyMakesService.addUpdate(id, minutes: 45);
        var make = (await MyMakesService.load())[id]!;
        expect(make.minutes, 75);
        expect(make.coverPhoto, isNotNull);
        expect(make.finished, isFalse);

        await MyMakesService.finish(id);
        make = (await MyMakesService.load())[id]!;
        expect(make.finished, isTrue);
        expect(
          await ProgressService.getChallengeItemIds(MyMakesService.progressKey),
          contains(id),
        );
        expect(
          await ProgressService.getRewardedEventIds(),
          contains('collection:made_$id'),
        );
      },
    );

    test(
      'your own project works too, without touching the catalogue',
      () async {
        final make = await MyMakesService.startCustom('Crochet a tote bag');
        await MyMakesService.finish(make.id);
        expect(
          await ProgressService.getChallengeItemIds(MyMakesService.progressKey),
          isEmpty,
        );
        expect(() => MyMakesService.startCustom('  '), throwsArgumentError);
      },
    );

    testWidgets('My makes shows what is on the go and what is made', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await MyMakesService.start(
          'make_crochet_a_coaster',
          'Crochet a coaster',
        );
        await MyMakesService.start('make_knit_a_scarf', 'Knit a scarf');
        await MyMakesService.finish('make_knit_a_scarf');
      });
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MyMakesPage()),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        if (find.byKey(const ValueKey('makes-summary')).evaluate().isNotEmpty) {
          break;
        }
      }
      expect(
        find.byKey(const ValueKey('make-going-make_crochet_a_coaster')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('make-done-make_knit_a_scarf')),
        findsOneWidget,
      );
    });
  });

  group('Collection wishlist, favourites and goals', () {
    test('a wanted piece moves into the collection with Got it', () async {
      await MyCollectionsService.start('collect_coins', 'Coins');
      await MyCollectionsService.addThing(
        'collect_coins',
        name: '1985 one-rupee coin',
        source: 'Gift',
      );
      await MyCollectionsService.addThing(
        'collect_coins',
        name: '1950 one-anna coin',
        wanted: true,
      );
      var c = (await MyCollectionsService.load())['collect_coins']!;
      expect(c.owned.single.source, 'Gift');
      final want = c.wishlist.single;

      await MyCollectionsService.gotIt('collect_coins', want.id);
      c = (await MyCollectionsService.load())['collect_coins']!;
      expect(c.wishlist, isEmpty);
      expect(c.owned, hasLength(2));
      expect(
        await ProgressService.getRewardedEventIds(),
        contains('collection:collect_wish_${want.id}'),
      );
    });

    test('favourites and a set goal', () async {
      await MyCollectionsService.start('collect_stamps', 'Stamps');
      for (final n in ['Taj Mahal', 'Tiger']) {
        await MyCollectionsService.addThing('collect_stamps', name: n);
      }
      var c = (await MyCollectionsService.load())['collect_stamps']!;
      await MyCollectionsService.toggleFavourite(
        'collect_stamps',
        c.owned.first.id,
      );
      c = (await MyCollectionsService.load())['collect_stamps']!;
      expect(c.owned.where((t) => t.favourite), hasLength(1));

      await MyCollectionsService.setGoal('collect_stamps', 2);
      c = (await MyCollectionsService.load())['collect_stamps']!;
      expect(c.goal, 2);
      expect(
        await ProgressService.getRewardedEventIds(),
        contains('collection:collect_goal_collect_stamps_2'),
      );
      await MyCollectionsService.setGoal('collect_stamps', null);
      expect(
        (await MyCollectionsService.load())['collect_stamps']!.goal,
        isNull,
      );
    });
  });

  testWidgets('the phone-down timer returns the minutes spent', (tester) async {
    var now = DateTime(2026, 11, 28, 18);
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (_) => PhoneDownTimerPage(
                    hobbyName: 'Sketching',
                    clock: () => now,
                  ),
                ),
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('00:00'), findsOneWidget);
    now = now.add(const Duration(minutes: 25, seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('25:10'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('phone-down-done')));
    await tester.pumpAndSettle();
    expect(result, 25);
  });
}
