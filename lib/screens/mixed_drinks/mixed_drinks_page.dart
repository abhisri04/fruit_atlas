import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../models/challenge.dart';
import '../../models/mixed_drink.dart';
import '../../services/drink_mix_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/exploration_hero.dart';
import '../../widgets/filter_chip_group.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/saved_challenge_button.dart';
import 'mix_share_page.dart';
import 'mix_widgets.dart';
import 'mixed_drink_detail_page.dart';

/// What the filter sheet can narrow the list by.
class DrinkFilters {
  final Set<String> flavours;
  final Set<String> methods;
  final Set<String> spirits;
  final bool quick;
  final bool canMake;
  final bool? made;
  const DrinkFilters({
    this.flavours = const {},
    this.methods = const {},
    this.spirits = const {},
    this.quick = false,
    this.canMake = false,
    this.made,
  });

  int get count =>
      flavours.length +
      methods.length +
      spirits.length +
      (quick ? 1 : 0) +
      (canMake ? 1 : 0) +
      (made == null ? 0 : 1);

  bool allows(
    MixedDrink d, {
    required Set<String> madeIds,
    required Set<String> shelf,
    required DrinkBook book,
  }) =>
      (flavours.isEmpty || d.flavours.any(flavours.contains)) &&
      (methods.isEmpty || methods.contains(d.method)) &&
      (spirits.isEmpty || spirits.contains(d.spirit)) &&
      (!quick || d.minutes <= 5) &&
      (!canMake || book.missing(d, shelf).isEmpty) &&
      (made == null || madeIds.contains(d.id) == made);
}

/// Cocktails & Mocktails: recipes to make at home, what your shelf can make,
/// and a record of every drink you've mixed.
class MixedDrinksPage extends StatefulWidget {
  final Challenge challenge;
  final Random? random;
  const MixedDrinksPage({super.key, required this.challenge, this.random});

  @override
  State<MixedDrinksPage> createState() => _MixedDrinksPageState();
}

class _MixedDrinksPageState extends State<MixedDrinksPage> {
  static const sections = [
    'Mocktails',
    'Cocktails',
    'What can I make?',
    'By country',
  ];
  late final Random random = widget.random ?? Random();
  DrinkBook? book;
  Set<String> made = {};
  Set<String> shelf = {};
  bool? cocktails;
  String section = 'Mocktails';
  String origin = 'All';
  String query = '';
  DrinkFilters filters = const DrinkFilters();

  bool get showCocktails => cocktails ?? false;

  @override
  void initState() {
    super.initState();
    DrinkMixService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DrinkMixService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final b = await DrinkMixService.book();
    final m = await DrinkMixService.madeIds();
    final s = await DrinkMixService.shelf();
    final c = await DrinkMixService.showCocktails();
    if (!mounted) return;
    setState(() {
      book = b;
      made = m.intersection({for (final d in b.drinks) d.id});
      shelf = s;
      cocktails = c;
    });
  }

  Future<void> _toggle(MixedDrink d) async {
    final total = book!.visible(cocktails: showCocktails).length;
    final before = made.length;
    final now = !made.contains(d.id);
    setState(() => now ? made.add(d.id) : made.remove(d.id));
    await DrinkMixService.setMade(d.id, now);
    if (mounted) {
      showCompletionFeedback(
        context,
        before: before,
        after: made.length,
        total: total,
        challengeId: widget.challenge.id,
      );
    }
  }

  void _open(MixedDrink d) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MixedDrinkDetailPage(drinkId: d.id)),
  );

  Future<void> _pickSection(String value) async {
    if (value == 'Cocktails' && cocktails == null) {
      final show = await askAboutCocktails(context);
      if (!mounted) return;
      setState(() {
        cocktails = show ?? cocktails;
        if (show == true) section = value;
      });
      return;
    }
    setState(() {
      section = value;
      filters = const DrinkFilters();
      origin = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = book;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        actions: [
          IconButton(
            key: const ValueKey('mix-share'),
            tooltip: 'Share my mix book',
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MixSharePage()),
            ),
          ),
          SavedChallengeButton(challengeId: widget.challenge.id),
        ],
      ),
      body: b == null
          ? const Center(child: CircularProgressIndicator())
          : _body(context, b),
    );
  }

  Widget _body(BuildContext context, DrinkBook b) {
    final accent = AppColors.categoryAccent(widget.challenge.categoryId);
    final total = b.visible(cocktails: showCocktails).length;
    final countries = b.originCountries(made);
    final latest = Achievement.latestFor(widget.challenge.id, made.length);
    final header = <Widget>[
      ExplorationHero(
        title: widget.challenge.name,
        accent: accent,
        icon: Icons.local_bar_outlined,
        subtitle: widget.challenge.description,
      ),
      ProgressCard(
        prominent: true,
        title: 'Your mix book',
        summary: made.isEmpty
            ? 'Make your first drink to start'
            : '${made.length} ${made.length == 1 ? 'drink' : 'drinks'} made · '
                  'from ${countries.length} '
                  '${countries.length == 1 ? 'country' : 'countries'}',
        progress: total == 0 ? 0 : min(1, made.length / total),
      ),
      if (latest != null) ...[
        const SizedBox(height: 12),
        AchievementCard(achievement: latest),
      ],
      const SizedBox(height: 14),
      FilterChipGroup(
        options: sections,
        selected: section,
        onChanged: _pickSection,
      ),
    ];

    return switch (section) {
      'Cocktails' when !showCocktails => _list(header, [_cocktailsOff()]),
      'Cocktails' => _drinkList(context, b, header, cocktail: true),
      'What can I make?' => _list(header, [
        ShelfView(
          book: b,
          shelf: shelf,
          made: made,
          cocktails: showCocktails,
          onOpen: _open,
          onToggle: _toggle,
          onSurprise: () => _surprise(b),
        ),
      ]),
      'By country' => _list(header, [
        DrinkCountryView(
          book: b,
          made: made,
          cocktails: showCocktails,
          onOpen: _open,
          onToggle: _toggle,
        ),
      ]),
      _ => _drinkList(context, b, header, cocktail: false),
    };
  }

  void _surprise(DrinkBook b) {
    final ready = b.canMake(shelf, cocktails: showCocktails);
    final pool = ready.isNotEmpty ? ready : b.visible(cocktails: showCocktails);
    _open(pool[random.nextInt(pool.length)]);
  }

  Widget _cocktailsOff() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        const Icon(
          Icons.local_drink_outlined,
          size: 40,
          color: AppColors.muted,
        ),
        const SizedBox(height: 10),
        const Text(
          "You're seeing mocktails only. Cocktails contain alcohol and are "
          'for adults of legal drinking age.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('cocktails-turn-on'),
          onPressed: () async {
            final show = await askAboutCocktails(context);
            if (mounted && show != null) setState(() => cocktails = show);
          },
          child: const Text('Show cocktails'),
        ),
      ],
    ),
  );

  Widget _list(List<Widget> header, List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
    children: [...header, ...children],
  );

  Widget _drinkList(
    BuildContext context,
    DrinkBook b,
    List<Widget> header, {
    required bool cocktail,
  }) {
    final pool = [
      for (final d in b.drinks)
        if (d.isCocktail == cocktail) d,
    ];
    final visible = [
      for (final d in pool)
        if (d.matches(query) &&
            (origin == 'All' || b.country(d.country).continent == origin) &&
            filters.allows(d, madeIds: made, shelf: shelf, book: b))
          d,
    ];
    final continents = [
      for (final c in WorldCountry.continents)
        if (pool.any((d) => b.country(d.country).continent == c)) c,
    ];
    final noun = cocktail ? 'cocktail' : 'mocktail';
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: header.length + 1 + (visible.isEmpty ? 1 : visible.length),
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        if (index == header.length) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cocktail) ...[
                const _ResponsibleNote(),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('mix-search'),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        hintText: cocktail
                            ? 'Search: mojito, gin, lime…'
                            : 'Search: mojito, mango, mint…',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: filters.count > 0,
                    label: Text('${filters.count}'),
                    child: IconButton.filledTonal(
                      key: const ValueKey('mix-filter'),
                      tooltip: 'Filters',
                      icon: const Icon(Icons.tune),
                      onPressed: () => _openFilters(context, cocktail),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Comes from',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              FilterChipGroup(
                options: ['All', ...continents],
                selected: origin,
                onChanged: (v) => setState(() => origin = v),
              ),
              Text(
                '${visible.length} ${visible.length == 1 ? noun : '${noun}s'}',
                key: const ValueKey('mix-count'),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
            ],
          );
        }
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('No ${noun}s match these filters.'),
                TextButton(
                  onPressed: () => setState(() {
                    filters = const DrinkFilters();
                    origin = 'All';
                  }),
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          );
        }
        final d = visible[index - header.length - 1];
        return DrinkTile(
          drink: d,
          book: b,
          made: made.contains(d.id),
          onTap: () => _open(d),
          onToggle: () => _toggle(d),
        );
      },
    );
  }

  Future<void> _openFilters(BuildContext context, bool cocktail) async {
    final result = await showModalBottomSheet<DrinkFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: filters, cocktail: cocktail),
    );
    if (result != null) setState(() => filters = result);
  }
}

class _ResponsibleNote extends StatelessWidget {
  const _ResponsibleNote();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.information,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Enjoy responsibly, and never drink and drive. Each cocktail '
            'shows a zero-proof way to make it too.',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final DrinkFilters initial;
  final bool cocktail;
  const _FilterSheet({required this.initial, required this.cocktail});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> flavours = {...widget.initial.flavours};
  late Set<String> methods = {...widget.initial.methods};
  late Set<String> spirits = {...widget.initial.spirits};
  late bool quick = widget.initial.quick;
  late bool canMake = widget.initial.canMake;
  late bool? made = widget.initial.made;

  Widget _group(String title, List<String> options, Set<String> chosen) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final o in options)
                FilterChip(
                  label: Text(o),
                  selected: chosen.contains(o),
                  onSelected: (on) =>
                      setState(() => on ? chosen.add(o) : chosen.remove(o)),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter drinks', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _group('Flavour', DrinkBook.flavours, flavours),
          _group('How it is made', DrinkBook.methods, methods),
          if (widget.cocktail) _group('Spirit', DrinkBook.spirits, spirits),
          SwitchListTile(
            key: const ValueKey('mix-filter-quick'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Ready in 5 minutes'),
            value: quick,
            onChanged: (v) => setState(() => quick = v),
          ),
          SwitchListTile(
            key: const ValueKey('mix-filter-can-make'),
            contentPadding: EdgeInsets.zero,
            title: const Text('I have everything for it'),
            subtitle: const Text('Uses what you ticked in What can I make?'),
            value: canMake,
            onChanged: (v) => setState(() => canMake = v),
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('All')),
              ButtonSegment(value: 1, label: Text('Made')),
              ButtonSegment(value: 2, label: Text('To make')),
            ],
            selected: {
              made == null
                  ? 0
                  : made!
                  ? 1
                  : 2,
            },
            onSelectionChanged: (v) => setState(
              () => made = switch (v.single) {
                1 => true,
                2 => false,
                _ => null,
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, const DrinkFilters()),
                child: const Text('Clear'),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('mix-filter-apply'),
                onPressed: () => Navigator.pop(
                  context,
                  DrinkFilters(
                    flavours: flavours,
                    methods: methods,
                    spirits: spirits,
                    quick: quick,
                    canMake: canMake,
                    made: made,
                  ),
                ),
                child: const Text('Show drinks'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Tick what's in your kitchen and see what you can make right now.
class ShelfView extends StatelessWidget {
  final DrinkBook book;
  final Set<String> shelf;
  final Set<String> made;
  final bool cocktails;
  final ValueChanged<MixedDrink> onOpen;
  final ValueChanged<MixedDrink> onToggle;
  final VoidCallback onSurprise;
  const ShelfView({
    super.key,
    required this.book,
    required this.shelf,
    required this.made,
    required this.cocktails,
    required this.onOpen,
    required this.onToggle,
    required this.onSurprise,
  });

  @override
  Widget build(BuildContext context) {
    final ready = book.canMake(shelf, cocktails: cocktails);
    final close = book.oneAway(shelf, cocktails: cocktails);
    final groups = [
      for (final g in book.groups)
        if (cocktails || !book.alcoholGroups.contains(g)) g,
    ];
    final used = {
      for (final d in book.visible(cocktails: cocktails))
        for (final l in d.ingredients) l.ingredientId,
    };
    final title = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w800);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                shelf.isEmpty
                    ? 'Tick what you have at home. Ice and water are already '
                          'counted, and sugar covers sugar syrup.'
                    : 'You can make ${ready.length} '
                          '${ready.length == 1 ? 'drink' : 'drinks'} now',
                key: const ValueKey('shelf-count'),
                style: shelf.isEmpty
                    ? const TextStyle(color: AppColors.muted, height: 1.4)
                    : title,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              key: const ValueKey('drink-surprise'),
              onPressed: onSurprise,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('Surprise me'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final g in groups) ...[
          Text(
            g,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final ing in book.ingredients.values)
                if (ing.group == g && used.contains(ing.id))
                  FilterChip(
                    key: ValueKey('shelf-${ing.id}'),
                    label: Text(ing.name),
                    selected: shelf.contains(ing.id),
                    onSelected: (on) => DrinkMixService.setOnShelf(ing.id, on),
                  ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (ready.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Ready to make', style: title),
          const SizedBox(height: 8),
          for (final d in ready)
            DrinkTile(
              drink: d,
              book: book,
              made: made.contains(d.id),
              onTap: () => onOpen(d),
              onToggle: () => onToggle(d),
            ),
        ],
        if (shelf.isNotEmpty && close.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('One thing away', style: title),
          const SizedBox(height: 8),
          for (final (d, need) in close.take(12))
            DrinkTile(
              drink: d,
              book: book,
              made: made.contains(d.id),
              note: 'Just add: ${book.ingredientName(need).toLowerCase()}',
              onTap: () => onOpen(d),
              onToggle: () => onToggle(d),
            ),
        ],
      ],
    );
  }
}

/// Countries by continent, with the drinks that first came from each.
class DrinkCountryView extends StatelessWidget {
  final DrinkBook book;
  final Set<String> made;
  final bool cocktails;
  final ValueChanged<MixedDrink> onOpen;
  final ValueChanged<MixedDrink> onToggle;
  const DrinkCountryView({
    super.key,
    required this.book,
    required this.made,
    required this.cocktails,
    required this.onOpen,
    required this.onToggle,
  });

  List<MixedDrink> _from(String code) => [
    for (final d in book.visible(cocktails: cocktails))
      if (d.country == code) d,
  ];

  @override
  Widget build(BuildContext context) {
    final reached = book.originCountries(made);
    final codes = {
      for (final d in book.visible(cocktails: cocktails)) d.country,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          made.isEmpty
              ? 'Every drink has a home. Tap a country to see what it gave the world.'
              : "You've made drinks from ${reached.length} of "
                    '${codes.length} countries.',
          key: const ValueKey('mix-country-summary'),
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        for (final continent in WorldCountry.continents)
          if (codes.any((c) => book.country(c).continent == continent)) ...[
            Text(
              continent,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code
                    in (codes
                        .where((c) => book.country(c).continent == continent)
                        .toList()
                      ..sort(
                        (a, b) => _from(b).length.compareTo(_from(a).length),
                      )))
                  _CountryChip(
                    country: book.country(code),
                    drinks: _from(code),
                    made: made,
                    onTap: () => _openCountry(context, book.country(code)),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
      ],
    );
  }

  void _openCountry(BuildContext context, WorldCountry c) {
    final local = {...made};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .55,
        maxChildSize: .92,
        builder: (_, controller) => StatefulBuilder(
          builder: (context, setSheet) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                '${c.flag}  ${c.name}',
                key: ValueKey('mix-country-title-${c.code}'),
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              for (final d in _from(c.code))
                DrinkTile(
                  drink: d,
                  book: book,
                  made: local.contains(d.id),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onOpen(d);
                  },
                  onToggle: () {
                    onToggle(d);
                    setSheet(
                      () => local.contains(d.id)
                          ? local.remove(d.id)
                          : local.add(d.id),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  final WorldCountry country;
  final List<MixedDrink> drinks;
  final Set<String> made;
  final VoidCallback onTap;
  const _CountryChip({
    required this.country,
    required this.drinks,
    required this.made,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = drinks.where((d) => made.contains(d.id)).length;
    final any = done > 0;
    return Material(
      key: ValueKey('mix-country-${country.code}'),
      color: any ? AppColors.completedSurface : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: any
              ? AppColors.primary.withValues(alpha: .4)
              : AppColors.outline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    any
                        ? '$done of ${drinks.length} made'
                        : '${drinks.length} '
                              '${drinks.length == 1 ? 'drink' : 'drinks'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
