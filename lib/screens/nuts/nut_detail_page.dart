import 'package:flutter/material.dart';

import '../../models/nut.dart';
import '../../services/nut_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reward_animations.dart';
import 'nuts_page.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String nutDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Everything about one nut: where it's from, where it grows, how it tastes,
/// how to eat it, and your own tasting.
class NutDetailPage extends StatefulWidget {
  final String nutId;
  const NutDetailPage({super.key, required this.nutId});

  @override
  State<NutDetailPage> createState() => _NutDetailPageState();
}

class _NutDetailPageState extends State<NutDetailPage> {
  NutAtlas? atlas;
  NutTasting? tasting;
  bool tried = false;
  Set<String> triedKinds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await NutService.atlas();
    final ids = await NutService.triedIds();
    final t = (await NutService.tastings())[widget.nutId];
    final k = await NutService.triedKindIds();
    if (!mounted) return;
    setState(() {
      atlas = a;
      tried = ids.contains(widget.nutId);
      tasting = t;
      triedKinds = k;
    });
  }

  Future<void> _toggle() async {
    await NutService.setTried(widget.nutId, !tried);
    await _load();
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: tasting?.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Where did you try it?'),
        content: TextField(
          key: const ValueKey('nut-note-field'),
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: "e.g. Nani's kitchen, a market in Goa",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('nut-note-save'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (note == null) return;
    await NutService.setNote(widget.nutId, note);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final a = atlas;
    final nut = a?.byId(widget.nutId);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 48),
      body: a == null || nut == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Center(child: NutBadge(kind: nut.kind, size: 72)),
                const SizedBox(height: 14),
                Text(
                  nut.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (nut.aliases.isNotEmpty)
                  Text(
                    nut.aliases.join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  nut.scientificName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text(nut.kind)),
                    Chip(label: Text(nut.find)),
                    for (final t in nut.tastes) Chip(label: Text(t)),
                  ],
                ),
                const SizedBox(height: 14),
                _tastedCard(),
                const SizedBox(height: 20),
                Text(
                  nut.about,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 18),
                _section(
                  'First came from',
                  _flags(a, nut.native),
                  icon: Icons.history_edu_outlined,
                ),
                _section(
                  'Grown today in',
                  _flags(a, nut.grown),
                  icon: Icons.public,
                ),
                _section(
                  'In India',
                  Text(
                    nut.indiaStates.isNotEmpty
                        ? 'Grown in ${nut.indiaStates.join(', ')}.'
                        : nut.easyInIndia
                        ? 'Not grown here much, but you can find it: '
                              '${nut.find.toLowerCase()}.'
                        : 'Rare in India. One to look out for on your travels.',
                  ),
                  icon: Icons.location_on_outlined,
                ),
                _section('Taste', Text(nut.taste), icon: Icons.restaurant),
                _section(
                  'Ways to try it',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final w in nut.ways)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $w'),
                        ),
                    ],
                  ),
                  icon: Icons.lunch_dining_outlined,
                ),
                if (nut.kinds.isNotEmpty) _kindsSection(nut),
                if (nut.shopKinds case final kinds?)
                  _section(
                    'Kinds you will see in shops',
                    Text(kinds),
                    icon: Icons.storefront_outlined,
                  ),
                _section(
                  'Did you know?',
                  Text(nut.fact),
                  icon: Icons.lightbulb_outline,
                ),
                if (nut.safety case final safety?)
                  Container(
                    key: const ValueKey('nut-safety'),
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFB26A00),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(safety)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _kindsSection(Nut nut) {
    final done = nut.kinds.where((k) => triedKinds.contains(k.id)).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kinds you can buy',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$done of ${nut.kinds.length} tasted',
                key: const ValueKey('nut-kinds-count'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final k in nut.kinds)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: CheckboxListTile(
                key: ValueKey('nut-kind-${k.id}'),
                dense: true,
                value: triedKinds.contains(k.id),
                onChanged: (v) async {
                  await NutService.setKindTried(nut.id, k.id, v ?? false);
                  await _load();
                },
                title: Text(
                  [k.flag, k.name].whereType<String>().join('  '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  k.fromName == null
                      ? k.description
                      : '${k.description} From ${k.fromName}.',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tastedCard() => Card(
    child: Column(
      children: [
        TactileScale(
          child: CheckboxListTile(
            key: const ValueKey('nut-tried'),
            value: tried,
            onChanged: (_) => _toggle(),
            title: Text(
              tried ? 'Tasted' : 'I tasted this',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              tried && tasting != null
                  ? 'First tasted ${nutDate(tasting!.at)}'
                  : 'One tap adds it to your nut passport.',
            ),
          ),
        ),
        if (tried)
          ListTile(
            key: const ValueKey('nut-note'),
            dense: true,
            leading: const Icon(Icons.edit_note),
            title: Text(
              tasting?.note?.isNotEmpty == true
                  ? tasting!.note!
                  : 'Add where you tried it (optional)',
            ),
            onTap: _editNote,
          ),
      ],
    ),
  );

  Widget _flags(NutAtlas a, List<String> codes) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final code in codes)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline),
          ),
          child: Text('${a.country(code).flag} ${a.country(code).name}'),
        ),
    ],
  );

  Widget _section(String title, Widget body, {required IconData icon}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  body,
                ],
              ),
            ),
          ],
        ),
      );
}
