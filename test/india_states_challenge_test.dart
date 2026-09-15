import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/achievement.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/screens/challenge/generic_checklist_challenge_page.dart';
import 'package:fruit_atlas/screens/my_life/my_life_page.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  Challenge statesChallenge() {
    final raw = readJson('assets/data/challenges.json')['challenges'] as List;
    return raw
        .map((entry) => Challenge.fromJson(entry as Map<String, dynamic>))
        .firstWhere((challenge) => challenge.id == 'explore_indian_states');
  }

  void installAssetHandler(WidgetTester tester) {
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
  }

  test('dataset and configuration contain exactly 28 states and 8 UTs', () {
    final challenge = statesChallenge();
    final items =
        readJson('assets/data/india_states_uts.json')['items'] as List;

    expect(challenge.status, 'active');
    expect(challenge.totalItems, 36);
    expect(challenge.progressKey, 'completed_india_state_ut_ids');
    expect(challenge.sections, ['List', 'Achievements', 'About']);
    expect(items, hasLength(36));
    expect(items.map((item) => item['id']).toSet(), hasLength(36));
    expect(items.where((item) => item['category'] == 'State'), hasLength(28));
    expect(
      items.where((item) => item['category'] == 'Union Territory'),
      hasLength(8),
    );
    expect(Achievement.forChallenge(challenge.id).map((a) => a.threshold), [
      1,
      10,
      18,
      25,
      36,
    ]);
  });

  testWidgets('filters, details, and persisted progress use generic flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    installAssetHandler(tester);
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

    final challenge = statesChallenge();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GenericChecklistChallengePage(
          key: UniqueKey(),
          challenge: challenge,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('0 of 36 explored'), findsOneWidget);
    expect(find.text('28 States · 8 Union Territories'), findsOneWidget);
    for (final filter in [
      'All',
      'States',
      'Union Territories',
      'Explored',
      'To Explore',
    ]) {
      expect(find.widgetWithText(ChoiceChip, filter), findsOneWidget);
    }
    await tester.tap(find.byTooltip('Save challenge'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('saved_challenge_ids'), [challenge.id]);

    await tester.scrollUntilVisible(find.text('Rajasthan'), 300);
    await tester.pumpAndSettle();
    final row = find.ancestor(
      of: find.text('Rajasthan'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: row, matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('completed_india_state_ut_ids'), ['rajasthan']);

    await tester.tap(find.text('Rajasthan'));
    await tester.pumpAndSettle();
    expect(find.text('State · India'), findsOneWidget);
    expect(find.text('About Rajasthan'), findsOneWidget);
    expect(find.text('Capital'), findsOneWidget);
    expect(find.text('Jaipur'), findsWidgets);
    expect(find.text('Region'), findsOneWidget);
    expect(find.text('Northwestern India'), findsOneWidget);
    expect(find.text('EXPLORE RAJASTHAN'), findsOneWidget);
    expect(find.text('0 of 117'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GenericChecklistChallengePage(
          key: UniqueKey(),
          challenge: challenge,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 of 36 explored'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Explored'));
    await tester.pumpAndSettle();
    expect(find.text('Rajasthan'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Union Territories'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Andaman and Nicobar Islands'),
      100,
    );
    expect(find.text('Andaman and Nicobar Islands'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MyLifePage()),
    );
    await tester.pumpAndSettle();
    expect(find.text('States & UTs explored'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('1 of 36 states and UTs explored'),
      250,
    );
    expect(find.text('1 of 36 states and UTs explored'), findsOneWidget);
  });
}
