import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fruit_atlas/models/book.dart';
import 'package:fruit_atlas/services/books_repository.dart';
import 'package:fruit_atlas/services/book_collection_service.dart';
import 'package:fruit_atlas/services/book_discovery_service.dart';
import 'package:fruit_atlas/services/book_share_service.dart';
import 'package:fruit_atlas/services/global_search_service.dart';
import 'package:fruit_atlas/services/progress_service.dart';
import 'package:fruit_atlas/services/progress_summary_service.dart';
import 'package:fruit_atlas/widgets/book_share_button.dart';
import 'package:fruit_atlas/screens/books/book_browse_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('1,000-book catalogue has canonical relationship integrity', () async {
    final catalogue = await const BooksRepository().load();
    expect(catalogue.books.length, 1000);
    expect(catalogue.books.map((b) => b.id).toSet().length, 1000);
    expect(catalogue.authors.map((a) => a.id).toSet().length, 873);
    expect(
      catalogue.books
          .where((b) => b.availableLanguages.contains(BookLanguage.english))
          .length,
      953,
    );
    expect(
      catalogue.books
          .where((b) => b.availableLanguages.contains(BookLanguage.hindi))
          .length,
      162,
    );
    expect(
      catalogue.books.where((b) => b.availableLanguages.length == 2).length,
      115,
    );
    expect(
      catalogue.books,
      contains(
        predicate<Book>(
          (b) =>
              b.availableLanguages.length == 1 &&
              b.availableLanguages.single == BookLanguage.english,
        ),
      ),
    );
    expect(
      catalogue.books,
      contains(
        predicate<Book>(
          (b) =>
              b.availableLanguages.length == 1 &&
              b.availableLanguages.single == BookLanguage.hindi,
        ),
      ),
    );
    for (final book in catalogue.books) {
      expect(book.id, matches(RegExp(r'^BK\d{6}$')));
      expect(catalogue.genres, contains(book.primaryGenre));
      expect(
        catalogue.genreEntities.map((genre) => genre.id),
        contains(book.primaryGenreId),
      );
      expect(book.authorIds, isNotEmpty);
      expect(book.authorIds.every(catalogue.authorById.containsKey), isTrue);
      if (book.seriesId != null) {
        expect(
          catalogue.series.map((series) => series.id),
          contains(book.seriesId),
        );
        expect(book.seriesPosition, greaterThan(0));
      }
      expect(book.coverAsset, isNull);
      expect(
        book.editions.every((edition) => edition.bookId == book.id),
        isTrue,
      );
    }
    expect(catalogue.bookById.length, 1000);
    expect(catalogue.booksByLanguage[BookLanguage.english]!.length, 953);
    expect(catalogue.booksByLanguage[BookLanguage.hindi]!.length, 162);
    expect(catalogue.series, hasLength(4));
    expect(catalogue.collections, hasLength(17));
    for (final collection in catalogue.collections) {
      expect(collection.bookIds.toSet().length, collection.bookIds.length);
      expect(collection.bookIds.every(catalogue.bookById.containsKey), isTrue);
    }
    for (final author in catalogue.authors) {
      expect(author.bookIds.every(catalogue.bookById.containsKey), isTrue);
      if (author.bibliographyStatus == BibliographyStatus.complete) {
        expect(author.verifiedBookCount, author.bookIds.length);
        expect(author.bibliographyScope, isNotEmpty);
        expect(author.sourceUrls, isNotEmpty);
      }
    }
    expect(
      BooksRepository.filter(
        catalogue.books,
        language: BookLanguage.english,
      ).length,
      953,
    );
    expect(
      BooksRepository.filter(
        catalogue.books,
        language: BookLanguage.hindi,
      ).length,
      162,
    );
  });

  test('catalogue identities and provenance remain deduplicated', () async {
    final catalogue = await const BooksRepository().load();
    String normalize(String value) => value.trim().toLowerCase();
    final identities = <String>{};
    for (final book in catalogue.books) {
      final identity =
          '${normalize(book.canonicalTitle)}|${normalize(book.primaryAuthorDisplay)}';
      expect(identities.add(identity), isTrue, reason: book.id);
      expect(book.availableLanguages, isNotEmpty);
      expect(
        book.availableLanguages.toSet().difference(BookLanguage.values.toSet()),
        isEmpty,
      );
      if (book.contentStatus.endsWith('needs_review')) {
        expect(book.metadataVerified, isFalse);
        expect(book.sourceUrls, isNotEmpty);
        expect(book.verificationNotes, isNotEmpty);
      }
    }
  });

  test(
    'one canonical read advances overlapping relationship views once',
    () async {
      SharedPreferences.setMockInitialValues({});
      final catalogue = await const BooksRepository().load();
      final book = catalogue.books.firstWhere((b) => b.id == 'BK000001');
      await ProgressService.setBookStatus(
        book: book,
        status: BookStatus.read,
        language: BookLanguage.hindi,
      );
      final progress = await ProgressService.getBookProgress();
      final collections = const BookCollectionService().build(catalogue);
      final related = collections.where((c) => c.bookIds.contains(book.id));
      expect(
        related.map((c) => c.type).toSet(),
        containsAll([
          BookCollectionType.author,
          BookCollectionType.genre,
          BookCollectionType.language,
          BookCollectionType.curated,
        ]),
      );
      expect(
        related.every(
          (c) =>
              const BookCollectionService().progress(c, progress).completed ==
              1,
        ),
        isTrue,
      );
      expect(
        (await const ProgressSummaryService().load()).completedReferences.where(
          (r) => r == 'book:${book.id}',
        ),
        hasLength(1),
      );
      expect(await ProgressService.getRewardedXp(), 10);
      final profile = const BookCollectionService().readingProfile(
        catalogue,
        progress,
      );
      expect(profile.uniqueBooksRead, 1);
      expect(profile.languageCounts[BookLanguage.hindi], 1);
    },
  );

  test(
    'finite and open collection semantics prevent false completion claims',
    () {
      const service = BookCollectionService();
      final progress = {
        'BK1': const BookProgress(bookId: 'BK1', status: BookStatus.read),
      };
      const completeAuthor = TrackableBookCollection(
        id: 'author:a',
        title: 'Verified Author',
        description: '',
        type: BookCollectionType.author,
        bookIds: {'BK1'},
        isFinite: true,
        isComplete: true,
      );
      const partialAuthor = TrackableBookCollection(
        id: 'author:b',
        title: 'Partial Author',
        description: '',
        type: BookCollectionType.author,
        bookIds: {'BK1'},
        isFinite: false,
        isComplete: false,
      );
      const genre = TrackableBookCollection(
        id: 'genre:classics',
        title: 'Classics',
        description: '',
        type: BookCollectionType.genre,
        bookIds: {'BK1'},
        isFinite: false,
      );
      expect(service.progress(completeAuthor, progress).canClaimAll, isTrue);
      expect(service.progress(partialAuthor, progress).canClaimAll, isFalse);
      expect(service.progress(genre, progress).percentage, isNull);
      expect(
        service.share(service.progress(genre, progress)).subtitle,
        "I've read 1 book in Classics.",
      );
    },
  );

  test('featured authors are canonical and globally balanced', () async {
    final repository = const BooksRepository();
    final catalogue = await repository.load();
    final featured = await repository.loadFeaturedAuthors();
    expect(featured, hasLength(12));
    expect(featured.map((item) => item.authorId).toSet(), hasLength(12));
    expect(
      featured.every((item) => catalogue.authorById.containsKey(item.authorId)),
      isTrue,
    );
    expect(
      featured
          .where((item) => item.group == FeaturedAuthorGroup.international)
          .length,
      6,
    );
    expect(
      featured
          .where((item) => item.group != FeaturedAuthorGroup.international)
          .length,
      6,
    );
  });

  test('author, genre and collection search use canonical indexes', () async {
    final catalogue = await const BooksRepository().load();
    final discovery = BookDiscoveryService(catalogue);
    expect(discovery.authors('Premchand').single.id, 'AU001');
    expect(discovery.authors('प्रेमचंद').single.id, 'AU001');
    expect(discovery.genres('science fiction').single.name, 'Science Fiction');
    final curated = const BookCollectionService()
        .build(catalogue)
        .where((item) => item.isCurated)
        .toList();
    expect(
      discovery.collections(curated, 'modern global').single.title,
      'Modern Global Literature',
    );
  });

  test('book share payloads preserve open and finite semantics', () {
    const service = BookCollectionService();
    const completeAuthor = TrackableBookCollection(
      id: 'author:complete',
      title: 'Complete Author',
      description: '',
      type: BookCollectionType.author,
      bookIds: {'BK1', 'BK2'},
      isFinite: true,
      isComplete: true,
    );
    const partialAuthor = TrackableBookCollection(
      id: 'author:partial',
      title: 'Premchand',
      description: '',
      type: BookCollectionType.author,
      bookIds: {'BK1', 'BK2'},
      isFinite: false,
      isComplete: false,
    );
    const genre = TrackableBookCollection(
      id: 'genre:classics',
      title: 'Classics',
      description: '',
      type: BookCollectionType.genre,
      bookIds: {'BK1', 'BK2'},
      isFinite: false,
    );
    const collection = TrackableBookCollection(
      id: 'curated:classics',
      title: 'Essential Classics',
      description: '',
      type: BookCollectionType.curated,
      bookIds: {'BK1', 'BK2'},
      isFinite: true,
      isComplete: true,
    );
    const series = TrackableBookCollection(
      id: 'series:test',
      title: 'Test Series',
      description: '',
      type: BookCollectionType.series,
      bookIds: {'BK1', 'BK2'},
      isFinite: true,
      isComplete: true,
    );
    const readOne = {
      'BK1': BookProgress(bookId: 'BK1', status: BookStatus.read),
    };
    const readAll = {
      'BK1': BookProgress(bookId: 'BK1', status: BookStatus.read),
      'BK2': BookProgress(bookId: 'BK2', status: BookStatus.read),
    };
    final completeProgress = service.share(
      service.progress(completeAuthor, readOne),
    );
    expect(completeProgress.percentage, 50);
    expect(completeProgress.shareText, contains('1 of 2 books'));
    expect(
      service.share(service.progress(completeAuthor, readAll)).shareText,
      contains('every book in the Complete Author bibliography'),
    );
    final partial = service.share(service.progress(partialAuthor, readAll));
    expect(partial.percentage, isNull);
    expect(partial.shareText, contains("I've read 2 books by Premchand"));
    expect(partial.shareText, isNot(contains('every book')));
    expect(
      service.share(service.progress(genre, readOne)).shareText,
      contains("I've read 1 book in Classics"),
    );
    expect(
      service.share(service.progress(collection, readOne)).shareText,
      contains('50% of the Essential Classics collection'),
    );
    expect(
      service.share(service.progress(collection, readAll)).shareText,
      contains('I completed Essential Classics'),
    );
    expect(
      service.share(service.progress(series, readOne)).shareText,
      contains('1 of 2 books in Test Series'),
    );
  });

  test('native text share is the reliable share fallback', () async {
    final gateway = _RecordingBookShareGateway();
    final service = BookShareService(gateway: gateway);
    const payload = BookSharePayload(
      title: 'Classics',
      subtitle: "I've read 2 Classics books.",
      progressCurrent: 2,
      collectionType: 'genre',
      shareText: "I've read 2 Classics books. — UPLYFA — Experience more.",
    );
    await service.share(payload);
    expect(gateway.text, payload.shareText);
  });

  testWidgets('author share button invokes the configured share service', (
    tester,
  ) async {
    final gateway = _RecordingBookShareGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookShareButton(
            payload: const BookSharePayload(
              title: 'Premchand',
              subtitle: "I've read 2 books by Premchand.",
              progressCurrent: 2,
              collectionType: 'author',
              shareText: "I've read 2 books by Premchand. — UPLYFA — Experience more.",
            ),
            shareService: BookShareService(gateway: gateway),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('book-share-progress')));
    await tester.pump();
    expect(gateway.text, contains('Premchand'));
  });

  testWidgets('share invocation failure shows a visible error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookShareButton(
            payload: const BookSharePayload(
              title: 'Classics',
              subtitle: 'Two Classics read',
              progressCurrent: 2,
              collectionType: 'genre',
              shareText: 'Two Classics read — UPLYFA — Experience more.',
            ),
            shareService: BookShareService(
              gateway: _ThrowingBookShareGateway(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('book-share-progress')));
    await tester.pump();
    expect(find.textContaining('Sharing is unavailable'), findsOneWidget);
  });

  testWidgets('dedicated Books browse searches fit a narrow screen', (
    tester,
  ) async {
    final repository = const BooksRepository();
    late BookCatalogue catalogue;
    late List<FeaturedAuthorConfig> featuredAuthors;
    await tester.runAsync(() async {
      catalogue = await repository.load();
      featuredAuthors = await repository.loadFeaturedAuthors();
    });
    final collections = const BookCollectionService().build(catalogue);
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: BookAuthorsPage(
          catalogue: catalogue,
          progress: const {},
          collections: collections
              .where((item) => item.type == BookCollectionType.author)
              .toList(),
          featured: featuredAuthors,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('author-search')),
      'प्रेमचंद',
    );
    await tester.pump();
    expect(find.textContaining('Premchand'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: BookGenresPage(
          catalogue: catalogue,
          progress: const {},
          collections: collections
              .where((item) => item.type == BookCollectionType.genre)
              .toList(),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('genre-search')),
      'Mystery',
    );
    await tester.pump();
    expect(find.text('Mystery & Thriller'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final curated = collections
        .where(
          (item) => item.isCurated || item.type == BookCollectionType.series,
        )
        .toList();
    await tester.pumpWidget(
      MaterialApp(
        home: BookCollectionsPage(
          catalogue: catalogue,
          progress: const {},
          collections: curated,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('collection-search')),
      'Hindi Classics',
    );
    await tester.pump();
    expect(find.text('Hindi Classics'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test(
    'finite curated and series progress and share payload are canonical',
    () {
      const service = BookCollectionService();
      const curated = TrackableBookCollection(
        id: 'curated:test',
        title: 'Essential Test Books',
        description: '',
        type: BookCollectionType.curated,
        bookIds: {'BK1', 'BK2'},
        isFinite: true,
        isCurated: true,
        isComplete: true,
      );
      const series = TrackableBookCollection(
        id: 'series:test',
        title: 'Test Series',
        description: '',
        type: BookCollectionType.series,
        bookIds: {'BK1', 'BK2'},
        isFinite: true,
        isComplete: true,
      );
      final half = service.progress(curated, {
        'BK1': const BookProgress(bookId: 'BK1', status: BookStatus.read),
      });
      expect(half.percentage, .5);
      expect(service.share(half).percentage, 50);
      final all = {
        'BK1': const BookProgress(bookId: 'BK1', status: BookStatus.read),
        'BK2': const BookProgress(bookId: 'BK2', status: BookStatus.read),
      };
      expect(service.progress(series, all).canClaimAll, isTrue);
      expect(
        service.share(service.progress(series, all)).badge,
        'SERIES COMPLETED',
      );
    },
  );

  test(
    'bilingual work completes once and stores both read languages',
    () async {
      SharedPreferences.setMockInitialValues({});
      final catalogue = await const BooksRepository().load();
      final godaan = catalogue.books.firstWhere((b) => b.id == 'BK000001');
      await ProgressService.setBookStatus(
        book: godaan,
        status: BookStatus.read,
        language: BookLanguage.hindi,
        now: DateTime(2026, 9, 28),
      );
      await ProgressService.addReadLanguage(
        godaan,
        BookLanguage.english,
        now: DateTime(2026, 9, 28),
      );
      final progress = (await ProgressService.getBookProgress())[godaan.id]!;
      expect(progress.readLanguages, {
        BookLanguage.hindi,
        BookLanguage.english,
      });
      final summary = await const ProgressSummaryService().load();
      expect(
        summary.completedReferences
            .where((r) => r == 'book:${godaan.id}')
            .length,
        1,
      );
      final culture = summary.challenges['explore_great_books']!;
      expect((culture.completed, culture.total), (1, 1000));
      expect(summary.experiencesExplored, 1);
      expect(await ProgressService.getRewardedXp(), 10);
      expect(
        (await ProgressService.getStreak(now: DateTime(2026, 9, 28))).current,
        1,
      );
      await ProgressService.setBookStatus(
        book: godaan,
        status: BookStatus.unread,
      );
      await ProgressService.setBookStatus(
        book: godaan,
        status: BookStatus.read,
        language: BookLanguage.hindi,
      );
      expect(await ProgressService.getRewardedXp(), 10);
    },
  );

  test(
    'want-to-read and currently-reading do not complete or create activity',
    () async {
      SharedPreferences.setMockInitialValues({});
      final book = (await const BooksRepository().load()).books.first;
      await ProgressService.setBookStatus(
        book: book,
        status: BookStatus.wantToRead,
      );
      expect(await ProgressService.isEntitySaved('book:${book.id}'), isTrue);
      await ProgressService.setBookStatus(
        book: book,
        status: BookStatus.currentlyReading,
        language: BookLanguage.hindi,
      );
      final summary = await const ProgressSummaryService().load();
      expect(summary.completedReferences, isNot(contains('book:${book.id}')));
      expect(await ProgressService.getRewardedXp(), 0);
      expect((await ProgressService.getStreak()).current, 0);
    },
  );

  test(
    'global search resolves author, translated title and Devanagari once',
    () async {
      final search = GlobalSearchService();
      await search.load();
      expect(
        search.search('Premchand').where((r) => r.title == 'Godaan').length,
        1,
      );
      expect(
        search.search('Godan').where((r) => r.title == 'Godaan').length,
        1,
      );
      expect(
        search.search('गोदान').where((r) => r.title == 'Godaan').length,
        1,
      );
    },
  );
}

class _RecordingBookShareGateway implements BookShareGateway {
  String? text;
  @override
  Future<void> shareText(String value) async => text = value;
}

class _ThrowingBookShareGateway implements BookShareGateway {
  @override
  Future<void> shareText(String value) => throw StateError('unavailable');
}
