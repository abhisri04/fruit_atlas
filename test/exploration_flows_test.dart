import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/screens/challenge/generic_checklist_challenge_page.dart';
import 'package:fruit_atlas/screens/challenge/jyotirlinga_challenge_page.dart';
import 'package:fruit_atlas/screens/my_life/my_life_page.dart';
import 'package:fruit_atlas/screens/saved/saved_page.dart';
import 'package:fruit_atlas/theme/app_theme.dart';

void main() {
  testWidgets('Yoga and temple completion feed Saved and My Life', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
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
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = jsonDecode(
      File('assets/data/challenges.json').readAsStringSync(),
    );
    final challenges = (data['challenges'] as List)
        .map((c) => Challenge.fromJson(c))
        .toList();
    final yoga = challenges.firstWhere((c) => c.id == 'learn_yoga_poses');
    final temple = challenges.firstWhere(
      (c) => c.id == 'visit_12_jyotirlingas',
    );
    Future<void> show(Widget page) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: page));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      await tester.pump();
    }

    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    await show(GenericChecklistChallengePage(challenge: yoga));
    await tester.tap(find.text('Mountain Pose'));
    await settle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark as Completed'));
    await settle();
    await tester.pageBack();
    await settle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('completed_yoga_pose_ids'), ['mountain_pose']);
    await tester.tap(find.byTooltip('Save challenge'));
    await settle();
    expect(prefs.getStringList('saved_challenge_ids'), [yoga.id]);
    await show(const SavedPage());
    expect(find.text('1 of 132 explored'), findsOneWidget);
    await tester.tap(find.text(yoga.name));
    await settle();
    await tester.tap(find.text('Mountain Pose'));
    await settle();
    expect(find.widgetWithText(FilledButton, 'Completed'), findsOneWidget);
    await tester.pageBack();
    await settle();
    await tester.pageBack();
    await settle();
    await tester.tap(find.byTooltip('Remove from Saved'));
    await settle();
    expect(prefs.getStringList('saved_challenge_ids'), isEmpty);
    expect(find.text('Keep your next adventure close'), findsOneWidget);
    await show(JyotirlingaChallengePage(challenge: temple));
    await tester.scrollUntilVisible(find.byType(Image), 200);
    await settle();
    expect(find.byType(Image), findsOneWidget);
    await tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, 'List'),
      -180,
    );
    await settle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'List'));
    await settle();
    await tester.scrollUntilVisible(find.text('Kedarnath'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(prefs.getStringList('completed_jyotirlinga_ids'), hasLength(1));
    await show(const MyLifePage());
    expect(
      find.text(
        '2 challenges completed. Your experiences include fruits, varieties, visits and yoga poses.',
      ),
      findsNothing,
    );
    expect(find.text('Challenges started'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('1 of 12 visited'), 200);
    expect(find.text('1 of 12 visited'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('1 of 132 poses learned'), 200);
    expect(find.text('1 of 132 poses learned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
