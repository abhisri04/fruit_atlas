import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/indian_dish.dart';
import 'package:fruit_atlas/screens/challenge/generic_checklist_challenge_page.dart';
import 'package:fruit_atlas/screens/dishes/indian_dishes_page.dart';
import 'package:fruit_atlas/services/indian_dishes_repository.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/services/challenge_repository.dart';
import 'package:fruit_atlas/theme/app_colors.dart';
import 'package:fruit_atlas/widgets/dish_image.dart';
import 'package:fruit_atlas/widgets/circular_progress_widget.dart';
import 'package:fruit_atlas/widgets/dish_dietary_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Indian Dishes catalogue', () {
    late IndianDishesCatalogue catalogue;

    setUpAll(() async {
      catalogue = await const IndianDishesRepository().load();
    });

    test('contains the complete state-first canonical catalogue', () {
      expect(catalogue.category.id, 'CAT_INDIAN_DISHES');
      expect(catalogue.dishes, hasLength(640));
      expect(catalogue.dishes.map((dish) => dish.id).toSet(), hasLength(640));
      expect(
        catalogue.dishes.map((dish) => dish.name.toLowerCase()).toSet(),
        hasLength(640),
      );

      final stateCounts = <String, int>{};
      const allowedDietaryTypes = {
        'vegetarian',
        'non_vegetarian',
        'contains_egg',
      };
      const allowedDishTypes = {
        'bread',
        'breakfast',
        'dessert',
        'main_course',
        'salad',
        'side',
        'snack',
        'soup',
        'street_food',
      };
      final dietaryCounts = <String, int>{};
      final dishTypeCounts = <String, int>{};
      for (final dish in catalogue.dishes) {
        for (final stateId in dish.associatedStateIds) {
          stateCounts.update(stateId, (count) => count + 1, ifAbsent: () => 1);
        }
        expect(dish.imageAsset, 'assets/images/dishes/${dish.id}.webp');
        expect(dish.shortDescription, isNotEmpty);
        expect(dish.associatedStateIds, isNotEmpty);
        expect(dish.legacyIds, isNotEmpty);
        expect(
          allowedDietaryTypes,
          contains(dish.dietaryType),
          reason: '${dish.id} has an unsupported dietary type',
        );
        expect(
          DishDietaryIndicator.identityFor(dish.dietaryType),
          isNotNull,
          reason: '${dish.id} has no dietary marker',
        );
        dietaryCounts.update(
          dish.dietaryType,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        expect(
          allowedDishTypes,
          contains(dish.dishType),
          reason: '${dish.id} has an unsupported dish type',
        );
        dishTypeCounts.update(
          dish.dishType,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      expect(stateCounts, hasLength(36));
      expect(stateCounts['chhattisgarh'], 16);
      expect(stateCounts['uttar_pradesh'], 43);
      expect(stateCounts['andaman_nicobar'], 11);
      expect(dietaryCounts, {
        'vegetarian': 422,
        'non_vegetarian': 213,
        'contains_egg': 5,
      });
      expect(dishTypeCounts, {
        'bread': 24,
        'breakfast': 45,
        'dessert': 103,
        'main_course': 290,
        'salad': 3,
        'side': 37,
        'snack': 87,
        'soup': 6,
        'street_food': 45,
      });
    });

    test('all dishes have explicit canonical State/UT relationships', () async {
      final raw = jsonDecode(
        await rootBundle.loadString(IndianDishesRepository.assetPath),
      ) as Map<String, dynamic>;
      final records = raw['items'] as List<dynamic>;
      expect(records, hasLength(catalogue.dishes.length));
      expect(
        records.every(
          (record) =>
              (record as Map<String, dynamic>)['associated_state_ids']
                  is List<dynamic> &&
              (record['associated_state_ids'] as List<dynamic>).isNotEmpty,
        ),
        isTrue,
      );
      expect(IndianDishesRepository.canonicalStateIds, hasLength(36));

      final canonicalIds = IndianDishesRepository.canonicalStateIds.values
          .toSet();
      for (final dish in catalogue.dishes) {
        final relatedIds = dish.associatedStateIds.toSet();
        expect(relatedIds, isNotEmpty, reason: dish.id);
        expect(
          canonicalIds.containsAll(relatedIds),
          isTrue,
          reason: '${dish.id} has a non-canonical State/UT relationship',
        );
      }
    });

    test('Incredible India expansion keeps names and aliases unambiguous', () {
      String normalize(String value) =>
          value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

      final identities = <String, String>{};
      for (final dish in catalogue.dishes) {
        for (final value in [dish.name, ...dish.aliases]) {
          final key = normalize(value);
          expect(key, isNotEmpty, reason: dish.id);
          expect(
            identities[key],
            anyOf(isNull, dish.id),
            reason: '$value resolves to both ${identities[key]} and ${dish.id}',
          );
          identities[key] = dish.id;
        }
      }

      final expectedRelationships = {
        'Grilled Lobster': 'andaman_nicobar',
        'Khunchang-Tok': 'arunachal_pradesh',
        'Mangaluru Fish Curry': 'karnataka',
        'Kilanji': 'lakshadweep',
        'Mandia Sukua Raav': 'odisha',
        'Nattukozhi Kozhambu': 'tamil_nadu',
        'Bhetki Paturi': 'west_bengal',
      };
      for (final entry in expectedRelationships.entries) {
        final dish = catalogue.dishes.singleWhere(
          (value) => value.name == entry.key,
        );
        expect(dish.associatedStateIds, contains(entry.value));
      }
    });

    test(
      'every State/UT Dishes collection mirrors canonical relationships',
      () async {
        for (final stateId in IndianDishesRepository.canonicalStateIds.values) {
          final assetPath = stateId == 'rajasthan'
              ? 'assets/data/experience_collections.json'
              : 'assets/data/${stateId}_collections.json';
          final raw = jsonDecode(
            await rootBundle.loadString(assetPath),
          ) as Map<String, dynamic>;
          final collections = raw['collections'] as List<dynamic>;
          final dishesCollection = collections
              .cast<Map<String, dynamic>>()
              .singleWhere((value) => value['entity_type'] == 'dish');
          final actualIds =
              (dishesCollection['member_entity_ids'] as List<dynamic>)
                  .cast<String>()
                  .toSet();
          final expectedIds = catalogue.dishes
              .where((dish) => dish.associatedStateIds.contains(stateId))
              .map((dish) => dish.id)
              .toSet();
          expect(actualIds, expectedIds, reason: stateId);
        }
      },
    );

    test('tried dishes never change State/UT explored progress', () async {
      SharedPreferences.setMockInitialValues({
        'completed_india_state_ut_ids': ['kerala'],
      });
      await ProgressService.toggleCategoryItemAction(
        categoryId: catalogue.category.id,
        itemId: 'exp_ker_sangri',
        action: 'tried',
      );
      expect(
        await ProgressService.getChallengeItemIds(
          'completed_india_state_ut_ids',
        ),
        {'kerala'},
      );
    });

    test('is an active Food & Drink challenge', () async {
      final challenges = await const ChallengeRepository().loadChallenges();
      final challenge = challenges.singleWhere(
        (value) => value.id == 'explore_indian_dishes',
      );
      expect(challenge.categoryId, 'food_drink');
      expect(challenge.itemType, 'indian_dish');
      expect(challenge.presentationType, 'catalogue');
      expect(challenge.totalItems, 640);
    });

    test('dish identity supports multiple related states', () {
      final dish = IndianDish.fromJson({
        'id': 'DSH_TEST',
        'name': 'Shared Dish',
        'origin_state_ids': ['punjab'],
        'associated_state_ids': ['punjab', 'haryana'],
        'regions': ['North'],
        'dietary_type': 'vegetarian',
        'dish_type': 'main_course',
        'short_description': 'Test fixture',
        'tags': <String>[],
        'image_asset': 'assets/images/dishes/DSH_TEST.webp',
      });
      expect(dish.originStateIds, ['punjab']);
      expect(dish.associatedStateIds, ['punjab', 'haryana']);
      expect(dish.states, ['Punjab', 'Haryana']);
    });

    test('loads canonical collection and achievement definitions', () {
      expect(catalogue.collections, hasLength(13));
      expect(catalogue.achievements, hasLength(13));
      expect(
        catalogue.collections.map((value) => value.id).toSet(),
        hasLength(catalogue.collections.length),
      );
      expect(
        catalogue.achievements.map((value) => value.id).toSet(),
        hasLength(catalogue.achievements.length),
      );
      for (final collection in catalogue.collections) {
        expect(
          IndianDishesRepository.dishesForCollection(
            collection,
            catalogue.dishes,
          ),
          isNotEmpty,
          reason: collection.id,
        );
      }
    });

    test('action rules remain independent and apply required implications', () {
      final wanted = const ItemActionProgress().toggle('want_to_try');
      expect(wanted.wantToTry, isTrue);
      expect(wanted.tried, isFalse);

      final cooked = wanted.toggle('cooked');
      expect(cooked.cooked, isTrue);
      expect(cooked.tried, isTrue);
      expect(cooked.wantToTry, isFalse);

      final favourite = cooked.toggle('favourite');
      expect(favourite.favourite, isTrue);
      expect(favourite.cooked, isTrue);
      expect(favourite.tried, isTrue);

      final plannedAfterTrying = favourite.toggle('want_to_try');
      expect(plannedAfterTrying.wantToTry, isTrue);
      expect(plannedAfterTrying.tried, isTrue);
    });

    test('category action progress persists on canonical IDs', () async {
      SharedPreferences.setMockInitialValues({});
      final pesarattu = catalogue.dishes.singleWhere(
        (dish) => dish.name == 'Pesarattu',
      );
      await ProgressService.toggleCategoryItemAction(
        categoryId: catalogue.category.id,
        itemId: pesarattu.id,
        action: 'cooked',
      );
      final restored = await ProgressService.getDishProgress(catalogue);
      expect(restored[pesarattu.id]?.cooked, isTrue);
      expect(restored[pesarattu.id]?.tried, isTrue);
    });

    test('legacy state and seed progress migrates without loss', () async {
      SharedPreferences.setMockInitialValues({
        'completed_experience_ids': ['exp_chhattisgarh_faraa'],
        'category_item_progress_v1_CAT_INDIAN_DISHES': jsonEncode({
          'DSH013': {'favourite': true},
        }),
      });
      final progress = await ProgressService.getDishProgress(catalogue);
      final faraa = catalogue.dishes.singleWhere(
        (dish) => dish.name == 'Faraa',
      );
      expect(faraa.id, 'exp_chhattisgarh_faraa');
      expect(faraa.legacyIds, contains('DSH013'));
      expect(progress[faraa.id]?.tried, isTrue);
      expect(progress[faraa.id]?.favourite, isTrue);
      expect(progress['DSH013'], isNull);
    });

    test('global search indexes dishes and state context', () async {
      final search = GlobalSearchService();
      await search.load();
      expect(
        search.categories.any((value) => value.id == 'CAT_INDIAN_DISHES'),
        isFalse,
      );
      expect(search.search('Indian Dishes').first.categoryId, 'food_drink');
      expect(
        search.search('biryani').map((result) => result.title),
        contains('Hyderabadi Biryani'),
      );
      expect(
        search.search('Punjab').map((result) => result.title),
        containsAll(['Sarson da Saag with Makki di Roti', 'Butter Chicken']),
      );
    });

    testWidgets('missing dish photos use the food placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DishImage(
              assetPath: 'assets/images/dishes/DSH001.webp',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Explore entries and destination pages show circular progress',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const MaterialApp(home: IndianDishesPage()));
        await tester.pumpAndSettle();
        expect(find.text('Explore'), findsOneWidget);
        for (final title in [
          'All Dishes',
          'States',
          'Regions',
          'Collections & Challenges',
          'Achievements',
        ]) {
          await tester.scrollUntilVisible(find.text(title), 180);
          final card = find.ancestor(
            of: find.text(title),
            matching: find.byType(Card),
          );
          expect(
            find.descendant(
              of: card,
              matching: find.byType(CircularProgressWidget),
            ),
            findsOneWidget,
          );
        }

        await tester.scrollUntilVisible(find.text('All Dishes'), -180);
        await tester.tap(find.text('All Dishes'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('dish-progress-filter')), findsOneWidget);
        expect(find.byKey(const Key('dish-sort')), findsOneWidget);
        expect(find.byType(CircularProgressWidget), findsOneWidget);

        await tester.pumpWidget(
          MaterialApp(
            home: DishGroupPage(
              catalogue: catalogue,
              field: 'primary_state',
              title: 'Dishes by State',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressWidget), findsWidgets);

        await tester.pumpWidget(
          MaterialApp(home: DishCollectionsPage(catalogue: catalogue)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressWidget), findsWidgets);

        await tester.pumpWidget(
          MaterialApp(home: DishAchievementsPage(catalogue: catalogue)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressWidget), findsWidgets);
      },
    );

    testWidgets('All Dishes filters by action and sorts by state', (
      tester,
    ) async {
      final cookedDish = catalogue.dishes.first;
      SharedPreferences.setMockInitialValues({
        'category_item_progress_v1_CAT_INDIAN_DISHES': jsonEncode({
          cookedDish.id: {'tried': true, 'cooked': true},
        }),
      });
      await tester.pumpWidget(
        MaterialApp(home: DishBrowsePage(catalogue: catalogue)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dish-progress-filter')));
      await tester.pumpAndSettle();
      expect(find.text('Want to try'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      await tester.tap(find.text('Cooked').last);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('dish-card-${cookedDish.id}')), findsOneWidget);
      expect(find.byType(DishQuickActionCard), findsOneWidget);

      await tester.tap(find.byKey(const Key('dish-progress-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All dishes').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dish-sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('By state').last);
      await tester.pumpAndSettle();

      final expectedFirst = [...catalogue.dishes]
        ..sort((a, b) {
          final stateComparison = a.primaryState.compareTo(b.primaryState);
          return stateComparison != 0
              ? stateComparison
              : a.name.compareTo(b.name);
        });
      final firstCard = tester.widget<DishQuickActionCard>(
        find.byType(DishQuickActionCard).first,
      );
      expect(firstCard.dish.id, expectedFirst.first.id);
    });

    testWidgets('dietary markers and filter use canonical dish identity', (
      tester,
    ) async {
      expect(
        DishDietaryIndicator.identityFor('vegetarian')?.color,
        const Color(0xFF16843A),
      );
      expect(
        DishDietaryIndicator.identityFor('non_vegetarian')?.color,
        const Color(0xFFD32F2F),
      );
      expect(
        DishDietaryIndicator.identityFor('contains_egg')?.color,
        const Color(0xFFF4B400),
      );
      expect(DishDietaryIndicator.identityFor('unknown'), isNull);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                DishDietaryIndicator(dietaryType: 'vegetarian'),
                DishDietaryIndicator(dietaryType: 'non_vegetarian'),
                DishDietaryIndicator(dietaryType: 'contains_egg'),
              ],
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Vegetarian dish'), findsOneWidget);
      expect(find.bySemanticsLabel('Non-vegetarian dish'), findsOneWidget);
      expect(find.bySemanticsLabel('Contains egg'), findsOneWidget);
      expect(find.text('Veg'), findsNothing);
      expect(find.text('Non-veg'), findsNothing);
      expect(find.text('Egg'), findsNothing);

      SharedPreferences.setMockInitialValues({});
      final source = [
        catalogue.dishes.singleWhere((dish) => dish.name == 'Pesarattu'),
        catalogue.dishes.singleWhere((dish) => dish.name == 'Butter Chicken'),
        catalogue.dishes.singleWhere((dish) => dish.name == 'Bebinca'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: DishBrowsePage(catalogue: catalogue, source: source),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dish-filter-dietary_type')));
      await tester.pumpAndSettle();
      expect(find.text('Egg'), findsWidgets);
      await tester.tap(find.text('Egg').last);
      await tester.pumpAndSettle();
      expect(find.byType(DishQuickActionCard), findsOneWidget);
      expect(find.text('Bebinca'), findsOneWidget);

      final bebinca = source.singleWhere((dish) => dish.name == 'Bebinca');
      await tester.pumpWidget(
        MaterialApp(
          home: DishDetailPage(
            catalogue: catalogue,
            dishes: [bebinca],
            initialIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final detailMarker = find.byKey(
        Key('dish-dietary-marker-${bebinca.id}'),
        skipOffstage: false,
      );
      expect(detailMarker, findsOneWidget);
      expect(
        tester.widget<DishDietaryIndicator>(detailMarker).showLabel,
        isFalse,
      );
      final titleRow = find.ancestor(
        of: detailMarker,
        matching: find.byType(Row),
      );
      expect(titleRow, findsOneWidget);
      final detailTitle = find.descendant(
        of: titleRow,
        matching: find.text('Bebinca'),
      );
      expect(detailTitle, findsOneWidget);
      expect(
        tester.getCenter(detailMarker).dx,
        greaterThan(tester.getTopRight(detailTitle).dx),
      );
      expect(find.text('Egg'), findsNothing);
      expect(find.text('Contains Egg'), findsNothing);
    });

    testWidgets(
      'list cards persist Tried and Cooked without changing state progress',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'completed_india_state_ut_ids': ['kerala'],
        });
        final source = catalogue.dishes.take(2).toList();
        final firstId = source[0].id;
        final secondId = source[1].id;
        await tester.pumpWidget(
          MaterialApp(
            home: DishBrowsePage(catalogue: catalogue, source: source),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(Key('dish-list-tried-$firstId')), findsOneWidget);
        expect(find.byKey(Key('dish-list-cooked-$firstId')), findsOneWidget);

        await tester.tap(find.byKey(Key('dish-list-tried-$firstId')));
        await tester.pumpAndSettle();
        final dishProgress = await ProgressService.getDishProgress(catalogue);
        expect(dishProgress[firstId]?.tried, isTrue);
        expect(
          await ProgressService.getChallengeItemIds(
            'completed_india_state_ut_ids',
          ),
          {'kerala'},
        );

        await tester.ensureVisible(
          find.byKey(Key('dish-list-tried-$secondId')),
        );
        await tester.tap(find.byKey(Key('dish-list-tried-$secondId')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(Key('dish-list-tried-$firstId')));
        await tester.tap(find.byKey(Key('dish-list-tried-$firstId')));
        await tester.pumpAndSettle();
        expect(
          await ProgressService.getChallengeItemIds(
            'completed_india_state_ut_ids',
          ),
          {'kerala'},
        );
      },
    );

    testWidgets(
      'Ker Sangri stays tried inside Rajasthan without exploring the state',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final stateChallenge =
            (await const ChallengeRepository().loadChallenges()).singleWhere(
              (value) => value.id == 'explore_indian_states',
            );
        final kerSangri = catalogue.dishes.singleWhere(
          (dish) => dish.name == 'Ker Sangri',
        );
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            home: GenericChecklistChallengePage(challenge: stateChallenge),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Rajasthan'), 300);
        await tester.pumpAndSettle();

        Finder rajasthanCheckbox() => find.descendant(
          of: find.ancestor(
            of: find.text('Rajasthan'),
            matching: find.byType(ListTile),
          ),
          matching: find.byType(Checkbox),
        );
        expect(tester.widget<Checkbox>(rajasthanCheckbox()).value, isFalse);

        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) =>
                DishBrowsePage(catalogue: catalogue, source: [kerSangri]),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('dish-list-tried-${kerSangri.id}')));
        await tester.pumpAndSettle();
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(rajasthanCheckbox()).value, isFalse);
        expect(
          await ProgressService.getChallengeItemIds(
            'completed_india_state_ut_ids',
          ),
          isEmpty,
        );

        await tester.tap(find.text('Rajasthan'));
        await tester.pumpAndSettle();
        final foodSection = find.byKey(
          const ValueKey('exploration-section-Food & Drink'),
        );
        await tester.scrollUntilVisible(foodSection, 300);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: foodSection, matching: find.text('Food & Drink')),
        );
        await tester.pumpAndSettle();
        final dishesTile = find.text('Dishes');
        await tester.scrollUntilVisible(dishesTile, 250);
        await tester.tap(dishesTile);
        await tester.pumpAndSettle();
        final stateDishTried = find.byKey(
          Key('dish-list-tried-${kerSangri.id}'),
        );
        await tester.scrollUntilVisible(
          stateDishTried,
          300,
          scrollable: find
              .descendant(
                of: find.byType(DishBrowsePage),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<FilterChip>(stateDishTried).selected, isTrue);
        expect(
          find.byKey(Key('dish-list-cooked-${kerSangri.id}')),
          findsNothing,
        );

        await tester.tap(stateDishTried);
        await tester.pumpAndSettle();
        expect(tester.widget<FilterChip>(stateDishTried).selected, isFalse);
        final sharedDishProgress = await ProgressService.getDishProgress(
          catalogue,
        );
        expect(sharedDishProgress[kerSangri.id]?.tried, isFalse);
        expect(
          await ProgressService.getChallengeItemIds(
            'completed_india_state_ut_ids',
          ),
          isEmpty,
        );
      },
    );

    testWidgets('detail actions persist and swipe retains browse context', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final detailDishes = ['Pesarattu', 'Gongura Pachadi']
          .map(
            (name) => catalogue.dishes.singleWhere((dish) => dish.name == name),
          )
          .toList();
      await tester.pumpWidget(
        MaterialApp(
          home: DishDetailPage(
            catalogue: catalogue,
            dishes: detailDishes,
            initialIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pesarattu'), findsWidgets);
      expect(
        tester.widget<Text>(find.text('Tags')).style?.color,
        AppColors.ink,
      );
      expect(
        tester.widget<Text>(find.text('Your journey')).style?.color,
        AppColors.ink,
      );
      await tester.ensureVisible(find.byKey(const Key('dish-action-cooked')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dish-action-cooked')));
      await tester.pumpAndSettle();
      final saved = await ProgressService.getDishProgress(catalogue);
      expect(saved[detailDishes.first.id]?.cooked, isTrue);
      expect(saved[detailDishes.first.id]?.tried, isTrue);

      await tester.fling(find.byType(PageView), const Offset(-500, 0), 900);
      await tester.pumpAndSettle();
      expect(find.text('Gongura Pachadi'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
