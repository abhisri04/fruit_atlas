import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/book_share_service.dart';

class BookShareButton extends StatelessWidget {
  final BookSharePayload payload;
  final BookShareService shareService;
  const BookShareButton({
    super.key,
    required this.payload,
    this.shareService = const BookShareService(),
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const ValueKey('book-share-progress'),
    onPressed: () async {
      try {
        await shareService.share(payload);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sharing is unavailable right now. Please try again.',
            ),
          ),
        );
      }
    },
    icon: const Icon(Icons.share_outlined),
    label: const Text('Share progress'),
  );
}
