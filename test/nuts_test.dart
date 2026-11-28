import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/achievement.dart';
import 'package:fruit_atlas/models/nut.dart';
import 'package:fruit_atlas/models/share_highlight.dart';
import 'package:fruit_atlas/screens/nuts/nut_detail_page.dart';
import 'package:fruit_atlas/screens/nuts/nut_quiz.dart';
import 'package:fruit_atlas/screens/nuts/nut_share_page.dart';
import 'package:fruit_atlas/screens/nuts/nuts_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/nut_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

NutAtlas _atlas() => NutAtlas.fromJson(
  jsonDecode(File('assets/data/nuts.json').readAsStringSync())
      as Map<String, dynamic>,
);

Future<void> _settle(WidgetTester tester, Finder until) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (until.evaluate().isNotEmpty) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NutService.resetCache();
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

  group('Nut catalogue', () {
    final atlas = _atlas();

    test('53 nuts from every continent, not just India, and no prices', () {
      expect(atlas.nuts, hasLength(53));
      expect(atlas.nuts.map((n) => n.id).toSet(), hasLength(53));
      final continents = {for (final n in atlas.nuts) ...atlas.continentsOf(n)};
      expect(continents, containsAll(NutAtlas.continents));
      // Most nuts first came from outside India.
      expect(
        atlas.nuts.where((n) => !n.native.contains('IN')).length,
        greaterThan(35),
      );
      for (final name in [
        'Almond', 'Cashew', 'Pistachio', 'Hazelnut', 'Pecan', //
        'Macadamia', 'Brazil nut', 'Walnut', 'Chilgoza', 'Makhana',
      ]) {
        expect(atlas.nuts.map((n) => n.name), contains(name));
      }
      final text = File('assets/data/nuts.json').readAsStringSync();
      expect(text, isNot(contains('₹')));
      expect(text.toLowerCase(), isNot(contains('price')));
      expect(text.toLowerCase(), isNot(contains(' rs')));
    });

    test('every nut has a home, a kind, a taste and ways to try it', () {
      for (final n in atlas.nuts) {
        expect(n.native, isNotEmpty, reason: n.name);
        expect(n.grown, isNotEmpty, reason: n.name);
        expect(NutAtlas.kinds, contains(n.kind));
        expect(NutAtlas.finds, contains(n.find));
        expect(n.ways, isNotEmpty);
        expect(n.fact, isNotEmpty);
        for (final c in n.countries) {
          expect(atlas.countries, contains(c), reason: '${n.name} $c');
        }
      }
      final cashew = atlas.nuts.singleWhere((n) => n.name == 'Cashew');
      expect(cashew.native, ['BR']);
      expect(cashew.grownInIndia, isTrue);
      expect(cashew.aliases, contains('Kaju'));
      final pistachio = atlas.nuts.singleWhere((n) => n.name == 'Pistachio');
      expect(pistachio.grownInIndia, isFalse);
      expect(pistachio.easyInIndia, isTrue);
    });

    test('search finds Indian names, and countries list their nuts', () {
      final kaju = atlas.nuts.where((n) => n.matches('kaju'));
      expect(kaju.single.name, 'Cashew');
      expect(
        atlas.nuts.where((n) => n.matches('akhrot')).single.name,
        'Walnut',
      );
      final brazil = atlas.nutsFor('BR').map((n) => n.name);
      expect(brazil, containsAll(['Cashew', 'Brazil nut']));
      expect(NutCountry('IN', 'India', 'Asia').flag, '🇮🇳');
    });

    test('the challenge is live with its own page and achievements', () async {
      final c = (await const AssetDataService().loadChallenges()).singleWhere(
        (c) => c.id == 'taste_world_nuts',
      );
      expect(c.status, 'active');
      expect(c.presentationType, 'nut_atlas');
      expect(c.totalItems, 53);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- ${c.dataAsset}'),
      );
      expect(Achievement.forChallenge('taste_world_nuts').last.threshold, 53);
    });
  });

  test(
    'tasting a nut is one tap, rewarded, dated, with an optional note',
    () async {
      await NutService.setTried('nut_cashew', true);
      expect(await NutService.triedIds(), contains('nut_cashew'));
      expect(
        await ProgressService.getRewardedEventIds(),
        contains('completion:nut:nut_cashew'),
      );
      await NutService.setNote('nut_cashew', 'Goa market');
      final t = (await NutService.tastings())['nut_cashew']!;
      expect(t.note, 'Goa market');

      final passport = NutPassport(
        await NutService.atlas(),
        await NutService.triedIds(),
        await NutService.tastings(),
      );
      expect(passport.origins, {'BR'});
      expect(passport.shareText(), contains('1 nut from 1 country'));

      await NutService.setTried('nut_cashew', false);
      expect(await NutService.triedIds(), isEmpty);
      expect(await NutService.tastings(), isEmpty);
    },
  );

  testWidgets('filters narrow the list and the country view opens a country', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final challenge = (await tester.runAsync(
      () => const AssetDataService().loadChallenges(),
    ))!.singleWhere((c) => c.id == 'taste_world_nuts');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NutsPage(challenge: challenge),
      ),
    );
    await _settle(tester, find.byKey(const ValueKey('nuts-count')));
    expect(find.text('53 nuts'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'South America'));
    await tester.pump();
    final south = tester.widget<Text>(find.byKey(const ValueKey('nuts-count')));
    expect(south.data, isNot('53 nuts'));
    expect(find.byKey(const ValueKey('nut-nut_cashew')), findsOneWidget);
    expect(find.byKey(const ValueKey('nut-nut_almond')), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.enterText(find.byKey(const ValueKey('nuts-search')), 'pista');
    await tester.pump();
    expect(find.text('1 nut'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nut-check-nut_pistachio')));
    await _settle(tester, find.textContaining('1 of 53 tasted'));
    expect(find.textContaining('from 2 countries'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'By country'));
    await tester.pump();
    expect(find.byKey(const ValueKey('nuts-country-summary')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nut-country-IR')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nut-country-title-IR')), findsOneWidget);
    expect(find.text('First came from here'), findsOneWidget);
  });

  testWidgets('the nut page shows origins, India and safety', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const NutDetailPage(nutId: 'nut_brazil_nut'),
      ),
    );
    await _settle(tester, find.text('First came from'));
    expect(find.text('First came from'), findsOneWidget);
    expect(find.textContaining('Bolivia'), findsWidgets);
    expect(find.byKey(const ValueKey('nut-safety')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nut-tried')));
    await _settle(tester, find.textContaining('First tasted'));
    expect(find.byKey(const ValueKey('nut-note')), findsOneWidget);
  });

  testWidgets('Nut or not? teaches the answer and can be played again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: NutQuiz(atlas: _atlas(), rounds: 2, random: Random(1)),
          ),
        ),
      ),
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('nut-quiz-Legume')));
      await tester.pump();
      expect(find.byKey(const ValueKey('nut-quiz-answer')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nut-quiz-next')));
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('nut-quiz-done')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nut-quiz-again')));
    await tester.pump();
    expect(find.byKey(const ValueKey('nut-quiz-question')), findsOneWidget);
  });

  testWidgets('the passport card renders in both formats', (tester) async {
    final atlas = _atlas();
    final passport = NutPassport(
      atlas,
      {'nut_cashew', 'nut_pecan', 'nut_makhana'},
      {'nut_cashew': NutTasting(DateTime(2026, 11, 2), note: 'Goa')},
    );
    for (final story in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: NutPassportCard(
                  passport: passport,
                  format: story
                      ? ShareCardFormat.story
                      : ShareCardFormat.square,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('3 nuts tasted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test(
    'kinds live inside their nut, are searchable and count as tasting',
    () async {
      final atlas = _atlas();
      final almond = atlas.nuts.singleWhere((n) => n.name == 'Almond');
      expect(
        almond.kinds.map((k) => k.name),
        containsAll(['Mamra', 'Marcona']),
      );
      expect(almond.kinds.first.flag, isNotNull);
      expect(atlas.nuts.where((n) => n.matches('mamra')).single.name, 'Almond');
      expect(
        atlas.nuts.where((n) => n.kinds.isNotEmpty).length,
        greaterThanOrEqualTo(12),
      );
      for (final name in ['Soy nut', 'Hemp seed', 'African walnut']) {
        expect(atlas.nuts.map((n) => n.name), contains(name));
      }

      final mamra = almond.kinds.first;
      await NutService.setKindTried(almond.id, mamra.id, true);
      expect(await NutService.triedKindIds(), {mamra.id});
      expect(await NutService.triedIds(), {almond.id});
      expect(
        await ProgressService.getRewardedEventIds(),
        contains('completion:nutkind:${mamra.id}'),
      );
    },
  );

  testWidgets('the nut page lists kinds you can tick', (tester) async {
    tester.view.physicalSize = const Size(800, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const NutDetailPage(nutId: 'nut_pistachio'),
      ),
    );
    await _settle(tester, find.byKey(const ValueKey('nut-kinds-count')));
    expect(find.text('0 of 5 tasted'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('nut-kind-nut_pistachio__antep')),
    );
    await _settle(tester, find.text('1 of 5 tasted'));
    expect(find.text('1 of 5 tasted'), findsOneWidget);
    expect(find.text('Tasted'), findsOneWidget);
  });
}
