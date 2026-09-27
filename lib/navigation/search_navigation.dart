import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/challenge.dart';
import '../models/district.dart';
import '../models/fruit.dart';
import '../models/experience.dart';
import '../models/item.dart';
import '../models/jyotirlinga.dart';
import '../models/indian_dish.dart';
import '../models/indian_drink.dart';
import '../models/search_result.dart';
import '../services/global_search_service.dart';
import '../screens/discover/category_details_page.dart';
import '../screens/district/district_details_page.dart';
import '../screens/fruit/fruit_details_page.dart';
import '../screens/fruit/variety_details_page.dart';
import '../screens/experience/experience_details_page.dart';
import '../screens/jyotirlinga/jyotirlinga_details_page.dart';
import '../screens/challenge/checklist_item_details_page.dart';
import '../screens/dishes/indian_dishes_page.dart';
import '../screens/drinks/indian_drinks_page.dart';
import 'challenge_navigation.dart';

Future<void> openSearchResult(
  BuildContext context,
  SearchResult result,
  GlobalSearchService search,
) async {
  final target = result.destination;
  final challenge = search.challenges
      .where((c) => c.id == result.challengeId)
      .firstOrNull;
  if (target is Challenge && target.status == 'active') {
    await openChallenge(context, target);
    return;
  }
  final category = search.categories
      .where((c) => c.id == result.categoryId)
      .firstOrNull;
  final Widget? page = switch (target) {
    Category c => CategoryDetailsPage(
      category: c,
      challenges: search.challenges,
    ),
    Challenge _ when category != null => CategoryDetailsPage(
      category: category,
      challenges: search.challenges,
    ),
    Fruit f => FruitDetailsPage(fruit: f, states: search.states),
    FruitVariety v when result.parent is Fruit => VarietyDetailsPage(
      variety: v,
      fruit: result.parent as Fruit,
      states: search.states,
    ),
    JyotirlingaSite site => JyotirlingaDetailsPage(site: site),
    Experience experience => ExperienceDetailsPage(experience: experience),
    District district => DistrictDetailsPage(district: district),
    IndianDish dish when search.dishesCatalogue != null => DishDetailPage(
      catalogue: search.dishesCatalogue!,
      dishes: search.dishesCatalogue!.dishes,
      initialIndex: search.dishesCatalogue!.dishes.indexWhere(
        (value) => value.id == dish.id,
      ),
    ),
    IndianDrink drink when search.drinksCatalogue != null => DrinkDetailPage(
      catalogue: search.drinksCatalogue!,
      drink: drink,
    ),
    Item item when challenge != null => ChecklistItemDetailsPage(
      challenge: challenge,
      item: item,
    ),
    SubItem _ when challenge != null && result.parent is Item =>
      ChecklistItemDetailsPage(
        challenge: challenge,
        item: result.parent as Item,
      ),
    _ => null,
  };
  if (page != null) {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
