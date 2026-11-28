import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/my_garden.dart';
import '../screens/garden/garden_plant_page.dart';
import '../screens/garden/my_garden_page.dart';
import '../services/my_garden_service.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

Color get _accent => AppColors.categoryAccent('garden');

/// On a Plants to Grow page: add it to My Garden, or open its story.
class GrowThisButton extends StatefulWidget {
  final Item item;
  const GrowThisButton({super.key, required this.item});

  @override
  State<GrowThisButton> createState() => _GrowThisButtonState();
}

class _GrowThisButtonState extends State<GrowThisButton> {
  GardenPlant? growing;
  bool loaded = false;

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
    final garden = await MyGardenService.load();
    if (!mounted) return;
    setState(() {
      growing = garden.growing
          .where((p) => p.catalogueId == widget.item.id)
          .firstOrNull;
      loaded = true;
    });
  }

  Future<void> _add() async {
    final plant = await MyGardenService.addCatalogue(widget.item);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${plant.name} is in My Garden'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GardenPlantPage(plantId: plant.id),
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const SizedBox(height: 56);
    final plant = growing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.yard_outlined, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              plant == null
                  ? 'Want to grow it? Add it to My Garden to track it.'
                  : 'Growing in My Garden',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          TactileScale(
            child: plant == null
                ? FilledButton(
                    key: const ValueKey('grow-this'),
                    onPressed: _add,
                    child: const Text('Add to my garden'),
                  )
                : OutlinedButton(
                    key: const ValueKey('grow-this-open'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GardenPlantPage(plantId: plant.id),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Entry card to My Garden, for the Garden hub and My Hobbies.
class MyGardenEntry extends StatelessWidget {
  const MyGardenEntry({super.key});

  @override
  Widget build(BuildContext context) => TactileScale(
    child: Material(
      key: const ValueKey('my-garden-entry'),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _accent.withValues(alpha: .35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyGardenPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.yard_outlined, color: _accent),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Garden',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your plants, their firsts and what you learned.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _accent),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A compact "Add" for plant lists; shows "Growing" once it's in My Garden.
class AddPlantButton extends StatefulWidget {
  final Item item;
  const AddPlantButton({super.key, required this.item});

  @override
  State<AddPlantButton> createState() => _AddPlantButtonState();
}

class _AddPlantButtonState extends State<AddPlantButton> {
  GardenPlant? growing;
  bool busy = false;

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
    final garden = await MyGardenService.load();
    if (!mounted) return;
    setState(
      () => growing = garden.growing
          .where((p) => p.catalogueId == widget.item.id)
          .firstOrNull,
    );
  }

  Future<void> _add() async {
    setState(() => busy = true);
    final plant = await MyGardenService.addCatalogue(widget.item);
    if (!mounted) return;
    setState(() => busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${plant.name} is in My Garden'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GardenPlantPage(plantId: plant.id),
              ),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final plant = growing;
    if (plant != null) {
      return TextButton.icon(
        key: ValueKey('add-plant-growing-${widget.item.id}'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GardenPlantPage(plantId: plant.id)),
        ),
        icon: Icon(Icons.check_circle, color: _accent, size: 18),
        label: const Text('Growing'),
      );
    }
    return TactileScale(
      child: FilledButton.tonalIcon(
        key: ValueKey('add-plant-${widget.item.id}'),
        onPressed: busy ? null : _add,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add'),
      ),
    );
  }
}
