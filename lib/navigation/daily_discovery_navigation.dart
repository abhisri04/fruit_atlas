import 'package:flutter/material.dart';

import '../models/daily_discovery.dart';
import '../models/fruit.dart';
import '../screens/challenge/checklist_item_details_page.dart';
import '../screens/dishes/indian_dishes_page.dart';
import '../screens/drinks/indian_drinks_page.dart';
import '../screens/fruit/fruit_details_page.dart';
import '../screens/fruit/variety_details_page.dart';
import '../screens/jyotirlinga/jyotirlinga_details_page.dart';
import '../screens/books/book_detail_page.dart';
import '../services/asset_data_service.dart';
import '../services/indian_dishes_repository.dart';
import '../services/indian_drinks_repository.dart';

Future<void> openDailyDiscoveryItem(
  BuildContext context,
  DailyDiscovery discovery,
) async {
  final states = discovery.type == DailyDiscoveryType.yogaPose
      ? const <AtlasState>[]
      : (await const AssetDataService().loadFruitData()).states;
  final dishes = discovery.type == DailyDiscoveryType.indianDish
      ? await const IndianDishesRepository().load()
      : null;
  final drinks = discovery.type == DailyDiscoveryType.indianDrink
      ? await const IndianDrinksRepository().load()
      : null;
  if (!context.mounted) return;
  final page = switch (discovery.type) {
    DailyDiscoveryType.fruit => FruitDetailsPage(
      fruit: discovery.fruit!,
      states: states,
    ),
    DailyDiscoveryType.variety => VarietyDetailsPage(
      variety: discovery.variety!,
      fruit: discovery.fruit!,
      states: states,
    ),
    DailyDiscoveryType.yogaPose => ChecklistItemDetailsPage(
      challenge: discovery.yogaChallenge!,
      item: discovery.yogaPose!,
    ),
    DailyDiscoveryType.indianDish => DishDetailPage(
      catalogue: dishes!,
      dishes: dishes.dishes,
      initialIndex: dishes.dishes.indexWhere(
        (dish) => dish.id == discovery.canonicalId,
      ),
    ),
    DailyDiscoveryType.indianDrink => DrinkDetailPage(
      catalogue: drinks!,
      drink: discovery.drink!,
    ),
    DailyDiscoveryType.indiaLocation => ChecklistItemDetailsPage(
      challenge: discovery.locationChallenge!,
      item: discovery.location!,
    ),
    DailyDiscoveryType.hobby ||
    DailyDiscoveryType.game ||
    DailyDiscoveryType.scent => ChecklistItemDetailsPage(
      challenge: discovery.hobbyChallenge!,
      item: discovery.hobby!,
    ),
    DailyDiscoveryType.jyotirlinga => JyotirlingaDetailsPage(
      site: discovery.jyotirlinga!,
    ),
    DailyDiscoveryType.book => BookDetailPage(book: discovery.book!),
  };
  await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}
