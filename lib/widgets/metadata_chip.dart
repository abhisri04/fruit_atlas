import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A non-selectable metadata pill with explicit contrast on Android.
class MetadataChip extends StatelessWidget {
  final String label;

  const MetadataChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.accentSurface,
      side: const BorderSide(color: AppColors.outline),
    );
  }
}
