import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/challenge.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/screens/challenge/checklist_item_details_page.dart';
import 'package:fruit_atlas/screens/challenge/generic_checklist_challenge_page.dart';
import 'package:fruit_atlas/theme/app_colors.dart';
import 'package:fruit_atlas/theme/app_theme.dart';
import 'package:fruit_atlas/widgets/yoga_pose_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Challenge yoga;
  late List<Item> yogaItems;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final data = jsonDecode(
      File('assets/data/challenges.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    yoga = (data['challenges'] as List<dynamic>)
        .map((entry) => Challenge.fromJson(entry as Map<String, dynamic>))
        .firstWhere((challenge) => challenge.id == 'learn_yoga_poses');
    final yogaData = jsonDecode(
      File('assets/data/yoga_poses.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    yogaItems = (yogaData['items'] as List<dynamic>)
        .map((entry) => Item.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  });

  Future<void> installAssets(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final name = utf8.decode(message!.buffer.asUint8List());
        if (name == 'AssetManifest.bin') {
          return const StandardMessageCodec().encodeMessage(<String, Object>{});
        }
        if (name.startsWith('assets/images/yoga/')) {
          return ByteData.sublistView(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            ),
          );
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
  }

  Future<void> showYoga(WidgetTester tester) async {
    await installAssets(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GenericChecklistChallengePage(challenge: yoga),
      ),
    );
    await tester.pump();
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .text('Explore yoga poses and build your practice.')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
  }

  Future<void> showYogaPose(
    WidgetTester tester,
    String poseId, {
    bool provideCatalogue = true,
  }) async {
    await installAssets(tester);
    final pose = yogaItems.firstWhere((item) => item.id == poseId);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChecklistItemDetailsPage(
          key: ValueKey(poseId),
          challenge: yoga,
          item: pose,
          itemCatalogue: provideCatalogue ? yogaItems : null,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();
  }

  Future<void> swipeRight(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(340, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('Yoga challenge hierarchy, detail, completion and Saved flow', (
    tester,
  ) async {
    await showYoga(tester);

    expect(find.text('Yoga Poses'), findsOneWidget);
    expect(
      find.text('Explore yoga poses and build your practice.'),
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .join(' | '),
    );
    for (final label in [
      'All',
      'Beginner',
      'Intermediate',
      'Difficult',
      'Expert',
    ]) {
      expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
    }
    final beginnerChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Beginner'),
    );
    expect(beginnerChip.labelStyle?.color, AppColors.ink);
    final allChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'All'),
    );
    expect(allChip.labelStyle?.color, Colors.white);
    expect(find.text('48 poses'), findsOneWidget);
    expect(find.text('Mountain Pose'), findsOneWidget);
    expect(
      tester.widget<YogaPoseImage>(find.byType(YogaPoseImage).first).imagePath,
      'assets/images/yoga/mountain_pose.webp',
    );
    expect(
      tester.widget<YogaPoseImage>(find.byType(YogaPoseImage).first).fit,
      BoxFit.contain,
    );

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Intermediate'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Intermediate'));
    await tester.pumpAndSettle();
    expect(find.text('41 poses'), findsOneWidget);
    expect(find.text('Eagle Pose'), findsOneWidget);
    expect(find.text('Dancer Pose'), findsOneWidget);
    expect(find.text('Mountain Pose'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Difficult'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Difficult'));
    await tester.pumpAndSettle();
    expect(find.text('27 poses'), findsOneWidget);
    expect(find.byType(YogaPoseTile), findsWidgets);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Expert'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Expert'));
    await tester.pumpAndSettle();
    expect(find.text('16 poses'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'All'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.byType(YogaPoseTile).evaluate().length, lessThan(28));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pumpAndSettle();

    final section = find.byKey(const ValueKey('yoga-difficulty-Beginner-All'));
    final headerTitle = find.descendant(
      of: section,
      matching: find.text('Beginner'),
    );
    expect(headerTitle, findsOneWidget);
    expect(tester.getTopLeft(headerTitle).dy, lessThan(100));

    await tester.tap(headerTitle);
    await tester.pumpAndSettle();
    expect(find.byType(YogaPoseTile), findsNothing);
    expect(find.text('Intermediate'), findsWidgets);

    await tester.tap(headerTitle);
    await tester.pumpAndSettle();
    expect(find.text('Mountain Pose'), findsOneWidget);

    await tester.tap(find.text('Mountain Pose'));
    await tester.pumpAndSettle();
    expect(find.byType(ChecklistItemDetailsPage), findsOneWidget);
    expect(
      tester.widget<YogaPoseImage>(find.byType(YogaPoseImage)).imagePath,
      'assets/images/yoga/mountain_pose.webp',
    );
    expect(
      tester.widget<YogaPoseImage>(find.byType(YogaPoseImage)).fit,
      BoxFit.contain,
    );
    expect(find.text('Yoga Pose'), findsOneWidget);
    expect(find.text('Standing'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Tadasana'), findsOneWidget);
    expect(find.text('Alignment'), findsOneWidget);
    expect(find.text('How to do it'), findsOneWidget);
    expect(find.text('Practice safely'), findsOneWidget);

    await swipeLeft(tester);
    expect(find.text('Raised Arms Pose'), findsOneWidget);
    expect(find.text('Mountain Pose'), findsNothing);
    await swipeRight(tester);
    expect(find.text('Mountain Pose'), findsOneWidget);

    await tester.tap(find.byTooltip('Save pose'));
    await tester.pumpAndSettle();
    var prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('saved_entity_references'),
      contains('yogaPose:mountain_pose'),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Mark as Completed'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Completed'), findsOneWidget);

    await swipeLeft(tester);
    expect(find.byTooltip('Save pose'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Mark as Completed'),
      findsOneWidget,
    );
    await swipeRight(tester);
    expect(find.byTooltip('Remove pose from Saved'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Completed'), findsOneWidget);
    prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList('completed_yoga_pose_ids'),
      contains('mountain_pose'),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('1 of 132 explored'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Mountain Pose'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Mountain Pose'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove pose from Saved'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Yoga pager detects every difficulty boundary in both directions',
    (tester) async {
      for (final boundary in [
        ('tabletop_pose', 'Eagle Pose', 'Intermediate'),
        ('side_reclining_leg_lift', 'Crow Pose', 'Difficult'),
        ('revolved_half_moon_pose', 'Scorpion Pose', 'Expert'),
      ]) {
        await showYogaPose(tester, boundary.$1);
        await swipeLeft(tester);
        expect(find.text(boundary.$2), findsOneWidget);
        expect(
          find.text("You're now exploring ${boundary.$3} poses"),
          findsOneWidget,
        );
        await swipeRight(tester);
        final previousDifficulty = yogaItems
            .firstWhere((item) => item.id == boundary.$1)
            .difficulty;
        expect(
          find.text("You're now exploring $previousDifficulty poses"),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'Yoga pager resolves entry index and clamps first and last poses',
    (tester) async {
      await showYogaPose(tester, 'eagle_pose', provideCatalogue: false);
      expect(find.text('Eagle Pose'), findsOneWidget);

      await showYogaPose(tester, 'mountain_pose');
      await swipeRight(tester);
      expect(find.text('Mountain Pose'), findsOneWidget);

      await showYogaPose(tester, 'dragonfly_pose');
      await swipeLeft(tester);
      expect(find.text('Dragonfly Pose'), findsOneWidget);
    },
  );

  testWidgets('missing Yoga illustration displays the shared placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: YogaPoseImage(
            imagePath: 'assets/images/yoga/not_available.webp',
            width: 72,
            height: 52,
            iconSize: 28,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.self_improvement), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
