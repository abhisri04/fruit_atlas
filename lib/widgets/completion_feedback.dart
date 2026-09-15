import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/app_colors.dart';

/// Called only after a successful user-initiated completion write.
void showCompletionFeedback(
  BuildContext context, {
  required int before,
  required int after,
  int total = 0,
  String? challengeId,
  String message = 'Another experience added to your Life.',
}) {
  if (after <= before) return;
  final unlocked = Achievement.forChallenge(challengeId ?? '')
      .where((a) => a.threshold > before && a.threshold <= after);
  final complete = total > 0 && before < total && after >= total;
  final text = complete
      ? 'Collection complete. Every experience counts.'
      : unlocked.isNotEmpty
      ? 'Achievement unlocked: ${unlocked.last.title}'
      : message;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
      duration: Duration(seconds: complete || unlocked.isNotEmpty ? 3 : 2),
      content: Row(
        children: [
          Icon(
            complete || unlocked.isNotEmpty
                ? Icons.emoji_events_outlined
                : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}
