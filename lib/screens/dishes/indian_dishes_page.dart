import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../models/indian_dish.dart';
import '../../models/item_action_progress.dart';
import '../../models/india_location_registry.dart';
import '../../services/indian_dishes_repository.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/circular_progress_widget.dart';
import '../../widgets/dish_image.dart';
import '../../widgets/dish_dietary_indicator.dart';
import '../../widgets/empty_state.dart';

typedef DishProgress = Map<String, ItemActionProgress>;

String _label(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

class IndianDishesPage extends StatefulWidget {
  final IndianDishesRepository repository;

  const IndianDishesPage({
    super.key,
    this.repository = const IndianDishesRepository(),
  });

  @override
  State<IndianDishesPage> createState() => _IndianDishesPageState();
}

class _IndianDishesPageState extends State<IndianDishesPage> {
  IndianDishesCatalogue? catalogue;
  DishProgress progress = {};
  Object? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.repository.load();
      final saved = await ProgressService.getDishProgress(data);
      if (mounted) {
        setState(() {
          catalogue = data;
          progress = saved;
          error = null;
        });
      }
    } catch (value) {
      if (mounted) setState(() => error = value);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = catalogue;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Indian Dishes')),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load dishes',
          message: error.toString(),
        ),
      );
    }
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tried = data.dishes
        .where((dish) => progress[dish.id]?.tried ?? false)
        .length;
    final cooked = data.dishes
        .where((dish) => progress[dish.id]?.cooked ?? false)
        .length;
    final locationsTried = IndianDishesRepository.triedLocationIds(
      data.dishes,
      progress,
    ).length;
    final regionNames = data.dishes.expand((dish) => dish.regions).toSet();
    final regionsTried = data.dishes
        .where((dish) => progress[dish.id]?.tried ?? false)
        .expand((dish) => dish.regions)
        .toSet()
        .length;
    final completedCollections = data.collections.where((collection) {
      final counts = _collectionCounts(collection, data.dishes, progress);
      return counts.total > 0 && counts.completed >= counts.total;
    }).length;
    final unlockedAchievements = data.achievements
        .where(
          (achievement) =>
              _achievementMetric(achievement.metric, data.dishes, progress) >=
              achievement.threshold,
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(data.category.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE76522), Color(0xFFF59B31)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.restaurant, color: Colors.white, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    data.category.subtitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.category.description,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$tried / ${data.dishes.length} Tried',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: data.dishes.isEmpty
                          ? 0
                          : tried / data.dishes.length,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 10),
                    Text('$cooked / ${data.dishes.length} Cooked'),
                    const SizedBox(height: 4),
                    Text(
                      '$locationsTried / ${IndiaLocationRegistry.allLocationIds.length} States & UTs explored',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Explore',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _EntryCard(
              icon: Icons.grid_view_rounded,
              title: 'All Dishes',
              subtitle: '${data.dishes.length} regional dishes',
              completed: tried,
              total: data.dishes.length,
              onTap: () => _open(DishBrowsePage(catalogue: data)),
            ),
            _EntryCard(
              icon: Icons.map_outlined,
              title: 'States',
              subtitle: 'Explore dishes from every State and UT',
              completed: locationsTried,
              total: IndiaLocationRegistry.allLocationIds.length,
              onTap: () => _open(
                DishGroupPage(
                  catalogue: data,
                  field: 'primary_state',
                  title: 'Dishes by State',
                ),
              ),
            ),
            _EntryCard(
              icon: Icons.public,
              title: 'Regions',
              subtitle: 'Browse India by food region',
              completed: regionsTried,
              total: regionNames.length,
              onTap: () => _open(
                DishGroupPage(
                  catalogue: data,
                  field: 'region',
                  title: 'Dishes by Region',
                ),
              ),
            ),
            _EntryCard(
              icon: Icons.flag_outlined,
              title: 'Collections & Challenges',
              subtitle: '${data.collections.length} ways to explore',
              completed: completedCollections,
              total: data.collections.length,
              onTap: () => _open(DishCollectionsPage(catalogue: data)),
            ),
            _EntryCard(
              icon: Icons.emoji_events_outlined,
              title: 'Achievements',
              subtitle: '${data.achievements.length} milestones',
              completed: unlockedAchievements,
              total: data.achievements.length,
              onTap: () => _open(DishAchievementsPage(catalogue: data)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int completed;
  final int total;
  final VoidCallback onTap;
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFFE8D5),
        child: Icon(icon, color: const Color(0xFFB94F16)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$subtitle · $completed/$total'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressWidget(
            progress: total == 0 ? 0 : completed / total,
            variant: ProgressSize.compact,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    ),
  );
}

class DishBrowsePage extends StatefulWidget {
  final IndianDishesCatalogue catalogue;
  final List<IndianDish>? source;
  final String title;
  final bool showCookedOnTiles;
  const DishBrowsePage({
    super.key,
    required this.catalogue,
    this.source,
    this.title = 'All Dishes',
    this.showCookedOnTiles = true,
  });

  @override
  State<DishBrowsePage> createState() => _DishBrowsePageState();
}

class _DishBrowsePageState extends State<DishBrowsePage> {
  DishProgress progress = {};
  String query = '';
  String actionFilter = 'all';
  String sortBy = 'name';
  final filters = <String, String?>{
    'primary_state': null,
    'region': null,
    'dietary_type': null,
    'dish_type': null,
  };

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final value = await ProgressService.getDishProgress(widget.catalogue);
    if (mounted) setState(() => progress = value);
  }

  Future<void> _toggle(IndianDish dish, String action) async {
    final updated = await ProgressService.toggleCategoryItemAction(
      categoryId: widget.catalogue.category.id,
      itemId: dish.id,
      action: action,
    );
    progress[dish.id] = updated;
    if (mounted) setState(() {});
  }

  List<IndianDish> get visible {
    final source = widget.source ?? widget.catalogue.dishes;
    final normalized = query.trim().toLowerCase();
    final result = source.where((dish) {
      if (normalized.isNotEmpty &&
          ![
            dish.name,
            ...dish.states,
            dish.region,
            ...dish.tags,
          ].join(' ').toLowerCase().contains(normalized)) {
        return false;
      }
      return filters.entries.every((entry) {
            if (entry.value == null) return true;
            if (entry.key == 'primary_state') {
              return dish.states.contains(entry.value);
            }
            return dish.valueFor(entry.key) == entry.value;
          }) &&
          (actionFilter == 'all' ||
              (progress[dish.id] ?? const ItemActionProgress()).hasAction(
                actionFilter,
              ));
    }).toList();
    result.sort((a, b) {
      if (sortBy == 'state') {
        final stateComparison = a.primaryState.compareTo(b.primaryState);
        if (stateComparison != 0) return stateComparison;
      }
      return a.name.compareTo(b.name);
    });
    return result;
  }

  List<String> _values(String field) {
    final values =
        (widget.source ?? widget.catalogue.dishes)
            .expand(
              (dish) => field == 'primary_state'
                  ? dish.states
                  : [dish.valueFor(field)],
            )
            .where(
              (value) =>
                  field != 'dietary_type' ||
                  DishDietaryIndicator.identityFor(value) != null,
            )
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final dishes = visible;
    final source = widget.source ?? widget.catalogue.dishes;
    final tried = source
        .where((dish) => progress[dish.id]?.tried ?? false)
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              key: const Key('dish-search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search dishes, states, or tags',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: _DishProgressSummary(
              completed: tried,
              total: source.length,
              label: '$tried of ${source.length} tried',
            ),
          ),
          if (widget.source == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('dish-progress-filter'),
                      initialValue: actionFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Progress',
                        prefixIcon: Icon(Icons.filter_list),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All dishes'),
                        ),
                        DropdownMenuItem(value: 'tried', child: Text('Tried')),
                        DropdownMenuItem(
                          value: 'cooked',
                          child: Text('Cooked'),
                        ),
                        DropdownMenuItem(
                          value: 'want_to_try',
                          child: Text('Want to try'),
                        ),
                        DropdownMenuItem(
                          value: 'favourite',
                          child: Text('Favorite'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => actionFilter = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('dish-sort'),
                      initialValue: sortBy,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sort',
                        prefixIcon: Icon(Icons.sort),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('By name')),
                        DropdownMenuItem(
                          value: 'state',
                          child: Text('By state'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => sortBy = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: filters.keys
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: DropdownButton<String>(
                        key: Key('dish-filter-$field'),
                        hint: Text(
                          field == 'dietary_type'
                              ? 'Food type'
                              : _label(
                                  field == 'primary_state' ? 'state' : field,
                                ),
                        ),
                        value: filters[field],
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              field == 'dietary_type'
                                  ? 'All food types'
                                  : 'All ${_label(field == 'primary_state' ? 'states' : field)}',
                            ),
                          ),
                          ..._values(field).map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: field == 'dietary_type'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DishDietaryIndicator(
                                          dietaryType: value,
                                          compact: true,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DishDietaryIndicator.identityFor(
                                            value,
                                          )!.label,
                                        ),
                                      ],
                                    )
                                  : Text(_label(value)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => filters[field] = value),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: dishes.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No dishes found',
                    message: 'Try changing your search or filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: dishes.length,
                    itemBuilder: (context, index) => DishQuickActionCard(
                      dish: dishes[index],
                      progress:
                          progress[dishes[index].id] ??
                          const ItemActionProgress(),
                      onToggle: (action) => _toggle(dishes[index], action),
                      showCookedAction: widget.showCookedOnTiles,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DishDetailPage(
                              catalogue: widget.catalogue,
                              dishes: dishes,
                              initialIndex: index,
                            ),
                          ),
                        );
                        await _loadProgress();
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class DishQuickActionCard extends StatelessWidget {
  final IndianDish dish;
  final ItemActionProgress progress;
  final VoidCallback onTap;
  final ValueChanged<String> onToggle;
  final bool showCookedAction;
  const DishQuickActionCard({
    super.key,
    required this.dish,
    required this.progress,
    required this.onTap,
    required this.onToggle,
    required this.showCookedAction,
  });
  @override
  Widget build(BuildContext context) => Card(
    key: Key('dish-card-${dish.id}'),
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Row(
              children: [
                DishImage(
                  assetPath: dish.imageAsset,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dish.name,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (DishDietaryIndicator.identityFor(
                                dish.dietaryType,
                              ) !=
                              null) ...[
                            const SizedBox(width: 8),
                            DishDietaryIndicator(
                              key: Key('dish-dietary-marker-${dish.id}'),
                              dietaryType: dish.dietaryType,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dish.primaryState} | ${_label(dish.dietaryType)} | ${_label(dish.dishType)}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  key: Key('dish-list-tried-${dish.id}'),
                  avatar: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Tried',
                    style: TextStyle(color: AppColors.ink),
                  ),
                  selected: progress.tried,
                  onSelected: (_) => onToggle('tried'),
                ),
              ),
              if (showCookedAction) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    key: Key('dish-list-cooked-${dish.id}'),
                    avatar: const Icon(Icons.soup_kitchen_outlined, size: 18),
                    label: const Text(
                      'Cooked',
                      style: TextStyle(color: AppColors.ink),
                    ),
                    selected: progress.cooked,
                    onSelected: (_) => onToggle('cooked'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}

class DishDetailPage extends StatefulWidget {
  final IndianDishesCatalogue catalogue;
  final List<IndianDish> dishes;
  final int initialIndex;
  const DishDetailPage({
    super.key,
    required this.catalogue,
    required this.dishes,
    required this.initialIndex,
  });
  @override
  State<DishDetailPage> createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  late final PageController controller;
  late int index;
  DishProgress progress = {};
  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    controller = PageController(initialPage: index);
    _load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final value = await ProgressService.getDishProgress(widget.catalogue);
    if (mounted) setState(() => progress = value);
  }

  Future<void> _toggle(IndianDish dish, String action) async {
    final updated = await ProgressService.toggleCategoryItemAction(
      categoryId: widget.catalogue.category.id,
      itemId: dish.id,
      action: action,
    );
    progress[dish.id] = updated;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: Text(widget.dishes[index].name)),
    body: PageView.builder(
      controller: controller,
      itemCount: widget.dishes.length,
      onPageChanged: (value) => setState(() => index = value),
      itemBuilder: (context, pageIndex) {
        final dish = widget.dishes[pageIndex];
        final state = progress[dish.id] ?? const ItemActionProgress();
        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            DishImage(
              assetPath: dish.imageAsset,
              width: double.infinity,
              height: 260,
            ),
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          dish.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (DishDietaryIndicator.identityFor(dish.dietaryType) !=
                          null) ...[
                        const SizedBox(width: 12),
                        DishDietaryIndicator(
                          key: Key('dish-dietary-marker-${dish.id}'),
                          dietaryType: dish.dietaryType,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dish.shortDescription,
                    style: const TextStyle(
                      color: AppColors.ink,
                      height: 1.5,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in [dish.primaryState, dish.region])
                        Chip(
                          label: Text(
                            value,
                            style: const TextStyle(color: AppColors.ink),
                          ),
                        ),
                      Chip(
                        label: Text(
                          _label(dish.dishType),
                          style: const TextStyle(color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                  if (dish.tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: dish.tags
                          .map(
                            (tag) => Chip(
                              label: Text(
                                _label(tag),
                                style: const TextStyle(color: AppColors.ink),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Your journey',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.catalogue.category.actions
                        .map(
                          (action) => FilterChip(
                            key: Key('dish-action-${action.key}'),
                            avatar: Icon(_actionIcon(action.key), size: 18),
                            label: Text(
                              action.label,
                              style: const TextStyle(color: AppColors.ink),
                            ),
                            selected: state.hasAction(action.key),
                            onSelected: (_) => _toggle(dish, action.key),
                          ),
                        )
                        .toList(),
                  ),
                  if (widget.dishes.length > 1) ...[
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Swipe for the next dish',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

IconData _actionIcon(String action) => switch (action) {
  'tried' => Icons.check_circle_outline,
  'cooked' => Icons.soup_kitchen_outlined,
  'want_to_try' => Icons.bookmark_add_outlined,
  'favourite' => Icons.favorite_border,
  _ => Icons.circle_outlined,
};

class DishGroupPage extends StatefulWidget {
  final IndianDishesCatalogue catalogue;
  final String field;
  final String title;
  const DishGroupPage({
    super.key,
    required this.catalogue,
    required this.field,
    required this.title,
  });
  @override
  State<DishGroupPage> createState() => _DishGroupPageState();
}

class _DishGroupPageState extends State<DishGroupPage> {
  DishProgress progress = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ProgressService.getDishProgress(widget.catalogue);
    if (mounted) setState(() => progress = value);
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<IndianDish>>{};
    for (final dish in widget.catalogue.dishes) {
      final values = widget.field == 'primary_state'
          ? dish.states
          : [dish.valueFor(widget.field)];
      for (final value in values) {
        (groups[value] ??= []).add(dish);
      }
    }
    final names = groups.keys.toList()..sort();
    final exploredGroups = names
        .where(
          (name) =>
              groups[name]!.any((dish) => progress[dish.id]?.tried ?? false),
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: names.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DishProgressSummary(
                completed: exploredGroups,
                total: names.length,
                label: '$exploredGroups of ${names.length} explored',
              ),
            );
          }
          final name = names[index - 1];
          final dishes = groups[name]!;
          final tried = dishes
              .where((dish) => progress[dish.id]?.tried ?? false)
              .length;
          return Card(
            child: ListTile(
              leading: CircularProgressWidget(
                progress: dishes.isEmpty ? 0 : tried / dishes.length,
                variant: ProgressSize.small,
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('$tried/${dishes.length} tried'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DishBrowsePage(
                      catalogue: widget.catalogue,
                      source: dishes,
                      title: name,
                    ),
                  ),
                );
                await _load();
              },
            ),
          );
        },
      ),
    );
  }
}

class DishCollectionsPage extends StatefulWidget {
  final IndianDishesCatalogue catalogue;
  const DishCollectionsPage({super.key, required this.catalogue});
  @override
  State<DishCollectionsPage> createState() => _DishCollectionsPageState();
}

class _DishCollectionsPageState extends State<DishCollectionsPage> {
  DishProgress progress = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ProgressService.getDishProgress(widget.catalogue);
    if (mounted) setState(() => progress = value);
  }

  @override
  Widget build(BuildContext context) {
    final collectionRows = widget.catalogue.collections
        .map((collection) {
          final dishes = IndianDishesRepository.dishesForCollection(
            collection,
            widget.catalogue.dishes,
          );
          final counts = _collectionCounts(collection, dishes, progress);
          return (collection: collection, dishes: dishes, counts: counts);
        })
        .toList(growable: false);
    final completedCollections = collectionRows
        .where(
          (row) =>
              row.counts.total > 0 && row.counts.completed >= row.counts.total,
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('Collections & Challenges')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DishProgressSummary(
              completed: completedCollections,
              total: collectionRows.length,
              label:
                  '$completedCollections of ${collectionRows.length} completed',
            ),
          ),
          ...collectionRows.map((row) {
            final collection = row.collection;
            final dishes = row.dishes;
            final completed = row.counts.completed;
            final total = row.counts.total;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircularProgressWidget(
                  progress: total == 0 ? 0 : completed / total,
                  variant: ProgressSize.small,
                ),
                title: Text(
                  collection.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${collection.description}\n$completed/$total complete',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DishBrowsePage(
                        catalogue: widget.catalogue,
                        source: dishes,
                        title: collection.name,
                      ),
                    ),
                  );
                  await _load();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DishAchievementsPage extends StatefulWidget {
  final IndianDishesCatalogue catalogue;
  const DishAchievementsPage({super.key, required this.catalogue});
  @override
  State<DishAchievementsPage> createState() => _DishAchievementsPageState();
}

class _DishAchievementsPageState extends State<DishAchievementsPage> {
  DishProgress progress = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ProgressService.getDishProgress(widget.catalogue);
    if (mounted) setState(() => progress = value);
  }

  int _metric(String metric) => switch (metric) {
    _ => _achievementMetric(metric, widget.catalogue.dishes, progress),
  };
  @override
  Widget build(BuildContext context) {
    final unlockedCount = widget.catalogue.achievements
        .where(
          (achievement) => _metric(achievement.metric) >= achievement.threshold,
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DishProgressSummary(
              completed: unlockedCount,
              total: widget.catalogue.achievements.length,
              label:
                  '$unlockedCount of ${widget.catalogue.achievements.length} earned',
            ),
          ),
          ...widget.catalogue.achievements.map((achievement) {
            final current = _metric(achievement.metric);
            final unlocked = current >= achievement.threshold;
            return AchievementCard(
              unlocked: unlocked,
              progress: achievement.threshold == 0
                  ? 0
                  : current / achievement.threshold,
              achievement: Achievement(
                id: achievement.id,
                title: achievement.name,
                description:
                    '${achievement.description} ${current.clamp(0, achievement.threshold)}/${achievement.threshold}',
                threshold: achievement.threshold,
                challengeId: widget.catalogue.category.id,
                iconIdentifier: achievement.metric == 'unique_states_tried'
                    ? 'map'
                    : achievement.metric == 'cooked_count'
                    ? 'start'
                    : 'explore',
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DishProgressSummary extends StatelessWidget {
  final int completed;
  final int total;
  final String label;

  const _DishProgressSummary({
    required this.completed,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircularProgressWidget(
            progress: total == 0 ? 0 : completed / total,
            variant: ProgressSize.small,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

({int completed, int total}) _collectionCounts(
  DishCollection collection,
  List<IndianDish> dishes,
  DishProgress progress,
) {
  if (collection.type == 'unique_field') {
    return (
      completed: IndianDishesRepository.triedStateIds(dishes, progress).length,
      total: collection.rule['unique_required'] as int,
    );
  }
  return (
    completed: dishes.where((dish) => progress[dish.id]?.tried ?? false).length,
    total: dishes.length,
  );
}

int _achievementMetric(
  String metric,
  List<IndianDish> dishes,
  DishProgress progress,
) => switch (metric) {
  'tried_count' =>
    dishes.where((dish) => progress[dish.id]?.tried ?? false).length,
  'cooked_count' =>
    dishes.where((dish) => progress[dish.id]?.cooked ?? false).length,
  'unique_states_tried' => IndianDishesRepository.triedStateIds(
    dishes,
    progress,
  ).length,
  _ => 0,
};
