import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/challenge.dart';
import '../../models/hobby.dart';
import '../../models/hobby_preferences.dart';
import '../../services/asset_data_service.dart';
import '../../services/hobby_matcher.dart';
import '../../services/hobby_preferences_service.dart';
import '../../services/hobby_repository.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/hobby_icon.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../challenge/checklist_item_details_page.dart';
import 'hobby_quiz_page.dart';

/// Helps people choose a hobby: personal matches, quick filters and a
/// "Pick for me" suggestion that learns from "Not for me".
class HobbyFinderPage extends StatefulWidget {
  final Random? random;

  const HobbyFinderPage({super.key, this.random});

  @override
  State<HobbyFinderPage> createState() => _HobbyFinderPageState();
}

class _HobbyFinderPageState extends State<HobbyFinderPage> {
  static const _matcher = HobbyMatcher();

  List<Hobby> hobbies = [];
  Challenge? challenge;
  HobbyPreferences? prefs;
  Set<String> tried = {};
  Set<String> skipped = {};
  HobbyFilters filters = const HobbyFilters();
  HobbyMatch? pick;
  bool loading = true;
  String? error;

  late final Random _random = widget.random ?? Random();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loadedHobbies = await const HobbyRepository().load();
      final challenges = await const AssetDataService().loadChallenges();
      final loadedPrefs = await HobbyPreferencesService.load();
      final loadedSkipped = await HobbyPreferencesService.skippedIds();
      final loadedTried = await ProgressService.getChallengeItemIds(
        HobbyRepository.progressKey,
      );
      if (!mounted) return;
      setState(() {
        hobbies = loadedHobbies;
        challenge = challenges
            .where((c) => c.id == HobbyRepository.challengeId)
            .firstOrNull;
        prefs = loadedPrefs;
        skipped = loadedSkipped;
        tried = loadedTried;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<HobbyMatch> get matches =>
      _matcher.rank(hobbies, prefs, filters: filters);

  Future<void> _editPreferences() async {
    final updated = await Navigator.push<HobbyPreferences>(
      context,
      MaterialPageRoute(builder: (_) => HobbyQuizPage(initial: prefs)),
    );
    if (updated != null && mounted) {
      setState(() {
        prefs = updated;
        pick = null;
      });
    }
  }

  void _pickForMe() {
    final next = _matcher.pick(
      hobbies,
      prefs,
      exclude: {...tried, ...skipped, ?pick?.hobby.id},
      filters: filters,
      random: _random,
    );
    if (next == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('You\'ve seen every match for these filters.'),
            action: skipped.isEmpty
                ? null
                : SnackBarAction(
                    label: 'Show skipped again',
                    onPressed: () async {
                      await HobbyPreferencesService.clearSkipped();
                      if (mounted) setState(() => skipped = {});
                    },
                  ),
          ),
        );
      return;
    }
    setState(() => pick = next);
  }

  Future<void> _notForMe(HobbyMatch match) async {
    await HobbyPreferencesService.skip(match.hobby.id);
    if (!mounted) return;
    setState(() => skipped = {...skipped, match.hobby.id});
    _pickForMe();
  }

  Future<void> _open(Hobby hobby) async {
    final target = challenge;
    if (target == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChecklistItemDetailsPage(challenge: target, item: hobby.item),
      ),
    );
    final updated = await ProgressService.getChallengeItemIds(
      HobbyRepository.progressKey,
    );
    if (mounted) setState(() => tried = updated);
  }

  void _setFilters(HobbyFilters next) => setState(() {
    filters = next;
    pick = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a hobby'),
        actions: [
          if (prefs != null)
            IconButton(
              tooltip: 'Edit preferences',
              icon: const Icon(Icons.tune),
              onPressed: _editPreferences,
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load',
              message: 'Could not load hobbies.\n\n$error',
            )
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final list = matches;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList.list(
            children: [
              Reveal(
                child: _HeroCard(
                  hasPreferences: prefs != null,
                  onPick: _pickForMe,
                  onQuiz: _editPreferences,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween(begin: .96, end: 1.0).animate(animation),
                      child: child,
                    ),
                  ),
                  child: pick == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          key: ValueKey(pick!.hobby.id),
                          padding: const EdgeInsets.only(top: 14),
                          child: _PickCard(
                            match: pick!,
                            onTry: () => _open(pick!.hobby),
                            onAnother: _pickForMe,
                            onNotForMe: () => _notForMe(pick!),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              _FilterBar(filters: filters, onChanged: _setFilters),
              const SizedBox(height: 14),
              Text(
                prefs == null
                    ? '${list.length} hobbies'
                    : '${list.length} hobbies · best matches first',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (list.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No hobbies match',
                message: 'Try removing a filter or two.',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final match = list[index];
                final tile = _HobbyTile(
                  match: match,
                  tried: tried.contains(match.hobby.id),
                  onTap: () => _open(match.hobby),
                );
                return index < Reveal.maxStaggered
                    ? Reveal(
                        key: ValueKey('finder-${match.hobby.id}'),
                        index: index,
                        child: tile,
                      )
                    : tile;
              },
            ),
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool hasPreferences;
  final VoidCallback onPick;
  final VoidCallback onQuiz;

  const _HeroCard({
    required this.hasPreferences,
    required this.onPick,
    required this.onQuiz,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: AppGradients.category(
        AppColors.categoryAccent('life_experiences'),
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
        const SizedBox(height: 10),
        Text(
          hasPreferences
              ? 'Not sure what to try?'
              : 'Find hobbies that suit you',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          hasPreferences
              ? 'We\'ll pick one that fits your preferences.'
              : 'Answer ${HobbyQuizPage.questionCount} quick questions and '
                    'we\'ll match you with hobbies, indoors or out.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .92),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (!hasPreferences)
              FilledButton(
                key: const ValueKey('hobby-finder-quiz'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.ink,
                ),
                onPressed: onQuiz,
                child: const Text('Get my matches'),
              ),
            TactileScale(
              child: hasPreferences
                  ? FilledButton.icon(
                      key: const ValueKey('hobby-finder-pick'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.ink,
                      ),
                      onPressed: onPick,
                      icon: const Icon(Icons.casino_outlined),
                      label: const Text('Pick for me'),
                    )
                  : OutlinedButton.icon(
                      key: const ValueKey('hobby-finder-pick'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        minimumSize: const Size(48, 48),
                      ),
                      onPressed: onPick,
                      icon: const Icon(Icons.casino_outlined),
                      label: const Text('Surprise me'),
                    ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PickCard extends StatelessWidget {
  final HobbyMatch match;
  final VoidCallback onTry;
  final VoidCallback onAnother;
  final VoidCallback onNotForMe;

  const _PickCard({
    required this.match,
    required this.onTry,
    required this.onAnother,
    required this.onNotForMe,
  });

  @override
  Widget build(BuildContext context) {
    final hobby = match.hobby;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.categoryAccent('life_experiences')
                    .withValues(alpha: .14),
                child: Icon(
                  hobbyGroupIcon(hobby.item.filterGroup),
                  color: AppColors.categoryAccent('life_experiences'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TRY ${hobby.name.toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(hobby.title, style: Theme.of(context).textTheme.titleLarge),
          if (hobby.item.description case final about?) ...[
            const SizedBox(height: 6),
            Text(about, style: const TextStyle(color: AppColors.muted)),
          ],
          if (match.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final reason in match.reasons.take(4))
                  _ReasonChip(label: reason),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const ValueKey('hobby-pick-try'),
                  onPressed: onTry,
                  child: const Text('Let\'s try it'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                key: const ValueKey('hobby-pick-another'),
                tooltip: 'Show another',
                onPressed: onAnother,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                key: const ValueKey('hobby-pick-skip'),
                tooltip: 'Not for me',
                onPressed: onNotForMe,
                icon: const Icon(Icons.thumb_down_alt_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String label;
  const _ReasonChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.accentSurface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _FilterBar extends StatelessWidget {
  final HobbyFilters filters;
  final ValueChanged<HobbyFilters> onChanged;

  const _FilterBar({required this.filters, required this.onChanged});

  HobbyFilters _with({
    Object? setting = _keep,
    bool? freeOnly,
    bool? quick,
    Object? energy = _keep,
    Object? social = _keep,
    Object? goal = _keep,
  }) => HobbyFilters(
    setting: identical(setting, _keep)
        ? filters.setting
        : setting as HobbySetting?,
    freeOnly: freeOnly ?? filters.freeOnly,
    quick: quick ?? filters.quick,
    energy: identical(energy, _keep) ? filters.energy : energy as HobbyEnergy?,
    social: identical(social, _keep) ? filters.social : social as HobbySocial?,
    goal: identical(goal, _keep) ? filters.goal : goal as HobbyGoal?,
  );

  static const _keep = Object();

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final f = filters;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(
                'Indoors',
                f.setting == HobbySetting.indoor,
                () => onChanged(
                  _with(
                    setting: f.setting == HobbySetting.indoor
                        ? null
                        : HobbySetting.indoor,
                  ),
                ),
              ),
              _chip(
                'Outdoors',
                f.setting == HobbySetting.outdoor,
                () => onChanged(
                  _with(
                    setting: f.setting == HobbySetting.outdoor
                        ? null
                        : HobbySetting.outdoor,
                  ),
                ),
              ),
              _chip(
                'Free',
                f.freeOnly,
                () => onChanged(_with(freeOnly: !f.freeOnly)),
              ),
              _chip(
                'Under 30 min',
                f.quick,
                () => onChanged(_with(quick: !f.quick)),
              ),
              _chip(
                'Calm',
                f.energy == HobbyEnergy.calm,
                () => onChanged(
                  _with(
                    energy: f.energy == HobbyEnergy.calm
                        ? null
                        : HobbyEnergy.calm,
                  ),
                ),
              ),
              _chip(
                'Active',
                f.energy == HobbyEnergy.active,
                () => onChanged(
                  _with(
                    energy: f.energy == HobbyEnergy.active
                        ? null
                        : HobbyEnergy.active,
                  ),
                ),
              ),
              _chip(
                'Solo',
                f.social == HobbySocial.solo,
                () => onChanged(
                  _with(
                    social: f.social == HobbySocial.solo
                        ? null
                        : HobbySocial.solo,
                  ),
                ),
              ),
              _chip(
                'With others',
                f.social == HobbySocial.social,
                () => onChanged(
                  _with(
                    social: f.social == HobbySocial.social
                        ? null
                        : HobbySocial.social,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final goal in HobbyGoal.values)
                _chip(
                  goal.label,
                  f.goal == goal,
                  () => onChanged(_with(goal: f.goal == goal ? null : goal)),
                ),
              if (!f.isEmpty)
                TextButton.icon(
                  onPressed: () => onChanged(const HobbyFilters()),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Clear'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HobbyTile extends StatelessWidget {
  final HobbyMatch match;
  final bool tried;
  final VoidCallback onTap;

  const _HobbyTile({
    required this.match,
    required this.tried,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hobby = match.hobby;
    final accent = AppColors.categoryAccent('life_experiences');
    final details = [
      hobby.name,
      hobby.item.metadata['Cost'],
      hobby.item.metadata['Time'],
    ].whereType<String>().join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TactileScale(
        child: Material(
          color: tried ? AppColors.completedSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hobbyGroupIcon(hobby.item.filterGroup),
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hobby.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        if (match.reasons.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final reason in match.reasons.take(3))
                                _ReasonChip(label: reason),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (tried)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        semanticLabel: 'Tried',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
