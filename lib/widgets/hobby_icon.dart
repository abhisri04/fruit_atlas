import 'package:flutter/material.dart';

/// Icon for a hobby catalogue group, e.g. "Creative & Crafts".
IconData hobbyGroupIcon(String? group) => switch (group) {
  'Creative & Crafts' => Icons.palette_outlined,
  'Mind & Words' => Icons.psychology_outlined,
  'Outdoors & Nature' => Icons.park_outlined,
  'Grow & Make' => Icons.local_florist_outlined,
  'Music & Play' => Icons.music_note_outlined,
  'Capture & Share' => Icons.photo_camera_outlined,
  'Fitness & Movement' => Icons.directions_run,
  'Learn & Explore' => Icons.lightbulb_outline,
  'People & Community' => Icons.diversity_3_outlined,
  _ => Icons.auto_awesome_outlined,
};
