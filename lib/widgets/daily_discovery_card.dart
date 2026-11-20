import 'package:flutter/material.dart';

import '../models/daily_discovery.dart';
import '../theme/app_colors.dart';
import 'experience_artwork.dart';
import 'reward_animations.dart';

class DailyDiscoveryCard extends StatelessWidget {
  final DailyDiscovery? discovery;
  final bool isLoading;
  final bool isSaved;
  final VoidCallback? onDiscover;
  final VoidCallback? onSave;
  final VoidCallback? onAnother;

  const DailyDiscoveryCard({
    super.key,
    required this.discovery,
    required this.isLoading,
    required this.isSaved,
    this.onDiscover,
    this.onSave,
    this.onAnother,
  });

  IconData get icon => switch (discovery?.type) {
    DailyDiscoveryType.fruit => Icons.eco_outlined,
    DailyDiscoveryType.variety => Icons.local_florist_outlined,
    DailyDiscoveryType.yogaPose => Icons.self_improvement_outlined,
    DailyDiscoveryType.indianDish => Icons.ramen_dining_outlined,
    DailyDiscoveryType.indianDrink => Icons.local_cafe_outlined,
    DailyDiscoveryType.indiaLocation => Icons.map_outlined,
    DailyDiscoveryType.jyotirlinga => Icons.temple_hindu_outlined,
    DailyDiscoveryType.book => Icons.menu_book_outlined,
    DailyDiscoveryType.hobby => Icons.palette_outlined,
    null => Icons.auto_awesome_outlined,
  };

  String get presentationTitle => switch (discovery!.type) {
    DailyDiscoveryType.book => 'Read ${discovery!.title}',
    // Hobby titles are already actions, e.g. "Fold a paper crane".
    DailyDiscoveryType.hobby => discovery!.title,
    _ => 'Try ${discovery!.title}',
  };

  String get supportingCopy => switch (discovery!.type) {
    DailyDiscoveryType.fruit => 'Add a new fruit to your collection.',
    DailyDiscoveryType.variety =>
      'Discover another variety to add to your fruit journey.',
    DailyDiscoveryType.yogaPose => _yogaSupportingCopy(),
    DailyDiscoveryType.indianDish =>
      'Discover a dish from India’s food traditions.',
    DailyDiscoveryType.indianDrink =>
      'Discover a drink from India’s regional traditions.',
    DailyDiscoveryType.indiaLocation => 'Discover another part of India.',
    DailyDiscoveryType.jyotirlinga =>
      'Discover one of India’s twelve Jyotirlingas.',
    DailyDiscoveryType.book => 'Open a new chapter in your reading journey.',
    DailyDiscoveryType.hobby => 'A low-cost hobby you can start today.',
  };

  String get compactMetadata => switch (discovery!.type) {
    DailyDiscoveryType.fruit => 'Fruit',
    DailyDiscoveryType.variety => 'Fruit variety · ${discovery!.fruit!.name}',
    DailyDiscoveryType.yogaPose => [
      'Yoga',
      discovery!.yogaPose?.difficulty,
      discovery!.yogaPose?.category,
    ].whereType<String>().join(' · '),
    DailyDiscoveryType.indianDish => 'Indian dish',
    DailyDiscoveryType.indianDrink => 'Indian drink',
    DailyDiscoveryType.indiaLocation => 'State or Union Territory',
    DailyDiscoveryType.jyotirlinga => 'Jyotirlinga',
    DailyDiscoveryType.book => 'Book',
    DailyDiscoveryType.hobby => [
      'Hobby',
      discovery!.hobby?.category,
    ].whereType<String>().join(' · '),
  };

  String get primaryAction => switch (discovery!.type) {
    DailyDiscoveryType.fruit => 'Explore this fruit →',
    DailyDiscoveryType.variety => 'Explore this variety →',
    DailyDiscoveryType.yogaPose => 'Try this pose →',
    DailyDiscoveryType.indianDish => 'Explore this dish →',
    DailyDiscoveryType.indianDrink => 'Explore this drink →',
    DailyDiscoveryType.indiaLocation => 'Explore this place →',
    DailyDiscoveryType.jyotirlinga => 'Explore this Jyotirlinga →',
    DailyDiscoveryType.book => 'Explore this book →',
    DailyDiscoveryType.hobby => 'Try this hobby →',
  };

  String _yogaSupportingCopy() {
    final difficulty = discovery!.yogaPose?.difficulty?.trim();
    final category = discovery!.yogaPose?.category?.trim();
    if (difficulty == 'Beginner' && category != null && category.isNotEmpty) {
      return 'A beginner-friendly ${category.toLowerCase()} pose to add to your yoga journey.';
    }
    if (difficulty != null &&
        difficulty.isNotEmpty &&
        category != null &&
        category.isNotEmpty) {
      final article =
          RegExp(r'^[aeiou]', caseSensitive: false).hasMatch(difficulty)
          ? 'An'
          : 'A';
      return '$article ${difficulty.toLowerCase()}-level ${category.toLowerCase()} pose to add to your yoga journey.';
    }
    return 'Add a new pose to your yoga journey.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TODAY'S DISCOVERY",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'A fresh experience picked for you',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
              ? Duration.zero
              : const Duration(milliseconds: 340),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(.06, 0), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
          ),
          child: Card(
            key: ValueKey(
              isLoading ? 'loading' : discovery?.reference ?? 'complete',
            ),
            color: AppColors.accentSurface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const SizedBox(
                      height: 96,
                      child: Center(
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome_outlined),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text('Finding today\'s discoveryâ€¦'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : discovery == null
                  ? const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You have explored every Daily Discovery currently available.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExperienceArtwork(
                          discovery: discovery,
                          icon: icon,
                          height: 150,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    presentationTitle,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          supportingCopy,
                          style: const TextStyle(height: 1.35),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          compactMetadata,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TactileScale(
                            child: FilledButton(
                              onPressed: onDiscover,
                              child: Text(primaryAction),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: onSave,
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                ),
                                label: Text(
                                  isSaved
                                      ? 'Saved for later'
                                      : 'Save for later',
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: onAnother,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Surprise me'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
