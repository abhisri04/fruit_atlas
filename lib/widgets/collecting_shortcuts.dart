import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../navigation/challenge_navigation.dart';
import '../services/challenge_groups.dart';
import '../screens/making/my_makes_page.dart';
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

/// Under the DIY & Art chip: the project catalogue and your makes.
class MakingShortcuts extends StatelessWidget {
  final List<Challenge> challenges;
  const MakingShortcuts({super.key, required this.challenges});

  @override
  Widget build(BuildContext context) {
    final make = challenges.where((c) => c.id == 'make_something').firstOrNull;
    final color = AppColors.categoryAccent('making');
    Widget tile(
      String key,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
    ) => Padding(
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
            onTap: onTap,
          ),
        ),
      ),
    );
    return Column(
      children: [
        if (make != null)
          tile(
            'making-start',
            Icons.brush_outlined,
            'Make something',
            'Crochet, journaling, painting, Indian folk art',
            () => openChallenge(context, make),
          ),
        tile(
          'making-mine',
          Icons.photo_library_outlined,
          'My makes',
          'Projects on the go and a gallery of what you made',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyMakesPage()),
          ),
        ),
      ],
    );
  }
}
