import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/achievement.dart';
import 'package:fruit_atlas/models/mixed_drink.dart';
import 'package:fruit_atlas/models/share_highlight.dart';
import 'package:fruit_atlas/screens/mixed_drinks/mix_share_page.dart';
import 'package:fruit_atlas/screens/mixed_drinks/mixed_drink_detail_page.dart';
import 'package:fruit_atlas/screens/mixed_drinks/mixed_drinks_page.dart';
import 'package:fruit_atlas/services/asset_data_service.dart';
import 'package:fruit_atlas/services/drink_mix_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

DrinkBook _book() => DrinkBook.fromJson(
  jsonDecode(File('assets/data/mixed_drinks.json').readAsStringSync())
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

Future<void> _pumpPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final challenge = (await tester.runAsync(
    () => const AssetDataService().loadChallenges(),
  ))!.singleWhere((c) => c.id == 'mix_drinks');
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MixedDrinksPage(challenge: challenge, random: Random(1)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DrinkMixService.resetCache();
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

  group('Drink book', () {
    final book = _book();

    test('mocktails and cocktails from every continent, no prices', () {
      final mocktails = book.drinks.where((d) => !d.isCocktail);
      expect(book.drinks, hasLength(83));
      expect(mocktails, hasLength(41));
      expect(book.drinks.map((d) => d.id).toSet(), hasLength(83));
      expect({
        for (final d in book.drinks) book.country(d.country).continent,
      }, containsAll(WorldCountry.continents));
      for (final name in [
        'Virgin Mojito', 'Mango Mastani', 'Dalgona Coffee', 'Mojito', //
        'Margarita', 'Negroni', 'Gin and Tonic', 'Feni Cooler',
      ]) {
        expect(book.drinks.map((d) => d.name), contains(name));
      }
      final text = File('assets/data/mixed_drinks.json').readAsStringSync();
      expect(text, isNot(contains('₹')));
      expect(text.toLowerCase(), isNot(contains('price')));
    });

    test('every drink has a recipe; every cocktail a zero-proof way', () {
      for (final d in book.drinks) {
        expect(d.ingredients, isNotEmpty, reason: d.name);
        expect(d.steps, isNotEmpty, reason: d.name);
        expect(d.fact, isNotEmpty, reason: d.name);
        expect(book.countries, contains(d.country), reason: d.name);
        expect(DrinkBook.methods, contains(d.method));
        for (final l in d.ingredients) {
          expect(book.ingredients, contains(l.ingredientId), reason: d.name);
        }
        if (d.isCocktail) {
          expect(d.zeroProof, isNotNull, reason: d.name);
          expect(d.spirit, isNotNull, reason: d.name);
          expect(d.needs.any(book.isAlcohol), isTrue, reason: d.name);
        } else if (d.name != 'Lemon, Lime & Bitters') {
          expect(d.needs.any(book.isAlcohol), isFalse, reason: d.name);
        }
      }
    });

    test('recipes scale by glass and read naturally', () {
      final mojito = book.drinks.singleWhere((d) => d.name == 'Virgin Mojito');
      expect(mojito.ingredients.first.format(1), '10 leaves mint');
      expect(mojito.ingredients.first.format(2), '20 leaves mint');
      expect(mojito.ingredients.last.format(3), 'soda water, to top up');
      expect(RecipeLine.formatAmount(0.5), '½');
      expect(RecipeLine.formatAmount(1.5), '1½');
      expect(
        const RecipeLine(
          ingredientId: 'mint',
          qty: 1,
          unit: 'leaves',
          label: 'mint',
        ).format(1),
        '1 leaf mint',
      );
    });

    test('the shelf finds what you can make, and what is one away', () {
      final shelf = {'mint', 'lime', 'sugar', 'soda'};
      final ready = book.canMake(shelf, cocktails: false).map((d) => d.name);
      expect(ready, containsAll(['Virgin Mojito', 'Lime Rickey']));
      expect(ready, isNot(contains('Mojito')));
      expect(
        book
            .canMake(shelf..add('white_rum'), cocktails: true)
            .map((d) => d.name),
        contains('Mojito'),
      );
      final close = book.oneAway({'lime', 'soda'}, cocktails: false);
      expect(close.map((e) => e.$1.name), isNot(contains('Virgin Mojito')));
      expect(
        close.where((e) => e.$1.name == 'Lime Rickey').single.$2,
        'sugar_syrup',
      );
    });

    test('the challenge is live with its own page and achievements', () async {
      final c = (await const AssetDataService().loadChallenges()).singleWhere(
        (c) => c.id == 'mix_drinks',
      );
      expect(c.status, 'active');
      expect(c.presentationType, 'drink_maker');
      expect(c.totalItems, 83);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- ${c.dataAsset}'),
      );
      // The top achievement is reachable with mocktails alone.
      expect(
        Achievement.forChallenge('mix_drinks').last.threshold,
        lessThanOrEqualTo(41),
      );
    });
  });

  test('making a drink is one tap, rewarded, dated, with a note', () async {
    await DrinkMixService.setMade('mix_virgin_mojito', true);
    expect(await DrinkMixService.madeIds(), {'mix_virgin_mojito'});
    expect(
      await ProgressService.getRewardedEventIds(),
      contains('completion:mix:mix_virgin_mojito'),
    );
    await DrinkMixService.setNote('mix_virgin_mojito', 'Sunday brunch');
    final r = (await DrinkMixService.made())['mix_virgin_mojito']!;
    expect(r.note, 'Sunday brunch');

    final mix = MixBook(
      await DrinkMixService.book(),
      await DrinkMixService.madeIds(),
      await DrinkMixService.made(),
    );
    expect(mix.origins, {'CU'});
    expect(mix.mocktails, 1);
    expect(mix.shareText(), contains('1 drink from 1 country'));

    await DrinkMixService.setMade('mix_virgin_mojito', false);
    expect(await DrinkMixService.madeIds(), isEmpty);
    expect(await DrinkMixService.made(), isEmpty);
  });

  testWidgets('cocktails stay hidden until you choose to see them', (
    tester,
  ) async {
    await _pumpPage(tester);
    await _settle(tester, find.byKey(const ValueKey('mix-count')));
    expect(find.text('41 mocktails'), findsOneWidget);
    expect(find.byKey(const ValueKey('drink-mix_mojito')), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Cocktails'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cocktails-no')));
    await _settle(tester, find.byKey(const ValueKey('cocktails-turn-on')));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cocktails'));
    await tester.pump();
    expect(find.byKey(const ValueKey('cocktails-turn-on')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cocktails-turn-on')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cocktails-yes')));
    await _settle(tester, find.text('42 cocktails'));
    expect(find.text('42 cocktails'), findsOneWidget);
    expect(await tester.runAsync(DrinkMixService.showCocktails), isTrue);
  });

  testWidgets('search, continents and the country view', (tester) async {
    await _pumpPage(tester);
    await _settle(tester, find.byKey(const ValueKey('mix-count')));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Asia'));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('drink-mix_mango_mastani')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('drink-mix_virgin_mojito')), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.enterText(find.byKey(const ValueKey('mix-search')), 'dalgona');
    await tester.pump();
    expect(find.text('1 mocktail'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('drink-check-mix_dalgona_coffee')),
    );
    await _settle(tester, find.textContaining('1 drink made'));
    expect(find.textContaining('from 1 country'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'By country'));
    await tester.pump();
    expect(find.byKey(const ValueKey('mix-country-summary')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mix-country-IN')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mix-country-title-IN')), findsOneWidget);
  });

  testWidgets('ticking the shelf shows what you can make', (tester) async {
    await _pumpPage(tester);
    await _settle(tester, find.byKey(const ValueKey('mix-count')));
    await tester.tap(find.widgetWithText(ChoiceChip, 'What can I make?'));
    await tester.pump();
    expect(find.byKey(const ValueKey('shelf-white_rum')), findsNothing);
    for (final id in ['mint', 'lime', 'sugar', 'soda']) {
      await tester.ensureVisible(find.byKey(ValueKey('shelf-$id')));
      await tester.tap(find.byKey(ValueKey('shelf-$id')));
      await _settle(tester, find.byKey(const ValueKey('shelf-count')));
    }
    await _settle(tester, find.text('Ready to make'));
    expect(find.textContaining('You can make'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('drink-mix_virgin_mojito')),
      findsOneWidget,
    );
    expect(find.text('One thing away'), findsOneWidget);
  });

  testWidgets('the recipe scales, and make mode adds it to the mix book', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MixedDrinkDetailPage(drinkId: 'mix_mojito'),
      ),
    );
    await _settle(tester, find.byKey(const ValueKey('drink-glasses')));
    expect(find.byKey(const ValueKey('drink-zero')), findsOneWidget);
    expect(find.byKey(const ValueKey('drink-responsible')), findsOneWidget);
    expect(find.text('45 ml white rum'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('drink-glasses-plus')));
    await tester.pump();
    expect(find.text('90 ml white rum'), findsOneWidget);
    expect(find.text('2 glasses'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('drink-ing-0')));
    await _settle(tester, find.byIcon(Icons.check_circle));
    expect(await tester.runAsync(DrinkMixService.shelf), contains('white_rum'));

    await tester.ensureVisible(find.byKey(const ValueKey('drink-make')));
    await tester.tap(find.byKey(const ValueKey('drink-make')));
    await tester.pumpAndSettle();
    expect(find.text('Get ready'), findsOneWidget);
    while (find
        .byKey(const ValueKey('drink-step-next'))
        .evaluate()
        .isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('drink-step-next')));
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('drink-cheers')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('drink-make-done')));
    await tester.pumpAndSettle();
    await _settle(tester, find.textContaining('First made'));
    expect(find.text('Made it'), findsOneWidget);
    expect(find.byKey(const ValueKey('drink-note')), findsOneWidget);
  });

  testWidgets('the mix book card renders in both formats', (tester) async {
    final book = _book();
    final mix = MixBook(
      book,
      {'mix_virgin_mojito', 'mix_mango_mastani', 'mix_negroni'},
      {'mix_negroni': DrinkMade(DateTime(2026, 11, 2), note: 'Friday')},
    );
    expect((mix.mocktails, mix.cocktails), (2, 1));
    for (final story in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: MixBookCard(
                  book: mix,
                  format: story
                      ? ShareCardFormat.story
                      : ShareCardFormat.square,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('3 drinks made'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
