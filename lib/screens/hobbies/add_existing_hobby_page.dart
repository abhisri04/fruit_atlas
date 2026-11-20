import 'package:flutter/material.dart';

import '../../models/hobby.dart';
import '../../services/hobby_journal_service.dart';
import '../../services/hobby_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/hobby_icon.dart';

const _levels = [
  ('Just tried it', 'I\'ve done it once or twice'),
  ('Learning', 'I\'m picking up the basics'),
  ('Practising', 'I do it regularly'),
  ('Confident', 'I\'m pretty good at it'),
];

/// Lets someone add a hobby they already do, from the catalogue or their
/// own, at their current level.
class AddExistingHobbyPage extends StatefulWidget {
  const AddExistingHobbyPage({super.key});

  @override
  State<AddExistingHobbyPage> createState() => _AddExistingHobbyPageState();
}

class _AddExistingHobbyPageState extends State<AddExistingHobbyPage> {
  List<Hobby> hobbies = [];
  String query = '';

  @override
  void initState() {
    super.initState();
    const HobbyRepository().load().then((loaded) {
      if (mounted) setState(() => hobbies = loaded);
    });
  }

  List<Hobby> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return hobbies;
    return hobbies
        .where(
          (h) =>
              h.name.toLowerCase().contains(q) ||
              h.title.toLowerCase().contains(q) ||
              (h.item.filterGroup ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  Future<int?> _chooseLevel(String name) => showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Where are you with $name?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final (index, level) in _levels.indexed)
            ListTile(
              key: ValueKey('level-$index'),
              leading: CircleAvatar(
                backgroundColor: AppColors.accentSurface,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              title: Text(level.$1),
              subtitle: Text(level.$2),
              onTap: () => Navigator.pop(context, index),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  Future<void> _add({
    required String id,
    required String name,
    String? group,
    bool custom = false,
  }) async {
    final level = await _chooseLevel(name);
    if (level == null || !mounted) return;
    await HobbyJournalService.addExisting(
      hobbyId: id,
      name: name,
      group: group,
      custom: custom,
      level: level,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$name added to My Hobbies')));
    Navigator.pop(context);
  }

  Future<void> _addCustom() async {
    final controller = TextEditingController(text: query.trim());
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add your own hobby'),
        content: TextField(
          key: const ValueKey('custom-hobby-name'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Guitar, Pottery'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('custom-hobby-next'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Next'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    final slug = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await _add(id: 'custom_$slug', name: trimmed, custom: true);
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Add a hobby')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const Text(
            'Already have a hobby? Add it to track sessions and progress.',
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('add-hobby-search'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search hobbies',
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              key: const ValueKey('add-custom-hobby'),
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Can\'t find it? Add your own'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _addCustom,
            ),
          ),
          for (final hobby in list)
            ListTile(
              key: ValueKey('add-${hobby.id}'),
              leading: Icon(
                hobbyGroupIcon(hobby.item.filterGroup),
                color: AppColors.categoryAccent('life_experiences'),
              ),
              title: Text(hobby.name),
              subtitle: Text(hobby.item.filterGroup ?? ''),
              trailing: const Icon(Icons.add),
              onTap: () => _add(
                id: hobby.id,
                name: hobby.name,
                group: hobby.item.filterGroup,
              ),
            ),
        ],
      ),
    );
  }
}
