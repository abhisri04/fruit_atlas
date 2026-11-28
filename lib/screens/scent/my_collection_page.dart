import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../models/scent_collection.dart';
import '../../services/scent_collection_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../../widgets/skill_ladder.dart';
import 'scent_sheets.dart';

String _wears(int n) => n == 1 ? '1 wear' : '$n wears';

const _collectorPath = [
  LadderStep(level: 'tried', milestone: 'Put your first perfume on a shelf'),
  LadderStep(
    level: 'learning',
    milestone: 'Own or try 5 perfumes across 3 families',
  ),
  LadderStep(level: 'practising', milestone: 'Log what you wore on 20 days'),
  LadderStep(level: 'confident', milestone: 'Experience all 9 scent families'),
];

/// My perfume collection: shelves, wear diary, collection map and the
/// collector path. No prices anywhere.
class MyCollectionPage extends StatefulWidget {
  final DateTime Function()? clock;
  const MyCollectionPage({super.key, this.clock});

  @override
  State<MyCollectionPage> createState() => _MyCollectionPageState();
}

class _MyCollectionPageState extends State<MyCollectionPage> {
  ScentCollection collection = const ScentCollection();
  ScentCatalogue? catalogue;
  ScentShelf shelf = ScentShelf.own;
  bool loading = true;

  DateTime get now => (widget.clock ?? DateTime.now)();
  Color get accent => AppColors.categoryAccent('scent');

  @override
  void initState() {
    super.initState();
    ScentCollectionService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    ScentCollectionService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await ScentCollectionService.load();
    final cat = catalogue ?? await ScentCatalogue.load();
    if (!mounted) return;
    setState(() {
      collection = loaded;
      catalogue = cat;
      loading = false;
    });
  }

  Future<void> _openAdd([ScentShelf? initial]) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddToCollectionPage(initialShelf: initial),
    ),
  );

  Future<void> _entryActions(ScentEntry entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                entry.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                [
                  entry.maker,
                  entry.family,
                  entry.format.label,
                ].whereType<String>().join(' · '),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Wore it today'),
              onTap: () => Navigator.pop(context, 'wear'),
            ),
            for (final target in ScentShelf.values)
              if (target != entry.shelf)
                ListTile(
                  leading: const Icon(Icons.drive_file_move_outline),
                  title: Text('Move to ${target.label}'),
                  onTap: () => Navigator.pop(context, 'move:${target.name}'),
                ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove from collection'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'wear') {
      await showWearSheet(context, entry);
    } else if (action == 'remove') {
      await ScentCollectionService.remove(entry.id);
    } else if (action.startsWith('move:')) {
      final target = ScentShelf.values.byName(action.substring(5));
      await ScentCollectionService.move(entry.id, target);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Collection'),
      actions: [
        IconButton(
          key: const ValueKey('collection-add'),
          tooltip: 'Add a perfume',
          icon: const Icon(Icons.add),
          onPressed: () => _openAdd(),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : collection.isEmpty
        ? _Empty(accent: accent, onAdd: () => _openAdd())
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              Reveal(child: _header()),
              const SizedBox(height: 22),
              Reveal(index: 1, child: _path(context)),
              const SizedBox(height: 22),
              Reveal(index: 2, child: _map(context)),
              ..._insights(context),
              const SizedBox(height: 22),
              Text('Shelves', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              SegmentedButton<ScentShelf>(
                showSelectedIcon: false,
                segments: [
                  for (final s in ScentShelf.values)
                    ButtonSegment(
                      value: s,
                      label: Text('${s.label} (${collection.shelf(s).length})'),
                    ),
                ],
                selected: {shelf},
                onSelectionChanged: (value) =>
                    setState(() => shelf = value.first),
              ),
              const SizedBox(height: 10),
              ..._shelfList(context),
              ..._diary(context),
            ],
          ),
  );

  Widget _header() {
    final own = collection.shelf(ScentShelf.own).length;
    final tried = collection.shelf(ScentShelf.tried).length;
    final want = collection.shelf(ScentShelf.wantToSmell).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.category(accent),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _HeaderStat(value: own, label: 'own'),
              _HeaderStat(value: tried, label: 'tried'),
              _HeaderStat(value: want, label: 'want to smell'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${collection.distinctWornThisMonth(now)} different scents worn this month',
            style: TextStyle(color: Colors.white.withValues(alpha: .92)),
          ),
        ],
      ),
    );
  }

  Widget _path(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Collector path', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      SkillLadder(
        steps: _collectorPath,
        reached: collection.collectorLevel(
          familyTotal: catalogue?.families.length ?? 9,
        ),
      ),
    ],
  );

  Widget _map(BuildContext context) {
    final families = catalogue?.families ?? const <String>[];
    final counts = collection.familyCounts();
    final max = counts.values.fold(1, (a, b) => a > b ? a : b);
    // Skip families already on the want-to-smell list.
    final wanted = {
      for (final e in collection.shelf(ScentShelf.wantToSmell)) ?e.family,
    };
    final missing = families
        .where((f) => !counts.containsKey(f) && !wanted.contains(f))
        .toList();
    Item? suggestion;
    String? suggestionFamily;
    for (final family in missing) {
      suggestion = catalogue?.perfumes
          .where(
            (p) =>
                ScentCatalogue.familyOf(p) == family &&
                !collection.entries.containsKey(p.id),
          )
          .firstOrNull;
      if (suggestion != null) {
        suggestionFamily = family;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your scent map', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Families you own or have tried',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        for (final family in families)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    family,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: counts.containsKey(family)
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedProgressValue(
                      value: (counts[family] ?? 0) / max,
                      minHeight: 10,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: .1),
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${counts[family] ?? 0}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        if (suggestion case final next?) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.explore_outlined, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No $suggestionFamily yet. Next time, smell ${next.name}.',
                  ),
                ),
                TextButton(
                  key: const ValueKey('collection-suggestion-add'),
                  onPressed: () => ScentCollectionService.addItem(
                    next,
                    ScentShelf.wantToSmell,
                  ),
                  child: const Text('Add to list'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _insights(BuildContext context) {
    final mostWorn = collection.mostWorn();
    final signatures = collection.signatures();
    final dusty = collection.gatheringDust(now).take(3).toList();
    if (mostWorn.isEmpty && dusty.isEmpty) return const [];
    return [
      const SizedBox(height: 22),
      Text('Insights', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      if (mostWorn.isNotEmpty)
        _InsightCard(
          icon: Icons.favorite_border,
          title: 'Most worn',
          lines: [for (final (e, n) in mostWorn) '${e.name} · ${_wears(n)}'],
        ),
      if (signatures.isNotEmpty)
        _InsightCard(
          icon: Icons.wb_sunny_outlined,
          title: 'Signature scents',
          lines: [
            for (final season in ScentSeason.values)
              if (signatures[season] case final entry?)
                '${season.label}: ${entry.name}',
          ],
        ),
      if (dusty.isNotEmpty)
        _InsightCard(
          icon: Icons.hourglass_empty,
          title: 'Gathering dust',
          lines: [for (final e in dusty) '${e.name}: not worn in 60 days'],
        ),
    ];
  }

  List<Widget> _shelfList(BuildContext context) {
    final entries = collection.shelf(shelf);
    if (entries.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: OutlinedButton.icon(
            onPressed: () => _openAdd(shelf),
            icon: const Icon(Icons.add),
            label: Text('Add to ${shelf.label}'),
          ),
        ),
      ];
    }
    return [
      for (final entry in entries)
        _EntryTile(
          entry: entry,
          woreToday: collection.woreOn(entry.id, now),
          wears: collection.wearCounts()[entry.id] ?? 0,
          accent: accent,
          onWear: () => showWearSheet(context, entry),
          onMore: () => _entryActions(entry),
        ),
    ];
  }

  List<Widget> _diary(BuildContext context) {
    final recent = [...collection.wears]..sort((a, b) => b.at.compareTo(a.at));
    if (recent.isEmpty) return const [];
    return [
      const SizedBox(height: 22),
      Text('Wear diary', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      for (final wear in recent.take(15))
        if (collection.entries[wear.entryId] case final entry?)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.event_available_outlined, color: accent),
            title: Text(entry.name),
            subtitle: Text(
              [
                _date(wear.at),
                wear.occasion,
                wear.note,
              ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
            ),
          ),
    ];
  }

  String _date(DateTime at) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(at.year, at.month, at.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${at.day} ${months[at.month - 1]}';
  }
}

class _Empty extends StatelessWidget {
  final Color accent;
  final VoidCallback onAdd;
  const _Empty({required this.accent, required this.onAdd});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 24),
      Reveal(
        child: Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.category(accent),
          ),
          child: const Icon(
            Icons.local_florist_outlined,
            size: 44,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Reveal(
        index: 1,
        child: Text(
          'Start your perfume collection',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 8),
      const Reveal(
        index: 2,
        child: Text(
          'Add what you own, what you\'ve tried and what you want to smell. '
          'Samples and attars count too. Log what you wear and watch your '
          'scent map grow.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 15),
        ),
      ),
      const SizedBox(height: 24),
      Reveal(
        index: 3,
        child: FilledButton.icon(
          key: const ValueKey('collection-empty-add'),
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add a perfume'),
        ),
      ),
    ],
  );
}

class _HeaderStat extends StatelessWidget {
  final int value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        AnimatedCount(
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .9),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppColors.categoryAccent('scent')),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(lines.join('\n')),
    ),
  );
}

class _EntryTile extends StatelessWidget {
  final ScentEntry entry;
  final bool woreToday;
  final int wears;
  final Color accent;
  final VoidCallback onWear;
  final VoidCallback onMore;

  const _EntryTile({
    required this.entry,
    required this.woreToday,
    required this.wears,
    required this.accent,
    required this.onWear,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TactileScale(
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('collection-entry-${entry.id}'),
          onTap: onMore,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Icon(
                  entry.format == ScentFormat.attar
                      ? Icons.water_drop_outlined
                      : Icons.local_florist_outlined,
                  color: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        [
                          entry.maker,
                          entry.family,
                          entry.format.label,
                          if (wears > 0) _wears(wears),
                        ].whereType<String>().join(' · '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.shelf == ScentShelf.own)
                  woreToday
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            semanticLabel: 'Worn today',
                          ),
                        )
                      : TextButton(
                          key: ValueKey('wear-${entry.id}'),
                          onPressed: onWear,
                          child: const Text('Wore it'),
                        ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
