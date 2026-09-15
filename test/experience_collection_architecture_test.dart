import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/experience_collection.dart';
import 'package:fruit_atlas/screens/experience/experience_collection_page.dart';
import 'package:fruit_atlas/widgets/circular_progress_widget.dart';
import 'package:fruit_atlas/widgets/experience_collection_tile.dart';
import 'package:fruit_atlas/widgets/exploration_section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  test('Rajasthan collections use explicit canonical memberships', () {
    final collectionJson =
        readJson('assets/data/experience_collections.json')['collections']
            as List;
    final collections = collectionJson
        .map(
          (item) => ExperienceCollection.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    final experienceJson =
        readJson('assets/data/rajasthan_experiences.json')['experiences']
            as List;
    final experienceIds = experienceJson
        .map((item) => item['id'] as String)
        .toSet();

    expect(collections.map((item) => item.parentSectionId).toSet(), {
      'food_drink',
      'things_to_do',
      'culture',
    });
    expect(
      collections.where((item) => item.parentSectionId == 'food_drink').length,
      3,
    );
    expect(
      collections
          .where((item) => item.parentSectionId == 'things_to_do')
          .length,
      3,
    );
    expect(
      collections.where((item) => item.parentSectionId == 'culture').length,
      3,
    );

    final configuredExperienceIds = collections
        .where((item) => item.entityType == 'experience')
        .expand((item) => item.memberEntityIds)
        .toSet();
    expect(configuredExperienceIds.difference(experienceIds), isEmpty);
    expect(configuredExperienceIds, hasLength(74));

    final cityPalaces = experienceJson
        .where((item) => (item['title'] as String).startsWith('City Palace'))
        .toList();
    expect(cityPalaces, hasLength(2));
    expect(cityPalaces.map((item) => item['id']).toSet(), hasLength(2));

    // Existing persisted IDs remain stable while instruction-style titles are reconciled.
    final dal = experienceJson.firstWhere(
      (item) => item['id'] == 'exp_rajasthan_dal_baati_churma',
    );
    expect(dal['title'], 'Dal Baati Churma');
    expect(
      experienceJson.any(
        (item) => item['id'] == 'exp_rajasthan_mehrangarh_fort',
      ),
      isTrue,
    );
  });

  test(
    'duplicate collection memberships contribute once to parent progress',
    () {
      const sharedId = 'exp_shared';
      const first = ExperienceCollection(
        id: 'first',
        title: 'First',
        description: '',
        iconIdentifier: 'activity',
        parentSectionId: 'things_to_do',
        contextId: 'context',
        contextName: 'Context',
        entityType: 'experience',
        memberEntityIds: [sharedId, 'exp_a'],
        sortOrder: 1,
        completionVerb: 'experienced',
        emptyMessage: '',
      );
      const second = ExperienceCollection(
        id: 'second',
        title: 'Second',
        description: '',
        iconIdentifier: 'activity',
        parentSectionId: 'things_to_do',
        contextId: 'context',
        contextName: 'Context',
        entityType: 'experience',
        memberEntityIds: [sharedId, 'exp_b'],
        sortOrder: 2,
        completionVerb: 'experienced',
        emptyMessage: '',
      );
      final uniqueMembers = [
        first,
        second,
      ].expand((collection) => collection.memberEntityIds).toSet();
      final completed = uniqueMembers.intersection({sharedId, 'exp_b'});
      expect(uniqueMembers, hasLength(3));
      expect(completed, hasLength(2));
    },
  );

  testWidgets('zero-item collections use the generic coming-soon treatment', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const drinks = ExperienceCollection(
      id: 'drinks',
      title: 'Drinks',
      description: 'Curated drinks.',
      iconIdentifier: 'drink',
      parentSectionId: 'food_drink',
      contextId: 'rajasthan',
      contextName: 'Rajasthan',
      entityType: 'experience',
      sortOrder: 3,
      completionVerb: 'tried',
      emptyMessage: 'More Rajasthan drink experiences are coming soon.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExperienceCollectionTile(
            collection: drinks,
            completedCount: 0,
            totalCount: 0,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.byType(CircularProgressWidget), findsNothing);
    expect(find.textContaining('0 of 0'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(home: ExperienceCollectionPage(collection: drinks)),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 experiences'), findsOneWidget);
    expect(find.byType(CircularProgressWidget), findsNothing);
    expect(find.textContaining('0 of 0'), findsNothing);
  });

  testWidgets('expanded sections pin their header and lazily build rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              ExplorationSectionCard(
                icon: Icons.place_outlined,
                title: 'Places',
                completedCount: 0,
                totalCount: 100,
                initiallyExpanded: true,
                itemCount: 100,
                itemBuilder: (_, index) =>
                    SizedBox(height: 56, child: Text('Item $index')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Item ').evaluate().length, lessThan(100));
    await tester.scrollUntilVisible(
      find.text('Item 60'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Places')).dy, lessThan(40));
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text('Item 60'), findsNothing);
  });
}
