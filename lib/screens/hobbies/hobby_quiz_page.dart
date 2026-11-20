import 'package:flutter/material.dart';

import '../../models/hobby.dart';
import '../../models/hobby_preferences.dart';
import '../../services/hobby_preferences_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';

class _Option {
  final String label;
  final String? hint;
  final IconData icon;
  final HobbyPreferences Function(HobbyPreferences) apply;
  final bool Function(HobbyPreferences) isSelected;

  const _Option({
    required this.label,
    this.hint,
    required this.icon,
    required this.apply,
    required this.isSelected,
  });
}

class _Question {
  final String title;
  final String subtitle;
  final List<_Option> options;
  final bool multi;

  const _Question({
    required this.title,
    required this.subtitle,
    required this.options,
    this.multi = false,
  });
}

_Option _goal(HobbyGoal goal, IconData icon) => _Option(
  label: goal.label,
  icon: icon,
  apply: (p) => p.copyWith(
    goals: p.goals.contains(goal)
        ? ({...p.goals}..remove(goal))
        : {...p.goals, goal},
  ),
  isSelected: (p) => p.goals.contains(goal),
);

final _questions = <_Question>[
  _Question(
    title: 'Where do you like to spend free time?',
    subtitle: 'We\'ll suggest hobbies that fit the place.',
    options: [
      _Option(
        label: 'Indoors',
        hint: 'At home or somewhere cosy',
        icon: Icons.chair_outlined,
        apply: (p) => p.copyWith(place: HobbySetting.indoor),
        isSelected: (p) => p.place == HobbySetting.indoor,
      ),
      _Option(
        label: 'Outdoors',
        hint: 'Parks, streets, nature',
        icon: Icons.park_outlined,
        apply: (p) => p.copyWith(place: HobbySetting.outdoor),
        isSelected: (p) => p.place == HobbySetting.outdoor,
      ),
      _Option(
        label: 'A bit of both',
        icon: Icons.swap_horiz,
        apply: (p) => p.copyWith(place: HobbySetting.either),
        isSelected: (p) => p.place == HobbySetting.either,
      ),
    ],
  ),
  _Question(
    title: 'How much time do you usually have?',
    subtitle: 'For one session.',
    options: [
      _Option(
        label: '15–30 minutes',
        icon: Icons.timer_outlined,
        apply: (p) => p.copyWith(maxMinutes: 30),
        isSelected: (p) => p.maxMinutes <= 30,
      ),
      _Option(
        label: 'About an hour',
        icon: Icons.schedule_outlined,
        apply: (p) => p.copyWith(maxMinutes: 60),
        isSelected: (p) => p.maxMinutes > 30 && p.maxMinutes <= 60,
      ),
      _Option(
        label: 'A few hours',
        icon: Icons.wb_sunny_outlined,
        apply: (p) => p.copyWith(maxMinutes: 240),
        isSelected: (p) => p.maxMinutes > 60,
      ),
    ],
  ),
  _Question(
    title: 'What kind of energy?',
    subtitle: 'Pick what you\'re in the mood for most of the time.',
    options: [
      _Option(
        label: 'Calm',
        hint: 'Slow, quiet, mindful',
        icon: Icons.spa_outlined,
        apply: (p) => p.copyWith(energy: HobbyEnergy.calm),
        isSelected: (p) => p.energy == HobbyEnergy.calm,
      ),
      _Option(
        label: 'A mix',
        icon: Icons.tune,
        apply: (p) => p.copyWith(clearEnergy: true),
        isSelected: (p) => p.energy == null,
      ),
      _Option(
        label: 'Active',
        hint: 'Get moving, break a sweat',
        icon: Icons.directions_run,
        apply: (p) => p.copyWith(energy: HobbyEnergy.active),
        isSelected: (p) => p.energy == HobbyEnergy.active,
      ),
    ],
  ),
  _Question(
    title: 'On your own or with others?',
    subtitle: '',
    options: [
      _Option(
        label: 'On my own',
        icon: Icons.person_outline,
        apply: (p) => p.copyWith(company: HobbySocial.solo),
        isSelected: (p) => p.company == HobbySocial.solo,
      ),
      _Option(
        label: 'With others',
        icon: Icons.groups_outlined,
        apply: (p) => p.copyWith(company: HobbySocial.social),
        isSelected: (p) => p.company == HobbySocial.social,
      ),
      _Option(
        label: 'Either is fine',
        icon: Icons.people_outline,
        apply: (p) => p.copyWith(company: HobbySocial.either),
        isSelected: (p) => p.company == HobbySocial.either,
      ),
    ],
  ),
  _Question(
    title: 'What do you want from a hobby?',
    subtitle: 'Pick as many as you like.',
    multi: true,
    options: [
      _goal(HobbyGoal.relax, Icons.self_improvement),
      _goal(HobbyGoal.active, Icons.fitness_center_outlined),
      _goal(HobbyGoal.create, Icons.palette_outlined),
      _goal(HobbyGoal.connect, Icons.diversity_3_outlined),
      _goal(HobbyGoal.learn, Icons.lightbulb_outline),
    ],
  ),
];

/// Six quick questions that personalise the hobby finder. Pops with the
/// saved [HobbyPreferences], or null if dismissed.
class HobbyQuizPage extends StatefulWidget {
  final HobbyPreferences? initial;

  const HobbyQuizPage({super.key, this.initial});

  static int get questionCount => _questions.length;

  @override
  State<HobbyQuizPage> createState() => _HobbyQuizPageState();
}

class _HobbyQuizPageState extends State<HobbyQuizPage> {
  late HobbyPreferences prefs = widget.initial ?? const HobbyPreferences();
  int step = 0;
  bool forward = true;
  bool saving = false;

  _Question get question => _questions[step];
  bool get isLast => step == _questions.length - 1;

  void _choose(_Option option) {
    setState(() => prefs = option.apply(prefs));
    if (!question.multi && !isLast) _go(step + 1);
  }

  void _go(int next) => setState(() {
    forward = next > step;
    step = next;
  });

  Future<void> _finish() async {
    setState(() => saving = true);
    await HobbyPreferencesService.save(prefs);
    if (mounted) Navigator.pop(context, prefs);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: step == 0 ? 'Close' : 'Back',
          icon: Icon(step == 0 ? Icons.close : Icons.arrow_back),
          onPressed: step == 0
              ? () => Navigator.pop(context)
              : () => _go(step - 1),
        ),
        title: Text('${step + 1} of ${_questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedProgressValue(
              value: (step + 1) / _questions.length,
              minHeight: 6,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: Offset(forward ? .15 : -.15, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: ListView(
            key: ValueKey(step),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                question.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (question.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  question.subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
              ],
              const SizedBox(height: 22),
              for (final (index, option) in question.options.indexed)
                Reveal(
                  index: index,
                  child: _OptionCard(
                    option: option,
                    selected: option.isSelected(prefs),
                    multi: question.multi,
                    onTap: () => _choose(option),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: question.multi || isLast
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton.icon(
                key: const ValueKey('hobby-quiz-finish'),
                onPressed: saving ? null : _finish,
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  prefs.goals.isEmpty
                      ? 'Skip and show my hobbies'
                      : 'Show my hobbies',
                ),
              ),
            )
          : null,
    );
  }
}

class _OptionCard extends StatelessWidget {
  final _Option option;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TactileScale(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    option.icon,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (option.hint case final hint?)
                          Text(
                            hint,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      selected
                          ? (multi ? Icons.check_box : Icons.check_circle)
                          : (multi
                                ? Icons.check_box_outline_blank
                                : Icons.radio_button_unchecked),
                      key: ValueKey(selected),
                      color: selected ? AppColors.primary : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
