import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/indian_dish.dart';
import '../models/catalogue_category.dart';
import '../models/item_action_progress.dart';
import '../models/india_location_registry.dart';

class IndianDishesRepository {
  static const assetPath = 'assets/data/indian_dishes.json';
  static const categoryId = 'CAT_INDIAN_DISHES';
  final AssetBundle? bundle;
  static IndianDishesCatalogue? _cache;

  static final canonicalStateIds = <String, String>{
    for (final entry in IndianDish.stateNames.entries) entry.value: entry.key,
  };

  const IndianDishesRepository({this.bundle});

  Future<IndianDishesCatalogue> load() async {
    if (bundle == null && _cache != null) return _cache!;
    final raw = jsonDecode(await (bundle ?? rootBundle).loadString(assetPath));
    final json = raw as Map<String, dynamic>;
    final catalogue = IndianDishesCatalogue(
      category: CatalogueCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      dishes: (json['items'] as List<dynamic>)
          .map((value) => IndianDish.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      collections: (json['collections'] as List<dynamic>)
          .map(
            (value) => DishCollection.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
      achievements: (json['achievements'] as List<dynamic>)
          .map(
            (value) => DishAchievement.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
    if (bundle == null) _cache = catalogue;
    return catalogue;
  }

  static void clearCacheForTesting() => _cache = null;

  static List<IndianDish> dishesForCollection(
    DishCollection collection,
    List<IndianDish> dishes,
  ) {
    if (collection.type == 'all_items' || collection.type == 'unique_field') {
      return dishes;
    }
    if (collection.rule.isEmpty) return const [];
    final entry = collection.rule.entries.first;
    final expected = entry.value is List
        ? List<String>.from(entry.value as List)
        : [entry.value.toString()];
    return dishes
        .where(
          (dish) =>
              expected.any((value) => dish.matchesField(entry.key, value)),
        )
        .toList(growable: false);
  }

  static String stateId(String stateName) =>
      canonicalStateIds[stateName] ??
      stateName
          .toLowerCase()
          .replaceAll('&', 'and')
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

  static Set<String> triedDishIds(
    IndianDishesCatalogue catalogue,
    Map<String, ItemActionProgress> progress,
  ) => catalogue.dishes
      .where((dish) => progress[dish.id]?.tried ?? false)
      .map((dish) => dish.id)
      .toSet();

  static Set<String> triedLocationIds(
    List<IndianDish> dishes,
    Map<String, ItemActionProgress> progress,
  ) => dishes
      .where((dish) => progress[dish.id]?.tried ?? false)
      .expand((dish) => dish.associatedStateIds)
      .where(IndiaLocationRegistry.allLocationIds.contains)
      .toSet();

  static Set<String> triedStateIds(
    List<IndianDish> dishes,
    Map<String, ItemActionProgress> progress,
  ) => triedLocationIds(
    dishes,
    progress,
  ).where(IndiaLocationRegistry.isState).toSet();
}
