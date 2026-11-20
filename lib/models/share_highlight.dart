import 'indian_dish.dart';

enum HighlightSelectionMode { auto, manual }

enum ShareCardFormat {
  story,
  square;

  int get selectionLimit => this == story ? 12 : 8;
  String get label => this == story ? 'Story 9:16' : 'Square 1:1';
}

enum ShareHighlightCategory {
  fruit('Fruits'),
  dish('Dishes'),
  drink('Drinks'),
  book('Books'),
  yoga('Yoga'),
  travel('Travel'),
  pilgrimage('Pilgrimage');

  const ShareHighlightCategory(this.label);
  final String label;
}

class ShareHighlightItem {
  final String reference;
  final String title;
  final String subtitle;
  final String? imageAsset;
  final IndianDish? dish;
  final ShareHighlightCategory category;

  const ShareHighlightItem({
    required this.reference,
    required this.title,
    required this.category,
    this.subtitle = '',
    this.imageAsset,
    this.dish,
  });

  String get searchableText =>
      '${title.toLowerCase()} ${subtitle.toLowerCase()} ${category.label.toLowerCase()}';
}

abstract final class ShareHighlightLayout {
  static int columns(int itemCount, ShareCardFormat format) {
    if (itemCount <= 2) return 1;
    if (format == ShareCardFormat.story && itemCount >= 9) return 3;
    return 2;
  }
}

class ShareHighlightController {
  ShareHighlightController({
    required Iterable<ShareHighlightItem> completedItems,
    this.mode = HighlightSelectionMode.auto,
    this.format = ShareCardFormat.story,
    Iterable<String> selectedReferences = const [],
  }) : completedItems = List.unmodifiable(_unique(completedItems)) {
    final valid = this.completedItems.map((item) => item.reference).toSet();
    _selected.addAll(
      selectedReferences.where(valid.contains).take(format.selectionLimit),
    );
  }

  final List<ShareHighlightItem> completedItems;
  HighlightSelectionMode mode;
  ShareCardFormat format;
  final Set<String> _selected = {};

  static Iterable<ShareHighlightItem> _unique(
    Iterable<ShareHighlightItem> items,
  ) sync* {
    final seen = <String>{};
    for (final item in items) {
      if (seen.add(item.reference)) yield item;
    }
  }

  Set<String> get selectedReferences => Set.unmodifiable(_selected);
  int get limit => format.selectionLimit;

  List<ShareHighlightItem> get selectedItems => completedItems
      .where((item) => _selected.contains(item.reference))
      .take(limit)
      .toList(growable: false);

  List<ShareHighlightItem> get previewItems =>
      mode == HighlightSelectionMode.auto
      ? autoSelection(completedItems, limit)
      : selectedItems;

  void setFormat(ShareCardFormat value) {
    format = value;
    while (_selected.length > limit) {
      _selected.remove(_selected.last);
    }
  }

  bool toggle(String reference) {
    if (_selected.remove(reference)) return true;
    if (_selected.length >= limit ||
        !completedItems.any((item) => item.reference == reference)) {
      return false;
    }
    _selected.add(reference);
    return true;
  }

  void clear() => _selected.clear();

  void autoFill() {
    _selected
      ..clear()
      ..addAll(
        autoSelection(completedItems, limit).map((item) => item.reference),
      );
  }

  List<ShareHighlightItem> visibleItems({
    String query = '',
    ShareHighlightCategory? category,
  }) {
    final normalized = query.trim().toLowerCase();
    return completedItems
        .where((item) {
          return (category == null || item.category == category) &&
              (normalized.isEmpty || item.searchableText.contains(normalized));
        })
        .toList(growable: false);
  }

  static List<ShareHighlightItem> autoSelection(
    Iterable<ShareHighlightItem> source,
    int limit,
  ) {
    final buckets = <ShareHighlightCategory, List<ShareHighlightItem>>{
      for (final category in ShareHighlightCategory.values) category: [],
    };
    for (final item in _unique(source)) {
      buckets[item.category]!.add(item);
    }
    final result = <ShareHighlightItem>[];
    var row = 0;
    while (result.length < limit) {
      var added = false;
      for (final category in ShareHighlightCategory.values) {
        final bucket = buckets[category]!;
        if (row < bucket.length) {
          result.add(bucket[row]);
          added = true;
          if (result.length == limit) break;
        }
      }
      if (!added) break;
      row++;
    }
    return result;
  }
}
