import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../models/challenge.dart';
import '../../models/nut.dart';
import '../../services/nut_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/exploration_hero.dart';
import '../../widgets/filter_chip_group.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/saved_challenge_button.dart';
import 'nut_detail_page.dart';
import 'nut_quiz.dart';
import 'nut_share_page.dart';

/// What the filter sheet can narrow the list by.
class NutFilters {
  final Set<String> kinds;
  final Set<String> finds;
  final Set<String> tastes;
  final bool grownInIndia;
  final bool? tried;
  const NutFilters({
    this.kinds = const {},
    this.finds = const {},
    this.tastes = const {},
    this.grownInIndia = false,
    this.tried,
  });

  int get count =>
      kinds.length +
      finds.length +
      tastes.length +
      (grownInIndia ? 1 : 0) +
      (tried == null ? 0 : 1);

  bool allows(Nut nut, Set<String> triedIds) =>
      (kinds.isEmpty || kinds.contains(nut.kind)) &&
      (finds.isEmpty || finds.contains(nut.find)) &&
      (tastes.isEmpty || nut.tastes.any(tastes.contains)) &&
      (!grownInIndia || nut.grownInIndia) &&
      (tried == null || triedIds.contains(nut.id) == tried);
}

/// Nuts of the World: every nut, where it comes from, and what you've tasted.
class NutsPage extends StatefulWidget {
  final Challenge challenge;
  const NutsPage({super.key, required this.challenge});

  @override
  State<NutsPage> createState() => _NutsPageState();
}

class _NutsPageState extends State<NutsPage> {
  static const sections = ['Nuts', 'By country', 'Nut or not?'];
  NutAtlas? atlas;
  Set<String> tried = {};
  String section = 'Nuts';
  String origin = 'All';
  String query = '';
  NutFilters filters = const NutFilters();

  @override
  void initState() {
    super.initState();
    NutService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    NutService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final a = await NutService.atlas();
    final t = await NutService.triedIds();
    if (!mounted) return;
    setState(() {
      atlas = a;
      tried = t.intersection({for (final n in a.nuts) n.id});
    });
  }

  Future<void> _toggle(Nut nut) async {
    final before = tried.length;
    final now = !tried.contains(nut.id);
    setState(() => now ? tried.add(nut.id) : tried.remove(nut.id));
    await NutService.setTried(nut.id, now);
    if (mounted) {
      showCompletionFeedback(
        context,
        before: before,
        after: tried.length,
        total: atlas!.nuts.length,
        challengeId: widget.challenge.id,
      );
    }
  }

  void _open(Nut nut) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NutDetailPage(nutId: nut.id)),
  );

  @override
  Widget build(BuildContext context) {
    final a = atlas;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        actions: [
          IconButton(
            key: const ValueKey('nuts-share'),
            tooltip: 'Share my nut passport',
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NutSharePage()),
            ),
          ),
          SavedChallengeButton(challengeId: widget.challenge.id),
        ],
      ),
      body: a == null
          ? const Center(child: CircularProgressIndicator())
          : _body(context, a),
    );
  }

  Widget _body(BuildContext context, NutAtlas a) {
    final accent = AppColors.categoryAccent(widget.challenge.categoryId);
    final origins = a.originCountries(tried);
    final latest = Achievement.latestFor(widget.challenge.id, tried.length);
    final header = <Widget>[
      ExplorationHero(
        title: widget.challenge.name,
        accent: accent,
        icon: Icons.spa_outlined,
        subtitle: widget.challenge.description,
      ),
      ProgressCard(
        prominent: true,
        title: 'Your nut passport',
        summary: tried.isEmpty
            ? 'Taste your first nut to start'
            : '${tried.length} of ${a.nuts.length} tasted · from '
                  '${origins.length} ${origins.length == 1 ? 'country' : 'countries'}',
        progress: tried.length / a.nuts.length,
      ),
      if (latest != null) ...[
        const SizedBox(height: 12),
        AchievementCard(achievement: latest),
      ],
      const SizedBox(height: 14),
      FilterChipGroup(
        options: sections,
        selected: section,
        onChanged: (v) => setState(() => section = v),
      ),
    ];

    return switch (section) {
      'By country' => _list(header, [
        NutCountryView(
          atlas: a,
          tried: tried,
          onOpen: _open,
          onToggle: _toggle,
        ),
      ]),
      'Nut or not?' => _list(header, [NutQuiz(atlas: a)]),
      _ => _nutList(context, a, header),
    };
  }

  Widget _list(List<Widget> header, List<Widget> children) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
    children: [...header, ...children],
  );

  Widget _nutList(BuildContext context, NutAtlas a, List<Widget> header) {
    final visible = [
      for (final n in a.nuts)
        if (n.matches(query) &&
            (origin == 'All' || a.continentsOf(n).contains(origin)) &&
            filters.allows(n, tried))
          n,
    ];
    final continents = [
      for (final c in NutAtlas.continents)
        if (a.nuts.any((n) => a.continentsOf(n).contains(c))) c,
    ];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: header.length + 1 + (visible.isEmpty ? 1 : visible.length),
      itemBuilder: (context, index) {
        if (index < header.length) return header[index];
        if (index == header.length) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AllergyNote(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('nuts-search'),
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search: kaju, pecan, chilgoza…',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Badge(
                    isLabelVisible: filters.count > 0,
                    label: Text('${filters.count}'),
                    child: IconButton.filledTonal(
                      key: const ValueKey('nuts-filter'),
                      tooltip: 'Filters',
                      icon: const Icon(Icons.tune),
                      onPressed: () => _openFilters(context, a),
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
                '${visible.length} ${visible.length == 1 ? 'nut' : 'nuts'}',
                key: const ValueKey('nuts-count'),
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
                const Text('No nuts match these filters.'),
                TextButton(
                  onPressed: () => setState(() {
                    filters = const NutFilters();
                    origin = 'All';
                  }),
                  child: const Text('Clear filters'),
                ),
              ],
            ),
          );
        }
        final nut = visible[index - header.length - 1];
        return NutTile(
          nut: nut,
          atlas: a,
          tried: tried.contains(nut.id),
          onTap: () => _open(nut),
          onToggle: () => _toggle(nut),
        );
      },
    );
  }

  Future<void> _openFilters(BuildContext context, NutAtlas a) async {
    final result = await showModalBottomSheet<NutFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: filters),
    );
    if (result != null) setState(() => filters = result);
  }
}

class _AllergyNote extends StatelessWidget {
  const _AllergyNote();

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
            'Allergic to nuts? Enjoy reading about them, and skip anything '
            "you're unsure of.",
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

/// One nut in a list: name, Indian name, where it's from, one-tap tasted.
class NutTile extends StatelessWidget {
  final Nut nut;
  final NutAtlas atlas;
  final bool tried;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  const NutTile({
    super.key,
    required this.nut,
    required this.atlas,
    required this.tried,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final from = nut.native.map((c) => atlas.country(c).flag).join(' ');
    final aka = nut.aliases.isEmpty ? '' : ' · ${nut.aliases.first}';
    return Container(
      key: ValueKey('nut-${nut.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tried ? AppColors.completedSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(
          color: tried
              ? AppColors.primary.withValues(alpha: .35)
              : AppColors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: onTap,
          leading: NutBadge(kind: nut.kind),
          title: Text(
            '${nut.name}$aka',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: tried ? AppColors.primary : AppColors.ink,
            ),
          ),
          subtitle: Text(
            'From $from · ${nut.find}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Checkbox(
            key: ValueKey('nut-check-${nut.id}'),
            value: tried,
            onChanged: (_) => onToggle(),
          ),
        ),
      ),
    );
  }
}

/// A small coloured badge for what a nut is botanically.
class NutBadge extends StatelessWidget {
  final String kind;
  final double size;
  const NutBadge({super.key, required this.kind, this.size = 40});

  static Color colorFor(String kind) => switch (kind) {
    'True nut' => const Color(0xFF8A5A2B),
    'Drupe seed' => const Color(0xFFB7792F),
    'Seed' => const Color(0xFF5E8C3A),
    'Legume' => const Color(0xFFC0392B),
    _ => const Color(0xFF6D5BA8),
  };

  static IconData iconFor(String kind) => switch (kind) {
    'True nut' => Icons.park_outlined,
    'Drupe seed' => Icons.spa_outlined,
    'Seed' => Icons.grain,
    'Legume' => Icons.grass,
    _ => Icons.help_outline,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(kind);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(iconFor(kind), color: color, size: size * .55),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final NutFilters initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> kinds = {...widget.initial.kinds};
  late Set<String> finds = {...widget.initial.finds};
  late Set<String> tastes = {...widget.initial.tastes};
  late bool india = widget.initial.grownInIndia;
  late bool? tried = widget.initial.tried;

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
          Text('Filter nuts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _group('Where to find it', NutAtlas.finds, finds),
          _group('Botanically', NutAtlas.kinds, kinds),
          _group('Taste', NutAtlas.tastes, tastes),
          SwitchListTile(
            key: const ValueKey('nuts-filter-india'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Grown in India'),
            value: india,
            onChanged: (v) => setState(() => india = v),
          ),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('All')),
              ButtonSegment(value: 1, label: Text('Tasted')),
              ButtonSegment(value: 2, label: Text('To taste')),
            ],
            selected: {
              tried == null
                  ? 0
                  : tried!
                  ? 1
                  : 2,
            },
            onSelectionChanged: (v) => setState(
              () => tried = switch (v.single) {
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
                onPressed: () => Navigator.pop(context, const NutFilters()),
                child: const Text('Clear'),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('nuts-filter-apply'),
                onPressed: () => Navigator.pop(
                  context,
                  NutFilters(
                    kinds: kinds,
                    finds: finds,
                    tastes: tastes,
                    grownInIndia: india,
                    tried: tried,
                  ),
                ),
                child: const Text('Show nuts'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Countries by continent, with how many of their nuts you've tasted.
class NutCountryView extends StatelessWidget {
  final NutAtlas atlas;
  final Set<String> tried;
  final ValueChanged<Nut> onOpen;
  final ValueChanged<Nut> onToggle;
  const NutCountryView({
    super.key,
    required this.atlas,
    required this.tried,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final reached = atlas.originCountries(tried);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tried.isEmpty
              ? 'Every nut has a home. Tap a country to see what comes from there.'
              : "You've tasted nuts that first came from ${reached.length} of "
                    '${atlas.countries.length} countries.',
          key: const ValueKey('nuts-country-summary'),
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        for (final continent in NutAtlas.continents) ...[
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
              for (final c
                  in (atlas.countries.values
                      .where((c) => c.continent == continent)
                      .toList()
                    ..sort(
                      (a, b) => atlas
                          .nutsFor(b.code)
                          .length
                          .compareTo(atlas.nutsFor(a.code).length),
                    )))
                _CountryChip(
                  country: c,
                  nuts: atlas.nutsFor(c.code),
                  tried: tried,
                  onTap: () => _openCountry(context, c),
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  void _openCountry(BuildContext context, NutCountry c) {
    final local = {...tried};
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        maxChildSize: .92,
        builder: (_, controller) => StatefulBuilder(
          builder: (context, setSheet) {
            final native = atlas.nuts
                .where((n) => n.native.contains(c.code))
                .toList();
            final grown = atlas.nuts
                .where(
                  (n) => !n.native.contains(c.code) && n.grown.contains(c.code),
                )
                .toList();
            Widget tile(Nut n) => NutTile(
              nut: n,
              atlas: atlas,
              tried: local.contains(n.id),
              onTap: () {
                Navigator.pop(sheetContext);
                onOpen(n);
              },
              onToggle: () {
                onToggle(n);
                setSheet(
                  () => local.contains(n.id)
                      ? local.remove(n.id)
                      : local.add(n.id),
                );
              },
            );
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  '${c.flag}  ${c.name}',
                  key: ValueKey('nut-country-title-${c.code}'),
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                if (native.isNotEmpty) ...[
                  Text(
                    'First came from here',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...native.map(tile),
                  const SizedBox(height: 10),
                ],
                if (grown.isNotEmpty) ...[
                  Text(
                    'Grown here today',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...grown.map(tile),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  final NutCountry country;
  final List<Nut> nuts;
  final Set<String> tried;
  final VoidCallback onTap;
  const _CountryChip({
    required this.country,
    required this.nuts,
    required this.tried,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = nuts.where((n) => tried.contains(n.id)).length;
    final any = done > 0;
    return Material(
      key: ValueKey('nut-country-${country.code}'),
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
                        ? '$done of ${nuts.length} tasted'
                        : '${nuts.length} ${nuts.length == 1 ? 'nut' : 'nuts'}',
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
