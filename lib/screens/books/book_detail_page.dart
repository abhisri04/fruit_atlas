import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/progress_service.dart';
import '../../widgets/reward_animations.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});
  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  BookProgress? progress;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p =
        (await ProgressService.getBookProgress())[widget.book.id] ??
        BookProgress(bookId: widget.book.id);
    if (mounted) setState(() => progress = p);
  }

  Future<BookLanguage?> pickLanguage() async {
    if (widget.book.availableLanguages.length == 1) {
      return widget.book.availableLanguages.single;
    }
    return showModalBottomSheet<BookLanguage>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Which version did you read?')),
            for (final l in widget.book.availableLanguages)
              ListTile(
                title: Text(l.label),
                onTap: () => Navigator.pop(context, l),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> setStatus(BookStatus value) async {
    BookLanguage? language;
    if (value == BookStatus.read) {
      language = await pickLanguage();
      if (language == null) return;
    }
    await ProgressService.setBookStatus(
      book: widget.book,
      status: value,
      language: language,
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.book, p = progress ?? BookProgress(bookId: b.id);
    return Scaffold(
      appBar: AppBar(title: Text(b.canonicalTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.menu_book_outlined, size: 72),
          ),
          const SizedBox(height: 20),
          Text(
            b.originalTitle ?? b.canonicalTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (b.originalTitle != null)
            Text(
              b.canonicalTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          Text(b.primaryAuthorDisplay),
          const SizedBox(height: 12),
          Text(
            '${b.availableLanguages.map((v) => v.label).join(' • ')} · ${b.primaryGenre}${b.publicationYear == null ? '' : ' · ${b.publicationYear}'}',
          ),
          const SizedBox(height: 16),
          Text(b.description),
          if (b.seriesId != null) ...[
            const SizedBox(height: 12),
            Text(
              'Series: ${b.seriesId} · Book ${b.seriesPosition?.toStringAsFixed(0)}',
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Want to Read'),
                selected: p.status == BookStatus.wantToRead,
                onSelected: (_) => setStatus(BookStatus.wantToRead),
              ),
              ChoiceChip(
                label: const Text('Currently Reading'),
                selected: p.status == BookStatus.currentlyReading,
                onSelected: (_) => setStatus(BookStatus.currentlyReading),
              ),
              TactileScale(
                child: ChoiceChip(
                  label: Text(p.isRead ? '✓ Read' : 'Read'),
                  selected: p.isRead,
                  onSelected: (_) =>
                      setStatus(p.isRead ? BookStatus.unread : BookStatus.read),
                ),
              ),
            ],
          ),
          if (p.readLanguages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Read in: ${p.readLanguages.map((v) => v.label).join(', ')}'),
          ],
        ],
      ),
    );
  }
}
