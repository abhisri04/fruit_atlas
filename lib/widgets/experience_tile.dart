import 'package:flutter/material.dart';

import '../models/experience.dart';
import '../theme/app_colors.dart';

class ExperienceTile extends StatelessWidget {
  final Experience experience;
  final bool completed;
  final VoidCallback onTap;
  final ValueChanged<bool> onCompletionChanged;

  const ExperienceTile({
    super.key,
    required this.experience,
    required this.completed,
    required this.onTap,
    required this.onCompletionChanged,
  });

  IconData get icon => switch (experience.type) {
    'place' => Icons.place_outlined,
    'activity' => Icons.directions_walk_outlined,
    'food' => Icons.restaurant_outlined,
    'culture' => Icons.theater_comedy_outlined,
    _ => Icons.explore_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: completed ? AppColors.completedSurface : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: completed ? AppColors.primary : null),
        title: Text(
          experience.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: completed ? AppColors.primary : AppColors.ink,
          ),
        ),
        subtitle: Text(experience.locationLabel),
        trailing: Checkbox(
          value: completed,
          onChanged: (value) => onCompletionChanged(value ?? false),
        ),
        onTap: onTap,
      ),
    );
  }
}
