import 'package:flutter/material.dart';

import '../../models/garden_starter.dart';
import '../../models/item.dart';
import '../../services/my_garden_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/my_garden_buttons.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../challenge/checklist_item_details_page.dart';
import 'garden_basics_page.dart';
import 'garden_sheets.dart';

Color get _accent => AppColors.categoryAccent('garden');

IconData _spaceIcon(GardenSpace s) => switch (s) {
  GardenSpace.windowsill => Icons.window_outlined,
  GardenSpace.balcony => Icons.balcony_outlined,
  GardenSpace.terrace => Icons.roofing_outlined,
  GardenSpace.ground => Icons.grass_outlined,
  GardenSpace.indoors => Icons.chair_outlined,
};

IconData _lightIcon(GardenLight l) => switch (l) {
  GardenLight.sun => Icons.wb_sunny_outlined,
  GardenLight.some => Icons.wb_cloudy_outlined,
  GardenLight.low => Icons.nightlight_outlined,
};

IconData _wishIcon(GardenWish w) => switch (w) {
  GardenWish.flowers => Icons.local_florist_outlined,
  GardenWish.food => Icons.restaurant_outlined,
  GardenWish.herbs => Icons.spa_outlined,
  GardenWish.greenery => Icons.eco_outlined,
  GardenWish.lowCare => Icons.favorite_outline,
};

/// Three quick questions, then the starter set.
class GardenStarterQuizPage extends StatefulWidget {
  final DateTime Function()? clock;
  const GardenStarterQuizPage({super.key, this.clock});

  @override
  State<GardenStarterQuizPage> createState() => _GardenStarterQuizPageState();
}

class _GardenStarterQuizPageState extends State<GardenStarterQuizPage> {
  int step = 0;
  GardenSpace? space;
  GardenLight? light;

  Future<void> _finish(GardenWish wish) async {
    final answers = StarterAnswers(space: space!, light: light!, wish: wish);
    await MyGardenService.saveStarterAnswers(answers);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GardenStarterResultPage(clock: widget.clock),
      ),
    );
  }

  Widget _option({
    required Key key,
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TactileScale(
      child: Material(
        key: key,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final (title, options) = switch (step) {
      0 => (
        'Where will your plants live?',
        [
          for (final s in GardenSpace.values)
            _option(
              key: ValueKey('starter-space-${s.name}'),
              icon: _spaceIcon(s),
              label: s.label,
              hint: s.hint,
              onTap: () => setState(() {
                space = s;
                step = 1;
              }),
            ),
        ],
      ),
      1 => (
        'How much light does it get?',
        [
          for (final l in GardenLight.values)
            _option(
              key: ValueKey('starter-light-${l.name}'),
              icon: _lightIcon(l),
              label: l.label,
              hint: l.hint,
              onTap: () => setState(() {
                light = l;
                step = 2;
              }),
            ),
        ],
      ),
      _ => (
        'What would you love to grow?',
        [
          for (final w in GardenWish.values)
            _option(
              key: ValueKey('starter-wish-${w.name}'),
              icon: _wishIcon(w),
              label: w.label,
              hint: w.hint,
              onTap: () => _finish(w),
            ),
        ],
      ),
    };
    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => step--);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Start gardening')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i <= step
                            ? _accent
                            : _accent.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${step + 1} of 3',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey(step),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  ...options,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The starter set for the saved answers: easy plants that suit you, how to
/// set up your space, and the basics to read first.
class GardenStarterResultPage extends StatefulWidget {
  final DateTime Function()? clock;
  const GardenStarterResultPage({super.key, this.clock});

  @override
  State<GardenStarterResultPage> createState() =>
      _GardenStarterResultPageState();
}

class _GardenStarterResultPageState extends State<GardenStarterResultPage> {
  StarterAnswers? answers;
  StarterSet? set;
  bool loading = true;

  DateTime get now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await MyGardenService.starterAnswers();
    final plants = await GardenCatalogue.raw();
    if (!mounted) return;
    setState(() {
      answers = saved;
      set = saved == null ? null : starterSet(plants, saved, month: now.month);
      loading = false;
    });
  }

  Future<void> _open(Map<String, dynamic> raw) async {
    final challenge = await GardenCatalogue.plantsChallenge();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistItemDetailsPage(
          challenge: challenge,
          item: Item.fromJson(raw),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = answers;
    final s = set;
    return Scaffold(
      appBar: AppBar(title: const Text('Your starter plants')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : a == null || s == null
          ? Center(
              child: FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GardenStarterQuizPage(clock: widget.clock),
                  ),
                ),
                child: const Text('Answer 3 quick questions'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                Reveal(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (icon, label) in [
                        (_spaceIcon(a.space), a.space.label),
                        (_lightIcon(a.light), a.light.label),
                        (_wishIcon(a.wish), a.wish.label),
                      ])
                        Chip(
                          avatar: Icon(icon, size: 18, color: _accent),
                          label: Text(label),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Start with these',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Easy plants that suit your space. One or two is a great '
                  'start.',
                  style: TextStyle(color: AppColors.muted),
                ),
                if (s.note != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const ValueKey('starter-note'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.information,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(s.note!, style: const TextStyle(height: 1.4)),
                  ),
                ],
                const SizedBox(height: 12),
                for (final (i, pick) in s.picks.indexed)
                  Reveal(
                    index: i + 1,
                    child: _PickCard(
                      key: ValueKey('starter-pick-${pick.id}'),
                      pick: pick,
                      onOpen: () => _open(pick.plant),
                    ),
                  ),
                const SizedBox(height: 18),
                _Section(
                  icon: _spaceIcon(a.space),
                  title: 'Set up ${a.space.label.toLowerCase()}',
                  steps: a.space.setup,
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: Icons.school_outlined,
                  title: 'Three things every beginner should know',
                  steps: const [
                    'Use pots with drainage holes. Roots hate sitting in water.',
                    'Water only when the top inch of soil feels dry. Too much '
                        'water kills more plants than too little.',
                    'Most flowers and vegetables want 4+ hours of direct sun.',
                  ],
                  footer: TextButton(
                    key: const ValueKey('starter-basics'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GardenBasicsPage(),
                      ),
                    ),
                    child: const Text('All gardening basics →'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    key: const ValueKey('starter-redo'),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            GardenStarterQuizPage(clock: widget.clock),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Change my answers'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final StarterPick pick;
  final VoidCallback onOpen;
  const _PickCard({super.key, required this.pick, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final meta = (pick.plant['metadata'] as Map?) ?? const {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      plantTypeIcon(pick.plant['filter_group'] as String?),
                      color: _accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pick.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            [
                              pick.plant['filter_group'],
                              meta['First reward'],
                            ].whereType<String>().join(' · '),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    AddPlantButton(item: Item.fromJson(pick.plant)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  pick.plant['about'] as String? ?? '',
                  style: const TextStyle(height: 1.35),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final reason in pick.reasons) _Tag(label: reason),
                    if (!pick.matchesWish) const _Tag(label: 'Also suits you'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: _accent,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> steps;
  final Widget? footer;
  const _Section({
    required this.icon,
    required this.title,
    required this.steps,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _accent.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _accent.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final (i, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(step, style: const TextStyle(height: 1.35)),
                ),
              ],
            ),
          ),
        ?footer,
      ],
    ),
  );
}
