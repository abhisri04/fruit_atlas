import 'package:flutter/material.dart';

import '../models/item.dart';
import '../screens/collecting/my_collection_tracker_page.dart';
import '../screens/scent/my_collection_page.dart';
import '../services/my_collections_service.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

/// On a "Start a Collection" page: start it, or open your collection.
/// Perfume goes to My Perfume Collection, which already does this well.
class StartCollectionButton extends StatefulWidget {
  final Item item;
  const StartCollectionButton({super.key, required this.item});

  @override
  State<StartCollectionButton> createState() => _StartCollectionButtonState();
}

class _StartCollectionButtonState extends State<StartCollectionButton> {
  MyCollection? mine;
  bool loaded = false;

  bool get perfume => widget.item.id == 'collect_perfumes';
  String get thing => widget.item.category ?? widget.item.name;

  @override
  void initState() {
    super.initState();
    MyCollectionsService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    MyCollectionsService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await MyCollectionsService.load();
    if (!mounted) return;
    setState(() {
      mine = all[widget.item.id];
      loaded = true;
    });
  }

  Future<void> _open() async {
    if (perfume) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyCollectionPage()),
      );
      return;
    }
    if (mine == null) await MyCollectionsService.start(widget.item.id, thing);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyCollectionTrackerPage(typeId: widget.item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const SizedBox(height: 56);
    final accent = AppColors.categoryAccent('collecting');
    final c = mine;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.collections_bookmark_outlined, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              perfume
                  ? 'Keep your perfumes on shelves in My Perfume Collection.'
                  : c == null
                  ? 'Keep track of your ${thing.toLowerCase()}, with photos.'
                  : 'My ${thing.toLowerCase()} · ${c.things.length} '
                        '${c.things.length == 1 ? 'piece' : 'pieces'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          TactileScale(
            child: FilledButton(
              key: const ValueKey('start-collection'),
              onPressed: _open,
              child: Text(perfume || c != null ? 'Open' : 'Start'),
            ),
          ),
        ],
      ),
    );
  }
}
