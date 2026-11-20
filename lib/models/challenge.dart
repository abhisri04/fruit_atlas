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
  final String shortTitle;
  final String categoryName;
  final String primaryAction;
  final String primaryActionLabel;
  final String progressVerb;
  final String startLabel;
  final String continueLabel;
  final String? singularNoun;
  final String? pluralNoun;
  final String iconIdentifier;
  final bool showInQuickExplore;
  final int quickExplorePriority;
  final String? heroImageAsset;

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
    this.shortTitle = '',
    this.categoryName = '',
    this.primaryAction = 'completed',
    this.primaryActionLabel = 'Complete',
    this.progressVerb = 'completed',
    this.startLabel = 'Start exploring',
    this.continueLabel = 'Continue your journey',
    this.singularNoun,
    this.pluralNoun,
    this.iconIdentifier = 'challenge',
    this.showInQuickExplore = false,
    this.quickExplorePriority = 999,
    this.heroImageAsset,
  });

  String get title => name;
  String get compactTitle => shortTitle.isEmpty ? name : shortTitle;

  String get displayCategoryName {
    if (categoryName.isNotEmpty) return categoryName;
    return switch (categoryId) {
      'food_drink' => 'Food & Drink',
      'fitness_wellness' => 'Fitness & Wellness',
      'travel_exploration' => 'Travel & Exploration',
      'culture_learning' => 'Culture & Learning',
      'faith_pilgrimage' => 'Faith & Pilgrimage',
      'collecting' => 'Collecting',
      'life_experiences' => 'Life Experiences',
      'games_play' => 'Games & Play',
      _ => 'Explore',
    };
  }

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
      shortTitle: json['short_title'] as String? ?? '',
      categoryName: json['category_name'] as String? ?? '',
      primaryAction: json['primary_action'] as String? ?? 'completed',
      primaryActionLabel: json['primary_action_label'] as String? ?? 'Complete',
      progressVerb:
          json['progress_verb'] as String? ??
          json['completion_verb'] as String? ??
          'completed',
      startLabel: json['start_label'] as String? ?? 'Start exploring',
      continueLabel:
          json['continue_label'] as String? ?? 'Continue your journey',
      singularNoun: json['singular_noun'] as String?,
      pluralNoun: json['plural_noun'] as String?,
      iconIdentifier: json['icon_identifier'] as String? ?? 'challenge',
      showInQuickExplore: json['show_in_quick_explore'] as bool? ?? false,
      quickExplorePriority: json['quick_explore_priority'] as int? ?? 999,
      heroImageAsset: json['hero_image_asset'] as String?,
    );
  }
}
