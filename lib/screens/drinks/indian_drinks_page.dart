import 'package:flutter/material.dart';

import '../../models/indian_dish.dart' show ItemActionProgress;
import '../../models/indian_drink.dart';
import '../../services/indian_drinks_repository.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/circular_progress_widget.dart';
import '../../widgets/empty_state.dart';

String drinkLabel(String value) => value
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

IconData drinkTypeIcon(String type) => switch (type) {
  'tea' => Icons.emoji_food_beverage_outlined,
  'coffee' => Icons.coffee_outlined,
  'dairy' => Icons.local_drink_outlined,
  'herbal_medicinal' => Icons.spa_outlined,
  'juice' => Icons.blender_outlined,
  'fermented' || 'distilled_spirit' => Icons.wine_bar_outlined,
  'grain_pulse' => Icons.grass_outlined,
  _ => Icons.local_cafe_outlined,
};

class IndianDrinksPage extends StatefulWidget {
  final IndianDrinksRepository repository;

  const IndianDrinksPage({
    super.key,
    this.repository = const IndianDrinksRepository(),
  });

  @override
  State<IndianDrinksPage> createState() => _IndianDrinksPageState();
}

class _IndianDrinksPageState extends State<IndianDrinksPage> {
  IndianDrinksCatalogue? catalogue;
  DrinkProgress progress = {};
  Object? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.repository.load();
      final saved = await ProgressService.getDrinkProgress(data);
      if (!mounted) return;
      setState(() {
        catalogue = data;
        progress = saved;
        error = null;
      });
    } catch (value) {
      if (mounted) setState(() => error = value);
    }
  }

  Future<void> open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final data = catalogue;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Indian Drinks')),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load drinks',
          message: error.toString(),
        ),
      );
    }
    if (data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tried = data.drinks
        .where((drink) => progress[drink.id]?.tried ?? false)
        .length;
    final typeCounts = <String, int>{};
    for (final drink in data.drinks) {
      typeCounts.update(
        drink.drinkType,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(data.category.name)),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6F4E37), Color(0xFFC7894A)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_cafe, color: Colors.white, size: 36),
                  const SizedBox(height: 14),
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
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircularProgressWidget(
                      progress: data.drinks.isEmpty
                          ? 0
                          : tried / data.drinks.length,
                      variant: ProgressSize.medium,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '$tried of ${data.drinks.length} drinks tried',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Explore',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _DrinkEntryCard(
              icon: Icons.grid_view_rounded,
              title: 'All Drinks',
              subtitle: '${data.drinks.length} regional drinks',
              completed: tried,
              total: data.drinks.length,
              onTap: () => open(DrinkBrowsePage(catalogue: data)),
            ),
            for (final type in data.drinkTypes.where(
              (type) => (typeCounts[type.id] ?? 0) > 0,
            ))
              _DrinkEntryCard(
                icon: drinkTypeIcon(type.id),
                title: type.label,
                subtitle: '${typeCounts[type.id]} drinks',
                completed: data.drinks
                    .where(
                      (drink) =>
                          drink.drinkType == type.id &&
                          (progress[drink.id]?.tried ?? false),
                    )
                    .length,
                total: typeCounts[type.id]!,
                onTap: () => open(
                  DrinkBrowsePage(
                    catalogue: data,
                    source: data.drinks
                        .where((drink) => drink.drinkType == type.id)
                        .toList(),
                    title: type.label,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DrinkBrowsePage extends StatefulWidget {
  final IndianDrinksCatalogue catalogue;
  final List<IndianDrink>? source;
  final String title;

  const DrinkBrowsePage({
    super.key,
    required this.catalogue,
    this.source,
    this.title = 'All Drinks',
  });

  @override
  State<DrinkBrowsePage> createState() => _DrinkBrowsePageState();
}

class _DrinkBrowsePageState extends State<DrinkBrowsePage> {
  DrinkProgress progress = {};
  String status = 'All';
  String type = 'All';
  String query = '';
  String sort = 'Name';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final value = await ProgressService.getDrinkProgress(widget.catalogue);
    if (mounted) setState(() => progress = value);
  }

  Future<void> toggle(IndianDrink drink, String action) async {
    final value = await ProgressService.toggleCategoryItemAction(
      categoryId: widget.catalogue.category.id,
      itemId: drink.id,
      action: action,
    );
    if (mounted) setState(() => progress[drink.id] = value);
  }

  List<IndianDrink> get visible {
    final normalized = query.trim().toLowerCase();
    final values = (widget.source ?? widget.catalogue.drinks).where((drink) {
      final state = progress[drink.id] ?? const ItemActionProgress();
      final statusMatches = switch (status) {
        'Tried' => state.tried,
        'Want to try' => state.wantToTry,
        'Favourite' => state.favourite,
        _ => true,
      };
      return statusMatches &&
          (type == 'All' || drink.drinkType == type) &&
          (normalized.isEmpty ||
              drink.name.toLowerCase().contains(normalized) ||
              drink.aliases.any(
                (alias) => alias.toLowerCase().contains(normalized),
              ) ||
              drink.states.any(
                (state) => state.toLowerCase().contains(normalized),
              ));
    }).toList();
    values.sort(
      sort == 'State'
          ? (a, b) => '${a.primaryState}${a.name}'.compareTo(
              '${b.primaryState}${b.name}',
            )
          : (a, b) => a.name.compareTo(b.name),
    );
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final values = visible;
    final availableTypes =
        (widget.source ?? widget.catalogue.drinks)
            .map((drink) => drink.drinkType)
            .toSet()
            .toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search drinks, aliases or states',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: status,
                  items: const ['All', 'Tried', 'Want to try', 'Favourite']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => status = value!),
                ),
                const SizedBox(width: 18),
                DropdownButton<String>(
                  value: type,
                  items: ['All', ...availableTypes]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == 'All' ? value : drinkLabel(value),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => type = value!),
                ),
                const SizedBox(width: 18),
                DropdownButton<String>(
                  value: sort,
                  items: const ['Name', 'State']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('By $value'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => sort = value!),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: values.isEmpty
                ? const EmptyState(
                    icon: Icons.local_cafe_outlined,
                    title: 'No drinks found',
                    message: 'Try changing the filters.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: values.length,
                    itemBuilder: (context, index) {
                      final drink = values[index];
                      final state =
                          progress[drink.id] ?? const ItemActionProgress();
                      return _DrinkCard(
                        drink: drink,
                        progress: state,
                        onAction: (action) => toggle(drink, action),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DrinkDetailPage(
                                catalogue: widget.catalogue,
                                drink: drink,
                              ),
                            ),
                          );
                          await load();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class DrinkDetailPage extends StatefulWidget {
  final IndianDrinksCatalogue catalogue;
  final IndianDrink drink;

  const DrinkDetailPage({
    super.key,
    required this.catalogue,
    required this.drink,
  });

  @override
  State<DrinkDetailPage> createState() => _DrinkDetailPageState();
}

class _DrinkDetailPageState extends State<DrinkDetailPage> {
  ItemActionProgress progress = const ItemActionProgress();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final values = await ProgressService.getDrinkProgress(widget.catalogue);
    if (mounted) {
      setState(
        () => progress = values[widget.drink.id] ?? const ItemActionProgress(),
      );
    }
  }

  Future<void> toggle(String action) async {
    final value = await ProgressService.toggleCategoryItemAction(
      categoryId: widget.catalogue.category.id,
      itemId: widget.drink.id,
      action: action,
    );
    if (mounted) setState(() => progress = value);
  }

  @override
  Widget build(BuildContext context) {
    final drink = widget.drink;
    return Scaffold(
      appBar: AppBar(title: Text(drink.name)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              drinkTypeIcon(drink.drinkType),
              size: 76,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            drink.name,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(drinkLabel(drink.drinkType))),
              Chip(label: Text(drinkLabel(drink.alcoholContent))),
              Chip(label: Text(drinkLabel(drink.servingStyle))),
              if (drink.containsCannabis)
                const Chip(label: Text('Contains cannabis')),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            drink.shortDescription,
            style: const TextStyle(color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Associated with ${drink.states.join(', ')}',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (drink.aliases.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Also known as ${drink.aliases.join(', ')}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            children: [
              FilterChip(
                label: const Text('Tried'),
                selected: progress.tried,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: progress.tried ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => toggle('tried'),
              ),
              FilterChip(
                label: const Text('Want to try'),
                selected: progress.wantToTry,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: progress.wantToTry ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => toggle('want_to_try'),
              ),
              FilterChip(
                label: const Text('Favourite'),
                selected: progress.favourite,
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: progress.favourite ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => toggle('favourite'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrinkCard extends StatelessWidget {
  final IndianDrink drink;
  final ItemActionProgress progress;
  final ValueChanged<String> onAction;
  final VoidCallback onTap;

  const _DrinkCard({
    required this.drink,
    required this.progress,
    required this.onAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: progress.tried ? AppColors.completedSurface : AppColors.surface,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(child: Icon(drinkTypeIcon(drink.drinkType))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${drinkLabel(drink.drinkType)} · ${drink.states.join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      FilterChip(
                        label: const Text('Tried'),
                        selected: progress.tried,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: progress.tried ? Colors.white : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => onAction('tried'),
                      ),
                      FilterChip(
                        avatar: Icon(
                          progress.favourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: progress.favourite
                              ? Colors.white
                              : AppColors.ink,
                        ),
                        label: const Text('Favourite'),
                        selected: progress.favourite,
                        showCheckmark: false,
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: progress.favourite
                              ? Colors.white
                              : AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => onAction('favourite'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DrinkEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int completed;
  final int total;
  final VoidCallback onTap;

  const _DrinkEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.completed,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$subtitle · $completed/$total tried'),
      trailing: SizedBox(
        width: 42,
        height: 42,
        child: CircularProgressWidget(
          progress: total == 0 ? 0 : completed / total,
          variant: ProgressSize.small,
        ),
      ),
      onTap: onTap,
    ),
  );
}
