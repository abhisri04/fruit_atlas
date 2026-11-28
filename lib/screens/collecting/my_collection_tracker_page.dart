import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/my_collections_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

Color get _accent => AppColors.categoryAccent('collecting');

/// A photo of a collected thing, or a soft placeholder.
class CollectedPhoto extends StatelessWidget {
  final String? photoId;
  final double size;
  const CollectedPhoto({super.key, required this.photoId, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final empty = Container(
      width: size,
      height: size,
      color: _accent.withValues(alpha: .12),
      child: Icon(
        Icons.collections_bookmark_outlined,
        color: _accent,
        size: size * .35,
      ),
    );
    if (photoId == null) return empty;
    return FutureBuilder(
      future: MyCollectionsService.photo(photoId!),
      builder: (context, snap) => snap.data == null
          ? empty
          : Image.memory(
              snap.data!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
    );
  }
}

/// Someone's own collection: every piece, with an optional photo and note.
class MyCollectionTrackerPage extends StatefulWidget {
  final String typeId;
  final ImagePicker? picker;
  const MyCollectionTrackerPage({super.key, required this.typeId, this.picker});

  @override
  State<MyCollectionTrackerPage> createState() =>
      _MyCollectionTrackerPageState();
}

class _MyCollectionTrackerPageState extends State<MyCollectionTrackerPage> {
  MyCollection? collection;
  bool loading = true;

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
      collection = all[widget.typeId];
      loading = false;
    });
  }

  Future<void> _add() async {
    final c = collection;
    if (c == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddThingSheet(collection: c, picker: widget.picker),
    );
  }

  Future<void> _open(CollectedThing t) async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (t.photoId != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, c) => SizedBox(
                      height: 220,
                      width: c.maxWidth,
                      child: CollectedPhoto(
                        photoId: t.photoId,
                        size: c.maxWidth,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(t.name, style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Added ${_date(t.addedAt)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              if (t.note?.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Text(t.note!, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                key: const ValueKey('collection-thing-remove'),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove from collection'),
              ),
            ],
          ),
        ),
      ),
    );
    if (remove == true) {
      await MyCollectionsService.removeThing(widget.typeId, t.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = collection;
    if (loading || c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : const Text('This collection is not started yet.'),
        ),
      );
    }
    final things = [...c.things]
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return Scaffold(
      appBar: AppBar(title: Text('My ${c.name.toLowerCase()}')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('collection-add'),
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Reveal(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  AnimatedCount(
                    value: c.things.length,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${c.things.length == 1 ? 'piece' : 'pieces'} · '
                      'collecting since ${_date(c.startedAt)}',
                      key: const ValueKey('collection-count'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (things.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Add the first piece of your ${c.name.toLowerCase()}. A name '
                'is enough; a photo is a nice extra.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final size = (constraints.maxWidth - 20) / 3;
                return Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (final t in things)
                      SizedBox(
                        width: size,
                        child: TactileScale(
                          child: InkWell(
                            key: ValueKey('collection-thing-${t.id}'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _open(t),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CollectedPhoto(
                                    photoId: t.photoId,
                                    size: size,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AddThingSheet extends StatefulWidget {
  final MyCollection collection;
  final ImagePicker? picker;
  const _AddThingSheet({required this.collection, this.picker});

  @override
  State<_AddThingSheet> createState() => _AddThingSheetState();
}

class _AddThingSheetState extends State<_AddThingSheet> {
  final name = TextEditingController();
  final note = TextEditingController();
  Uint8List? photo;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await (widget.picker ?? ImagePicker()).pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => photo = bytes);
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await MyCollectionsService.addThing(
      widget.collection.typeId,
      name: name.text,
      note: note.text,
      photo: photo,
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
          'Add to your ${widget.collection.name.toLowerCase()}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('collection-thing-name'),
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What is it?'),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('collection-thing-note'),
          controller: note,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Where it came from, or why you love it (optional)',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (photo != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    photo!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(photo == null ? 'Add a photo' : 'Change photo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('collection-thing-save'),
            onPressed: name.text.trim().isEmpty || saving ? null : _save,
            child: const Text('Add to collection'),
          ),
        ),
      ],
    ),
  );
}
