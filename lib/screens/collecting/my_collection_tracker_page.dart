import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Someone's own collection: what they have, what they want, favourites,
/// and an optional set to complete.
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
  bool showWishlist = false;

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
      builder: (_) => _AddThingSheet(
        collection: c,
        wanted: showWishlist,
        picker: widget.picker,
      ),
    );
  }

  Future<void> _setGoal() async {
    final c = collection;
    if (c == null) return;
    final controller = TextEditingController(text: c.goal?.toString() ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('A set to complete'),
        content: TextField(
          key: const ValueKey('collection-goal-field'),
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'e.g. 50 ${c.name.toLowerCase()}',
            helperText: 'Leave empty for no goal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('collection-goal-save'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await MyCollectionsService.setGoal(widget.typeId, int.tryParse(value));
  }

  Future<void> _open(CollectedThing t) async {
    final action = await showModalBottomSheet<String>(
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
                [
                  t.wanted ? 'On your wishlist' : 'Added ${_date(t.addedAt)}',
                  ?t.source,
                ].join(' · '),
                style: const TextStyle(color: AppColors.muted),
              ),
              if (t.note?.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Text(t.note!, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 12),
              if (t.wanted)
                FilledButton.icon(
                  key: const ValueKey('collection-thing-got'),
                  onPressed: () => Navigator.pop(context, 'got'),
                  icon: const Icon(Icons.celebration_outlined),
                  label: const Text('Got it!'),
                )
              else
                TextButton.icon(
                  key: const ValueKey('collection-thing-favourite'),
                  onPressed: () => Navigator.pop(context, 'favourite'),
                  icon: Icon(t.favourite ? Icons.star : Icons.star_border),
                  label: Text(
                    t.favourite
                        ? 'Remove from favourites'
                        : 'Mark as favourite',
                  ),
                ),
              TextButton.icon(
                key: const ValueKey('collection-thing-remove'),
                onPressed: () => Navigator.pop(context, 'remove'),
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  t.wanted ? 'Remove from wishlist' : 'Remove from collection',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case 'got':
        await MyCollectionsService.gotIt(widget.typeId, t.id);
      case 'favourite':
        await MyCollectionsService.toggleFavourite(widget.typeId, t.id);
      case 'remove':
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
    final owned = c.owned
      ..sort((a, b) {
        if (a.favourite != b.favourite) return a.favourite ? -1 : 1;
        return b.addedAt.compareTo(a.addedAt);
      });
    final wishlist = c.wishlist..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    final shown = showWishlist ? wishlist : owned;
    final noun = c.name.toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: Text('My $noun'),
        actions: [
          IconButton(
            key: const ValueKey('collection-goal'),
            tooltip: 'Set a goal',
            icon: const Icon(Icons.flag_outlined),
            onPressed: _setGoal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('collection-add'),
        onPressed: _add,
        icon: Icon(showWishlist ? Icons.favorite_border : Icons.add),
        label: Text(showWishlist ? 'Add a want' : 'Add'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedCount(
                        value: owned.length,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${owned.length == 1 ? 'piece' : 'pieces'} · '
                          'collecting since ${_date(c.startedAt)}',
                          key: const ValueKey('collection-count'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (c.goal case final goal?) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (owned.length / goal).clamp(0.0, 1.0),
                        minHeight: 8,
                        color: _accent,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owned.length >= goal
                          ? 'Set complete: $goal of $goal'
                          : '${owned.length} of $goal towards your set',
                      key: const ValueKey('collection-goal-progress'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            key: const ValueKey('collection-tabs'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text('Have (${owned.length})'),
              ),
              ButtonSegment(
                value: true,
                label: Text('Want (${wishlist.length})'),
              ),
            ],
            selected: {showWishlist},
            onSelectionChanged: (v) => setState(() => showWishlist = v.first),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                showWishlist
                    ? 'Keep a wishlist of $noun you hope to find. Tap "Got '
                          'it!" when one arrives.'
                    : 'Add the first piece of your $noun. A name is enough; '
                          'a photo is a nice extra.',
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
                    for (final t in shown)
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
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Opacity(
                                        opacity: t.wanted ? .55 : 1,
                                        child: CollectedPhoto(
                                          photoId: t.photoId,
                                          size: size,
                                        ),
                                      ),
                                    ),
                                    if (t.favourite)
                                      const Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Icon(
                                          Icons.star,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                  ],
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
  final bool wanted;
  final ImagePicker? picker;
  const _AddThingSheet({
    required this.collection,
    required this.wanted,
    this.picker,
  });

  @override
  State<_AddThingSheet> createState() => _AddThingSheetState();
}

class _AddThingSheetState extends State<_AddThingSheet> {
  final name = TextEditingController();
  final note = TextEditingController();
  Uint8List? photo;
  String? source;
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
      wanted: widget.wanted,
      source: widget.wanted ? null : source,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final noun = widget.collection.name.toLowerCase();
    return Padding(
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
            widget.wanted ? 'Add to your $noun wishlist' : 'Add to your $noun',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('collection-thing-name'),
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: widget.wanted
                  ? 'What are you looking for?'
                  : 'What is it?',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('collection-thing-note'),
            controller: note,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'A note: where, when, why you love it (optional)',
            ),
          ),
          if (!widget.wanted) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final s in CollectedThing.sources)
                  ChoiceChip(
                    key: ValueKey('collection-source-$s'),
                    label: Text(s),
                    selected: source == s,
                    onSelected: (_) =>
                        setState(() => source = source == s ? null : s),
                  ),
              ],
            ),
          ],
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
              child: Text(
                widget.wanted ? 'Add to wishlist' : 'Add to collection',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
