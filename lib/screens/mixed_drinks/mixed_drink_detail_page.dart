import 'package:flutter/material.dart';

import '../../models/mixed_drink.dart';
import '../../services/drink_mix_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reward_animations.dart';
import 'mix_widgets.dart';

/// One drink: the recipe for as many glasses as you need, where it's from,
/// how to make it zero-proof, and your own "made it".
class MixedDrinkDetailPage extends StatefulWidget {
  final String drinkId;
  const MixedDrinkDetailPage({super.key, required this.drinkId});

  @override
  State<MixedDrinkDetailPage> createState() => _MixedDrinkDetailPageState();
}

class _MixedDrinkDetailPageState extends State<MixedDrinkDetailPage> {
  DrinkBook? book;
  DrinkMade? record;
  bool made = false;
  Set<String> shelf = {};
  int glasses = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await DrinkMixService.book();
    final ids = await DrinkMixService.madeIds();
    final r = (await DrinkMixService.made())[widget.drinkId];
    final s = await DrinkMixService.shelf();
    if (!mounted) return;
    setState(() {
      book = b;
      made = ids.contains(widget.drinkId);
      record = r;
      shelf = s;
    });
  }

  Future<void> _toggle() async {
    await DrinkMixService.setMade(widget.drinkId, !made);
    await _load();
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: record?.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Who was it for?'),
        content: TextField(
          key: const ValueKey('drink-note-field'),
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(
            hintText: 'e.g. Sunday brunch, for Maa, Diwali party',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('drink-note-save'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (note == null) return;
    await DrinkMixService.setNote(widget.drinkId, note);
    await _load();
  }

  Future<void> _make(MixedDrink d) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MakeModePage(drink: d, glasses: glasses),
      ),
    );
    if (done == true && !made) await _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final b = book;
    final d = b?.byId(widget.drinkId);
    return Scaffold(
      appBar: AppBar(toolbarHeight: 48),
      body: b == null || d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                Center(child: DrinkBadge(drink: d, size: 72)),
                const SizedBox(height: 14),
                Text(
                  d.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (d.aliases.isNotEmpty)
                  Text(
                    d.aliases.join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${b.country(d.country).flag}  From ${b.country(d.country).name}',
                  key: const ValueKey('drink-origin'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Chip(label: Text(d.type)),
                    Chip(label: Text(d.method)),
                    Chip(label: Text('${d.minutes} min')),
                    for (final f in d.flavours) Chip(label: Text(f)),
                  ],
                ),
                const SizedBox(height: 14),
                _madeCard(),
                const SizedBox(height: 18),
                Text(
                  d.about,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                if (d.isCocktail) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Contains alcohol. For adults of legal drinking age. '
                    'Never drink and drive.',
                    key: ValueKey('drink-responsible'),
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 18),
                _ingredients(b, d),
                _section(
                  'How to make it',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (n, s) in d.steps.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${n + 1}. $s'),
                        ),
                      if (d.glass.isNotEmpty)
                        Text(
                          'Glass: ${d.glass}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                    ],
                  ),
                  icon: Icons.format_list_numbered,
                ),
                if (d.garnish.isNotEmpty)
                  _section(
                    'Garnish',
                    Text(d.garnish),
                    icon: Icons.local_florist_outlined,
                  ),
                if (d.zeroProof case final zero?)
                  Container(
                    key: const ValueKey('drink-zero'),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DrinkBadge.mocktailColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.local_drink_outlined,
                          color: DrinkBadge.mocktailColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Make it zero-proof',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(zero),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                _section(
                  'Did you know?',
                  Text(d.fact),
                  icon: Icons.lightbulb_outline,
                ),
                if (d.safety case final safety?)
                  Container(
                    key: const ValueKey('drink-safety'),
                    margin: const EdgeInsets.only(bottom: 16),
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
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('drink-make'),
                  onPressed: () => _make(d),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start making'),
                ),
              ],
            ),
    );
  }

  Widget _ingredients(DrinkBook b, MixedDrink d) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.shopping_basket_outlined,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'You need',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              key: const ValueKey('drink-glasses-minus'),
              tooltip: 'Fewer glasses',
              visualDensity: VisualDensity.compact,
              onPressed: glasses > 1 ? () => setState(() => glasses--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$glasses ${glasses == 1 ? 'glass' : 'glasses'}',
              key: const ValueKey('drink-glasses'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              key: const ValueKey('drink-glasses-plus'),
              tooltip: 'More glasses',
              visualDensity: VisualDensity.compact,
              onPressed: glasses < 12 ? () => setState(() => glasses++) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const Text(
          'Tap what you have. It is remembered for What can I make?',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        for (final (n, line) in d.ingredients.indexed) _ingredientRow(line, n),
      ],
    ),
  );

  Widget _ingredientRow(RecipeLine line, int index) {
    final have = shelf.contains(line.ingredientId);
    return InkWell(
      key: ValueKey('drink-ing-$index'),
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        await DrinkMixService.setOnShelf(line.ingredientId, !have);
        await _load();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              have ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: have ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                line.optional
                    ? '${line.format(glasses)} (optional)'
                    : line.format(glasses),
                style: TextStyle(
                  color: line.optional ? AppColors.muted : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _madeCard() => Card(
    child: Column(
      children: [
        TactileScale(
          child: CheckboxListTile(
            key: const ValueKey('drink-made'),
            value: made,
            onChanged: (_) => _toggle(),
            title: Text(
              made ? 'Made it' : 'I made this',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              made && record != null
                  ? 'First made ${mixDate(record!.at)}'
                  : 'One tap adds it to your mix book.',
            ),
          ),
        ),
        if (made)
          ListTile(
            key: const ValueKey('drink-note'),
            dense: true,
            leading: const Icon(Icons.edit_note),
            title: Text(
              record?.note?.isNotEmpty == true
                  ? record!.note!
                  : 'Add who it was for (optional)',
            ),
            onTap: _editNote,
          ),
      ],
    ),
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

/// Big, one-step-at-a-time instructions to follow while you mix.
class MakeModePage extends StatefulWidget {
  final MixedDrink drink;
  final int glasses;
  const MakeModePage({super.key, required this.drink, this.glasses = 1});

  @override
  State<MakeModePage> createState() => _MakeModePageState();
}

class _MakeModePageState extends State<MakeModePage> {
  int step = 0;

  int get last => widget.drink.steps.length + 1;

  @override
  Widget build(BuildContext context) {
    final d = widget.drink;
    final Widget body;
    if (step == 0) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get ready', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'For ${widget.glasses} '
            '${widget.glasses == 1 ? 'glass' : 'glasses'} · ${d.glass}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          for (final l in d.ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• ${l.format(widget.glasses)}${l.optional ? ' (optional)' : ''}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          const Text('• Ice', style: TextStyle(fontSize: 18)),
        ],
      );
    } else if (step < last) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $step of ${d.steps.length}',
            key: const ValueKey('drink-step-label'),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Text(
            d.steps[step - 1],
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (step == d.steps.length && d.garnish.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Garnish: ${d.garnish}',
              style: const TextStyle(fontSize: 16, color: AppColors.muted),
            ),
          ],
        ],
      );
    } else {
      body = Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.celebration_outlined, size: 64),
          const SizedBox(height: 14),
          Text(
            'Cheers!',
            key: const ValueKey('drink-cheers'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${d.name} is ready.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              LinearProgressIndicator(value: step / last),
              const SizedBox(height: 24),
              Expanded(child: SingleChildScrollView(child: body)),
              Row(
                children: [
                  if (step > 0)
                    TextButton(
                      onPressed: () => setState(() => step--),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (step < last)
                    FilledButton(
                      key: const ValueKey('drink-step-next'),
                      onPressed: () => setState(() => step++),
                      child: Text(step == 0 ? "Let's go" : 'Next'),
                    )
                  else
                    FilledButton.icon(
                      key: const ValueKey('drink-make-done'),
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Add to my mix book'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
