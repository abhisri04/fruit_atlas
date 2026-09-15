import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_atlas/widgets/discovery_search_field.dart';
import 'package:fruit_atlas/widgets/completion_feedback.dart';
import 'package:fruit_atlas/widgets/exploration_hero.dart';
import 'package:fruit_atlas/widgets/progress_card.dart';
import 'package:fruit_atlas/widgets/filter_chip_group.dart';
import 'package:fruit_atlas/screens/fruit/fruit_details_page.dart';
import 'package:fruit_atlas/models/fruit.dart';
import 'package:fruit_atlas/theme/app_colors.dart';
import 'package:fruit_atlas/widgets/metadata_chip.dart';
import 'package:fruit_atlas/theme/app_theme.dart';

void main() {
  testWidgets('Debounce coalesces typing and clear cancels pending search', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoverySearchField(
            controller: controller,
            onChanged: calls.add,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'man');
    await tester.pump(const Duration(milliseconds: 150));
    expect(calls, isEmpty);
    await tester.enterText(find.byType(TextField), 'mango');
    await tester.pump(const Duration(milliseconds: 249));
    expect(calls, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, ['mango']);
    await tester.enterText(find.byType(TextField), 'temple');
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls, ['mango', '']);
  });
  testWidgets('Feedback celebrates configured milestones and ignores removal', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    showCompletionFeedback(
      pageContext,
      before: 4,
      after: 5,
      total: 100,
      challengeId: 'taste_fruits_of_india',
    );
    await tester.pumpAndSettle();
    expect(find.text('Achievement unlocked: Getting Started'), findsOneWidget);
    ScaffoldMessenger.of(pageContext).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    showCompletionFeedback(pageContext, before: 5, after: 4);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    showCompletionFeedback(pageContext, before: 11, after: 12, total: 12);
    await tester.pumpAndSettle();
    expect(
      find.text('Collection complete. Every experience counts.'),
      findsOneWidget,
    );
  });
  testWidgets('Hero and large progress fit narrow phones with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    ExplorationHero(
                      title: 'Make room for discovery',
                      subtitle: 'Small experiences. A richer you.',
                      immersive: true,
                    ),
                    ProgressCard(
                      title: 'Your progress',
                      summary: '12 / 12 visited',
                      progress: 1,
                      prominent: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Collection complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Shared filter chips keep selected and unselected text readable',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: FilterChipGroup(
              options: const ['All', 'Active'],
              selected: 'All',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final selected = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      final unselected = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Active'),
      );
      expect(selected.labelStyle?.color, Colors.white);
      expect(unselected.labelStyle?.color, AppColors.ink);
      expect(unselected.backgroundColor, AppColors.surface);
      expect(unselected.side, isNot(BorderSide.none));
    },
  );

  testWidgets('Fruit details collapse and expand verified growing states', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final records = List.generate(
      8,
      (index) => FruitStateRecord(stateId: 'S$index'),
    );
    final states = List.generate(
      8,
      (index) => AtlasState(id: 'S$index', name: 'State $index'),
    );
    final fruit = Fruit(
      id: 'fruit',
      name: 'Test Fruit',
      scientificName: 'Fructus testus',
      states: records,
      varieties: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FruitDetailsPage(fruit: fruit, states: states),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Grown across 8 verified states/UTs'), findsOneWidget);
    expect(find.text('State 0'), findsOneWidget);
    expect(find.text('State 5'), findsOneWidget);
    final stateChip = tester.widget<MetadataChip>(
      find.widgetWithText(MetadataChip, 'State 0'),
    );
    expect(stateChip.label, 'State 0');
    final stateLabel = tester.widget<Text>(find.text('State 0'));
    expect(stateLabel.style?.color, AppColors.ink);
    final renderedChip = tester.widget<Chip>(
      find.descendant(
        of: find.widgetWithText(MetadataChip, 'State 0'),
        matching: find.byType(Chip),
      ),
    );
    expect(renderedChip.backgroundColor, AppColors.accentSurface);
    expect(find.text('State 6'), findsNothing);
    expect(find.text('View all 8'), findsOneWidget);
    await tester.ensureVisible(find.text('View all 8'));
    await tester.tap(find.text('View all 8'));
    await tester.pumpAndSettle();
    expect(find.text('State 7'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text('State 6'), findsNothing);
  });
}
