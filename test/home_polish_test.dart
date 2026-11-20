import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/screens/home/home_page.dart';
import 'package:fruit_atlas/screens/fruit/fruit_details_page.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/gamification_header.dart';
import 'package:fruit_atlas/widgets/journey_card.dart';

void main() {
  testWidgets(
    'Home shows real active progress and searches Mango and Dashehari',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'completed_fruit_ids': ['FR001', 'stale_id'],
        'completed_jyotirlinga_ids': ['kedarnath'],
        'completed_yoga_pose_ids': ['mountain_pose'],
      });
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async {
          final name = utf8.decode(message!.buffer.asUint8List());
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
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const HomePage()),
      );
      for (
        var attempt = 0;
        attempt < 40 && find.byType(GamificationHeader).evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump();
      }
      // Keep this assertion diagnostic meaningful when asynchronous loading fails.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final header = tester.widget<GamificationHeader>(
        find.byType(GamificationHeader),
      );
      expect(header.summary.experienceCount, 3);
      expect(header.title, 'UPLYFA');
      expect(find.text('UPLYFA'), findsOneWidget);
      expect(find.textContaining('Fruit Atlas'), findsNothing);
      final cards = tester
          .widgetList<JourneyCard>(find.byType(JourneyCard))
          .toList();
      expect(cards.length, greaterThanOrEqualTo(2));
      expect(cards.map((card) => card.completed), everyElement(1));
      expect(cards.take(2).map((card) => card.challenge.id), [
        'taste_fruits_of_india',
        'visit_12_jyotirlingas',
      ]);
      await tester.scrollUntilVisible(
        find.text('Quick Explore').first,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      final quickExploreTiles = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'quick-explore-',
            ),
      );
      expect(quickExploreTiles, findsNWidgets(6));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('quick-explore-taste_fruits_of_india')),
          matching: find.text('Fruits of India'),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Browse fruits'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Browse fruits'));
      await tester.pump();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Dashehari');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mango'), findsOneWidget);
      await tester.ensureVisible(find.text('Mango'));
      await tester.pump();
      await tester.tap(find.text('Mango'));
      await tester.pumpAndSettle();
      expect(find.byType(FruitDetailsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
