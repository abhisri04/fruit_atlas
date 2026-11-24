import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/my_garden.dart';
import '../../services/my_garden_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import 'garden_sheets.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String gardenDate(DateTime d) =>
    '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

/// The one-tap moments, in the order a plant's life usually goes.
const gardenQuickMoments = [
  GardenMoment.tended,
  GardenMoment.sown,
  GardenMoment.sprouted,
  GardenMoment.flowered,
  GardenMoment.harvested,
];

/// One plant's story: its photo, firsts, one-tap moments and timeline.
class GardenPlantPage extends StatefulWidget {
  final String plantId;
  final ImagePicker? picker;
  const GardenPlantPage({super.key, required this.plantId, this.picker});

  @override
  State<GardenPlantPage> createState() => _GardenPlantPageState();
}

class _GardenPlantPageState extends State<GardenPlantPage> {
  MyGarden garden = const MyGarden();
  bool loading = true;

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
    if (mounted) {
      setState(() {
        garden = loaded;
        loading = false;
      });
    }
  }

  String _buttonLabel(GardenPlant plant, GardenMoment moment) =>
      switch (moment) {
        GardenMoment.tended =>
          garden.tendedOn(plant.id, DateTime.now())
              ? 'Tended today ✓'
              : 'Tended today',
        GardenMoment.harvested =>
          garden.has(plant.id, moment) ? 'Harvested again' : 'First harvest',
        _ => garden.has(plant.id, moment) ? '${moment.label} ✓' : moment.label,
      };

  Future<void> _more(GardenPlant plant) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (plant.growing)
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Let it go'),
                subtitle: const Text('Move it to Lessons learned'),
                onTap: () => Navigator.pop(context, 'letgo'),
              )
            else
              ListTile(
                leading: const Icon(Icons.replay),
                title: const Text('Grow it again'),
                subtitle: const Text(
                  'Start a fresh story with what you learned',
                ),
                onTap: () => Navigator.pop(context, 'again'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove from My Garden'),
              subtitle: const Text('Only for plants added by mistake'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'letgo':
        await showLetGoSheet(context, plant);
      case 'again':
        final fresh = await MyGardenService.growAgain(plant.id);
        if (!mounted) return;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GardenPlantPage(plantId: fresh.id)),
        );
      case 'remove':
        final sure = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Remove ${plant.name}?'),
            content: const Text(
              'This deletes its record and photos. If the plant didn\'t make '
              'it, "Let it go" keeps its story instead.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (sure != true) return;
        await MyGardenService.remove(plant.id);
        if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = garden.plants[widget.plantId];
    if (loading || plant == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : const Text('This plant is no longer in your garden.'),
        ),
      );
    }
    final firsts = garden.firstsFor(plant.id);
    final timeline = garden.logsFor(plant.id).reversed.toList();
    final harvests = garden.harvestsFor(plant.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          IconButton(
            key: const ValueKey('garden-plant-more'),
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onPressed: () => _more(plant),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          Reveal(
            child: Row(
              children: [
                GardenPhoto(
                  photoId: garden.coverPhotoFor(plant.id),
                  size: 96,
                  radius: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          ?plant.type,
                          'Since ${gardenDate(plant.addedAt)}',
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      if (harvests > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          harvests == 1 ? '1 harvest' : '$harvests harvests',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!plant.growing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.caution,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                [
                  'In Lessons learned since '
                      '${gardenDate(plant.letGoAt ?? plant.addedAt)}.',
                  if (plant.lesson != null) 'You noted: ${plant.lesson}.',
                ].join(' '),
                style: const TextStyle(height: 1.4),
              ),
            ),
          ],
          if (plant.growing) ...[
            const SizedBox(height: 20),
            Text(
              'Log a moment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'One tap. You can add a photo after.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final moment in gardenQuickMoments)
                  TactileScale(
                    child: ActionChip(
                      key: ValueKey('garden-log-${moment.name}'),
                      avatar: Icon(
                        gardenMomentIcon(moment),
                        size: 18,
                        color: accent,
                      ),
                      label: Text(_buttonLabel(plant, moment)),
                      onPressed: () => logGardenMoment(
                        context,
                        plant,
                        moment,
                        picker: widget.picker,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Firsts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final moment in [
                GardenMoment.sown,
                GardenMoment.sprouted,
                GardenMoment.flowered,
                GardenMoment.harvested,
              ])
                if (firsts[moment] case final at?)
                  Chip(
                    avatar: Icon(
                      gardenMomentIcon(moment),
                      size: 18,
                      color: accent,
                    ),
                    label: Text('${moment.firstLabel} · ${gardenDate(at)}'),
                  ),
              if (!firsts.keys.any(
                (m) => m != GardenMoment.added && m != GardenMoment.tended,
              ))
                const Text(
                  'Your firsts will show here: sown, first sprout, first '
                  'flower, first harvest.',
                  style: TextStyle(color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Story so far', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final log in timeline)
            _TimelineRow(
              key: ValueKey('garden-timeline-${log.id}'),
              log: log,
              first: firsts[log.moment] == log.at,
              accent: accent,
              onAddPhoto: log.photoId == null
                  ? () => addGardenPhoto(
                      ScaffoldMessenger.of(context),
                      log,
                      picker: widget.picker,
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final GardenLog log;
  final bool first;
  final Color accent;
  final VoidCallback? onAddPhoto;

  const _TimelineRow({
    super.key,
    required this.log,
    required this.first,
    required this.accent,
    this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final label = first ? log.moment.firstLabel : log.moment.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(gardenMomentIcon(log.moment), size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  gardenDate(log.at),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                if (log.photoId != null) ...[
                  const SizedBox(height: 8),
                  GardenPhoto(photoId: log.photoId, size: 160, radius: 16),
                ],
              ],
            ),
          ),
          if (onAddPhoto != null)
            IconButton(
              tooltip: 'Add a photo',
              icon: const Icon(Icons.add_a_photo_outlined, size: 20),
              color: AppColors.muted,
              onPressed: onAddPhoto,
            ),
        ],
      ),
    );
  }
}
