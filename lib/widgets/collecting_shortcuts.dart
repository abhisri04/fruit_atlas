import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../navigation/challenge_navigation.dart';
import '../services/challenge_groups.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

/// Under the Collecting chip: perfume and every other kind of collection.
class CollectingShortcuts extends StatelessWidget {
  final List<Challenge> challenges;
  const CollectingShortcuts({super.key, required this.challenges});

  @override
  Widget build(BuildContext context) {
    final start = challenges
        .where((c) => c.id == 'start_a_collection')
        .firstOrNull;
    final scent = [
      for (final c in challenges)
        if (c.categoryId == scentCategoryId && c.status == 'active') c,
    ];
    final tiles = [
      if (start != null)
        (
          'collecting-start',
          Icons.collections_bookmark_outlined,
          'Start a collection',
          'Sneakers, coins, stamps, vinyl and more',
          AppColors.categoryAccent('collecting'),
          start,
        ),
      if (scent.isNotEmpty)
        (
          'collecting-scent',
          Icons.local_florist_outlined,
          'Scent & Perfume',
          'Families, famous perfumes and your shelf',
          AppColors.categoryAccent('scent'),
          hubChallenge(categoryHubs[scentCategoryId]!, scent),
        ),
    ];
    return Column(
      children: [
        for (final (key, icon, title, subtitle, color, challenge) in tiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TactileScale(
              child: Material(
                key: ValueKey(key),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: color.withValues(alpha: .35)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(subtitle),
                  trailing: Icon(Icons.chevron_right, color: color),
                  onTap: () => openChallenge(context, challenge),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
