import 'package:flutter/material.dart';

import '../screens/garden/garden_home_page.dart';
import '../services/challenge_groups.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

/// Easy hobbies that are a first step into Garden & Plants.
const gardeningHobbyIds = {
  'hobby_botanical_garden',
  'hobby_press_leaves',
  'hobby_plant_tree',
  'hobby_herb_pot',
  'hobby_microgreens_tray',
  'hobby_start_compost',
  'hobby_money_plant_cutting',
  'hobby_terrarium',
};

/// "Go deeper in Garden & Plants" on a gardening hobby's page.
class GardenHubLink extends StatelessWidget {
  const GardenHubLink({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent(gardenCategoryId);
    return TactileScale(
      child: Card(
        key: const ValueKey('garden-hub-link'),
        margin: EdgeInsets.zero,
        color: accent.withValues(alpha: .08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: accent.withValues(alpha: .25)),
        ),
        child: ListTile(
          leading: Icon(Icons.yard_outlined, color: accent),
          title: const Text(
            'Go deeper in Garden & Plants',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Plants to grow this season, garden skills and famous gardens.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GardenHomePage()),
          ),
        ),
      ),
    );
  }
}
