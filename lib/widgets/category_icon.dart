import 'package:flutter/material.dart';

IconData categoryIcon(String categoryId) => switch (categoryId) {
  'food_drink' => Icons.restaurant_outlined,
  'fitness_wellness' => Icons.self_improvement,
  'travel_exploration' => Icons.explore_outlined,
  'culture_learning' => Icons.menu_book_outlined,
  'faith_pilgrimage' => Icons.temple_hindu_outlined,
  'collecting' => Icons.collections_bookmark_outlined,
  'life_experiences' => Icons.auto_awesome_outlined,
  'games_play' => Icons.casino_outlined,
  'scent' => Icons.local_florist_outlined,
  _ => Icons.grid_view_rounded,
};
