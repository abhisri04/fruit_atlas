import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../models/scent_collection.dart';
import '../../services/scent_collection_service.dart';
import '../../theme/app_colors.dart';

const _occasions = [
  'Everyday',
  'Work',
  'Evening',
  'Date',
  'Festival',
  'Special occasion',
];

/// "Wore it today" with an optional occasion and note.
Future<void> showWearSheet(BuildContext context, ScentEntry entry) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WearSheet(entry: entry),
    );

class _WearSheet extends StatefulWidget {
  final ScentEntry entry;
  const _WearSheet({required this.entry});

  @override
  State<_WearSheet> createState() => _WearSheetState();
}

class _WearSheetState extends State<_WearSheet> {
  String? occasion = 'Everyday';
  final note = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await ScentCollectionService.logWear(
      widget.entry.id,
      occasion: occasion,
      note: note.text,
    );
    if (mounted) Navigator.pop(context);
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
          'Wearing ${widget.entry.name} today',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in _occasions)
              ChoiceChip(
                label: Text(value),
                selected: occasion == value,
                onSelected: (_) =>
                    setState(() => occasion = occasion == value ? null : value),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: note,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'How did it feel? Any compliments? (optional)',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('wear-save'),
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Wore it today'),
          ),
        ),
      ],
    ),
  );
}

/// Pick a shelf (and format) for a catalogue perfume or attar.
Future<ScentShelf?> showShelfPicker(
  BuildContext context, {
  required String name,
  ScentShelf? current,
}) => showModalBottomSheet<ScentShelf>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(name, style: Theme.of(context).textTheme.titleLarge),
        ),
        for (final (shelf, icon, hint) in const [
          (
            ScentShelf.own,
            Icons.inventory_2_outlined,
            'A bottle, decant, sample or attar you have',
          ),
          (
            ScentShelf.tried,
            Icons.check_circle_outline,
            'Smelled or worn, but not yours',
          ),
          (
            ScentShelf.wantToSmell,
            Icons.bookmark_border,
            'On your list to smell next',
          ),
        ])
          ListTile(
            key: ValueKey('shelf-${shelf.name}'),
            leading: Icon(icon, color: AppColors.categoryAccent('scent')),
            title: Text(shelf.label),
            subtitle: Text(hint),
            trailing: current == shelf
                ? const Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () => Navigator.pop(context, shelf),
          ),
        const SizedBox(height: 8),
      ],
    ),
  ),
);

/// Search the catalogue (or add your own) and put it on a shelf.
class AddToCollectionPage extends StatefulWidget {
  final ScentShelf? initialShelf;
  const AddToCollectionPage({super.key, this.initialShelf});

  @override
  State<AddToCollectionPage> createState() => _AddToCollectionPageState();
}

class _AddToCollectionPageState extends State<AddToCollectionPage> {
  ScentCatalogue? catalogue;
  String query = '';

  @override
  void initState() {
    super.initState();
    ScentCatalogue.load().then((loaded) {
      if (mounted) setState(() => catalogue = loaded);
    });
  }

  List<Item> get results {
    final all = catalogue?.all ?? const <Item>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (item) =>
              item.name.toLowerCase().contains(q) ||
              (item.category ?? '').toLowerCase().contains(q) ||
              (ScentCatalogue.familyOf(item) ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _add(Item item) async {
    final shelf =
        widget.initialShelf ?? await showShelfPicker(context, name: item.name);
    if (shelf == null) return;
    await ScentCollectionService.addItem(item, shelf);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added to ${shelf.label}')));
    Navigator.pop(context);
  }

  Future<void> _addCustom() async {
    final families = catalogue?.families ?? const <String>[];
    final name = TextEditingController(text: query.trim());
    final maker = TextEditingController();
    String? family;
    var format = ScentFormat.bottle;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add your own'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey('custom-perfume-name'),
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: maker,
                  decoration: const InputDecoration(
                    labelText: 'Made by (optional)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: family,
                  decoration: const InputDecoration(
                    labelText: 'Scent family (optional)',
                  ),
                  items: [
                    for (final f in families)
                      DropdownMenuItem(value: f, child: Text(f)),
                  ],
                  onChanged: (value) => setDialogState(() => family = value),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final f in ScentFormat.values)
                      ChoiceChip(
                        label: Text(f.label),
                        selected: format == f,
                        onSelected: (_) => setDialogState(() => format = f),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('custom-perfume-next'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
    final trimmed = name.text.trim();
    final makerText = maker.text.trim();
    name.dispose();
    maker.dispose();
    if (ok != true || trimmed.isEmpty || !mounted) return;
    final shelf =
        widget.initialShelf ?? await showShelfPicker(context, name: trimmed);
    if (shelf == null) return;
    final slug = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await ScentCollectionService.add(
      ScentEntry(
        id: 'custom_${slug}_${DateTime.now().millisecondsSinceEpoch}',
        name: trimmed,
        maker: makerText.isEmpty ? null : makerText,
        family: family,
        shelf: shelf,
        format: format,
        addedAt: DateTime.now(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final list = results;
    return Scaffold(
      appBar: AppBar(title: const Text('Add to collection')),
      body: catalogue == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                TextField(
                  key: const ValueKey('collection-search'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search perfumes, attars or families',
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    key: const ValueKey('collection-add-custom'),
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Not listed? Add your own'),
                    subtitle: const Text(
                      'Any perfume, deodorant, attar or sample',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _addCustom,
                  ),
                ),
                for (final item in list)
                  ListTile(
                    key: ValueKey('collection-add-${item.id}'),
                    leading: Icon(
                      item.id.startsWith('attar_')
                          ? Icons.water_drop_outlined
                          : Icons.local_florist_outlined,
                      color: AppColors.categoryAccent('scent'),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      [
                        if (!item.id.startsWith('attar_')) item.category,
                        ScentCatalogue.familyOf(item),
                      ].whereType<String>().join(' · '),
                    ),
                    trailing: const Icon(Icons.add),
                    onTap: () => _add(item),
                  ),
              ],
            ),
    );
  }
}
