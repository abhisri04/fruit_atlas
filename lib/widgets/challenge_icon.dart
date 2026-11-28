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
  'hobby' => Icons.palette_outlined,
  'game' => Icons.casino_outlined,
  'scent_family' => Icons.donut_large_outlined,
  'scent_note' => Icons.spa_outlined,
  'attar' => Icons.water_drop_outlined,
  'garden' => Icons.yard_outlined,
  'plant' => Icons.eco_outlined,
  'garden_skill' => Icons.handyman_outlined,
  'garden_visit' => Icons.park_outlined,
  _ => Icons.emoji_events_outlined,
};
