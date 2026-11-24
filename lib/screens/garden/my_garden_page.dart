import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../models/my_garden.dart';
import '../../services/my_garden_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../../widgets/skill_ladder.dart';
import 'garden_plant_page.dart';
import 'garden_sheets.dart';
import 'my_garden_share_page.dart';
import 'sow_now_card.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _gardenerPath = [
  LadderStep(level: 'tried', milestone: 'Put your first plant in My Garden'),
  LadderStep(
    level: 'learning',
    milestone: 'Grow 3 plants of 2 different kinds',
  ),
  LadderStep(level: 'practising', milestone: 'Tend your garden on 20 days'),
  LadderStep(
    level: 'confident',
    milestone: 'See 5 plants flower or give a harvest',
  ),
];

/// My Garden: what you grow, its firsts, and what you learned. No watering
/// alarms and no streaks that break.
class MyGardenPage extends StatefulWidget {
  final DateTime Function()? clock;
  const MyGardenPage({super.key, this.clock});

  @override
  State<MyGardenPage> createState() => _MyGardenPageState();
}

class _MyGardenPageState extends State<MyGardenPage> {
  MyGarden garden = const MyGarden();
  List<Map<String, dynamic>> catalogue = [];
  bool loading = true;

  DateTime get now => (widget.clock ?? DateTime.now)();
  Color get accent => AppColors.categoryAccent('garden');

  @override
  void initState() {
    super.initState();
    MyGardenService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    MyGardenService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await MyGardenService.load();
    final plants = catalogue.isEmpty ? await GardenCatalogue.raw() : catalogue;
    if (!mounted) return;
    setState(() {
      garden = loaded;
      catalogue = plants;
      loading = false;
    });
  }

  Future<void> _openAdd() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddGardenPlantPage()),
  );

  Future<void> _openPlant(GardenPlant plant) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => GardenPlantPage(plantId: plant.id)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Garden'),
      actions: [
        if (!garden.isEmpty)
          IconButton(
            key: const ValueKey('garden-share'),
            tooltip: 'Share your garden',
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyGardenSharePage()),
            ),
          ),
        IconButton(
          key: const ValueKey('garden-add'),
          tooltip: 'Add a plant',
          icon: const Icon(Icons.add),
          onPressed: _openAdd,
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : garden.isEmpty
        ? _Empty(accent: accent, onAdd: _openAdd, clock: widget.clock)
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              Reveal(child: _header()),
              ..._moments(context),
              const SizedBox(height: 22),
              Reveal(index: 1, child: _growing(context)),
              const SizedBox(height: 22),
              Reveal(index: 2, child: _map(context)),
              const SizedBox(height: 22),
              Reveal(
                index: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gardener path',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SkillLadder(
                      steps: _gardenerPath,
                      reached: garden.gardenerLevel(),
                    ),
                  ],
                ),
              ),
              ..._lessons(context),
            ],
          ),
  );

  Widget _header() {
    final growing = garden.growing.length;
    final firsts = garden.milestones().length;
    final gaveBack = garden.plantsThatGaveBack();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.category(accent),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _HeaderStat(value: growing, label: 'growing'),
          _HeaderStat(value: firsts, label: firsts == 1 ? 'first' : 'firsts'),
          _HeaderStat(value: gaveBack, label: 'flowered or fruited'),
        ],
      ),
    );
  }

  /// The monthly recap and "this day last year": only what was added.
  List<Widget> _moments(BuildContext context) {
    final recap = garden.recap(now);
    final lastYear = garden.onThisDayLastYear(now);
    final lines = [
      if (recap.newPlants > 0)
        recap.newPlants == 1 ? '1 new plant' : '${recap.newPlants} new plants',
      for (final (plant, moment) in recap.firsts.take(3))
        '${moment.firstLabel.toLowerCase()} from ${plant.name}',
      if (recap.harvests > 0)
        recap.harvests == 1 ? '1 harvest' : '${recap.harvests} harvests',
      if (recap.tendedDays > 0)
        recap.tendedDays == 1
            ? 'tended on 1 day'
            : 'tended on ${recap.tendedDays} days',
    ];
    return [
      if (lines.isNotEmpty) ...[
        const SizedBox(height: 14),
        _SoftCard(
          key: const ValueKey('garden-recap'),
          accent: accent,
          icon: Icons.auto_awesome_outlined,
          title: '${_months[now.month - 1]} in your garden',
          body: lines.join(' · '),
        ),
      ],
      if (lastYear.isNotEmpty) ...[
        const SizedBox(height: 10),
        _SoftCard(
          key: const ValueKey('garden-last-year'),
          accent: accent,
          icon: Icons.history,
          title: 'This day last year',
          body: [
            for (final (plant, log) in lastYear.take(2))
              '${log.moment.firstLabel}: ${plant.name}',
          ].join(' · '),
        ),
      ],
    ];
  }

  Widget _growing(BuildContext context) {
    final growing = garden.growing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Growing now', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Tap a plant for its story. Tend with one tap.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        if (growing.isEmpty)
          const Text(
            'Nothing growing right now. Whenever you are ready, add a plant.',
          ),
        for (final plant in growing)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlantTile(
              key: ValueKey('garden-plant-${plant.id}'),
              plant: plant,
              garden: garden,
              now: now,
              onOpen: () => _openPlant(plant),
            ),
          ),
      ],
    );
  }

  Widget _map(BuildContext context) {
    final counts = garden.typeCounts();
    final max = counts.values.fold(1, (a, b) => a > b ? a : b);
    final months = garden.activeMonths(now.year);
    // A gentle idea: a kind of plant they don't grow yet, that suits now.
    final knownIds = {for (final p in garden.plants.values) ?p.catalogueId};
    final ideaRaw = plantsForMonth(catalogue, now.month)
        .where(
          (p) =>
              !counts.containsKey(p['filter_group']) &&
              !knownIds.contains(p['id']),
        )
        .firstOrNull;
    final idea = ideaRaw == null ? null : Item.fromJson(ideaRaw);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your garden map', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'What you grow, by kind',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        for (final type in [
          ...gardenPlantTypes,
          if (counts.containsKey('Other')) 'Other',
        ])
          if (counts[type] case final count?)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      type,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: count / max,
                        minHeight: 10,
                        color: accent,
                        backgroundColor: accent.withValues(alpha: .12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$count'),
                ],
              ),
            ),
        const SizedBox(height: 12),
        Text(
          'Through ${now.year}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var m = 1; m <= 12; m++)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      key: ValueKey('garden-month-$m'),
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: months.contains(m)
                            ? accent
                            : accent.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _months[m - 1][0],
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (idea != null) ...[
          const SizedBox(height: 14),
          TactileScale(
            child: ActionChip(
              key: const ValueKey('garden-idea'),
              avatar: Icon(Icons.lightbulb_outline, size: 18, color: accent),
              label: Text(
                'New for ${_months[now.month - 1]}: ${idea.name}',
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () async {
                await MyGardenService.addCatalogue(idea);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${idea.name} is in your garden')),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _lessons(BuildContext context) {
    final lessons = garden.lessons;
    if (lessons.isEmpty) return const [];
    return [
      const SizedBox(height: 26),
      Text('Lessons learned', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      const Text(
        'Plants that taught you something. Every gardener has these.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 10),
      for (final plant in lessons)
        Card(
          key: ValueKey('garden-lesson-${plant.id}'),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: GardenPhoto(
              photoId: garden.coverPhotoFor(plant.id),
              size: 44,
              radius: 12,
            ),
            title: Text(plant.name),
            subtitle: Text(
              plant.lesson ?? 'Grown ${gardenDate(plant.addedAt)}',
            ),
            trailing: TextButton(
              onPressed: () async {
                final fresh = await MyGardenService.growAgain(plant.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('A fresh start for ${fresh.name}')),
                );
              },
              child: const Text('Grow again'),
            ),
            onTap: () => _openPlant(plant),
          ),
        ),
    ];
  }
}

class _PlantTile extends StatelessWidget {
  final GardenPlant plant;
  final MyGarden garden;
  final DateTime now;
  final VoidCallback onOpen;

  const _PlantTile({
    super.key,
    required this.plant,
    required this.garden,
    required this.now,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('garden');
    final firsts = garden.firstsFor(plant.id);
    final latest = [
      GardenMoment.harvested,
      GardenMoment.flowered,
      GardenMoment.sprouted,
      GardenMoment.sown,
    ].where(firsts.containsKey).firstOrNull;
    final tended = garden.tendedOn(plant.id, now);
    return TactileScale(
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                GardenPhoto(photoId: garden.coverPhotoFor(plant.id)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          ?plant.type,
                          latest == null
                              ? 'Since ${gardenDate(plant.addedAt)}'
                              : latest.firstLabel,
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: ValueKey('garden-tend-${plant.id}'),
                  tooltip: tended ? 'Tended today' : 'Tended today?',
                  isSelected: tended,
                  icon: Icon(Icons.water_drop_outlined, color: accent),
                  selectedIcon: Icon(Icons.water_drop, color: accent),
                  onPressed: () =>
                      logGardenMoment(context, plant, GardenMoment.tended),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final String body;

  const _SoftCard({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: .22)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(body, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      ],
    ),
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
          style: TextStyle(color: Colors.white.withValues(alpha: .9)),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  final Color accent;
  final VoidCallback onAdd;
  final DateTime Function()? clock;
  const _Empty({required this.accent, required this.onAdd, this.clock});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
    children: [
      Icon(Icons.yard_outlined, size: 64, color: accent),
      const SizedBox(height: 14),
      Text(
        'Start your garden',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'A pot of tulsi counts. Add what you grow, mark its firsts, and keep '
        'a record you will love looking back on. It stays private unless '
        'you share it.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, height: 1.4),
      ),
      const SizedBox(height: 18),
      Center(
        child: FilledButton.icon(
          key: const ValueKey('garden-empty-add'),
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add your first plant'),
        ),
      ),
      const SizedBox(height: 24),
      SowNowCard(clock: clock),
    ],
  );
}
