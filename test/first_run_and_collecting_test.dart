import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/screens/collecting/my_collection_tracker_page.dart';
import 'package:fruit_atlas/screens/welcome/welcome_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/daily_discovery_service.dart';
import 'package:fruit_atlas/services/my_collections_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/user_profile_service.dart';
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

  group('Welcome', () {
    testWidgets('shows once, then the app, and saves interests', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const WelcomeGate(child: Text('the app')),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.text('the app'), findsNothing);
      expect(find.text('UPLYFA'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('welcome-next')));
      await tester.pumpAndSettle();
      expect(find.text('How it works'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('welcome-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('interest-garden')));
      await tester.tap(find.byKey(const ValueKey('interest-travel')));
      await tester.pump();
      expect(find.text("Let's go (2 picked)"), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('welcome-next')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.text('the app'), findsOneWidget);
      await tester.runAsync(() async {
        expect(await UserProfileService.welcomeDone(), isTrue);
        expect(await UserProfileService.interests(), ['garden', 'travel']);
      });
    });

    test('skipping uses gentle defaults', () async {
      await UserProfileService.finishWelcome(const []);
      expect(await UserProfileService.interests(), Interests.defaults);
      expect(Interests.challengeIdsFor(['garden', 'collecting']), [
        'garden_hub',
        'start_a_collection',
        'scent_hub',
      ]);
    });
  });

  group('Collecting', () {
    final items = _raw('collecting.json');

    test('the catalogue is complete and money-free', () async {
      expect(items, hasLength(35));
      expect(items.map((i) => i['id']).toSet(), hasLength(35));
      for (final item in items) {
        expect(item['about'], isNotEmpty);
        expect((item['howToSteps'] as List), hasLength(greaterThan(2)));
        expect(item['metadata'], contains('Where to find'));
      }
      final text = File('assets/data/collecting.json').readAsStringSync();
      expect(text, isNot(contains('₹')));
      expect(text.toLowerCase(), isNot(contains('price')));
      final challenge = (await const AssetDataService().loadChallenges())
          .singleWhere((c) => c.id == 'start_a_collection');
      expect(challenge.categoryId, 'collecting');
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- ${challenge.dataAsset}'),
      );
    });

    test('starting a collection and adding pieces', () async {
      final c = await MyCollectionsService.start(
        'collect_sneakers',
        'Sneakers',
      );
      expect(c.things, isEmpty);
      expect(
        await ProgressService.getChallengeItemIds(
          MyCollectionsService.progressKey,
        ),
        contains('collect_sneakers'),
      );
      await MyCollectionsService.addThing(
        'collect_sneakers',
        name: 'First running pair',
        note: 'Bought for my first 10k',
        photo: Uint8List.fromList([1, 2, 3]),
      );
      final all = await MyCollectionsService.load();
      final thing = all['collect_sneakers']!.things.single;
      expect(thing.name, 'First running pair');
      expect(await MyCollectionsService.photo(thing.photoId!), [1, 2, 3]);
      expect(
        await ProgressService.getRewardedEventIds(),
        contains('collection:collect_first_collect_sneakers'),
      );
      await MyCollectionsService.removeThing('collect_sneakers', thing.id);
      expect(
        (await MyCollectionsService.load())['collect_sneakers']!.things,
        isEmpty,
      );
    });

    testWidgets('the tracker adds a piece in a couple of taps', (tester) async {
      await tester.runAsync(
        () => MyCollectionsService.start('collect_coins', 'Coins'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MyCollectionTrackerPage(typeId: 'collect_coins'),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        if (find
            .byKey(const ValueKey('collection-add'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      expect(find.text('My coins'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('collection-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('collection-thing-name')),
        '1985 one-rupee coin',
      );
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('collection-thing-save')));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
        if (find.text('1985 one-rupee coin').evaluate().isNotEmpty) break;
      }
      expect(find.text('1985 one-rupee coin'), findsWidgets);
      await tester.runAsync(() async {
        final all = await MyCollectionsService.load();
        expect(all['collect_coins']!.things.single.name, '1985 one-rupee coin');
      });
    });
  });

  group('Daily Discovery mix', () {
    test(
      'rare fruit varieties only appear once you have tried the fruit',
      () async {
        final none = await DailyDiscoveryService().buildEligiblePool();
        expect(
          none.where((d) => d.type == DailyDiscoveryType.variety),
          isEmpty,
        );
        SharedPreferences.setMockInitialValues({
          'completed_fruit_ids': ['FR001'],
        });
        final some = await DailyDiscoveryService().buildEligiblePool();
        expect(
          some.where((d) => d.type == DailyDiscoveryType.variety),
          isNotEmpty,
        );
      },
    );

    test('a week of picks covers several kinds of things', () async {
      final kinds = <DailyDiscoveryType>{};
      for (var day = 1; day <= 7; day++) {
        SharedPreferences.setMockInitialValues({});
        final pick = await DailyDiscoveryService(
          now: () => DateTime(2026, 12, day, 9),
        ).getToday();
        kinds.add(pick!.type);
      }
      expect(kinds.length, greaterThanOrEqualTo(5));
    });
  });
}
