import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/book_collection_service.dart';
import '../../services/books_repository.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import 'book_browse_pages.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});
  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  BookCatalogue? catalogue;
  Map<String, BookProgress> progress = {};
  List<FeaturedAuthorConfig> featured = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final values = await Future.wait([
      const BooksRepository().load(),
      ProgressService.getBookProgress(),
      const BooksRepository().loadFeaturedAuthors(),
    ]);
    if (!mounted) return;
    setState(() {
      catalogue = values[0] as BookCatalogue;
      progress = values[1] as Map<String, BookProgress>;
      featured = values[2] as List<FeaturedAuthorConfig>;
    });
  }

  Future<void> open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final data = catalogue;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Books')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final service = const BookCollectionService();
    final allCollections = service.build(data);
    final authors = allCollections
        .where((item) => item.type == BookCollectionType.author)
        .toList();
    final genres = allCollections
        .where((item) => item.type == BookCollectionType.genre)
        .toList();
    final collections =
        allCollections
            .where(
              (item) =>
                  item.isCurated || item.type == BookCollectionType.series,
            )
            .toList()
          ..sort((a, b) {
            if (a.isFinite != b.isFinite) return a.isFinite ? -1 : 1;
            return a.title.compareTo(b.title);
          });
    final authorById = {
      for (final item in authors)
        if (item.authorId != null) item.authorId!: item,
    };
    final genreById = {
      for (final item in genres)
        if (item.genreId != null) item.genreId!: item,
    };
    final read = progress.values.where((item) => item.isRead).length;
    final readingBooks = data.books
        .where(
          (book) => progress[book.id]?.status == BookStatus.currentlyReading,
        )
        .toList();
    int readIn(BookLanguage language) => progress.values
        .where((item) => item.isRead && item.readLanguages.contains(language))
        .length;
    final featuredAuthors = featured
        .map((item) => data.authorById[item.authorId])
        .whereType<Author>()
        .toList();
    const featuredGenreIds = [
      'GEN_CLASSICS',
      'GEN_MYSTERY_THRILLER',
      'GEN_FANTASY',
      'GEN_SCIENCE_FICTION',
    ];
    final featuredGenres = data.genreEntities
        .where((item) => featuredGenreIds.contains(item.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Books')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _ReadingHero(
              read: read,
              reading: readingBooks.length,
              english: readIn(BookLanguage.english),
              hindi: readIn(BookLanguage.hindi),
            ),
            if (readingBooks.isNotEmpty) ...[
              const SizedBox(height: 26),
              const _SectionTitle(title: 'Continue Reading'),
              const SizedBox(height: 10),
              SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: readingBooks.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, index) => SizedBox(
                    width: 260,
                    child: BookListTile(
                      book: readingBooks[index],
                      progress: progress[readingBooks[index].id]!,
                      onChanged: load,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 26),
            _SectionTitle(
              title: 'Featured Authors',
              onSeeAll: () => open(
                BookAuthorsPage(
                  catalogue: data,
                  progress: progress,
                  collections: authors,
                  featured: featured,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.separated(
                key: const ValueKey('featured-authors'),
                scrollDirection: Axis.horizontal,
                itemCount: featuredAuthors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final author = featuredAuthors[index];
                  final collection = authorById[author.id]!;
                  return SizedBox(
                    width: 218,
                    child: BookAuthorCard(
                      author: author,
                      value: service.progress(collection, progress),
                      onTap: () => openBookCollection(
                        context,
                        data,
                        collection,
                      ).then((_) => load()),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 26),
            _SectionTitle(
              title: 'Explore Genres',
              onSeeAll: () => open(
                BookGenresPage(
                  catalogue: data,
                  progress: progress,
                  collections: genres,
                ),
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 140,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: featuredGenres.length,
              itemBuilder: (_, index) {
                final genre = featuredGenres[index];
                final collection = genreById[genre.id]!;
                return BookGenreCard(
                  genre: genre,
                  value: service.progress(collection, progress),
                  onTap: () => openBookCollection(
                    context,
                    data,
                    collection,
                  ).then((_) => load()),
                );
              },
            ),
            const SizedBox(height: 26),
            _SectionTitle(
              title: 'Collections',
              onSeeAll: () => open(
                BookCollectionsPage(
                  catalogue: data,
                  progress: progress,
                  collections: collections,
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final collection in collections.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookCollectionCard(
                  collection: collection,
                  value: service.progress(collection, progress),
                  onTap: () => openBookCollection(
                    context,
                    data,
                    collection,
                  ).then((_) => load()),
                ),
              ),
            const SizedBox(height: 18),
            Card(
              color: AppColors.warm,
              child: ListTile(
                key: const ValueKey('browse-all-books'),
                leading: const Icon(Icons.library_books_outlined),
                title: const Text(
                  'All Books',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Search and filter all ${data.books.length} books',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    open(AllBooksPage(catalogue: data, progress: progress)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingHero extends StatelessWidget {
  final int read, reading, english, hindi;
  const _ReadingHero({
    required this.read,
    required this.reading,
    required this.english,
    required this.hindi,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.navyRaised],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_stories, color: AppColors.gold, size: 34),
        const SizedBox(height: 16),
        Text(
          '$read books read',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        Text(
          '$reading currently reading',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _LanguageStat(label: 'English', count: english),
            _LanguageStat(label: 'Hindi', count: hindi),
          ],
        ),
      ],
    ),
  );
}

class _LanguageStat extends StatelessWidget {
  final String label;
  final int count;
  const _LanguageStat({required this.label, required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label  $count read',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionTitle({required this.title, this.onSeeAll});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: .7),
        ),
      ),
      if (onSeeAll != null)
        TextButton(onPressed: onSeeAll, child: const Text('See all →')),
    ],
  );
}
