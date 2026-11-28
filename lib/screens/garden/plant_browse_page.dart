import 'package:flutter/material.dart';

import '../../models/garden_starter.dart';
import '../../models/item.dart';
import '../../theme/app_colors.dart';
import '../../widgets/my_garden_buttons.dart';
import '../../widgets/reveal.dart';
import '../challenge/checklist_item_details_page.dart';
import 'garden_sheets.dart';

/// One shelf of plants (Flowers, Herbs…), easiest first. "Easy only" is on by
/// default so beginners aren't overwhelmed.
class PlantBrowsePage extends StatefulWidget {
  final PlantShelf shelf;
  final DateTime Function()? clock;
  const PlantBrowsePage({super.key, required this.shelf, this.clock});

  @override
  State<PlantBrowsePage> createState() => _PlantBrowsePageState();
}

class _PlantBrowsePageState extends State<PlantBrowsePage> {
  List<Map<String, dynamic>> plants = [];
  bool easyOnly = false;
  bool loading = true;

  DateTime get now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    GardenCatalogue.raw().then((all) {
      if (!mounted) return;
      setState(() {
        plants = [
          for (final p in all)
            if (widget.shelf.types.contains(p['filter_group'])) p,
        ];
        loading = false;
      });
    });
  }

  Future<void> _open(Map<String, dynamic> raw) async {
    final challenge = await GardenCatalogue.plantsChallenge();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistItemDetailsPage(
          challenge: challenge,
          item: Item.fromJson(raw),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final month = now.month;
    int rank(Map<String, dynamic> p) =>
        (p['beginner'] == true ? 0 : 2) + (sowsIn(p, month) ? 0 : 1);
    final shown = [
      for (final p in plants)
        if (!easyOnly || p['beginner'] == true) p,
    ]..sort((a, b) => rank(a).compareTo(rank(b)));
    final shelf = widget.shelf;
    return Scaffold(
      appBar: AppBar(title: Text(shelf.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                Text(
                  '${plants.length} plants · easiest and in-season first',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    key: const ValueKey('browse-easy-only'),
                    label: const Text('Beginner-friendly only'),
                    selected: easyOnly,
                    onSelected: (v) => setState(() => easyOnly = v),
                  ),
                ),
                const SizedBox(height: 8),
                for (final (i, p) in shown.indexed)
                  Reveal(
                    index: i,
                    child: _PlantRow(
                      key: ValueKey('browse-${p['id']}'),
                      plant: p,
                      color: shelf.color,
                      inSeason: sowsIn(p, month),
                      onOpen: () => _open(p),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PlantRow extends StatelessWidget {
  final Map<String, dynamic> plant;
  final Color color;
  final bool inSeason;
  final VoidCallback onOpen;

  const _PlantRow({
    super.key,
    required this.plant,
    required this.color,
    required this.inSeason,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final meta = (plant['metadata'] as Map?) ?? const {};
    final tags = [
      if (plant['beginner'] == true) 'Beginner-friendly',
      if (inSeason && (plant['sow_months'] as List).length < 12) 'Start now',
      if (meta['Light'] case final String light) light,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    plantTypeIcon(plant['filter_group'] as String?),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plant['about'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tags.join(' · '),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AddPlantButton(item: Item.fromJson(plant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
