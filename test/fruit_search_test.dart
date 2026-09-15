import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/fruit.dart';
import 'package:fruit_atlas/services/fruit_search.dart';
import 'package:fruit_atlas/widgets/discovery_search_field.dart';

void main() {
  const mango = Fruit(
    id: 'mango',
    name: 'Mango',
    scientificName: 'Mangifera indica',
    states: [FruitStateRecord(stateId: 'UP')],
    varieties: [FruitVariety(id: 'alphonso', name: 'Alphonso')],
  );
  const apple = Fruit(
    id: 'apple',
    name: 'Apple',
    scientificName: '',
    states: [FruitStateRecord(stateId: 'HP')],
    varieties: [],
  );
  const fruits = [mango, apple];

  test('Matches fruit, scientific and variety names case-insensitively', () {
    for (final query in [' MANGO ', 'mangifera', 'ALPHONSO', 'phons']) {
      expect(filterFruits(fruits, query: query), [mango]);
    }
    expect(filterFruits(fruits, query: 'missing'), isEmpty);
  });
  test(
    'Global search, intersecting state filters, and clear preserve scope',
    () {
      expect(filterFruits(fruits, query: 'apple'), [apple]);
      expect(filterFruits(fruits, query: 'apple', stateId: 'UP'), isEmpty);
      expect(filterFruits(fruits, query: 'alphonso', stateId: 'UP'), [mango]);
      expect(filterFruits(fruits, stateId: 'UP'), [mango]);
      expect(filterFruits(fruits, query: '  '), fruits);
      expect(filterFruits([], query: 'apple'), isEmpty);
    },
  );
  testWidgets('Search updates immediately and clear restores the list', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var results = fruits.toList();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                DiscoverySearchField(
                  debounce: Duration.zero,
                  controller: controller,
                  onChanged: (query) {
                    setState(
                      () => results = filterFruits(fruits, query: query),
                    );
                  },
                ),
                ...results.map((fruit) => Text(fruit.name)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'alphonso');
    await tester.pump();
    expect(find.text('Mango'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Apple'), findsOneWidget);
    expect(controller.text, isEmpty);
  });
}
