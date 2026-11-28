import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fruit_atlas/models/share_highlight.dart';
import 'package:fruit_atlas/screens/share/share_studio_page.dart';

ShareHighlightItem item(
  String reference,
  String title,
  ShareHighlightCategory category,
) => ShareHighlightItem(reference: reference, title: title, category: category);

final completed = [
  item('fruit:FR001', 'Mango', ShareHighlightCategory.fruit),
  item('fruit:FR002', 'Banana', ShareHighlightCategory.fruit),
  item('dish:DIS001', 'Dosa', ShareHighlightCategory.dish),
  item('drink:DR001', 'Masala Chai', ShareHighlightCategory.drink),
  item('book:BK001', 'Godaan', ShareHighlightCategory.book),
  item('yoga:YP001', 'Mountain Pose', ShareHighlightCategory.yoga),
  item('state:RJ', 'Rajasthan', ShareHighlightCategory.travel),
  item('jyotirlinga:JY01', 'Somnath', ShareHighlightCategory.pilgrimage),
  item('dish:DIS002', 'Idli', ShareHighlightCategory.dish),
  item('drink:DR002', 'Kahwa', ShareHighlightCategory.drink),
  item('book:BK002', 'Gitanjali', ShareHighlightCategory.book),
  item('yoga:YP002', 'Tree Pose', ShareHighlightCategory.yoga),
  item('state:KL', 'Kerala', ShareHighlightCategory.travel),
];

void main() {
  group('ShareHighlightController', () {
    test('prunes stale, incomplete, duplicate, and over-limit references', () {
      final controller = ShareHighlightController(
        completedItems: [...completed, completed.first],
        format: ShareCardFormat.square,
        selectedReferences: [
          'fruit:FR001',
          'missing:OLD',
          ...completed.skip(1).map((value) => value.reference),
        ],
      );

      expect(controller.completedItems, hasLength(completed.length));
      expect(controller.selectedReferences, hasLength(8));
      expect(controller.selectedReferences, isNot(contains('missing:OLD')));
    });

    test('manual mode starts empty without changing Auto highlights', () {
      final controller = ShareHighlightController(completedItems: completed);
      final automatic = controller.previewItems;

      controller.mode = HighlightSelectionMode.manual;

      expect(automatic, hasLength(12));
      expect(controller.previewItems, isEmpty);
    });

    test('Story and Square enforce 12 and 8 item limits', () {
      final story = ShareHighlightController(completedItems: completed);
      story.mode = HighlightSelectionMode.manual;
      for (final value in completed) {
        story.toggle(value.reference);
      }
      expect(story.selectedReferences, hasLength(12));

      story.setFormat(ShareCardFormat.square);
      expect(story.selectedReferences, hasLength(8));
      expect(story.toggle(completed.last.reference), isFalse);
    });

    test('selection can be toggled and cleared', () {
      final controller = ShareHighlightController(completedItems: completed);
      expect(controller.toggle('fruit:FR001'), isTrue);
      expect(controller.selectedReferences, {'fruit:FR001'});
      expect(controller.toggle('fruit:FR001'), isTrue);
      expect(controller.selectedReferences, isEmpty);
      controller.autoFill();
      controller.clear();
      expect(controller.selectedReferences, isEmpty);
    });

    test('only canonical completed references can be selected', () {
      final controller = ShareHighlightController(completedItems: completed);
      expect(controller.toggle('fruit:FR999'), isFalse);
      expect(controller.selectedReferences, isEmpty);
    });

    test('search is normalized and category filters compose with it', () {
      final controller = ShareHighlightController(completedItems: completed);
      expect(
        controller.visibleItems(query: '  MASALA  ').single.reference,
        'drink:DR001',
      );
      expect(
        controller
            .visibleItems(query: 'ka', category: ShareHighlightCategory.drink)
            .map((value) => value.title),
        ['Kahwa'],
      );
      expect(
        controller.visibleItems(
          query: 'mango',
          category: ShareHighlightCategory.book,
        ),
        isEmpty,
      );
    });

    test('auto-fill is deterministic, balanced, unique, and capped', () {
      final first = ShareHighlightController.autoSelection(completed, 8);
      final second = ShareHighlightController.autoSelection(completed, 8);

      expect(
        first.map((value) => value.reference),
        second.map((value) => value.reference),
      );
      expect(first.map((value) => value.reference).toSet(), hasLength(8));
      expect(first.map((value) => value.category).toSet(), hasLength(7));
    });

    test(
      'preview layout promotes small selections and compacts larger ones',
      () {
        expect(ShareHighlightLayout.columns(1, ShareCardFormat.story), 1);
        expect(ShareHighlightLayout.columns(4, ShareCardFormat.story), 2);
        expect(ShareHighlightLayout.columns(10, ShareCardFormat.story), 3);
        expect(ShareHighlightLayout.columns(2, ShareCardFormat.square), 1);
        expect(ShareHighlightLayout.columns(7, ShareCardFormat.square), 2);
      },
    );
  });

  group('Share Studio picker', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'share_studio_highlights_mode_v1': 'manual',
        'share_studio_highlights_format_v1': 'story',
      });
    });

    testWidgets('shows only completed items and all requested filters', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ShareStudioPage(completedItems: completed)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mango'), findsWidgets);
      expect(find.text('Pick myself'), findsOneWidget);
      for (final label in [
        'All',
        'Fruits',
        'Dishes',
        'Drinks',
        'Books',
        'Yoga',
        'Travel',
        'Pilgrimage',
      ]) {
        expect(find.text(label), findsWidgets);
      }
    });

    testWidgets('search and filter update the picker without parsing data', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ShareStudioPage(completedItems: completed)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('share-picker-search')),
        'mango',
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('share-item-fruit:FR001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('share-item-dish:DIS001')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('share-filter-book')));
      await tester.pump();
      expect(find.text('No completed experiences match.'), findsOneWidget);
    });

    testWidgets('selection count, clear, auto-fill, and preview update live', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ShareStudioPage(completedItems: completed.take(4).toList()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UPLYFA · Experience more.'), findsOneWidget);

      final mango = find.byKey(const ValueKey('share-item-fruit:FR001'));
      await tester.ensureVisible(mango);
      await tester.tap(mango);
      await tester.pumpAndSettle();
      expect(find.text('1 / 12 selected'), findsOneWidget);
      expect(find.text('1 completed experiences'), findsOneWidget);

      final clear = find.byKey(const ValueKey('share-clear-all'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(find.text('0 / 12 selected'), findsOneWidget);
      expect(
        find.textContaining('Choose completed experiences'),
        findsOneWidget,
      );

      final autoFill = find.byKey(const ValueKey('share-auto-fill'));
      await tester.ensureVisible(autoFill);
      await tester.tap(autoFill);
      await tester.pumpAndSettle();
      expect(find.text('4 / 12 selected'), findsOneWidget);
    });

    testWidgets('format change prunes manual selection to square limit', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'share_studio_highlights_mode_v1': 'manual',
        'share_studio_highlights_format_v1': 'story',
        'share_studio_highlights_selection_v1': completed
            .take(12)
            .map((value) => value.reference)
            .toList(),
      });
      await tester.pumpWidget(
        MaterialApp(home: ShareStudioPage(completedItems: completed)),
      );
      await tester.pumpAndSettle();
      expect(find.text('12 / 12 selected'), findsOneWidget);

      await tester.tap(find.text('Square 1:1'));
      await tester.pump();
      expect(find.text('8 / 8 selected'), findsOneWidget);
    });

    testWidgets('Auto and Pick myself remain independent modes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ShareStudioPage(completedItems: completed.take(3).toList()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 completed experiences'), findsOneWidget);

      final auto = find.text('Auto');
      await tester.ensureVisible(auto);
      await tester.tap(auto);
      await tester.pumpAndSettle();
      expect(find.text('3 completed experiences'), findsOneWidget);

      final manual = find.text('Pick myself');
      await tester.ensureVisible(manual);
      await tester.tap(manual);
      await tester.pumpAndSettle();
      expect(find.text('0 completed experiences'), findsOneWidget);
    });
  });
}
