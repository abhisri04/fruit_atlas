import 'package:flutter/material.dart';

import '../screens/hobbies/hobby_finder_page.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

/// Entry card to the hobby finder, shown on Home, Explore and the hobby
/// challenge.
class HobbyFinderEntry extends StatelessWidget {
  final VoidCallback? onReturn;

  const HobbyFinderEntry({super.key, this.onReturn});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('life_experiences');
    return TactileScale(
      child: Material(
        key: const ValueKey('hobby-finder-entry'),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent.withValues(alpha: .35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HobbyFinderPage()),
            );
            onReturn?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.auto_awesome, color: accent),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find your next hobby',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '250 hobbies & games, indoors or out. Get matches or let us pick.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
