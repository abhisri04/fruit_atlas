import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ringTrack = Color(0xFFB7CBC0);
  static const orange = Color(0xFFF59E0B);
  static const purple = Color(0xFF8B5CF6);
  static const blue = Color(0xFF2498D1);
  static Color categoryAccent(String id) => switch (id) {
    'food_drink' || 'faith_pilgrimage' => orange,
    'fitness_wellness' || 'collecting' => purple,
    'travel_exploration' => blue,
    'culture_learning' => Color(0xFFAD6545),
    _ => primary,
  };
  static const background = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF0F766E);
  static const accentSurface = Color(0xFFEAF2ED);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const completedSurface = Color(0xFFF1F6F2);
  static const outline = Color(0xFFDEE5DF);
  static const information = Color(0xFFEDF3F8);
  static const caution = Color(0xFFFFF4DF);
}
