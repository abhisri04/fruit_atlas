import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../screens/challenge/fruit_challenge_page.dart';
import '../screens/challenge/generic_checklist_challenge_page.dart';
import '../screens/challenge/jyotirlinga_challenge_page.dart';
import '../screens/dishes/indian_dishes_page.dart';
import '../screens/drinks/indian_drinks_page.dart';

Future<void> openChallenge(BuildContext context, Challenge challenge) async {
  final Widget? page = switch (challenge.presentationType) {
    'catalogue' when challenge.itemType == 'indian_dish' =>
      const IndianDishesPage(),
    'catalogue' when challenge.itemType == 'indian_drink' =>
      const IndianDrinksPage(),
    'checklist_with_subitems' => FruitChallengePage(challenge: challenge),
    'map_checklist' => JyotirlingaChallengePage(challenge: challenge),
    'checklist' || 'checklist_with_details' => GenericChecklistChallengePage(
      challenge: challenge,
    ),
    _ => null,
  };

  if (page != null) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
