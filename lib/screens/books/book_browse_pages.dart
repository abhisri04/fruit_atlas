import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/book_collection_service.dart';
import '../../services/book_discovery_service.dart';
import '../../services/books_repository.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import 'book_collection_page.dart';
import 'book_detail_page.dart';

Future<void> openBookCollection(
  BuildContext context,
  BookCatalogue catalogue,
  TrackableBookCollection collection,
) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) =>
        BookCollectionPage(catalogue: catalogue, collection: collection),
  ),
);

class BookAuthorsPage extends StatefulWidget {
  final BookCatalogue catalogue;
  final Map<String, BookProgress> progress;
  final List<TrackableBookCollection> collections;
  final List<FeaturedAuthorConfig> featured;
  const BookAuthorsPage({
    super.key,
    required this.catalogue,
    required this.progress,
    required this.collections,
    required this.featured,
  });

  @override
  State<BookAuthorsPage> createState() => _BookAuthorsPageState();
}

class _BookAuthorsPageState extends State<BookAuthorsPage> {
  String query = '';
  BookLanguage? language;

  @override
  Widget build(BuildContext context) {
    final discovery = BookDiscoveryService(widget.catalogue);
    final authors = discovery.authors(query, language: language);
    final byAuthor = {
      for (final collection in widget.collections)
        if (collection.authorId != null) collection.authorId!: collection,
    };
    final featuredAuthors = widget.featured
        .map((item) => widget.catalogue.authorById[item.authorId])
        .whereType<Author>()
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Authors')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('author-search'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search authors…',
                    ),
                    onChanged: (value) => setState(() => query = value),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: language == null,
                        onSelected: (_) => setState(() => language = null),
                      ),
                      for (final value in BookLanguage.values)
                        ChoiceChip(
                          label: Text(value.label),
                          selected: language == value,
                          onSelected: (_) => setState(() => language = value),
                        ),
                    ],
                  ),
                  if (query.isEmpty && language == null) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Featured Authors',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 154,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredAuthors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final author = featuredAuthors[index];
                          final collection = byAuthor[author.id]!;
                          return SizedBox(
                            width: 220,
                            child: BookAuthorCard(
                              author: author,
                              value: const BookCollectionService().progress(
                                collection,
                                widget.progress,
                              ),
                              onTap: () => openBookCollection(
                                context,
                                widget.catalogue,
                                collection,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    '${authors.length} Authors',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.builder(
              itemCount: authors.length,
              itemBuilder: (_, index) {
                final author = authors[index];
                final collection = byAuthor[author.id]!;
                final value = const BookCollectionService().progress(
                  collection,
                  widget.progress,
                );
                return Card(
                  child: ListTile(
                    leading: AuthorMonogram(name: author.name),
                    title: Text(
                      author.nativeName == null
                          ? author.name
                          : '${author.name} · ${author.nativeName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(authorProgressText(value)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openBookCollection(
                      context,
                      widget.catalogue,
                      collection,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BookGenresPage extends StatefulWidget {
  final BookCatalogue catalogue;
  final Map<String, BookProgress> progress;
  final List<TrackableBookCollection> collections;
  const BookGenresPage({
    super.key,
    required this.catalogue,
    required this.progress,
    required this.collections,
  });

  @override
  State<BookGenresPage> createState() => _BookGenresPageState();
}

class _BookGenresPageState extends State<BookGenresPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final byGenre = {
      for (final collection in widget.collections)
        if (collection.genreId != null) collection.genreId!: collection,
    };
    final genres = BookDiscoveryService(widget.catalogue)
        .genres(query)
        .where((genre) => byGenre.containsKey(genre.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Genres')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const ValueKey('genre-search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search genres…',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 144,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: genres.length,
              itemBuilder: (_, index) {
                final genre = genres[index], collection = byGenre[genre.id]!;
                return BookGenreCard(
                  genre: genre,
                  value: const BookCollectionService().progress(
                    collection,
                    widget.progress,
                  ),
                  onTap: () =>
                      openBookCollection(context, widget.catalogue, collection),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BookCollectionsPage extends StatefulWidget {
  final BookCatalogue catalogue;
  final Map<String, BookProgress> progress;
  final List<TrackableBookCollection> collections;
  const BookCollectionsPage({
    super.key,
    required this.catalogue,
    required this.progress,
    required this.collections,
  });

  @override
  State<BookCollectionsPage> createState() => _BookCollectionsPageState();
}

class _BookCollectionsPageState extends State<BookCollectionsPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final discovery = BookDiscoveryService(widget.catalogue);
    final collections = discovery.collections(widget.collections, query);
    return Scaffold(
      appBar: AppBar(title: const Text('Collections')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const ValueKey('collection-search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search collections…',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: collections.length,
              itemBuilder: (_, index) {
                final collection = collections[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: BookCollectionCard(
                    collection: collection,
                    value: const BookCollectionService().progress(
                      collection,
                      widget.progress,
                    ),
                    onTap: () => openBookCollection(
                      context,
                      widget.catalogue,
                      collection,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AllBooksPage extends StatefulWidget {
  final BookCatalogue catalogue;
  final Map<String, BookProgress> progress;
  const AllBooksPage({
    super.key,
    required this.catalogue,
    required this.progress,
  });

  @override
  State<AllBooksPage> createState() => _AllBooksPageState();
}

class _AllBooksPageState extends State<AllBooksPage> {
  String query = '', language = 'all', status = 'all';
  late Map<String, BookProgress> localProgress = Map.of(widget.progress);

  Future<void> reloadProgress() async {
    final value = await ProgressService.getBookProgress();
    if (mounted) setState(() => localProgress = value);
  }

  @override
  Widget build(BuildContext context) {
    final books = BooksRepository.filter(
      widget.catalogue.books,
      query: query,
      language: language == 'all' ? null : BookLanguageValue.parse(language),
      status: status == 'all'
          ? null
          : BookStatus.values.firstWhere((value) => value.name == status),
      progress: localProgress,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('All Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  key: const ValueKey('book-search'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search title or author…',
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: language,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'english',
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: 'hindi',
                            child: Text('Hindi'),
                          ),
                        ],
                        onChanged: (value) => setState(() => language = value!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'unread',
                            child: Text('Unread'),
                          ),
                          DropdownMenuItem(
                            value: 'currentlyReading',
                            child: Text('Reading'),
                          ),
                          DropdownMenuItem(value: 'read', child: Text('Read')),
                          DropdownMenuItem(
                            value: 'wantToRead',
                            child: Text('Want to Read'),
                          ),
                        ],
                        onChanged: (value) => setState(() => status = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${books.length} books'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (_, index) => BookListTile(
                book: books[index],
                progress:
                    localProgress[books[index].id] ??
                    BookProgress(bookId: books[index].id),
                onChanged: reloadProgress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookAuthorCard extends StatelessWidget {
  final Author author;
  final BookCollectionProgress value;
  final VoidCallback onTap;
  const BookAuthorCard({
    super.key,
    required this.author,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.navy, AppColors.navyRaised],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthorMonogram(name: author.name, dark: true),
            const Spacer(),
            Text(
              author.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value.completed == 0
                  ? 'No books read yet · Explore books →'
                  : authorProgressText(value),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value.completed == 0 ? AppColors.gold : Colors.white70,
                fontSize: 12,
                fontWeight: value.completed == 0
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthorMonogram extends StatelessWidget {
  final String name;
  final bool dark;
  const AuthorMonogram({super.key, required this.name, this.dark = false});
  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = [
      parts.first,
      if (parts.length > 1) parts.last,
    ].map((part) => part.characters.first.toUpperCase()).join();
    return CircleAvatar(
      backgroundColor: dark ? Colors.white12 : AppColors.warm,
      foregroundColor: dark ? AppColors.gold : AppColors.ink,
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

String authorProgressText(BookCollectionProgress value) {
  if (value.collection.isFinite) {
    return '${value.completed} / ${value.total} read';
  }
  return value.completed == 0
      ? 'No books read yet'
      : '${value.completed} books read';
}

class BookGenreCard extends StatelessWidget {
  final BookGenre genre;
  final BookCollectionProgress value;
  final VoidCallback onTap;
  const BookGenreCard({
    super.key,
    required this.genre,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.information,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_stories_outlined, color: AppColors.blue),
            const Spacer(),
            Text(
              genre.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('${value.completed} books read'),
          ],
        ),
      ),
    ),
  );
}

class BookCollectionCard extends StatelessWidget {
  final TrackableBookCollection collection;
  final BookCollectionProgress value;
  final VoidCallback onTap;
  const BookCollectionCard({
    super.key,
    required this.collection,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              collection.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              collection.isFinite
                  ? '${value.completed} / ${value.total} read'
                  : '${value.completed} books read',
            ),
            if (value.percentage case final percentage?) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: percentage),
              const SizedBox(height: 4),
              Text('${(percentage * 100).round()}%'),
            ],
            const SizedBox(height: 8),
            const Text(
              'Continue →',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class BookListTile extends StatelessWidget {
  final Book book;
  final BookProgress progress;
  final VoidCallback? onChanged;
  const BookListTile({
    super.key,
    required this.book,
    required this.progress,
    this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    child: ListTile(
      leading: Container(
        width: 44,
        height: 58,
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.menu_book_outlined),
      ),
      title: Text(
        book.canonicalTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        book.primaryAuthorDisplay,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        progress.status == BookStatus.currentlyReading
            ? 'Reading'
            : progress.isRead
            ? 'Read'
            : progress.status == BookStatus.wantToRead
            ? 'Saved'
            : '',
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
        );
        onChanged?.call();
      },
    ),
  );
}
