import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum NoticeKind { information, research, caution }

class DataNotice extends StatelessWidget {
  final String message;
  final NoticeKind kind;
  const DataNotice({
    super.key,
    required this.message,
    this.kind = NoticeKind.information,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, title) = switch (kind) {
      NoticeKind.information => (
        AppColors.information,
        Icons.info_outline,
        'Good to know',
      ),
      NoticeKind.research => (
        AppColors.accentSurface,
        Icons.science_outlined,
        'Research-stage data',
      ),
      NoticeKind.caution => (
        AppColors.caution,
        Icons.warning_amber_rounded,
        'Mapping notice',
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
