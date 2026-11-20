import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/book.dart';

class BooksRepository {
  static const assetPath = 'assets/data/books.json';
  static const indexAssetPath = 'assets/data/book_index.json';
  static const featuredAuthorsAssetPath =
      'assets/data/featured_book_authors.json';
  static Future<BookCatalogue>? _cachedCatalogue;
  static Future<Set<String>>? _cachedIds;
  static Future<List<FeaturedAuthorConfig>>? _cachedFeaturedAuthors;
  const BooksRepository();
  Future<BookCatalogue> load() => _cachedCatalogue ??= _loadAsset();

  static Future<BookCatalogue> _loadAsset() async => BookCatalogue.fromJson(
    jsonDecode(await rootBundle.loadString(assetPath)) as Map<String, dynamic>,
  );

  Future<Set<String>> loadCanonicalIds() => _cachedIds ??= _loadIds();

  static Future<Set<String>> _loadIds() async {
    final data = jsonDecode(
      await rootBundle.loadString(indexAssetPath),
    ) as Map<String, dynamic>;
    return Set<String>.from(data['book_ids'] as List);
  }

  Future<List<FeaturedAuthorConfig>> loadFeaturedAuthors() =>
      _cachedFeaturedAuthors ??= _loadFeaturedAuthors();

  static Future<List<FeaturedAuthorConfig>> _loadFeaturedAuthors() async {
    final data = jsonDecode(
      await rootBundle.loadString(featuredAuthorsAssetPath),
    ) as Map<String, dynamic>;
    final values =
        (data['authors'] as List)
            .map(
              (value) =>
                  FeaturedAuthorConfig.fromJson(value as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));
    return List.unmodifiable(values);
  }

  static List<Book> filter(
    List<Book> books, {
    String query = '',
    BookLanguage? language,
    String? genre,
    BookStatus? status,
    Map<String, BookProgress> progress = const {},
  }) {
    final normalized = query.trim().toLowerCase();
    return books.where((book) {
      final state = progress[book.id] ?? BookProgress(bookId: book.id);
      final searchable = [
        ...book.searchableTitles,
        book.primaryAuthorDisplay,
        book.primaryGenre,
        ...book.secondaryGenres,
        ...book.tags,
      ];
      return (normalized.isEmpty ||
              searchable.any((v) => v.toLowerCase().contains(normalized))) &&
          (language == null || book.availableLanguages.contains(language)) &&
          (genre == null || book.primaryGenre == genre) &&
          (status == null || state.status == status);
    }).toList();
  }
}
