import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/india_location_registry.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String tripDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]} ${d.year}';

/// "12–15 Nov 2026" style range.
String tripRange(Trip t) {
  final s = t.start;
  final e = t.end;
  if (t.days == 1) return tripDate(s);
  if (s.year == e.year && s.month == e.month) {
    return '${s.day}–${e.day} ${_monthNames[s.month - 1]} ${s.year}';
  }
  if (s.year == e.year) {
    return '${s.day} ${_monthNames[s.month - 1]} – ${tripDate(e)}';
  }
  return '${tripDate(s)} – ${tripDate(e)}';
}

/// Add or edit a trip. Only "where" is needed; everything else is optional,
/// so logging takes seconds.
class TripEditPage extends StatefulWidget {
  final Trip? trip;
  final List<String> initialStates;
  final DateTime Function()? clock;
  final ImagePicker? picker;

  const TripEditPage({
    super.key,
    this.trip,
    this.initialStates = const [],
    this.clock,
    this.picker,
  });

  @override
  State<TripEditPage> createState() => _TripEditPageState();
}

class _TripEditPageState extends State<TripEditPage> {
  late final List<String> states = [
    ...?widget.trip?.stateIds,
    if (widget.trip == null) ...widget.initialStates,
  ];
  late DateTime start =
      widget.trip?.start ?? _day((widget.clock ?? DateTime.now)());
  late int days = widget.trip?.days ?? 1;
  late final title = TextEditingController(text: widget.trip?.title ?? '');
  late final note = TextEditingController(text: widget.trip?.note ?? '');
  late final companions = TextEditingController(
    text: widget.trip?.companions ?? '',
  );
  final search = TextEditingController();
  Uint8List? photo;
  bool saving = false;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    title.dispose();
    note.dispose();
    companions.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = (widget.clock ?? DateTime.now)();
    final picked = await showDatePicker(
      context: context,
      initialDate: start.isAfter(now) ? now : start,
      firstDate: DateTime(1950),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'When did the trip start?',
    );
    if (picked != null) setState(() => start = _day(picked));
  }

  Future<void> _pickPhoto() async {
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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add that photo.')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (states.isEmpty) return;
    setState(() => saving = true);
    final name = title.text.trim().isEmpty
        ? Trip.defaultTitle(states)
        : title.text.trim();
    final trip =
        (widget.trip ??
                Trip(
                  id: TripService.newId(),
                  title: name,
                  stateIds: states,
                  start: start,
                ))
            .copyWith(
              title: name,
              stateIds: List.of(states),
              start: start,
              days: days,
              note: note.text.trim(),
              companions: companions.text.trim(),
            );
    try {
      await TripService.save(trip, photo: photo);
      if (mounted) Navigator.pop(context, trip.id);
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.trim().toLowerCase();
    final matches = q.isEmpty
        ? const <IndiaLocation>[]
        : IndiaLocationRegistry.locations
              .where(
                (l) =>
                    l.name.toLowerCase().contains(q) && !states.contains(l.id),
              )
              .take(6)
              .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip == null ? 'Add a trip' : 'Edit trip'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            key: const ValueKey('trip-save'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: states.isEmpty || saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(
              states.isEmpty
                  ? 'Pick at least one place'
                  : (widget.trip == null ? 'Save trip' : 'Save changes'),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Where did you go?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in states)
                InputChip(
                  key: ValueKey('trip-state-$id'),
                  label: Text(IndiaLocationRegistry.nameFor(id)),
                  onDeleted: () => setState(() => states.remove(id)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('trip-search'),
            controller: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Add a state or UT',
            ),
          ),
          for (final l in matches)
            ListTile(
              key: ValueKey('trip-add-${l.id}'),
              dense: true,
              leading: const Icon(Icons.add_location_alt_outlined),
              title: Text(l.name),
              onTap: () => setState(() {
                states.add(l.id);
                search.clear();
              }),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('trip-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(tripDate(start)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                key: const ValueKey('trip-days-less'),
                tooltip: 'Fewer days',
                onPressed: days > 1 ? () => setState(() => days--) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  days == 1 ? '1 day' : '$days days',
                  key: const ValueKey('trip-days'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.outlined(
                key: const ValueKey('trip-days-more'),
                tooltip: 'More days',
                onPressed: days < 365 ? () => setState(() => days++) : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Optional',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('trip-title'),
            controller: title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Trip name',
              hintText: Trip.defaultTitle(states),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('trip-companions'),
            controller: companions,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Who with?',
              hintText: 'Family, friends, solo…',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('trip-note'),
            controller: note,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'A memory to keep',
              hintText: 'The best thing you ate, saw or did',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (photo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      photo!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              TextButton.icon(
                key: const ValueKey('trip-photo'),
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  photo != null || widget.trip?.photoId != null
                      ? 'Change photo'
                      : 'Add a photo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Saving stamps these places in your India Passport. Trips stay on '
            'your phone unless you share them.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
