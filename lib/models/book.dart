import 'app_branding.dart';

enum BookLanguage { english, hindi }

extension BookLanguageValue on BookLanguage {
  String get key => name;
  String get label => this == BookLanguage.english ? 'English' : 'Hindi';
  static BookLanguage parse(String value) =>
      BookLanguage.values.firstWhere((item) => item.name == value);
}

enum BibliographyStatus { complete, partial, unknown }

class Author {
  final String id;
  final String name;
  final String? nativeName,
      description,
      primaryLanguage,
      countryOrTradition,
      bibliographyScope,
      verificationNotes,
      lastVerified;
  final int? verifiedBookCount;
  final List<String> alternateNames, bookIds, sourceUrls;
  final BibliographyStatus bibliographyStatus;
  const Author({
    required this.id,
    required this.name,
    this.nativeName,
    this.description,
    this.primaryLanguage,
    this.countryOrTradition,
    this.bibliographyScope,
    this.verifiedBookCount,
    this.verificationNotes,
    this.lastVerified,
    this.alternateNames = const [],
    this.bookIds = const [],
    this.sourceUrls = const [],
    this.bibliographyStatus = BibliographyStatus.unknown,
  });
  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: json['id'] as String,
    name: json['name'] as String,
    nativeName: json['native_name'] as String?,
    description: json['description'] as String?,
    primaryLanguage: json['primary_language'] as String?,
    countryOrTradition: json['country_or_tradition'] as String?,
    bibliographyScope: json['bibliography_scope'] as String?,
    verifiedBookCount: json['verified_book_count'] as int?,
    verificationNotes: json['verification_notes'] as String?,
    lastVerified: json['last_verified'] as String?,
    alternateNames: List<String>.from(
      json['alternate_names'] as List? ?? const [],
    ),
    bookIds: List<String>.from(json['book_ids'] as List? ?? const []),
    sourceUrls: List<String>.from(json['source_urls'] as List? ?? const []),
    bibliographyStatus: BibliographyStatus.values.firstWhere(
      (v) => v.name == (json['bibliography_status'] as String? ?? 'unknown'),
    ),
  );
}

class BookGenre {
  final String id, name;
  final String? description, parentGenreId;
  const BookGenre({
    required this.id,
    required this.name,
    this.description,
    this.parentGenreId,
  });
  factory BookGenre.fromJson(Map<String, dynamic> json) => BookGenre(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    parentGenreId: json['parent_genre_id'] as String?,
  );
}

enum FeaturedAuthorGroup { international, indianEnglish, hindi, indianOther }

class FeaturedAuthorConfig {
  final String authorId;
  final int rank;
  final FeaturedAuthorGroup group;
  const FeaturedAuthorConfig({
    required this.authorId,
    required this.rank,
    required this.group,
  });
  factory FeaturedAuthorConfig.fromJson(Map<String, dynamic> json) =>
      FeaturedAuthorConfig(
        authorId: json['author_id'] as String,
        rank: json['rank'] as int,
        group: switch (json['group'] as String) {
          'international' => FeaturedAuthorGroup.international,
          'indian_english' => FeaturedAuthorGroup.indianEnglish,
          'hindi' => FeaturedAuthorGroup.hindi,
          _ => FeaturedAuthorGroup.indianOther,
        },
      );
}

class BookSeries {
  final String id, name;
  final String? legacyId, verificationNotes;
  final List<String> bookIds;
  final bool isComplete;
  const BookSeries({
    required this.id,
    required this.name,
    required this.bookIds,
    required this.isComplete,
    this.legacyId,
    this.verificationNotes,
  });
  factory BookSeries.fromJson(Map<String, dynamic> json) => BookSeries(
    id: json['id'] as String,
    name: json['name'] as String,
    legacyId: json['legacy_id'] as String?,
    bookIds: List<String>.from(json['book_ids'] as List? ?? const []),
    isComplete: json['is_complete'] as bool? ?? false,
    verificationNotes: json['verification_notes'] as String?,
  );
}

enum BookCollectionType { author, genre, series, language, curated }

class TrackableBookCollection {
  final String id, title, description;
  final BookCollectionType type;
  final Set<String> bookIds;
  final String? authorId, genreId, seriesId;
  final BookLanguage? language;
  final bool isFinite, isCurated, isComplete, shareEnabled;
  const TrackableBookCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.bookIds,
    this.authorId,
    this.genreId,
    this.language,
    this.seriesId,
    required this.isFinite,
    this.isCurated = false,
    this.isComplete = false,
    this.shareEnabled = true,
  });
}

class BookCollectionProgress {
  final TrackableBookCollection collection;
  final Set<String> completedBookIds;
  const BookCollectionProgress({
    required this.collection,
    required this.completedBookIds,
  });
  int get completed => completedBookIds.length;
  int get total => collection.bookIds.length;
  double? get percentage =>
      collection.isFinite && total > 0 ? completed / total : null;
  bool get isCompleted =>
      collection.isFinite && total > 0 && completed == total;
  bool get canClaimAll => collection.isComplete && isCompleted;
  Set<int> reachedMilestones() {
    if (collection.isFinite) {
      final value = ((percentage ?? 0) * 100).floor();
      return {
        for (final m in const [10, 25, 50, 75, 100])
          if (value >= m) m,
      };
    }
    return {
      for (final m in const [5, 10, 25, 50, 100])
        if (completed >= m) m,
    };
  }
}

class BookSharePayload {
  final String title,
      subtitle,
      collectionType,
      categoryColor,
      appBranding,
      completionState,
      shareText;
  final int progressCurrent;
  final int? progressTotal, percentage;
  final String? badge;
  const BookSharePayload({
    required this.title,
    required this.subtitle,
    required this.progressCurrent,
    this.progressTotal,
    this.percentage,
    this.badge,
    this.completionState = 'in_progress',
    required this.shareText,
    required this.collectionType,
    this.categoryColor = 'culture_learning',
    this.appBranding = AppBranding.appName,
  });
}

class ReadingProfile {
  final int uniqueBooksRead;
  final Map<BookLanguage, int> languageCounts;
  final Map<String, int> genreCounts;
  final Map<String, int> authorCounts;
  const ReadingProfile({
    required this.uniqueBooksRead,
    required this.languageCounts,
    required this.genreCounts,
    required this.authorCounts,
  });
}

class BookEdition {
  final String id;
  final String bookId;
  final BookLanguage language;
  final String title;
  final String? translator, publisher, isbn13, coverAsset;
  final int? publicationYear;
  const BookEdition({
    required this.id,
    required this.bookId,
    required this.language,
    required this.title,
    this.translator,
    this.publisher,
    this.publicationYear,
    this.isbn13,
    this.coverAsset,
  });
  factory BookEdition.fromJson(Map<String, dynamic> json) => BookEdition(
    id: json['id'] as String,
    bookId: json['book_id'] as String,
    language: BookLanguageValue.parse(json['language'] as String),
    title: json['title'] as String,
    translator: json['translator'] as String?,
    publisher: json['publisher'] as String?,
    publicationYear: json['publication_year'] as int?,
    isbn13: json['isbn13'] as String?,
    coverAsset: json['cover_asset'] as String?,
  );
}

class Book {
  final String id,
      canonicalTitle,
      primaryAuthorDisplay,
      primaryGenre,
      classification,
      description,
      contentStatus;
  final String? originalTitle,
      transliteratedTitle,
      originalLanguage,
      coverAsset,
      seriesId,
      primaryGenreId,
      countryOrLiteraryTradition,
      verificationNotes,
      sourceWorkId;
  final List<String> authorIds,
      alternateTitles,
      secondaryGenres,
      tags,
      sourceUrls;
  final bool? isIndianAuthorOrWork;
  final bool metadataVerified;
  final List<BookLanguage> availableLanguages;
  final List<BookEdition> editions;
  final int? publicationYear, pageCount;
  final double? seriesPosition;
  const Book({
    required this.id,
    required this.canonicalTitle,
    this.originalTitle,
    this.alternateTitles = const [],
    this.transliteratedTitle,
    required this.authorIds,
    required this.primaryAuthorDisplay,
    this.originalLanguage,
    required this.availableLanguages,
    this.publicationYear,
    required this.primaryGenre,
    this.primaryGenreId,
    this.secondaryGenres = const [],
    required this.classification,
    required this.description,
    this.coverAsset,
    this.tags = const [],
    this.seriesId,
    this.seriesPosition,
    this.pageCount,
    this.editions = const [],
    this.contentStatus = 'seed',
    this.countryOrLiteraryTradition,
    this.isIndianAuthorOrWork,
    this.sourceUrls = const [],
    this.metadataVerified = false,
    this.verificationNotes,
    this.sourceWorkId,
  });
  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'] as String,
    canonicalTitle: json['canonical_title'] as String,
    originalTitle: json['original_title'] as String?,
    alternateTitles: List<String>.from(
      json['alternate_titles'] as List? ?? const [],
    ),
    transliteratedTitle: json['transliterated_title'] as String?,
    authorIds: List<String>.from(json['author_ids'] as List? ?? const []),
    primaryAuthorDisplay: json['primary_author_display'] as String,
    originalLanguage: json['original_language'] as String?,
    availableLanguages: (json['available_languages'] as List)
        .map((v) => BookLanguageValue.parse(v as String))
        .toList(),
    publicationYear: json['publication_year'] as int?,
    primaryGenre: json['primary_genre'] as String,
    primaryGenreId: json['primary_genre_id'] as String?,
    secondaryGenres: List<String>.from(
      json['secondary_genres'] as List? ?? const [],
    ),
    classification: json['classification'] as String,
    description: json['description'] as String,
    coverAsset: json['cover_asset'] as String?,
    tags: List<String>.from(json['tags'] as List? ?? const []),
    seriesId: json['series_id'] as String?,
    seriesPosition: (json['series_position'] as num?)?.toDouble(),
    pageCount: json['page_count'] as int?,
    editions: (json['editions'] as List? ?? const [])
        .map((v) => BookEdition.fromJson(v as Map<String, dynamic>))
        .toList(),
    contentStatus: json['content_status'] as String? ?? 'seed',
    countryOrLiteraryTradition:
        json['country_or_literary_tradition'] as String?,
    isIndianAuthorOrWork: json['is_indian_author_or_work'] as bool?,
    sourceUrls: List<String>.from(json['source_urls'] as List? ?? const []),
    metadataVerified: json['metadata_verified'] as bool? ?? false,
    verificationNotes: json['verification_notes'] as String?,
    sourceWorkId: json['source_work_id'] as String?,
  );
  Iterable<String> get searchableTitles => {
    canonicalTitle,
    ?originalTitle,
    ...alternateTitles,
    ?transliteratedTitle,
    ...editions.map((e) => e.title),
  };
}

class BookCollection {
  final String id, title, description;
  final List<String> bookIds;
  final BookLanguage? language;
  final String? genre;
  const BookCollection({
    required this.id,
    required this.title,
    required this.description,
    this.bookIds = const [],
    this.language,
    this.genre,
  });
  factory BookCollection.fromJson(Map<String, dynamic> json) => BookCollection(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    bookIds: List<String>.from(json['book_ids'] as List? ?? const []),
    language: json['language'] == null
        ? null
        : BookLanguageValue.parse(json['language'] as String),
    genre: json['genre'] as String?,
  );
}

class BookCatalogue {
  final List<Author> authors;
  final List<Book> books;
  final List<BookCollection> collections;
  final List<String> genres;
  final List<BookGenre> genreEntities;
  final List<BookSeries> series;
  final Map<String, Book> bookById;
  final Map<String, Author> authorById;
  final Map<String, List<Book>> booksByAuthor;
  final Map<String, List<Book>> booksByGenre;
  final Map<BookLanguage, List<Book>> booksByLanguage;
  final Map<String, List<Book>> booksBySeries;
  BookCatalogue({
    required this.authors,
    required this.books,
    required this.collections,
    required this.genres,
    required this.genreEntities,
    required this.series,
  }) : bookById = {for (final book in books) book.id: book},
       authorById = {for (final author in authors) author.id: author},
       booksByAuthor = _groupByStrings(books, (book) => book.authorIds),
       booksByGenre = _groupByStrings(
         books,
         (book) => {book.primaryGenre, ...book.secondaryGenres},
       ),
       booksByLanguage = _groupByLanguage(books),
       booksBySeries = _groupByStrings(
         books,
         (book) => [if (book.seriesId != null) book.seriesId!],
       );
  factory BookCatalogue.fromJson(Map<String, dynamic> json) {
    // Parse books once so every index points to the same canonical objects.
    final parsedBooks = (json['books'] as List)
        .map((v) => Book.fromJson(v as Map<String, dynamic>))
        .toList();
    final genreNames = List<String>.from(json['genres'] as List);
    return BookCatalogue(
      authors: (json['authors'] as List)
          .map((v) => Author.fromJson(v as Map<String, dynamic>))
          .toList(),
      books: parsedBooks,
      collections: (json['collections'] as List)
          .map((v) => BookCollection.fromJson(v as Map<String, dynamic>))
          .toList(),
      genres: genreNames,
      genreEntities: (json['genre_entities'] as List? ?? const [])
          .map((v) => BookGenre.fromJson(v as Map<String, dynamic>))
          .toList(),
      series: (json['series'] as List? ?? const [])
          .map((v) => BookSeries.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, List<Book>> _groupByStrings(
    List<Book> books,
    Iterable<String> Function(Book) keys,
  ) {
    final result = <String, List<Book>>{};
    for (final book in books) {
      for (final key in keys(book)) {
        (result[key] ??= []).add(book);
      }
    }
    return result;
  }

  static Map<BookLanguage, List<Book>> _groupByLanguage(List<Book> books) {
    final result = <BookLanguage, List<Book>>{};
    for (final book in books) {
      for (final language in book.availableLanguages) {
        (result[language] ??= []).add(book);
      }
    }
    return result;
  }
}

enum BookStatus { unread, wantToRead, currentlyReading, read }

class BookProgress {
  final String bookId;
  final BookStatus status;
  final Set<BookLanguage> readLanguages;
  final BookLanguage? currentLanguage;
  final DateTime? firstReadAt, lastUpdatedAt;
  const BookProgress({
    required this.bookId,
    this.status = BookStatus.unread,
    this.readLanguages = const {},
    this.currentLanguage,
    this.firstReadAt,
    this.lastUpdatedAt,
  });
  bool get isRead => status == BookStatus.read;
  Map<String, dynamic> toJson() => {
    'book_id': bookId,
    'status': status.name,
    'read_languages': readLanguages.map((v) => v.name).toList(),
    'current_language': currentLanguage?.name,
    'first_read_at': firstReadAt?.toIso8601String(),
    'last_updated_at': lastUpdatedAt?.toIso8601String(),
  };
  factory BookProgress.fromJson(Map<String, dynamic> json) => BookProgress(
    bookId: json['book_id'] as String,
    status: BookStatus.values.firstWhere((v) => v.name == json['status']),
    readLanguages: (json['read_languages'] as List? ?? const [])
        .map((v) => BookLanguageValue.parse(v as String))
        .toSet(),
    currentLanguage: json['current_language'] == null
        ? null
        : BookLanguageValue.parse(json['current_language'] as String),
    firstReadAt: DateTime.tryParse(json['first_read_at'] as String? ?? ''),
    lastUpdatedAt: DateTime.tryParse(json['last_updated_at'] as String? ?? ''),
  );
}
