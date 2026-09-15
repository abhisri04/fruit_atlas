import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/screens/challenge/fruit_challenge_page.dart';
import 'package:fruit_atlas/services/district_repository.dart';
import 'package:fruit_atlas/services/experience_repository.dart';
import 'package:fruit_atlas/services/experience_collection_repository.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('fruit completion is shared with the Rajasthan context', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'completed_fruit_ids': ['FR001'],
    });
    ExperienceRepository.clearCacheForTesting();
    ExperienceCollectionRepository.clearCacheForTesting();
    DistrictRepository.clearCacheForTesting();
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
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic> readJson(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final challenges =
        (readJson('assets/data/challenges.json')['challenges'] as List)
            .map((entry) => Challenge.fromJson(entry as Map<String, dynamic>))
            .toList();
    final stateChallenge = challenges.firstWhere(
      (item) => item.id == 'explore_indian_states',
    );
    final fruitChallenge = challenges.firstWhere(
      (item) => item.id == 'taste_fruits_of_india',
    );
    final rajasthan =
        (readJson('assets/data/india_states_uts.json')['items'] as List)
            .map((entry) => Item.fromJson(entry as Map<String, dynamic>))
            .firstWhere((item) => item.id == 'rajasthan');

    Future<void> showRajasthan() async {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AppTheme.light,
          home: ChecklistItemDetailsPage(
            challenge: stateChallenge,
            item: rajasthan,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Food & Drink'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food & Drink'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Mango'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
    }

    Finder mangoCheckbox() => find.descendant(
      of: find.ancestor(
        of: find.text('Mango'),
        matching: find.byType(ListTile),
      ),
      matching: find.byType(Checkbox),
    );

    await showRajasthan();
    expect(tester.widget<Checkbox>(mangoCheckbox()).value, isTrue);
    await tester.tap(mangoCheckbox());
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('completed_fruit_ids'), isEmpty);
    expect(prefs.getStringList('completed_india_state_ut_ids'), isNull);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.light,
        home: FruitChallengePage(challenge: fruitChallenge),
      ),
    );
    await tester.pumpAndSettle();
    final mangoChallengeTile = find.widgetWithText(ListTile, 'Mango');
    await tester.scrollUntilVisible(
      mangoChallengeTile,
      250,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final fruitCheckbox = find.descendant(
      of: mangoChallengeTile.first,
      matching: find.byType(Checkbox),
    );
    expect(tester.widget<Checkbox>(fruitCheckbox).value, isFalse);
    await tester.tap(fruitCheckbox);
    await tester.pumpAndSettle();
    expect(prefs.getStringList('completed_fruit_ids'), ['FR001']);

    await showRajasthan();
    expect(tester.widget<Checkbox>(mangoCheckbox()).value, isTrue);
  });
}
