import 'package:flutter/material.dart';

import '../../models/experience.dart';
import '../../models/india_location_registry.dart';
import '../../models/state_travel_status.dart';
import '../../models/travel_theme.dart';
import '../../services/experience_repository.dart';
import '../../services/progress_service.dart';
import '../../services/state_travel_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/experience_tile.dart';
import '../../widgets/reward_animations.dart';
import '../dishes/indian_dishes_page.dart';
import '../experience/experience_details_page.dart';

/// Which part of India to show for a theme.
enum ThemeScope { all, wishList, beenThere, newPlaces }

extension on ThemeScope {
  String get label => switch (this) {
    ThemeScope.all => 'All India',
    ThemeScope.wishList => 'On my wish list',
    ThemeScope.beenThere => "Where I've been",
    ThemeScope.newPlaces => 'Somewhere new',
  };
}

/// The eight theme tiles, for Things to do.
class TravelThemeGrid extends StatelessWidget {
  const TravelThemeGrid({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 520 ? 4 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final theme in TravelTheme.values)
            SizedBox(
              width: width,
              child: TactileScale(
                child: Material(
                  key: ValueKey('theme-${theme.name}'),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.color.withValues(alpha: .35)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TravelThemePage(theme: theme),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(theme.icon, color: theme.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              theme.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Every experience in India for one theme, grouped by state, and
/// filterable by your passport: your wish list, where you've been, or
/// somewhere new.
class TravelThemePage extends StatefulWidget {
  final TravelTheme theme;
  final StateTravelService? travelService;
  const TravelThemePage({super.key, required this.theme, this.travelService});

  @override
  State<TravelThemePage> createState() => _TravelThemePageState();
}

class _TravelThemePageState extends State<TravelThemePage> {
  late final travel = widget.travelService ?? StateTravelService();
  List<Experience>? experiences;
  Set<String> done = {};
  ThemeScope scope = ThemeScope.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    if (widget.travelService == null) travel.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await const ExperienceRepository().loadExperiences();
    final completed = await ProgressService.getCompletedExperienceIds();
    await travel.load();
    if (!mounted) return;
    setState(() {
      experiences = [
        for (final e in all)
          if (widget.theme.matches(e)) e,
      ];
      done = completed;
    });
  }

  bool _inScope(Experience e) {
    final status = travel.statusFor(e.stateId);
    return switch (scope) {
      ThemeScope.all => true,
      ThemeScope.wishList => status == TravelStatus.wantToVisit,
      ThemeScope.beenThere => status == TravelStatus.visited,
      ThemeScope.newPlaces => status != TravelStatus.visited,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final all = experiences;
    final shown = all == null ? const <Experience>[] : all.where(_inScope);
    final byState = <String, List<Experience>>{};
    for (final e in shown) {
      byState.putIfAbsent(e.stateId, () => []).add(e);
    }
    final states = byState.keys.toList()
      ..sort(
        (a, b) =>
            IndiaLocationRegistry.nameFor(a)
                .compareTo(IndiaLocationRegistry.nameFor(b)),
      );
    final rows = <Widget>[];
    for (final id in states) {
      final list = byState[id]!;
      rows.add(
        Padding(
          key: ValueKey('theme-state-$id'),
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  IndiaLocationRegistry.nameFor(id),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (travel.statusFor(id) == TravelStatus.visited)
                const Icon(
                  Icons.verified,
                  size: 18,
                  color: AppColors.passportVisited,
                )
              else if (travel.statusFor(id) == TravelStatus.wantToVisit)
                const Icon(
                  Icons.favorite,
                  size: 18,
                  color: AppColors.passportWanted,
                ),
              const SizedBox(width: 6),
              Text(
                '${list.where((e) => done.contains(e.id)).length}/${list.length}',
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
      for (final e in list) {
        rows.add(
          ExperienceTile(
            key: ValueKey('theme-exp-${e.id}'),
            experience: e,
            completed: done.contains(e.id),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExperienceDetailsPage(experience: e),
                ),
              );
              _load();
            },
            onCompletionChanged: (_) async {
              await ProgressService.toggleExperience(e.id);
              _load();
            },
          ),
        );
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(theme.label)),
      body: all == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(theme.icon, color: theme.color, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme.subtitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${all.where((e) => done.contains(e.id)).length} '
                              'of ${all.length} explored · across '
                              '${{for (final e in all) e.stateId}.length} '
                              'states & UTs',
                              key: const ValueKey('theme-count'),
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in ThemeScope.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey('theme-scope-${s.name}'),
                            label: Text(s.label),
                            selected: scope == s,
                            onSelected: (_) => setState(() => scope = s),
                          ),
                        ),
                    ],
                  ),
                ),
                if (theme == TravelTheme.food) ...[
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      key: const ValueKey('theme-dishes'),
                      leading: Icon(Icons.restaurant, color: theme.color),
                      title: const Text('Taste India at home too'),
                      subtitle: const Text('640 Indian dishes to try'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IndianDishesPage(),
                        ),
                      ),
                    ),
                  ),
                ],
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      switch (scope) {
                        ThemeScope.wishList =>
                          'Nothing here yet. Add states to your wish list on '
                              'the India Passport map.',
                        ThemeScope.beenThere =>
                          'Stamp states on your India Passport to see '
                              '${theme.label.toLowerCase()} where you have been.',
                        _ => 'Nothing to show here yet.',
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                ...rows,
              ],
            ),
    );
  }
}
