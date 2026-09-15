import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/screens/challenge/fruit_challenge_page.dart';
import 'package:fruit_atlas/screens/fruit/fruit_details_page.dart';
import 'package:fruit_atlas/theme/app_theme.dart';

void main() {
  testWidgets(
    'Fruit search retains independent completion, persistence and navigation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      // Use the real atlas with a synchronous asset reply to keep the test deterministic.
      final bytes = File('assets/data/fruit_atlas_seed.json').readAsBytesSync();
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async {
          final name = utf8.decode(message!.buffer.asUint8List());
          if (name == 'assets/data/fruit_atlas_seed.json') {
            return ByteData.sublistView(bytes);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        ),
      );
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const challenge = Challenge(
        id: 'taste_fruits_of_india',
        categoryId: 'food_drink',
        name: 'Taste All Fruits of India',
        description: 'Discover fruits across India.',
        itemType: 'fruit',
        totalItems: 100,
        hasSubItems: true,
        status: 'active',
        presentationType: 'checklist_with_subitems',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const FruitChallengePage(challenge: challenge),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'mangifera');
      await tester.pumpAndSettle();
      expect(find.text('Mango'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.byType(FruitDetailsPage), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('completed_fruit_ids'), isNotEmpty);
      await tester.tap(find.text('Mango'));
      await tester.pumpAndSettle();
      expect(find.byType(FruitDetailsPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.ensureVisible(find.byTooltip('Clear search'));
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox).evaluate().length, greaterThan(1));
      expect(tester.takeException(), isNull);
    },
  );
}
