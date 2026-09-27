import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/screens/dishes/indian_dishes_page.dart';
import 'package:fruit_atlas/screens/drinks/indian_drinks_page.dart';
import 'package:fruit_atlas/screens/home/home_page.dart';
import 'package:fruit_atlas/screens/my_life/my_life_page.dart';
import 'package:fruit_atlas/screens/saved/saved_page.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'category_item_progress_v1_CAT_INDIAN_DISHES': jsonEncode({
        'exp_west_bengal_aam_achar_ilish': {
          'tried': true,
          'cooked': true,
          'want_to_try': false,
          'favourite': true,
        },
        'exp_uttar_pradesh_aam_papad': {
          'tried': false,
          'cooked': false,
          'want_to_try': true,
          'favourite': false,
        },
      }),
      'category_item_progress_v1_CAT_INDIAN_DRINKS': jsonEncode({
        'DRK011': {
          'tried': true,
          'cooked': false,
          'want_to_try': false,
          'favourite': true,
        },
        'exp_himachal_pradesh_apple_juice': {
          'tried': false,
          'cooked': false,
          'want_to_try': true,
          'favourite': false,
        },
      }),
    });
  });

  void installAssets(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final name = utf8.decode(message!.buffer.asUint8List());
        if (name == 'AssetManifest.bin') {
          return const StandardMessageCodec().encodeMessage(<String, Object>{});
        }
        final file = File(name);
        return file.existsSync()
            ? ByteData.sublistView(file.readAsBytesSync())
            : null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        null,
      ),
    );
  }

  Future<void> show(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
  }

  testWidgets('Home and My Life include canonical dish and drink progress', (
    tester,
  ) async {
    installAssets(tester);
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await show(tester, const HomePage());
    expect(find.text('2 experiences explored'), findsOneWidget);
    await show(tester, const MyLifePage());
    expect(find.text('Indian dishes tried'), findsOneWidget);
    expect(find.text('Indian dishes cooked'), findsOneWidget);
    expect(find.text('Indian drinks tried'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Indian Dishes'), 300);
    await tester.pump();
    expect(find.text('1 of 640 dishes tried'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Indian Drinks'), 300);
    await tester.pump();
    expect(find.text('1 of 68 drinks tried'), findsOneWidget);
  });

  testWidgets('Saved surfaces catalogue actions and opens canonical details', (
    tester,
  ) async {
    installAssets(tester);
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await show(tester, const SavedPage());
    expect(find.text('Want to Try'), findsOneWidget);
    expect(find.text('Favourites'), findsOneWidget);
    expect(find.text('Aam Papad'), findsOneWidget);
    expect(find.text('Apple Juice'), findsOneWidget);
    expect(find.text('Aam Achar Ilish'), findsOneWidget);
    expect(find.text('Aam Panna'), findsOneWidget);

    await tester.tap(find.text('Aam Achar Ilish'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DishDetailPage), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Aam Panna'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DrinkDetailPage), findsOneWidget);
  });
}
