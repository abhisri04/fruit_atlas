import 'package:flutter/material.dart';

class DishDietaryIndicator extends StatelessWidget {
  final String dietaryType;
  final bool showLabel;
  final bool compact;

  const DishDietaryIndicator({
    super.key,
    required this.dietaryType,
    this.showLabel = false,
    this.compact = false,
  });

  static DishDietaryIdentity? identityFor(String dietaryType) =>
      switch (dietaryType) {
        'vegetarian' => const DishDietaryIdentity(
          label: 'Veg',
          semanticLabel: 'Vegetarian dish',
          color: Color(0xFF16843A),
        ),
        'non_vegetarian' => const DishDietaryIdentity(
          label: 'Non-veg',
          semanticLabel: 'Non-vegetarian dish',
          color: Color(0xFFD32F2F),
        ),
        'contains_egg' => const DishDietaryIdentity(
          label: 'Egg',
          semanticLabel: 'Contains egg',
          color: Color(0xFFF4B400),
        ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final identity = identityFor(dietaryType);
    if (identity == null) return const SizedBox.shrink();
    final markerSize = compact ? 17.0 : 20.0;
    final marker = Container(
      width: markerSize,
      height: markerSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: identity.color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Container(
        width: compact ? 8 : 10,
        height: compact ? 8 : 10,
        decoration: BoxDecoration(
          color: identity.color,
          shape: BoxShape.circle,
        ),
      ),
    );
    return Semantics(
      label: identity.semanticLabel,
      child: Tooltip(
        message: identity.semanticLabel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            marker,
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                identity.label,
                style: TextStyle(
                  color: identity.color,
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DishDietaryIdentity {
  final String label;
  final String semanticLabel;
  final Color color;

  const DishDietaryIdentity({
    required this.label,
    required this.semanticLabel,
    required this.color,
  });
}
