import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/book_collection_service.dart';
import '../../services/book_share_service.dart';
import '../../services/progress_service.dart';
import '../../services/celebration_service.dart';
import '../../models/celebration_event.dart';
import '../../theme/app_colors.dart';
import '../../widgets/book_share_button.dart';
import '../../widgets/reward_animations.dart';
import 'book_detail_page.dart';

class BookCollectionPage extends StatefulWidget {
  final BookCatalogue catalogue;
  final TrackableBookCollection collection;
  final BookShareService shareService;
  const BookCollectionPage({
    super.key,
    required this.catalogue,
    required this.collection,
    this.shareService = const BookShareService(),
  });
  @override
  State<BookCollectionPage> createState() => _BookCollectionPageState();
}

class _BookCollectionPageState extends State<BookCollectionPage> {
  Map<String, BookProgress> progress = {};
  Future<void> load() async {
    final value = await ProgressService.getBookProgress();
    if (mounted) {
      setState(() => progress = value);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    final service = const BookCollectionService(),
        value = service.progress(widget.collection, progress);
    final books = widget.catalogue.books
        .where((b) => widget.collection.bookIds.contains(b.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.collection.type.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.collection.description,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.collection.isFinite
                ? '${value.completed} of ${value.total} read'
                : '${value.completed} books read',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (value.percentage case final p?) ...[
            const SizedBox(height: 8),
            AnimatedProgressValue(value: p, color: AppColors.primary),
            const SizedBox(height: 4),
            Text('${(p * 100).round()}%'),
          ],
          if (value.canClaimAll) ...[
            const SizedBox(height: 12),
            Chip(
              label: Text(
                '${widget.collection.type.name.toUpperCase()} COMPLETED',
              ),
            ),
          ],
          if (widget.collection.shareEnabled) ...[
            const SizedBox(height: 8),
            BookShareButton(
              payload: service.share(value),
              shareService: widget.shareService,
            ),
          ],
          const SizedBox(height: 12),
          ...books.map(
            (book) => ListTile(
              leading: Icon(
                (progress[book.id]?.isRead ?? false)
                    ? Icons.check_circle
                    : Icons.circle_outlined,
              ),
              title: Text(book.originalTitle ?? book.canonicalTitle),
              subtitle: Text(book.primaryAuthorDisplay),
              onTap: () async {
                final before = service.progress(widget.collection, progress);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
                );
                await load();
                final after = service.progress(widget.collection, progress);
                if (!before.canClaimAll && after.canClaimAll) {
                  final type = widget.collection.type;
                  await CelebrationService.instance.emitOnce(
                    CelebrationEvent(
                      id: 'bookCollection:${widget.collection.id}',
                      kind: CelebrationKind.collectionComplete,
                      intensity: CelebrationIntensity.large,
                      title: type == BookCollectionType.series
                          ? 'Series completed'
                          : type == BookCollectionType.author
                          ? 'Bibliography completed'
                          : 'Collection completed',
                      message: widget.collection.title,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
