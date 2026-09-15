class Challenge {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String itemType;
  final String? geography;
  final int totalItems;
  final bool hasSubItems;
  final String? subItemType;
  final String status;
  final String presentationType;
  final String? dataAsset;
  final String? progressKey;
  final List<String> sections;
  final bool completionFilters;
  final String? itemSummary;
  final String completionVerb;
  final String? detailFutureSection;
  final String? detailFutureMessage;
  final String? metricLabel;
  final String? collectionUnit;

  const Challenge({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.itemType,
    this.geography,
    required this.totalItems,
    required this.hasSubItems,
    this.subItemType,
    required this.status,
    required this.presentationType,
    this.dataAsset,
    this.progressKey,
    this.sections = const [],
    this.completionFilters = false,
    this.itemSummary,
    this.completionVerb = 'completed',
    this.detailFutureSection,
    this.detailFutureMessage,
    this.metricLabel,
    this.collectionUnit,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      itemType: json['item_type'] as String,
      geography: json['geography'] as String?,
      totalItems: json['total_items'] as int,
      hasSubItems: json['has_sub_items'] as bool,
      subItemType: json['sub_item_type'] as String?,
      status: json['status'] as String,
      presentationType: json['presentation_type'] as String? ?? 'checklist',
      dataAsset: json['data_asset'] as String?,
      progressKey: json['progress_key'] as String?,
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((value) => value.toString())
          .toList(),
      completionFilters: json['completion_filters'] as bool? ?? false,
      itemSummary: json['item_summary'] as String?,
      completionVerb: json['completion_verb'] as String? ?? 'completed',
      detailFutureSection: json['detail_future_section'] as String?,
      detailFutureMessage: json['detail_future_message'] as String?,
      metricLabel: json['metric_label'] as String?,
      collectionUnit: json['collection_unit'] as String?,
    );
  }
}
