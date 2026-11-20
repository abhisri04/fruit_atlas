import '../models/book.dart';
import '../models/app_branding.dart';

class BookCollectionService {
  const BookCollectionService();

  List<TrackableBookCollection> build(BookCatalogue catalogue) {
    final collections = <TrackableBookCollection>[];
    for (final author in catalogue.authors) {
      final ids = (catalogue.booksByAuthor[author.id] ?? const <Book>[])
          .map((b) => b.id)
          .toSet();
      if (ids.isEmpty) continue;
      collections.add(
        TrackableBookCollection(
          id: 'author:${author.id}',
          title: author.name,
          description: author.description ?? 'Books by ${author.name}.',
          type: BookCollectionType.author,
          bookIds: ids,
          authorId: author.id,
          isFinite: author.bibliographyStatus == BibliographyStatus.complete,
          isComplete: author.bibliographyStatus == BibliographyStatus.complete,
        ),
      );
    }
    for (final genre in catalogue.genreEntities) {
      final ids = (catalogue.booksByGenre[genre.name] ?? const <Book>[])
          .map((b) => b.id)
          .toSet();
      if (ids.isEmpty) continue;
      collections.add(
        TrackableBookCollection(
          id: 'genre:${genre.id}',
          title: genre.name,
          description: genre.description ?? 'Your reading in ${genre.name}.',
          type: BookCollectionType.genre,
          bookIds: ids,
          genreId: genre.id,
          isFinite: false,
        ),
      );
    }
    for (final language in BookLanguage.values) {
      final ids = (catalogue.booksByLanguage[language] ?? const <Book>[])
          .map((b) => b.id)
          .toSet();
      collections.add(
        TrackableBookCollection(
          id: 'language:${language.name}',
          title: '${language.label} Books',
          description: 'Books available in ${language.label}.',
          type: BookCollectionType.language,
          bookIds: ids,
          language: language,
          isFinite: false,
        ),
      );
    }
    for (final series in catalogue.series) {
      final books =
          List<Book>.from(catalogue.booksBySeries[series.id] ?? const <Book>[])
            ..sort(
              (a, b) =>
                  (a.seriesPosition ?? 0).compareTo(b.seriesPosition ?? 0),
            );
      collections.add(
        TrackableBookCollection(
          id: 'series:${series.id}',
          title: series.name,
          description: 'Books in the ${series.name} series.',
          type: BookCollectionType.series,
          bookIds: books.map((b) => b.id).toSet(),
          seriesId: series.id,
          isFinite: series.isComplete,
          isComplete: series.isComplete,
        ),
      );
    }
    for (final item in catalogue.collections) {
      final ids = resolveBookIds(item, catalogue.books);
      collections.add(
        TrackableBookCollection(
          id: 'curated:${item.id}',
          title: item.title,
          description: item.description,
          type: item.language != null
              ? BookCollectionType.language
              : BookCollectionType.curated,
          bookIds: ids,
          language: item.language,
          genreId: item.genre,
          isFinite: item.bookIds.isNotEmpty,
          isCurated: true,
          isComplete: item.bookIds.isNotEmpty,
        ),
      );
    }
    return collections;
  }

  Set<String> resolveBookIds(BookCollection collection, List<Book> books) {
    if (collection.bookIds.isNotEmpty) return collection.bookIds.toSet();
    return books
        .where(
          (book) =>
              (collection.language == null ||
                  book.availableLanguages.contains(collection.language)) &&
              (collection.genre == null ||
                  book.primaryGenre == collection.genre ||
                  book.secondaryGenres.contains(collection.genre)),
        )
        .map((book) => book.id)
        .toSet();
  }

  BookCollectionProgress progress(
    TrackableBookCollection collection,
    Map<String, BookProgress> progress,
  ) => BookCollectionProgress(
    collection: collection,
    completedBookIds: collection.bookIds
        .where((id) => progress[id]?.isRead ?? false)
        .toSet(),
  );

  BookSharePayload share(BookCollectionProgress value) {
    final c = value.collection;
    final percent = value.percentage == null
        ? null
        : (value.percentage! * 100).round();
    final complete = value.canClaimAll;
    final subtitle = switch (c.type) {
      BookCollectionType.author when complete =>
        "I've read every book in the ${c.title} bibliography.",
      BookCollectionType.author when c.isFinite =>
        "I've read ${value.completed} of ${value.total} books by ${c.title}.",
      BookCollectionType.author =>
        value.completed == 1
            ? "I've read 1 book by ${c.title}."
            : "I've read ${value.completed} books by ${c.title}.",
      BookCollectionType.series when complete =>
        "I've finished all ${value.total} ${c.title} books.",
      BookCollectionType.series when percent != null =>
        "I've read ${value.completed} of ${value.total} books in ${c.title}.",
      BookCollectionType.curated when complete => 'I completed ${c.title}.',
      BookCollectionType.curated when percent != null =>
        "I've completed $percent% of the ${c.title} collection — ${value.completed} of ${value.total} books read.",
      BookCollectionType.genre =>
        value.completed == 1
            ? "I've read 1 book in ${c.title}."
            : "I've read ${value.completed} ${c.title} books.",
      _ => "I've read ${value.completed} books in ${c.title}.",
    };
    return BookSharePayload(
      title: c.title,
      subtitle: subtitle,
      progressCurrent: value.completed,
      progressTotal: c.isFinite ? value.total : null,
      percentage: percent,
      badge: complete ? '${c.type.name.toUpperCase()} COMPLETED' : null,
      completionState: complete
          ? 'completed'
          : value.completed == 0
          ? 'not_started'
          : 'in_progress',
      shareText: '$subtitle — ${AppBranding.shareSignature}',
      collectionType: c.type.name,
    );
  }

  ReadingProfile readingProfile(
    BookCatalogue catalogue,
    Map<String, BookProgress> progress,
  ) {
    final read = catalogue.books
        .where((book) => progress[book.id]?.isRead ?? false)
        .toList();
    final languages = <BookLanguage, int>{},
        genres = <String, int>{},
        authors = <String, int>{};
    for (final book in read) {
      for (final language in progress[book.id]!.readLanguages) {
        languages[language] = (languages[language] ?? 0) + 1;
      }
      for (final genre in {book.primaryGenre, ...book.secondaryGenres}) {
        genres[genre] = (genres[genre] ?? 0) + 1;
      }
      for (final author in book.authorIds) {
        authors[author] = (authors[author] ?? 0) + 1;
      }
    }
    return ReadingProfile(
      uniqueBooksRead: read.length,
      languageCounts: languages,
      genreCounts: genres,
      authorCounts: authors,
    );
  }
}
