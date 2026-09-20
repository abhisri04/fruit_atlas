import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../models/fruit.dart';
import '../theme/app_colors.dart';
import 'fruit_image.dart';

class SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;
  const SearchResultTile({
    super.key,
    required this.result,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent(result.categoryId);
    final fruit = result.destination is Fruit
        ? result.destination as Fruit
        : result.parent is Fruit
        ? result.parent as Fruit
        : null;
    final icon = switch (result.entityType) {
      SearchEntityType.category => Icons.category_outlined,
      SearchEntityType.challenge => Icons.emoji_events_outlined,
      SearchEntityType.subItem => Icons.spa_outlined,
      SearchEntityType.experience => Icons.explore_outlined,
      SearchEntityType.district => Icons.location_city_outlined,
      SearchEntityType.item => switch (result.categoryId) {
        'food_drink' => Icons.eco_outlined,
        'faith_pilgrimage' => Icons.temple_hindu_outlined,
        'fitness_wellness' => Icons.self_improvement,
        _ => Icons.explore_outlined,
      },
    };
    return Card(
      child: ListTile(
        leading: fruit != null
            ? FruitImage(fruit: fruit, width: 46, height: 46)
            : Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Color.lerp(accent, Colors.black, .22)),
              ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          result.subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
