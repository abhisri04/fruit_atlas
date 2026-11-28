import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/my_makes_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String _time(int minutes) => minutes < 60
    ? '$minutes min'
    : '${minutes ~/ 60} h${minutes % 60 == 0 ? '' : ' ${minutes % 60} min'}';

Color get _accent => AppColors.categoryAccent('making');

class MakePhoto extends StatelessWidget {
  final String? photoId;
  final double width;
  final double height;
  const MakePhoto({
    super.key,
    required this.photoId,
    this.width = 96,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    final empty = Container(
      width: width,
      height: height,
      color: _accent.withValues(alpha: .12),
      child: Icon(Icons.brush_outlined, color: _accent, size: height * .35),
    );
    if (photoId == null) return empty;
    return FutureBuilder(
      future: MyMakesService.photo(photoId!),
      builder: (context, snap) => snap.data == null
          ? empty
          : Image.memory(
              snap.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
    );
  }
}

/// All your projects: what's on the go, and a gallery of what you've made.
class MyMakesPage extends StatefulWidget {
  const MyMakesPage({super.key});

  @override
  State<MyMakesPage> createState() => _MyMakesPageState();
}

class _MyMakesPageState extends State<MyMakesPage> {
  Map<String, MyMake>? makes;

  @override
  void initState() {
    super.initState();
    MyMakesService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    MyMakesService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await MyMakesService.load();
    if (mounted) setState(() => makes = all);
  }

  Future<void> _startOwn() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your own project'),
        content: TextField(
          key: const ValueKey('make-own-name'),
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Crochet a tote bag for Amma',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('make-own-start'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !mounted) return;
    final make = await MyMakesService.startCustom(name);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyMakePage(makeId: make.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = makes;
    final going = [
      for (final m in all?.values ?? const <MyMake>[])
        if (!m.finished) m,
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final done = [
      for (final m in all?.values ?? const <MyMake>[])
        if (m.finished) m,
    ]..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));
    return Scaffold(
      appBar: AppBar(title: const Text('My makes')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('make-own'),
        onPressed: _startOwn,
        icon: const Icon(Icons.add),
        label: const Text('Own project'),
      ),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                Text(
                  '${done.length} made · ${going.length} on the go · '
                  '${_time(all.values.fold(0, (s, m) => s + m.minutes))} spent making',
                  key: const ValueKey('makes-summary'),
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (going.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'On the go',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final m in going)
                    Card(
                      key: ValueKey('make-going-${m.id}'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: MakePhoto(
                            photoId: m.coverPhoto,
                            width: 48,
                            height: 48,
                          ),
                        ),
                        title: Text(m.name),
                        subtitle: Text(
                          'Started ${_date(m.startedAt)} · ${m.updates.length} '
                          '${m.updates.length == 1 ? 'update' : 'updates'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyMakePage(makeId: m.id),
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Text('Made', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (done.isEmpty)
                  const Text(
                    'Finished projects show here as a gallery you can look back on.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  LayoutBuilder(
                    builder: (context, c) {
                      final size = (c.maxWidth - 20) / 3;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 12,
                        children: [
                          for (final m in done)
                            SizedBox(
                              width: size,
                              child: InkWell(
                                key: ValueKey('make-done-${m.id}'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MyMakePage(makeId: m.id),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: MakePhoto(
                                        photoId: m.coverPhoto,
                                        width: size,
                                        height: size,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      m.name,
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
                        ],
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

/// One project: its progress photos and notes, time spent, and Finish.
class MyMakePage extends StatefulWidget {
  final String makeId;
  final ImagePicker? picker;
  const MyMakePage({super.key, required this.makeId, this.picker});

  @override
  State<MyMakePage> createState() => _MyMakePageState();
}

class _MyMakePageState extends State<MyMakePage> {
  MyMake? make;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    MyMakesService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    MyMakesService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await MyMakesService.load();
    if (!mounted) return;
    setState(() {
      make = all[widget.makeId];
      loading = false;
    });
  }

  Future<void> _addUpdate() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _UpdateSheet(makeId: widget.makeId, picker: widget.picker),
  );

  Future<void> _remove(MyMake m) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${m.name}?'),
        content: const Text('Its photos and notes are removed too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const ValueKey('make-remove-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await MyMakesService.remove(m.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = make;
    if (loading || m == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : const Text('This project is no longer here.'),
        ),
      );
    }
    final updates = m.updates.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(m.name),
        actions: [
          IconButton(
            tooltip: 'Remove project',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _remove(m),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('make-add-update'),
        onPressed: _addUpdate,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add progress'),
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
                  Text(
                    m.finished
                        ? 'Finished ${_date(m.finishedAt!)}'
                        : 'On the go since ${_date(m.startedAt)}',
                    key: const ValueKey('make-status'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${m.updates.length} '
                    '${m.updates.length == 1 ? 'update' : 'updates'} · '
                    '${_time(m.minutes)} spent',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  if (!m.finished) ...[
                    const SizedBox(height: 12),
                    TactileScale(
                      child: FilledButton.icon(
                        key: const ValueKey('make-finish'),
                        onPressed: () => MyMakesService.finish(m.id),
                        icon: const Icon(Icons.celebration_outlined),
                        label: const Text("It's finished!"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (updates.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Add progress as you go: a photo, a note, or the time you '
                'spent. Your first stitches are worth a photo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
          for (final u in updates)
            Padding(
              key: ValueKey('make-update-${u.id}'),
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      _date(u.at),
                      if (u.minutes != null) _time(u.minutes!),
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (u.note?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(u.note!, style: const TextStyle(height: 1.4)),
                  ],
                  if (u.photoId != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: MakePhoto(
                        photoId: u.photoId,
                        width: 220,
                        height: 220,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UpdateSheet extends StatefulWidget {
  final String makeId;
  final ImagePicker? picker;
  const _UpdateSheet({required this.makeId, this.picker});

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  final note = TextEditingController();
  int? minutes = 30;
  Uint8List? photo;
  bool saving = false;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final file = await (widget.picker ?? ImagePicker()).pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 72,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => photo = bytes);
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => saving = true);
    await MyMakesService.addUpdate(
      widget.makeId,
      note: note.text,
      minutes: minutes,
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
        Text('Add progress', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final value in [15, 30, 60, 120])
              ChoiceChip(
                key: ValueKey('make-minutes-$value'),
                label: Text(_time(value)),
                selected: minutes == value,
                onSelected: (_) => setState(() => minutes = value),
              ),
            ChoiceChip(
              label: const Text('Skip time'),
              selected: minutes == null,
              onSelected: (_) => setState(() => minutes = null),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('make-update-note'),
          controller: note,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'What did you do? (optional)',
          ),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('make-update-save'),
            onPressed: saving ? null : _save,
            child: const Text('Save progress'),
          ),
        ),
      ],
    ),
  );
}
