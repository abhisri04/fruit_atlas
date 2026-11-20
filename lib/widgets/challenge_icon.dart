import 'package:flutter/material.dart';

IconData challengeIcon(String identifier) => switch (identifier) {
  'fruit' => Icons.eco_outlined,
  'dish' => Icons.ramen_dining_outlined,
  'drink' => Icons.local_cafe_outlined,
  'jyotirlinga' => Icons.temple_hindu_outlined,
  'yoga' => Icons.self_improvement,
  'nut' => Icons.spa_outlined,
  'state' => Icons.map_outlined,
  'book' => Icons.menu_book_outlined,
  'perfume' => Icons.local_florist_outlined,
  _ => Icons.emoji_events_outlined,
};
