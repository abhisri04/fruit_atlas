import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FilterChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 6,
      runSpacing: 4,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(option),
              selected: selected == option,
              showCheckmark: false,
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: selected == option
                    ? AppColors.primary
                    : AppColors.outline,
              ),
              labelStyle: TextStyle(
                color: selected == option ? Colors.white : AppColors.ink,
                fontWeight: selected == option
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              onSelected: (_) => onChanged(option),
            ),
          )
          .toList(),
    ),
  );
}
