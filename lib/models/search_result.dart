enum SearchEntityType {
  category,
  challenge,
  item,
  subItem,
  district,
  experience,
}

/// Stable index identity and destination data, independent of search widgets.
class SearchResult {
  final String id, title, subtitle, categoryId;
  final String? challengeId, parentId;
  final SearchEntityType entityType;
  final List<String> keywords;
  final List<String> contextTerms;
  final List<String> relationTerms;
  final List<String> parentTerms;
  final String secondaryText;
  final Object destination;
  final Object? parent;
  const SearchResult({
    required this.id,
    required this.entityType,
    required this.title,
    required this.subtitle,
    required this.categoryId,
    this.challengeId,
    this.parentId,
    this.keywords = const [],
    this.contextTerms = const [],
    this.relationTerms = const [],
    this.parentTerms = const [],
    this.secondaryText = '',
    required this.destination,
    this.parent,
  });
}
