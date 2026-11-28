import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/challenge.dart';
import '../../models/item.dart';
import '../../models/my_garden.dart';
import '../../services/asset_data_service.dart';
import '../../services/my_garden_service.dart';
import '../../theme/app_colors.dart';

Color get _accent => AppColors.categoryAccent('garden');

/// Plants to Grow, for adding to My Garden.
abstract final class GardenCatalogue {
  static Future<List<Map<String, dynamic>>>? _cache;

  /// The raw catalogue, which keeps `sow_months`.
  static Future<List<Map<String, dynamic>>> raw() =>
      _cache ??= _load().catchError((Object error) {
        _cache = null;
        throw error;
      });

  static Future<Challenge>? _plantsChallenge;
  static Future<Challenge>? _skillsChallenge;

  /// The Plants to Grow collection, for opening plant pages.
  static Future<Challenge> plantsChallenge() =>
      _plantsChallenge ??= _challenge('explore_garden_plants');

  /// The Garden Skills collection, for the basics guide.
  static Future<Challenge> skillsChallenge() =>
      _skillsChallenge ??= _challenge('explore_garden_skills');

  static Future<Challenge> _challenge(String id) async =>
      (await const AssetDataService().loadChallenges()).firstWhere(
        (c) => c.id == id,
      );

  static Future<List<Map<String, dynamic>>>? _ways;

  /// Ideas for other ways to garden (not tracked).
  static Future<List<Map<String, dynamic>>> ways() => _ways ??= () async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/data/garden_ways.json'),
    ) as Map<String, dynamic>;
    return (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  }();

  static Future<List<Item>> plants() async =>
      (await raw()).map(Item.fromJson).toList(growable: false);

  static Future<List<Map<String, dynamic>>> _load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/data/garden_plants.json'),
    ) as Map<String, dynamic>;
    return (json['items'] as List<dynamic>).cast<Map<String, dynamic>>().toList(
      growable: false,
    );
  }
}

/// Icon for a moment, used on buttons and in the timeline.
IconData gardenMomentIcon(GardenMoment moment) => switch (moment) {
  GardenMoment.added => Icons.add_circle_outline,
  GardenMoment.sown => Icons.grain,
  GardenMoment.sprouted => Icons.spa_outlined,
  GardenMoment.flowered => Icons.local_florist_outlined,
  GardenMoment.harvested => Icons.shopping_basket_outlined,
  GardenMoment.tended => Icons.water_drop_outlined,
};

/// One tap logs the moment. A snackbar then offers an optional photo, so
/// logging never waits on one.
Future<GardenLog?> logGardenMoment(
  BuildContext context,
  GardenPlant plant,
  GardenMoment moment, {
  ImagePicker? picker,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final log = await MyGardenService.log(plant.id, moment);
  final text = log == null
      ? switch (moment) {
          GardenMoment.tended => 'Already tended today. Nice care.',
          _ => '${moment.firstLabel} is already in the record.',
        }
      : switch (moment) {
          GardenMoment.tended => 'Tended ${plant.name} today',
          GardenMoment.harvested => 'Harvest from ${plant.name} logged',
          _ => '${moment.firstLabel}: ${plant.name}',
        };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        action: log == null
            ? null
            : SnackBarAction(
                label: 'Add photo',
                onPressed: () => addGardenPhoto(messenger, log, picker: picker),
              ),
      ),
    );
  return log;
}

/// Picks an optional photo for a log. Kept small so it fits on the device.
Future<void> addGardenPhoto(
  ScaffoldMessengerState messenger,
  GardenLog log, {
  ImagePicker? picker,
  ImageSource source = ImageSource.gallery,
}) async {
  try {
    final file = await (picker ?? ImagePicker()).pickImage(
      source: source,
      maxWidth: 900,
      maxHeight: 900,
      imageQuality: 70,
    );
    if (file == null) return;
    await MyGardenService.attachPhoto(log.id, await file.readAsBytes());
    messenger.showSnackBar(const SnackBar(content: Text('Photo added')));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not add that photo. Your moment is still saved.'),
      ),
    );
  }
}

/// A stored garden photo, or a soft placeholder.
class GardenPhoto extends StatelessWidget {
  final String? photoId;
  final double size;

  /// Defaults to [size] (square).
  final double? height;
  final double radius;
  final IconData placeholder;

  const GardenPhoto({
    super.key,
    required this.photoId,
    this.size = 56,
    this.height,
    this.radius = 14,
    this.placeholder = Icons.eco_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? size;
    final empty = Container(
      width: size,
      height: h,
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(placeholder, color: _accent, size: size * .45),
    );
    if (photoId == null) return empty;
    return FutureBuilder(
      future: MyGardenService.photo(photoId!),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return empty;
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            bytes,
            width: size,
            height: h,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => empty,
          ),
        );
      },
    );
  }
}

/// "Let it go": a kind way to close a plant's story, with an optional lesson.
Future<bool> showLetGoSheet(BuildContext context, GardenPlant plant) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LetGoSheet(plant: plant),
    ) ??
    false;

class _LetGoSheet extends StatefulWidget {
  final GardenPlant plant;
  const _LetGoSheet({required this.plant});

  @override
  State<_LetGoSheet> createState() => _LetGoSheetState();
}

class _LetGoSheetState extends State<_LetGoSheet> {
  String? reason;
  final note = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final lesson = [
      ?reason,
      if (note.text.trim().isNotEmpty) note.text.trim(),
    ].join('. ');
    await MyGardenService.letGo(widget.plant.id, lesson: lesson);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Let ${widget.plant.name} go',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Every gardener loses plants. Its story stays in your record, '
          'and what you learned goes with you to the next one.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 14),
        const Text(
          'What do you think happened? (optional)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in gardenLessons)
              ChoiceChip(
                label: Text(value),
                selected: reason == value,
                onSelected: (_) =>
                    setState(() => reason = reason == value ? null : value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Anything to remember next time? (optional)',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('let-go-save'),
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.favorite_outline),
            label: const Text('Move to Lessons learned'),
          ),
        ),
      ],
    ),
  );
}

/// Add a plant: search Plants to Grow, or add any plant by name.
class AddGardenPlantPage extends StatefulWidget {
  const AddGardenPlantPage({super.key});

  @override
  State<AddGardenPlantPage> createState() => _AddGardenPlantPageState();
}

class _AddGardenPlantPageState extends State<AddGardenPlantPage> {
  final query = TextEditingController();
  List<Item> plants = [];
  String? type;

  @override
  void initState() {
    super.initState();
    GardenCatalogue.plants().then((value) {
      if (mounted) setState(() => plants = value);
    });
    query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> _added(String name) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$name is in your garden')));
    Navigator.pop(context, true);
  }

  Future<void> _addCustom() async {
    final name = query.text.trim();
    if (name.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What kind of plant is $name?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in gardenPlantTypes)
                    ActionChip(
                      label: Text(t),
                      onPressed: () => Navigator.pop(context, t),
                    ),
                  ActionChip(
                    label: const Text('Not sure'),
                    onPressed: () => Navigator.pop(context, ''),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    await MyGardenService.addCustom(name, type: picked.isEmpty ? null : picked);
    await _added(name);
  }

  @override
  Widget build(BuildContext context) {
    final q = query.text.trim().toLowerCase();
    final matches = plants
        .where(
          (p) =>
              (type == null || p.filterGroup == type) &&
              (q.isEmpty || p.name.toLowerCase().contains(q)),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Add to My Garden')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          TextField(
            key: const ValueKey('garden-add-search'),
            controller: query,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search plants, or type any plant',
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in [null, ...gardenPlantTypes])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t ?? 'All'),
                      selected: type == t,
                      onSelected: (_) => setState(() => type = t),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (q.isNotEmpty)
            ListTile(
              key: const ValueKey('garden-add-custom'),
              leading: Icon(Icons.add, color: _accent),
              title: Text('Add "${query.text.trim()}"'),
              subtitle: const Text('Any plant counts, even one from a friend'),
              onTap: _addCustom,
            ),
          for (final plant in matches)
            ListTile(
              key: ValueKey('garden-add-${plant.id}'),
              leading: Icon(Icons.eco_outlined, color: _accent),
              title: Text(plant.name),
              subtitle: Text(
                [
                  plant.filterGroup,
                  plant.metadata['Ease'],
                ].whereType<String>().join(' · '),
              ),
              trailing: const Icon(Icons.add_circle_outline),
              onTap: () async {
                await MyGardenService.addCatalogue(plant);
                await _added(plant.name);
              },
            ),
        ],
      ),
    );
  }
}

/// Icon for a plant type.
IconData plantTypeIcon(String? type) => switch (type) {
  'Flowers' => Icons.local_florist_outlined,
  'Vegetables' => Icons.restaurant_outlined,
  'Herbs' => Icons.spa_outlined,
  'Houseplants' => Icons.chair_outlined,
  'Succulents & Cacti' => Icons.filter_vintage_outlined,
  'Fruit' => Icons.apple_outlined,
  'Trees' => Icons.park_outlined,
  _ => Icons.eco_outlined,
};

/// The browse tiles: what people want, not botanical groups.
class PlantShelf {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> types;

  const PlantShelf({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.types,
  });
}

const plantShelves = [
  PlantShelf(
    id: 'flowers',
    title: 'Flowers',
    subtitle: 'Colour and scent',
    icon: Icons.local_florist_outlined,
    color: Color(0xFFD9467A),
    types: ['Flowers'],
  ),
  PlantShelf(
    id: 'food',
    title: 'Grow your food',
    subtitle: 'Vegetables to pick',
    icon: Icons.restaurant_outlined,
    color: Color(0xFFE07A1F),
    types: ['Vegetables'],
  ),
  PlantShelf(
    id: 'herbs',
    title: 'Herbs',
    subtitle: 'For tea and tadka',
    icon: Icons.spa_outlined,
    color: Color(0xFF3E8E4F),
    types: ['Herbs'],
  ),
  PlantShelf(
    id: 'indoor',
    title: 'Indoor plants',
    subtitle: 'Green for any room',
    icon: Icons.chair_outlined,
    color: Color(0xFF2F7D7A),
    types: ['Houseplants'],
  ),
  PlantShelf(
    id: 'succulents',
    title: 'Succulents & cacti',
    subtitle: 'Hard to kill',
    icon: Icons.filter_vintage_outlined,
    color: Color(0xFF7A8F3A),
    types: ['Succulents & Cacti'],
  ),
  PlantShelf(
    id: 'fruit_trees',
    title: 'Fruit & trees',
    subtitle: 'Grow something big',
    icon: Icons.park_outlined,
    color: Color(0xFF6B5B3E),
    types: ['Fruit', 'Trees'],
  ),
];
