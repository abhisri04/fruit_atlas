import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/indian_dish.dart';
import 'package:fruit_atlas/models/dish_visual_style.dart';
import 'package:fruit_atlas/widgets/dish_artwork.dart';
import 'package:fruit_atlas/widgets/experience_artwork.dart';
import 'package:fruit_atlas/models/daily_discovery.dart';
import 'package:fruit_atlas/screens/dishes/indian_dishes_page.dart';
import 'package:fruit_atlas/models/item_action_progress.dart';

void main() {
  test(
    'real photo override requires explicit approval and a bundled asset',
    () {
      final manifest = {
        'items': [
          {
            'dishId': 'approved',
            'status': 'manual_approved',
            'imageFile': 'approved.webp',
          },
          {
            'dishId': 'candidate',
            'status': 'pending_review',
            'imageFile': 'candidate.webp',
          },
          {
            'dishId': 'missing',
            'status': 'pixabay_approved',
            'imageFile': 'missing.webp',
          },
        ],
      };
      expect(
        DishArtwork.approvedPhotoPaths(manifest, {
          'approved.webp',
          'candidate.webp',
        }),
        {'approved': 'approved.webp'},
      );
    },
  );
  final data = jsonDecode(
    File('assets/data/indian_dishes.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final dishes = (data['items'] as List)
      .map((r) => IndianDish.fromJson(r))
      .toList();
  IndianDish named(String name) => dishes.firstWhere((d) => d.name == name);
  test('contains egg metadata is never labelled vegetarian', () {
    for (final dish in dishes.where((d) => d.dietaryType == 'contains_egg')) {
      expect(DishVisualResolver.dietaryLabel(dish), 'Contains egg');
    }
  });
  testWidgets('state and global dish list cards use canonical shared artwork', (
    tester,
  ) async {
    final dish = named('Kafuli');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DishQuickActionCard(
            dish: dish,
            progress: const ItemActionProgress(),
            onTap: () {},
            onToggle: (_) {},
            showCookedAction: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final artwork = tester.widget<DishArtwork>(find.byType(DishArtwork));
    expect(artwork.dish, same(dish));
    expect(artwork.variant, DishArtworkVariant.list);
    expect(find.text('Uttarakhand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Daily Discovery uses the shared dish artwork', (tester) async {
    final dish = named('Butter Chicken');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExperienceArtwork(
            discovery: DailyDiscovery(
              type: DailyDiscoveryType.indianDish,
              canonicalId: dish.id,
              title: dish.name,
              subtitle: '',
              dish: dish,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DishArtwork), findsOneWidget);
    expect(
      tester.widget<DishArtwork>(find.byType(DishArtwork)).dish.id,
      dish.id,
    );
    expect(tester.takeException(), isNull);
  });
  test('all 640 canonical dishes resolve to configured styles', () {
    expect(dishes.length, 640);
    for (final d in dishes) {
      expect(DishVisualStyle.styles[DishVisualResolver.resolve(d)], isNotNull);
    }
  });
  for (final item in [
    ('Aloo Paratha', DishVisualCategory.breadFlatbread),
    ('Butter Chicken', DishVisualCategory.curry),
    ('Hyderabadi Biryani', DishVisualCategory.rice),
    ('Chhena Poda', DishVisualCategory.dessert),
    ('Samosa', DishVisualCategory.snack),
    ('Kafuli', DishVisualCategory.leafyVeg),
  ]) {
    test(
      '${item.$1} maps correctly',
      () => expect(DishVisualResolver.resolve(named(item.$1)), item.$2),
    );
  }
  test('dietary semantics and canonical origin are preserved', () {
    expect(DishVisualResolver.dietaryLabel(named('Butter Chicken')), 'Non-Veg');
    expect(DishVisualResolver.dietaryLabel(named('Aloo Paratha')), 'Veg');
    expect(
      DishVisualResolver.location(named('Hyderabadi Biryani')),
      'Telangana',
    );
    expect(DishVisualResolver.location(named('Chhena Poda')), 'Odisha');
  });
  IndianDish synthetic({
    String name = 'Unknown',
    List<String> states = const [],
    List<String> regions = const [],
  }) => IndianDish(
    id: 'test',
    name: name,
    originStateIds: states,
    associatedStateIds: states,
    regions: regions,
    dietaryType: 'unknown',
    dishType: '',
    shortDescription: '',
    tags: const [],
    imageAsset: 'unapproved.webp',
  );
  test('unknown taxonomy and multi-region location are safe', () {
    expect(
      DishVisualResolver.resolve(synthetic()),
      DishVisualCategory.defaultFood,
    );
    expect(
      DishVisualResolver.resolve(synthetic(name: 'Fish stew')),
      DishVisualCategory.seafood,
    );
    expect(
      DishVisualResolver.location(
        synthetic(states: ['punjab', 'goa'], regions: ['North', 'West']),
      ),
      'India',
    );
    expect(DishVisualResolver.location(synthetic()), 'India');
  });
  for (final variant in DishArtworkVariant.values) {
    testWidgets(
      '${variant.name} renders long names and never unapproved images',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 360,
                child: DishArtwork(
                  dish: synthetic(name: 'Amritsari Kulcha Chandigarh Style'),
                  variant: variant,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(DishArtwork), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('hero remains readable at large text scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 360,
              height: 420,
              child: DishArtwork(
                dish: named('Hyderabadi Biryani'),
                variant: DishArtworkVariant.hero,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
