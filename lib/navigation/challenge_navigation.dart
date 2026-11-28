import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../screens/challenge/fruit_challenge_page.dart';
import '../screens/challenge/generic_checklist_challenge_page.dart';
import '../screens/challenge/jyotirlinga_challenge_page.dart';
import '../screens/dishes/indian_dishes_page.dart';
import '../screens/drinks/indian_drinks_page.dart';
import '../screens/books/books_page.dart';
import '../screens/hubs/category_hub_page.dart';
import '../screens/mixed_drinks/mixed_drinks_page.dart';
import '../screens/nuts/nuts_page.dart';
import '../services/challenge_groups.dart';
import '../screens/travel/india_passport_page.dart';

Future<void> openChallenge(BuildContext context, Challenge challenge) async {
  final hub = hubForId(challenge.id);
  final Widget? page = hub != null
      ? CategoryHubPage(categoryId: hub.categoryId)
      : challenge.itemType == 'state_or_union_territory'
      ? const IndiaPassportPage()
      : switch (challenge.presentationType) {
          'catalogue' when challenge.itemType == 'indian_dish' =>
            const IndianDishesPage(),
          'catalogue' when challenge.itemType == 'indian_drink' =>
            const IndianDrinksPage(),
          'book_catalogue' when challenge.itemType == 'book' =>
            const BooksPage(),
          'checklist_with_subitems' => FruitChallengePage(challenge: challenge),
          'map_checklist' => JyotirlingaChallengePage(challenge: challenge),
          'nut_atlas' => NutsPage(challenge: challenge),
          'drink_maker' => MixedDrinksPage(challenge: challenge),
          'checklist' || 'checklist_with_details' =>
            GenericChecklistChallengePage(challenge: challenge),
          _ => null,
        };

  if (page != null) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
