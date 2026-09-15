import 'package:flutter/material.dart';

import '../models/experience_collection.dart';
import '../theme/app_colors.dart';
import 'circular_progress_widget.dart';

IconData experienceCollectionIcon(String identifier) => switch (identifier) {
  'fruit' => Icons.eco_outlined,
  'dish' => Icons.restaurant_outlined,
  'drink' => Icons.local_drink_outlined,
  'landmark' => Icons.account_balance_outlined,
  'nature' => Icons.park_outlined,
  'activity' => Icons.directions_walk_outlined,
  'craft' => Icons.palette_outlined,
  'festival' => Icons.celebration_outlined,
  'music' => Icons.music_note_outlined,
  _ => Icons.collections_bookmark_outlined,
};

class ExperienceCollectionTile extends StatelessWidget {
  final ExperienceCollection collection;
  final int completedCount;
  final int totalCount;
  final VoidCallback onTap;
  const ExperienceCollectionTile({
    super.key,
    required this.collection,
    required this.completedCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            experienceCollectionIcon(collection.iconIdentifier),
            color: AppColors.primary,
          ),
          title: Text(
            collection.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('Coming soon'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          experienceCollectionIcon(collection.iconIdentifier),
          color: AppColors.primary,
        ),
        title: Text(
          collection.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$completedCount of $totalCount ${collection.completionVerb}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressWidget(
              progress: progress,
              variant: ProgressSize.compact,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
