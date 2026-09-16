import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/models/fruit.dart';
import 'package:fruit_atlas/models/item.dart';
import 'package:fruit_atlas/widgets/daily_discovery_card.dart';

void main() {
  testWidgets(
    'Fruit presentation uses action copy without scientific-name copy',
    (tester) async {
      const fruit = Fruit(
        id: 'FR001',
        name: 'Mango',
        scientificName: 'Mangifera indica',
        states: [],
        varieties: [],
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DailyDiscoveryCard(
              discovery: DailyDiscovery(
                type: DailyDiscoveryType.fruit,
                canonicalId: 'FR001',
                title: 'Mango',
                subtitle: 'Mangifera indica',
                fruit: fruit,
              ),
              isLoading: false,
              isSaved: false,
            ),
          ),
        ),
      );

      expect(find.text('Try Mango'), findsOneWidget);
      expect(find.text('Add a new fruit to your collection.'), findsOneWidget);
      expect(find.text('Fruit'), findsOneWidget);
      expect(find.text('Mangifera indica'), findsNothing);
      expect(find.text('Explore this fruit →'), findsOneWidget);
      expect(find.text('Save for later'), findsOneWidget);
      expect(find.text('Another'), findsOneWidget);
    },
  );

  testWidgets('Yoga presentation uses structured difficulty and category', (
    tester,
  ) async {
    const pose = Item(
      id: 'tree_pose',
      challengeId: 'learn_yoga_poses',
      name: 'Tree Pose',
      category: 'Standing',
      difficulty: 'Beginner',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DailyDiscoveryCard(
            discovery: DailyDiscovery(
              type: DailyDiscoveryType.yogaPose,
              canonicalId: 'tree_pose',
              title: 'Tree Pose',
              subtitle: 'Standing · Beginner',
              yogaPose: pose,
            ),
            isLoading: false,
            isSaved: false,
          ),
        ),
      ),
    );

    expect(find.text('Try Tree Pose'), findsOneWidget);
    expect(
      find.text(
        'A beginner-friendly standing pose to add to your yoga journey.',
      ),
      findsOneWidget,
    );
    expect(find.text('Yoga · Beginner · Standing'), findsOneWidget);
    expect(find.text('Try this pose →'), findsOneWidget);
  });
}
