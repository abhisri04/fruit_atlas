import 'package:flutter/material.dart';

import 'indian_dish.dart';

enum DishVisualCategory {
  breadFlatbread,
  rice,
  curry,
  snack,
  dessert,
  leafyVeg,
  seafood,
  meatSpeciality,
  regionalSpeciality,
  defaultFood,
}

class DishVisualStyle {
  final DishVisualCategory category;
  final Color backgroundStart, backgroundEnd, accent, foreground;
  final String label;
  const DishVisualStyle(
    this.category,
    this.backgroundStart,
    this.backgroundEnd,
    this.accent,
    this.label,
  ) : foreground = const Color(0xFF30251F);
  static final styles = <DishVisualCategory, DishVisualStyle>{
    for (final entry in [
      (
        DishVisualCategory.breadFlatbread,
        0xFFF9EACB,
        0xFFFFF8E9,
        0xFFAD7428,
        'Bread',
      ),
      (DishVisualCategory.rice, 0xFFFFDBA3, 0xFFFFF3D9, 0xFFBD651D, 'Rice'),
      (DishVisualCategory.curry, 0xFFF0C2A9, 0xFFFFECDD, 0xFFA7422D, 'Curry'),
      (DishVisualCategory.snack, 0xFFFFE39C, 0xFFFFF4D2, 0xFFC27A1F, 'Snack'),
      (
        DishVisualCategory.dessert,
        0xFFF5D0CE,
        0xFFFFF0E7,
        0xFFAC546A,
        'Dessert',
      ),
      (
        DishVisualCategory.leafyVeg,
        0xFFD5DFB9,
        0xFFF1F4E3,
        0xFF536B38,
        'Vegetables',
      ),
      (
        DishVisualCategory.seafood,
        0xFFBADDDC,
        0xFFEEF7EF,
        0xFF287879,
        'Seafood',
      ),
      (
        DishVisualCategory.meatSpeciality,
        0xFFE3C1B6,
        0xFFF7E8DB,
        0xFF813E3F,
        'Speciality',
      ),
      (
        DishVisualCategory.regionalSpeciality,
        0xFFDCCCE3,
        0xFFF5EDF5,
        0xFF76517F,
        'Regional',
      ),
      (
        DishVisualCategory.defaultFood,
        0xFFE5DDD0,
        0xFFFAF4E9,
        0xFF7B6A55,
        'Food',
      ),
    ])
      entry.$1: DishVisualStyle(
        entry.$1,
        Color(entry.$2),
        Color(entry.$3),
        Color(entry.$4),
        entry.$5,
      ),
  };
}

class DishVisualResolver {
  static final Map<String, RegExp> _patterns = {};
  static const overrides = <String, DishVisualCategory>{
    'exp_uttarakhand_kafuli': DishVisualCategory.leafyVeg,
    'exp_goa_ambadyachi_uddamethi': DishVisualCategory.leafyVeg,
  };
  static DishVisualCategory resolve(IndianDish dish) {
    if (overrides[dish.id] case final category?) return category;
    final words = '${dish.name} ${dish.dishType} ${dish.tags.join(' ')}'
        .toLowerCase()
        .replaceAll('_', ' ');
    bool has(String pattern) => _patterns
        .putIfAbsent(pattern, () => RegExp('\\b($pattern)\\b'))
        .hasMatch(words);
    if (has('bread|roti|flatbread|paratha|kulcha|naan|chapati|baati')) {
      return DishVisualCategory.breadFlatbread;
    }
    if (has('rice|biryani|biriyani|pulao|pulav|khichdi')) {
      return DishVisualCategory.rice;
    }
    if (has('dessert|sweet|kheer|halwa|poda')) {
      return DishVisualCategory.dessert;
    }
    if (has('snack|street food|fritter|pakodi|pakora|samosa|dosa|idli')) {
      return DishVisualCategory.snack;
    }
    if (has('fish|seafood|prawn|shrimp|crab|ilish')) {
      return DishVisualCategory.seafood;
    }
    if (has('leafy|vegetable|spinach|saag|salad|kafuli')) {
      return DishVisualCategory.leafyVeg;
    }
    if (has('curry|gravy|stew|dal|butter chicken')) {
      return DishVisualCategory.curry;
    }
    if (has('chicken|mutton|pork|meat|beef')) {
      return DishVisualCategory.meatSpeciality;
    }
    if (has('regional|traditional')) {
      return DishVisualCategory.regionalSpeciality;
    }
    return DishVisualCategory.defaultFood;
  }

  static String location(IndianDish dish) {
    final origins = dish.originStateIds.toSet();
    final associated = dish.associatedStateIds.toSet();
    if (origins.length == 1) {
      return IndianDish.stateNames[origins.single] ??
          origins.single.replaceAll('_', ' ');
    }
    if (origins.isEmpty && associated.length == 1) {
      return IndianDish.stateNames[associated.single] ??
          associated.single.replaceAll('_', ' ');
    }
    if (dish.regions.toSet().length == 1) return dish.regions.single;
    return 'India';
  }

  static String? dietaryLabel(IndianDish dish) => switch (dish.dietaryType) {
    'vegetarian' => 'Veg',
    'non_vegetarian' => 'Non-Veg',
    'vegan' => 'Vegan',
    'egg' || 'eggetarian' || 'contains_egg' => 'Contains egg',
    _ => null,
  };
}
