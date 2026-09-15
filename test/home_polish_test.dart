import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/screens/home/home_page.dart';
import 'package:fruit_atlas/screens/search/discovery_search_page.dart';
import 'package:fruit_atlas/screens/fruit/fruit_details_page.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/challenge_card.dart';

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
      await tester.pumpAndSettle();
      expect(find.text('3 experiences explored'), findsOneWidget);
      final cards = tester.widgetList<ChallengeCard>(
        find.byType(ChallengeCard),
      );
      expect(cards.length, 4);
      expect(
        cards.map((card) => card.completedCount),
        containsAll(<int>[1, 1, 1, 0]),
      );
      await tester.tap(find.byTooltip('Search discovery'));
      await tester.pumpAndSettle();
      expect(find.byType(DiscoverySearchPage), findsOneWidget);
      for (final query in ['Mango', 'Dashehari', 'Mangifera indica']) {
        await tester.enterText(find.byType(TextField), query);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.widgetWithText(ListTile, 'Mango'),
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.widgetWithText(ListTile, 'Mango'), findsOneWidget);
      }
      await Scrollable.ensureVisible(
        tester.element(find.text('Mango')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mango'));
      await tester.pumpAndSettle();
      expect(find.byType(FruitDetailsPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'not-a-fruit');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('No results found'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Explore categories and challenges'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Dashehari');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Mango'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
