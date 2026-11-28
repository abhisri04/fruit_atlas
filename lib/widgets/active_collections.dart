import 'package:flutter/material.dart';

import '../screens/collecting/my_collection_tracker_page.dart';
import '../screens/making/my_makes_page.dart';
import '../services/my_collections_service.dart';
import '../services/my_makes_service.dart';
import '../services/my_garden_service.dart';
import '../services/scent_collection_service.dart';
import 'my_garden_buttons.dart';
import 'scent_shelf_buttons.dart';

/// On the Hobbies tab: the collections you've actually started (My Garden,
/// My Perfume Collection). Ones you haven't started live in their hubs, so
/// they aren't repeated here.
class ActiveCollections extends StatefulWidget {
  const ActiveCollections({super.key});

  @override
  State<ActiveCollections> createState() => _ActiveCollectionsState();
}

class _ActiveCollectionsState extends State<ActiveCollections> {
  bool garden = false;
  bool perfume = false;
  List<MyCollection> mine = [];
  int makes = 0;

  @override
  void initState() {
    super.initState();
    MyGardenService.changes.addListener(_load);
    ScentCollectionService.changes.addListener(_load);
    MyCollectionsService.changes.addListener(_load);
    MyMakesService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    MyGardenService.changes.removeListener(_load);
    ScentCollectionService.changes.removeListener(_load);
    MyCollectionsService.changes.removeListener(_load);
    MyMakesService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final g = !(await MyGardenService.load()).isEmpty;
    final p = !(await ScentCollectionService.load()).isEmpty;
    final m = (await MyCollectionsService.load()).values.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final k = (await MyMakesService.load()).length;
    if (!mounted) return;
    setState(() {
      garden = g;
      perfume = p;
      mine = m;
      makes = k;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!garden && !perfume && mine.isEmpty && makes == 0) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        if (perfume) const MyCollectionEntry(),
        if (perfume && garden) const SizedBox(height: 12),
        if (garden) const MyGardenEntry(),
        if (makes > 0) ...[
          const SizedBox(height: 12),
          Card(
            key: const ValueKey('active-makes'),
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.brush_outlined),
              title: const Text('My makes'),
              subtitle: Text('$makes ${makes == 1 ? 'project' : 'projects'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyMakesPage()),
              ),
            ),
          ),
        ],
        for (final c in mine) ...[
          const SizedBox(height: 12),
          Card(
            key: ValueKey('active-collection-${c.typeId}'),
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              title: Text('My ${c.name.toLowerCase()}'),
              subtitle: Text(
                '${c.owned.length} ${c.owned.length == 1 ? 'piece' : 'pieces'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyCollectionTrackerPage(typeId: c.typeId),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
