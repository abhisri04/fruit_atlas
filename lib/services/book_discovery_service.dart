import '../models/book.dart';

class BookDiscoveryService {
  final BookCatalogue catalogue;
  late final Map<String, String> _authorSearch = {
    for (final author in catalogue.authors)
      author.id: _normalize(
        [
          author.name,
          author.nativeName,
          ...author.alternateNames,
        ].whereType<String>().join(' '),
      ),
  };
  late final Map<String, String> _genreSearch = {
    for (final genre in catalogue.genreEntities)
      genre.id: _normalize('${genre.name} ${genre.description ?? ''}'),
  };
  Map<String, String>? _collectionSearch;

  BookDiscoveryService(this.catalogue);

  void indexCollections(Iterable<TrackableBookCollection> collections) {
    _collectionSearch = {
      for (final collection in collections)
        collection.id: _normalize(
          '${collection.title} ${collection.description} '
          '${collection.type.name}',
        ),
    };
  }

  List<Author> authors(String query, {BookLanguage? language}) {
    final needle = _normalize(query);
    return catalogue.authors.where((author) {
        final matchesLanguage =
            language == null ||
            (catalogue.booksByAuthor[author.id] ?? const <Book>[]).any(
              (book) => book.availableLanguages.contains(language),
            );
        return matchesLanguage &&
            (needle.isEmpty || _authorSearch[author.id]!.contains(needle));
      }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<BookGenre> genres(String query) {
    final needle = _normalize(query);
    return catalogue.genreEntities
        .where(
          (genre) => needle.isEmpty || _genreSearch[genre.id]!.contains(needle),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<TrackableBookCollection> collections(
    Iterable<TrackableBookCollection> values,
    String query,
  ) {
    if (_collectionSearch == null) indexCollections(values);
    final needle = _normalize(query);
    return values
        .where(
          (collection) =>
              needle.isEmpty ||
              _collectionSearch![collection.id]!.contains(needle),
        )
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s\-_.،,]+'), '');
}
