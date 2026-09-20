import '../models/category.dart';
import '../models/challenge.dart';
import '../models/fruit.dart';
import '../models/search_result.dart';
import 'asset_data_service.dart';
import 'district_repository.dart';
import 'experience_repository.dart';

class GlobalSearchService {
  final AssetDataService data;
  final ExperienceRepository experiences;
  final DistrictRepository districts;
  GlobalSearchService({
    this.data = const AssetDataService(),
    this.experiences = const ExperienceRepository(),
    this.districts = const DistrictRepository(),
  });
  List<Category> categories = [];
  List<Challenge> challenges = [];
  List<AtlasState> states = [];
  List<SearchResult> _index = [];
  Future<void>? _loading;
  Future<void> load() => _loading ??= _load().catchError((Object error) {
    _loading = null;
    throw error;
  });

  Future<void> _load() async {
    categories = await data.loadCategories();
    challenges = await data.loadChallenges();
    final metadata = await data.loadSearchKeywords();
    final results = <SearchResult>[];
    for (final category in categories) {
      results.add(
        SearchResult(
          id: 'category:${category.id}',
          entityType: SearchEntityType.category,
          title: category.name,
          subtitle: 'Category',
          categoryId: category.id,
          keywords: metadata[category.id] ?? [],
          relationTerms: challenges
              .where((challenge) => challenge.categoryId == category.id)
              .map((challenge) => challenge.name)
              .toList(),
          secondaryText: category.description,
          destination: category,
        ),
      );
    }
    for (final challenge in challenges) {
      final matching = categories.where((c) => c.id == challenge.categoryId);
      final categoryName = matching.isEmpty ? '' : matching.first.name;
      final inherited = <String>[
        categoryName,
        challenge.name,
        ...?metadata[challenge.categoryId],
        ...?metadata[challenge.id],
      ];
      final children = <SearchResult>[];
      void addItem(
        String id,
        String title,
        String label,
        Object destination, {
        String secondary = '',
        List<String> keywords = const [],
        List<String> parentTerms = const [],
        Object? parent,
        String? parentId,
        bool sub = false,
      }) {
        children.add(
          SearchResult(
            id: '${challenge.id}:${sub ? 'sub' : 'item'}:$id',
            entityType: sub ? SearchEntityType.subItem : SearchEntityType.item,
            title: title,
            subtitle: '$label \u00b7 ${challenge.name}',
            categoryId: challenge.categoryId,
            challengeId: challenge.id,
            parentId: parentId ?? challenge.id,
            keywords: [...keywords, ...?metadata[id]],
            contextTerms: inherited,
            parentTerms: parentTerms,
            secondaryText: secondary,
            destination: destination,
            parent: parent,
          ),
        );
      }

      if (challenge.itemType == 'fruit') {
        final atlas = await data.loadFruitData();
        states = atlas.states;
        for (final fruit in atlas.fruits) {
          final id = fruit.id.isEmpty ? fruit.name : fruit.id;
          addItem(
            id,
            fruit.name,
            'Fruit',
            fruit,
            secondary: '${fruit.scientificName} ${fruit.cropGroup ?? ''}',
            keywords: [...fruit.aliases, ...fruit.varieties.map((v) => v.name)],
          );
          for (final variety in fruit.varieties) {
            addItem(
              '$id:${variety.id ?? variety.name}',
              variety.name,
              'Variety \u00b7 ${fruit.name}',
              variety,
              sub: true,
              parent: fruit,
              parentId: id,
              parentTerms: [fruit.name, fruit.scientificName, ...fruit.aliases],
              secondary: variety.notes ?? '',
            );
          }
        }
      } else if (challenge.itemType == 'jyotirlinga') {
        for (final site in await data.loadJyotirlingas()) {
          addItem(
            site.id,
            site.name,
            'Jyotirlinga',
            site,
            secondary: '${site.location} ${site.backstory}',
          );
        }
      } else if (challenge.dataAsset != null) {
        for (final item in await data.loadChallengeItems(challenge)) {
          final rawLabel =
              item.category ?? challenge.itemType.replaceAll('_', ' ');
          addItem(
            item.id,
            item.name,
            rawLabel.isEmpty
                ? 'Experience'
                : '${rawLabel[0].toUpperCase()}${rawLabel.substring(1)}',
            item,
            secondary:
                '${item.description ?? ''} ${item.scientificName ?? ''} ${item.category ?? ''} ${item.difficulty ?? ''} ${item.metadata.values.join(' ')}',
            keywords: [...item.keywords, ...item.subItems.map((s) => s.name)],
          );
          for (final sub in item.subItems) {
            addItem(
              '${item.id}:${sub.id}',
              sub.name,
              'Variant \u00b7 ${item.name}',
              sub,
              parent: item,
              parentId: item.id,
              sub: true,
              parentTerms: [item.name],
              keywords: sub.keywords,
              secondary: sub.description ?? '',
            );
          }
        }
      }
      results.add(
        SearchResult(
          id: 'challenge:${challenge.id}',
          entityType: SearchEntityType.challenge,
          title: challenge.name,
          subtitle:
              'Challenge \u00b7 $categoryName${challenge.status == 'active' ? '' : ' \u00b7 Coming soon'}',
          categoryId: challenge.categoryId,
          challengeId: challenge.id,
          destination: challenge,
          keywords: [...?metadata[challenge.id]],
          relationTerms: children.expand((child) => [child.title]).toList(),
          contextTerms: inherited,
          secondaryText: challenge.description,
        ),
      );
      results.addAll(children);
    }
    for (final experience in await experiences.loadExperiences()) {
      results.add(
        SearchResult(
          id: 'experience:${experience.id}',
          entityType: SearchEntityType.experience,
          title: experience.title,
          subtitle:
              '${experience.typeLabel} \u00b7 ${experience.locationLabel}',
          categoryId: experience.categoryId,
          parentId: experience.parentLocationId,
          keywords: experience.keywords,
          contextTerms: [
            experience.section,
            experience.typeLabel,
            experience.stateName,
            ?experience.city,
          ],
          parentTerms: [experience.stateName, ?experience.city],
          secondaryText: experience.description,
          destination: experience,
        ),
      );
    }
    for (final district in await districts.loadDistricts()) {
      results.add(
        SearchResult(
          id: 'district:${district.id}',
          entityType: SearchEntityType.district,
          title: district.name,
          subtitle: 'District \u00b7 ${district.stateName}',
          categoryId: 'travel_exploration',
          parentId: district.stateId,
          keywords: district.keywords,
          parentTerms: [district.stateName],
          contextTerms: ['District', district.stateName],
          secondaryText: district.description,
          destination: district,
        ),
      );
    }
    _index = {for (final result in results) result.id: result}.values.toList();
  }

  /// Rank once per candidate. Short queries never scan descriptions/metadata.
  List<SearchResult> search(String query) {
    final q = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (q.isEmpty) {
      return _index
          .where(
            (r) =>
                r.entityType == SearchEntityType.category ||
                r.entityType == SearchEntityType.challenge,
          )
          .take(12)
          .toList();
    }
    if (q.length < 2) return [];
    int score(SearchResult r) {
      final title = r.title.toLowerCase();
      if (title == q) return 0;
      if (r.relationTerms.any((term) => term.toLowerCase() == q)) return 1;
      if (r.parentTerms.any((term) => term.toLowerCase() == q)) return 2;
      if (q.length == 2 &&
          r.keywords.any((keyword) => keyword.toLowerCase() == q)) {
        return 2;
      }
      if (title.startsWith(q)) return 3;
      if (r.keywords.any((keyword) => keyword.toLowerCase() == q)) return 4;
      if (q.length == 2) return 8;
      if (r.keywords.any((keyword) => keyword.toLowerCase().contains(q))) {
        return 4;
      }
      if (title.contains(q)) return 5;
      if (r.contextTerms.any((term) => term.toLowerCase() == q)) return 6;
      if (r.contextTerms.any((term) => term.toLowerCase().contains(q))) {
        return 7;
      }
      if (r.secondaryText.toLowerCase().contains(q)) return 7;
      return 8;
    }

    final ranked = [for (final r in _index) (result: r, score: score(r))]
      ..removeWhere((entry) => entry.score == 8);
    ranked.sort((a, b) {
      final order = a.score.compareTo(b.score);
      if (order != 0) return order;
      // Related challenges precede contextual variants, without displacing direct titles.
      final type = a.result.entityType.index.compareTo(
        b.result.entityType.index,
      );
      return type != 0 ? type : a.result.title.compareTo(b.result.title);
    });
    return ranked.take(q.length == 2 ? 8 : 60).map((r) => r.result).toList();
  }
}
