import 'package:flutter/material.dart';

import '../models/daily_discovery.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import 'dish_image.dart';
import 'dish_artwork.dart';
import 'fruit_image.dart';
import 'yoga_pose_tile.dart';

class ExperienceArtwork extends StatelessWidget {
  final String? assetPath;
  final DailyDiscovery? discovery;
  final IconData icon;
  final Color accent;
  final double height;
  final BorderRadius borderRadius;

  const ExperienceArtwork({
    super.key,
    this.assetPath,
    this.discovery,
    this.icon = Icons.auto_awesome_outlined,
    this.accent = AppColors.primary,
    this.height = 150,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    final item = discovery;
    Widget child;
    if (item?.fruit != null) {
      child = FruitImage(
        fruit: item!.fruit!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (item?.yogaPose?.imageUrl case final yogaAsset?) {
      child = YogaPoseImage(
        imagePath: yogaAsset,
        width: double.infinity,
        height: height,
        iconSize: 52,
        fit: BoxFit.cover,
      );
    } else if (item?.dish case final dish?) {
      child = DishArtwork(
        dish: dish,
        variant: DishArtworkVariant.hero,
        width: double.infinity,
        height: height,
      );
    } else if (item?.drink?.imageAsset case final drinkAsset?) {
      child = DishImage(
        assetPath: drinkAsset,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (assetPath != null) {
      child = Image.asset(
        assetPath!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else {
      child = _fallback();
    }
    return ClipRRect(borderRadius: borderRadius, child: child);
  }

  Widget _fallback() => Container(
    width: double.infinity,
    height: height,
    decoration: BoxDecoration(gradient: AppGradients.category(accent)),
    alignment: Alignment.center,
    child: Icon(icon, size: 52, color: Colors.white.withValues(alpha: .92)),
  );
}
