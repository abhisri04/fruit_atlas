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

  /// Icon and colour for an item without a photo, based on what it is.
  (IconData, Color) get _fallbackStyle {
    final item = discovery;
    if (item == null) return (icon, accent);
    return switch (item.type) {
      DailyDiscoveryType.book => (
        Icons.menu_book_outlined,
        AppColors.categoryAccent('culture_learning'),
      ),
      DailyDiscoveryType.hobby => (
        Icons.palette_outlined,
        AppColors.categoryAccent('life_experiences'),
      ),
      DailyDiscoveryType.indiaLocation => (
        Icons.map_outlined,
        AppColors.categoryAccent('travel_exploration'),
      ),
      DailyDiscoveryType.jyotirlinga => (
        Icons.temple_hindu_outlined,
        AppColors.categoryAccent('faith_pilgrimage'),
      ),
      DailyDiscoveryType.yogaPose => (
        Icons.self_improvement,
        AppColors.categoryAccent('fitness_wellness'),
      ),
      _ => (icon, AppColors.categoryAccent(item.categoryId)),
    };
  }

  Widget _fallback() {
    final (glyph, tint) = _fallbackStyle;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(gradient: AppGradients.category(tint)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -height * .25,
            top: -height * .3,
            child: _Circle(size: height * .95),
          ),
          Positioned(
            left: -height * .2,
            bottom: -height * .35,
            child: _Circle(size: height * .7),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .16),
              border: Border.all(color: Colors.white.withValues(alpha: .35)),
            ),
            child: Icon(
              glyph,
              size: (height * .3).clamp(28.0, 52.0),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  const _Circle({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: .08),
    ),
  );
}
