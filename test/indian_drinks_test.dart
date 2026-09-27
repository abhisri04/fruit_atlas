import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/indian_drink.dart';
import 'package:fruit_atlas/screens/drinks/indian_drinks_page.dart';
import 'package:fruit_atlas/services/challenge_repository.dart';
import 'package:fruit_atlas/services/indian_drinks_repository.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Indian Drinks catalogue', () {
    late IndianDrinksCatalogue catalogue;

    setUpAll(() async {
      catalogue = await const IndianDrinksRepository().load();
    });

    test('has canonical IDs, identities, paths, and future-ready types', () {
      expect(catalogue.drinks, hasLength(68));
      expect(catalogue.drinks.map((drink) => drink.id).toSet(), hasLength(68));
      expect(
        catalogue.drinks.map((drink) => drink.name.toLowerCase()).toSet(),
        hasLength(68),
      );
      final allowedTypes = catalogue.drinkTypes.map((type) => type.id).toSet();
      expect(allowedTypes, containsAll(['tea', 'coffee', 'herbal_medicinal']));
      for (final drink in catalogue.drinks) {
        expect(drink.associatedStateIds, isNotEmpty, reason: drink.id);
        expect(allowedTypes, contains(drink.drinkType), reason: drink.id);
        expect(drink.alcoholContent, 'non_alcoholic', reason: drink.id);
        expect(drink.containsCannabis, isFalse, reason: drink.id);
        expect(drink.legacyIds, isNotEmpty, reason: drink.id);
        expect(drink.imageAsset, 'assets/images/drinks/${drink.id}.webp');
      }
      expect(
        catalogue.drinks.map((drink) => drink.imageAsset).toSet(),
        hasLength(catalogue.drinks.length),
      );
      expect(
        catalogue.drinks.map((drink) => drink.name).toSet().intersection({
          'Apong',
          'Bhaang',
          'Chauk',
          'Chhaang',
          'Feni',
          'Handia',
          'Tongba',
          'Zutho',
        }),
        isEmpty,
      );
    });

    test(
      'every State/UT Drinks collection mirrors canonical relationships',
      () async {
        for (final stateId in IndianDrink.stateNames.keys) {
          final path = stateId == 'rajasthan'
              ? 'assets/data/experience_collections.json'
              : 'assets/data/${stateId}_collections.json';
          final raw = jsonDecode(
            await rootBundle.loadString(path),
          ) as Map<String, dynamic>;
          final collection = (raw['collections'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .singleWhere((value) => value['id'] == '${stateId}_drinks');
          expect(collection['entity_type'], 'drink');
          final actual = (collection['member_entity_ids'] as List<dynamic>)
              .cast<String>()
              .toSet();
          final expected = catalogue.drinks
              .where((drink) => drink.associatedStateIds.contains(stateId))
              .map((drink) => drink.id)
              .toSet();
          expect(actual, expected, reason: stateId);
        }
      },
    );

    test(
      'legacy State experience progress migrates to canonical drink',
      () async {
        SharedPreferences.setMockInitialValues({
          'completed_experience_ids': ['exp_haryana_chaas'],
        });
        final progress = await ProgressService.getDrinkProgress(catalogue);
        final chaas = catalogue.drinks.singleWhere(
          (drink) => drink.name == 'Chaas',
        );
        expect(chaas.legacyIds, contains('exp_haryana_chaas'));
        expect(progress[chaas.id]?.tried, isTrue);
      },
    );

    test('drink actions do not mark a State/UT explored', () async {
      SharedPreferences.setMockInitialValues({
        'completed_india_state_ut_ids': ['kerala'],
      });
      await ProgressService.toggleCategoryItemAction(
        categoryId: catalogue.category.id,
        itemId: catalogue.drinks.first.id,
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
        (value) => value.id == 'explore_indian_drinks',
      );
      expect(challenge.categoryId, 'food_drink');
      expect(challenge.itemType, 'indian_drink');
      expect(challenge.presentationType, 'catalogue');
      expect(challenge.totalItems, catalogue.drinks.length);
    });

    test('aliases resolve to one canonical identity', () {
      String normalize(String value) =>
          value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
      final identities = <String, String>{};
      for (final drink in catalogue.drinks) {
        for (final value in [drink.name, ...drink.aliases]) {
          final key = normalize(value);
          expect(identities[key], anyOf(isNull, drink.id), reason: value);
          identities[key] = drink.id;
        }
      }
      expect(
        identities[normalize('Gur Gur Cha')],
        identities[normalize('Butter Tea')],
      );
    });

    test('government-sourced additions are documented and state-linked', () {
      const addedIds = {
        'DRK011',
        'DRK012',
        'DRK013',
        'DRK014',
        'DRK015',
        'DRK016',
        'DRK017',
        'DRK018',
        'DRK019',
        'DRK020',
        'DRK021',
      };
      final added = catalogue.drinks
          .where((drink) => addedIds.contains(drink.id))
          .toList();
      expect(added, hasLength(addedIds.length));
      for (final drink in added) {
        expect(drink.sourceRefs, isNotEmpty, reason: drink.id);
        expect(drink.associatedStateIds, isNotEmpty, reason: drink.id);
      }

      final sourceRegister = File(
        'docs/data_sources/incredible_india_drink_sources.csv',
      ).readAsStringSync();
      for (final id in addedIds) {
        expect(sourceRegister, contains('$id,'), reason: id);
      }
    });

    testWidgets('Tried and Favourite chips remain readable in both states', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(home: DrinkBrowsePage(catalogue: catalogue)),
      );
      await tester.pumpAndSettle();

      FilterChip chipNamed(String label) => tester.widget<FilterChip>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is FilterChip &&
                  widget.label is Text &&
                  (widget.label as Text).data == label,
            )
            .first,
      );

      final tried = chipNamed('Tried');
      final favourite = chipNamed('Favourite');
      expect(tried.backgroundColor, AppColors.surface);
      expect(tried.labelStyle?.color, AppColors.ink);
      expect(favourite.backgroundColor, AppColors.surface);
      expect(favourite.labelStyle?.color, AppColors.ink);

      await tester.tap(find.text('Favourite').first);
      await tester.pumpAndSettle();
      final selectedFavourite = chipNamed('Favourite');
      expect(selectedFavourite.selected, isTrue);
      expect(selectedFavourite.selectedColor, AppColors.primary);
      expect(selectedFavourite.labelStyle?.color, Colors.white);
    });
  });
}
