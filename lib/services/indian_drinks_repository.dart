import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/indian_drink.dart';

class IndianDrinksRepository {
  static const assetPath = 'assets/data/indian_drinks.json';
  static const categoryId = 'CAT_INDIAN_DRINKS';
  final AssetBundle? bundle;
  static IndianDrinksCatalogue? _cache;

  const IndianDrinksRepository({this.bundle});

  Future<IndianDrinksCatalogue> load() async {
    if (bundle == null && _cache != null) return _cache!;
    final value = jsonDecode(
      await (bundle ?? rootBundle).loadString(assetPath),
    ) as Map<String, dynamic>;
    final catalogue = IndianDrinksCatalogue(
      category: DrinkCategory.fromJson(
        value['category'] as Map<String, dynamic>,
      ),
      drinkTypes: (value['drink_types'] as List<dynamic>)
          .map(
            (item) =>
                DrinkTypeDefinition.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      drinks: (value['items'] as List<dynamic>)
          .map((item) => IndianDrink.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
    if (bundle == null) _cache = catalogue;
    return catalogue;
  }

  static void clearCacheForTesting() => _cache = null;

  static Set<String> triedDrinkIds(
    IndianDrinksCatalogue catalogue,
    DrinkProgress progress,
  ) => catalogue.drinks
      .where((drink) => progress[drink.id]?.tried ?? false)
      .map((drink) => drink.id)
      .toSet();
}
