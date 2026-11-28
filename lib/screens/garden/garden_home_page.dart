import 'package:flutter/material.dart';

import '../../models/garden_starter.dart';
import '../../models/my_garden.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/asset_data_service.dart';
import '../../services/my_garden_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/my_garden_buttons.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import 'garden_basics_page.dart';
import 'garden_sheets.dart';
import 'garden_starter_page.dart';
import 'plant_browse_page.dart';
import 'sow_now_card.dart';

/// Garden & Plants, beginner first: start with three questions, browse by
/// what you'd love to grow, and keep your own garden.
class GardenHomePage extends StatefulWidget {
  final DateTime Function()? clock;
  const GardenHomePage({super.key, this.clock});

  @override
  State<GardenHomePage> createState() => _GardenHomePageState();
}

class _GardenHomePageState extends State<GardenHomePage> {
  StarterAnswers? answers;
  StarterSet? starter;
  MyGarden garden = const MyGarden();
  List<Map<String, dynamic>> plants = [];
  List<Map<String, dynamic>> ways = [];
  bool loading = true;

  DateTime get now => (widget.clock ?? DateTime.now)();
  Color get accent => AppColors.categoryAccent('garden');

  @override
  void initState() {
    super.initState();
    MyGardenService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    MyGardenService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = plants.isEmpty ? await GardenCatalogue.raw() : plants;
    final ideas = ways.isEmpty ? await GardenCatalogue.ways() : ways;
    final saved = await MyGardenService.starterAnswers();
    final loaded = await MyGardenService.load();
    if (!mounted) return;
    setState(() {
      plants = all;
      ways = ideas;
      answers = saved;
      starter = saved == null
          ? null
          : starterSet(all, saved, month: now.month, size: 3);
      garden = loaded;
      loading = false;
    });
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Garden & Plants')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              Reveal(child: _start(context)),
              const SizedBox(height: 14),
              const Reveal(index: 1, child: MyGardenEntry()),
              const SizedBox(height: 24),
              Text(
                'What would you like to grow?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Reveal(index: 2, child: _shelves()),
              const SizedBox(height: 20),
              Reveal(index: 3, child: SowNowCard(clock: widget.clock)),
              const SizedBox(height: 14),
              Reveal(
                index: 4,
                child: _LinkCard(
                  key: const ValueKey('garden-basics'),
                  icon: Icons.school_outlined,
                  title: 'Gardening basics',
                  subtitle: 'Pots, soil, watering and light, explained simply',
                  onTap: () => _push(const GardenBasicsPage()),
                ),
              ),
              if (ways.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'More ways to garden',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ideas to try once you have the basics.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 122,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ways.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) =>
                        _WayCard(way: ways[i], accent: accent),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _LinkCard(
                key: const ValueKey('garden-visits'),
                icon: Icons.park_outlined,
                title: 'Famous gardens to visit',
                subtitle: 'Each visit stamps your India Passport',
                onTap: () async {
                  final visits =
                      (await const AssetDataService().loadChallenges())
                          .where((c) => c.id == 'explore_garden_visits')
                          .firstOrNull;
                  if (visits != null && context.mounted) {
                    await openChallenge(context, visits);
                  }
                },
              ),
            ],
          ),
  );

  Widget _start(BuildContext context) {
    final set = starter;
    final hasStarted = answers != null && set != null;
    return Container(
      key: const ValueKey('garden-start'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.category(accent),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.yard_outlined, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            hasStarted ? 'Your starter plants' : 'New to plants? Start here',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasStarted
                ? 'Easy picks for ${answers!.space.label.toLowerCase()} '
                      'with ${answers!.light.label.toLowerCase()}.'
                : 'Answer 3 quick questions and get easy plants that suit '
                      'your space and light.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .92),
              height: 1.35,
            ),
          ),
          if (hasStarted) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final pick in set.picks)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white.withValues(alpha: .9),
                    side: BorderSide.none,
                    label: Text(pick.name),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TactileScale(
                child: FilledButton(
                  key: const ValueKey('garden-start-action'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: accent,
                  ),
                  onPressed: () => _push(
                    hasStarted
                        ? GardenStarterResultPage(clock: widget.clock)
                        : GardenStarterQuizPage(clock: widget.clock),
                  ),
                  child: Text(
                    hasStarted ? 'See my starter set' : 'Start gardening',
                  ),
                ),
              ),
              if (hasStarted)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () =>
                      _push(GardenStarterQuizPage(clock: widget.clock)),
                  child: const Text('Change answers'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shelves() => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final shelf in plantShelves)
            SizedBox(
              width: width,
              child: _ShelfTile(
                shelf: shelf,
                count: plants
                    .where((p) => shelf.types.contains(p['filter_group']))
                    .length,
                onTap: () =>
                    _push(PlantBrowsePage(shelf: shelf, clock: widget.clock)),
              ),
            ),
        ],
      );
    },
  );
}

class _ShelfTile extends StatelessWidget {
  final PlantShelf shelf;
  final int count;
  final VoidCallback onTap;
  const _ShelfTile({
    required this.shelf,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => TactileScale(
    child: Material(
      key: ValueKey('shelf-${shelf.id}'),
      color: shelf.color.withValues(alpha: .10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: shelf.color.withValues(alpha: .25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(shelf.icon, color: shelf.color, size: 28),
              const SizedBox(height: 10),
              Text(
                shelf.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${shelf.subtitle} · $count',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('garden');
    return TactileScale(
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: accent.withValues(alpha: .3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          leading: Icon(icon, color: accent),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(Icons.chevron_right, color: accent),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _WayCard extends StatelessWidget {
  final Map<String, dynamic> way;
  final Color accent;
  const _WayCard({required this.way, required this.accent});

  void _open(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final meta = (way['metadata'] as Map?) ?? const {};
      final steps = (way['howToSteps'] as List?)?.cast<String>() ?? const [];
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                way['name'] as String,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(way['about'] as String? ?? ''),
              const SizedBox(height: 12),
              for (final key in ['Space', 'Light', 'Good plants', 'First win'])
                if (meta[key] case final String value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$key: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: value),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 10),
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${i + 1}. $step'),
                ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    child: Material(
      key: ValueKey('way-${way['id']}'),
      color: accent.withValues(alpha: .07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: .2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: accent),
              const SizedBox(height: 8),
              Text(
                way['name'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                ((way['metadata'] as Map?)?['Space'] as String?) ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
