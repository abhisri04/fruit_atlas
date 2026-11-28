import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/scent_collection.dart';
import '../screens/scent/my_collection_page.dart';
import '../services/scent_collection_service.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

/// On a perfume or attar page: put it on a shelf of My Collection.
class ScentShelfButtons extends StatefulWidget {
  final Item item;
  const ScentShelfButtons({super.key, required this.item});

  @override
  State<ScentShelfButtons> createState() => _ScentShelfButtonsState();
}

class _ScentShelfButtonsState extends State<ScentShelfButtons> {
  ScentShelf? current;

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
    final collection = await ScentCollectionService.load();
    if (mounted) {
      setState(() => current = collection.entries[widget.item.id]?.shelf);
    }
  }

  Future<void> _pick(ScentShelf shelf) async {
    await ScentCollectionService.addItem(widget.item, shelf);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('In My Collection: ${shelf.label}'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyCollectionPage()),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('scent');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: accent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'My Collection',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (current != null)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCollectionPage()),
                  ),
                  child: const Text('Open'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final shelf in ScentShelf.values)
                TactileScale(
                  child: ChoiceChip(
                    key: ValueKey('shelf-chip-${shelf.name}'),
                    label: Text(shelf.label),
                    selected: current == shelf,
                    onSelected: (_) => _pick(shelf),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Entry card to My Collection, for the Hobbies tab and Scent pages.
class MyCollectionEntry extends StatelessWidget {
  const MyCollectionEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('scent');
    return TactileScale(
      child: Material(
        key: const ValueKey('my-collection-entry'),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accent.withValues(alpha: .35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCollectionPage()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.local_florist_outlined, color: accent),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Perfume Collection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your shelves, wear diary and scent map.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
