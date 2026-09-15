import 'package:flutter/material.dart';

import '../models/district.dart';
import '../theme/app_colors.dart';

class DistrictTile extends StatelessWidget {
  final District district;
  final bool completed;
  final VoidCallback onTap;
  final ValueChanged<bool> onCompletionChanged;

  const DistrictTile({
    super.key,
    required this.district,
    required this.completed,
    required this.onTap,
    required this.onCompletionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: completed ? AppColors.completedSurface : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.location_city_outlined,
          color: completed ? AppColors.primary : null,
        ),
        title: Text(
          district.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: completed ? AppColors.primary : AppColors.ink,
          ),
        ),
        subtitle: const Text('District'),
        trailing: Checkbox(
          value: completed,
          onChanged: (value) => onCompletionChanged(value ?? false),
        ),
        onTap: onTap,
      ),
    );
  }
}
