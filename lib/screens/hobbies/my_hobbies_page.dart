import 'package:flutter/material.dart';

import '../../models/hobby_journal.dart';
import '../../services/hobby_journal_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/hobby_icon.dart';
import '../../widgets/log_session_sheet.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import 'add_existing_hobby_page.dart';
import 'hobby_finder_page.dart';
import 'hobby_journal_page.dart';

/// The Hobbies tab: hobbies someone is practising or trying, with quick
/// session logging, streaks and the 7-day starter.
class MyHobbiesPage extends StatefulWidget {
  final DateTime Function()? clock;

  const MyHobbiesPage({super.key, this.clock});

  @override
  State<MyHobbiesPage> createState() => _MyHobbiesPageState();
}

class _MyHobbiesPageState extends State<MyHobbiesPage> {
  Map<String, HobbyRecord> records = {};
  bool loading = true;

  DateTime get now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    HobbyJournalService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    HobbyJournalService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await HobbyJournalService.load();
    if (mounted) {
      setState(() {
        records = loaded;
        loading = false;
      });
    }
  }

  List<HobbyRecord> _by(bool Function(HobbyRecord) test) {
    final list = records.values.where(test).toList()
      ..sort((a, b) {
        final aLast = a.lastSessionAt ?? a.startedAt;
        final bLast = b.lastSessionAt ?? b.startedAt;
        return bLast.compareTo(aLast);
      });
    return list;
  }

  Future<void> _openFinder() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HobbyFinderPage()),
  );

  Future<void> _openAddExisting() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddExistingHobbyPage()),
  );

  Future<void> _openJournal(HobbyRecord record) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          HobbyJournalPage(hobbyId: record.hobbyId, clock: widget.clock),
    ),
  );

  Future<void> _log(HobbyRecord record) async {
    await showLogSessionSheet(context, record);
  }

  @override
  Widget build(BuildContext context) {
    final active = _by((r) => r.status == HobbyStatus.active);
    final decisions = active.where((r) => r.needsStarterDecision(now)).toList();
    final inactive = _by((r) => r.status != HobbyStatus.active);
    final weekSessions = active.fold(0, (s, r) => s + r.sessionsThisWeek(now));
    final weekMinutes = active.fold(0, (s, r) => s + r.minutesThisWeek(now));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hobbies'),
        actions: [
          IconButton(
            tooltip: 'Find a hobby',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: _openFinder,
          ),
          IconButton(
            key: const ValueKey('my-hobbies-add'),
            tooltip: 'Add a hobby you already do',
            icon: const Icon(Icons.add),
            onPressed: _openAddExisting,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
          ? _EmptyHobbies(onFind: _openFinder, onAdd: _openAddExisting)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                Reveal(
                  child: _WeekSummary(
                    active: active.length,
                    sessions: weekSessions,
                    minutes: weekMinutes,
                  ),
                ),
                for (final record in decisions) ...[
                  const SizedBox(height: 12),
                  _StarterDecision(record: record),
                ],
                const SizedBox(height: 20),
                if (active.isEmpty)
                  const Text(
                    'No active hobbies. Restart one below or find something new.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else ...[
                  const _SectionTitle('Practising'),
                  for (final (index, record) in active.indexed)
                    Reveal(
                      key: ValueKey('my-hobby-${record.hobbyId}'),
                      index: index + 1,
                      child: _ActiveHobbyCard(
                        record: record,
                        now: now,
                        onLog: () => _log(record),
                        onOpen: () => _openJournal(record),
                      ),
                    ),
                ],
                if (inactive.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('Paused & tried before'),
                  for (final record in inactive)
                    _InactiveHobbyTile(
                      record: record,
                      onOpen: () => _openJournal(record),
                    ),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _openFinder,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Find another hobby'),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _EmptyHobbies extends StatelessWidget {
  final VoidCallback onFind;
  final VoidCallback onAdd;

  const _EmptyHobbies({required this.onFind, required this.onAdd});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 24),
      Reveal(
        child: Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.category(
              AppColors.categoryAccent('life_experiences'),
            ),
          ),
          child: const Icon(
            Icons.palette_outlined,
            size: 44,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Reveal(
        index: 1,
        child: Text(
          'Your hobbies live here',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      const SizedBox(height: 8),
      const Reveal(
        index: 2,
        child: Text(
          'Track the hobbies you love, log practice in one tap, keep streaks '
          'and climb from Tried to Confident.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 15),
        ),
      ),
      const SizedBox(height: 24),
      Reveal(
        index: 3,
        child: FilledButton.icon(
          key: const ValueKey('my-hobbies-empty-find'),
          onPressed: onFind,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Find a hobby to try'),
        ),
      ),
      const SizedBox(height: 10),
      Reveal(
        index: 4,
        child: OutlinedButton.icon(
          key: const ValueKey('my-hobbies-empty-add'),
          onPressed: onAdd,
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.add),
          label: const Text('Add one I already do'),
        ),
      ),
    ],
  );
}

class _WeekSummary extends StatelessWidget {
  final int active;
  final int sessions;
  final int minutes;

  const _WeekSummary({
    required this.active,
    required this.sessions,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: AppGradients.category(
        AppColors.categoryAccent('life_experiences'),
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        _Stat(value: active, label: 'active'),
        _Stat(value: sessions, label: 'sessions\nthis week'),
        _Stat(value: minutes, label: 'minutes\nthis week'),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        AnimatedCount(
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .9),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _StarterDecision extends StatelessWidget {
  final HobbyRecord record;
  const _StarterDecision({required this.record});

  @override
  Widget build(BuildContext context) {
    final days = record.starterProgress().where((done) => done).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.caution,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your ${record.name} week is done!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'You practised on $days of ${HobbyRecord.starterDays} days. '
            'Keep it going, or let it go? Either way it stays on your list of '
            'things you\'ve tried.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                key: ValueKey('starter-keep-${record.hobbyId}'),
                onPressed: () => HobbyJournalService.decideStarter(
                  record.hobbyId,
                  keep: true,
                ),
                child: const Text('Keep it'),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: ValueKey('starter-drop-${record.hobbyId}'),
                onPressed: () => HobbyJournalService.decideStarter(
                  record.hobbyId,
                  keep: false,
                ),
                child: const Text('Not for me'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveHobbyCard extends StatelessWidget {
  final HobbyRecord record;
  final DateTime now;
  final VoidCallback onLog;
  final VoidCallback onOpen;

  const _ActiveHobbyCard({
    required this.record,
    required this.now,
    required this.onLog,
    required this.onOpen,
  });

  String _lastPractice() {
    final last = record.lastSessionAt;
    if (last == null) return 'No sessions yet';
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(last.year, last.month, last.day)).inDays;
    return switch (days) {
      0 => 'Practised today',
      1 => 'Practised yesterday',
      _ => 'Last practised $days days ago',
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('life_experiences');
    final streak = record.currentStreak(now);
    final starter = record.inStarter(now);
    final practisedToday = record.practisedOn(now);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TactileScale(
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          hobbyGroupIcon(record.group),
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${HobbyJournalService.levelLabel(record.level)} · ${_lastPractice()}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (streak > 0) _StreakBadge(days: streak),
                    ],
                  ),
                  if (starter) ...[
                    const SizedBox(height: 14),
                    _StarterDots(record: record, now: now),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: practisedToday
                        ? OutlinedButton.icon(
                            key: ValueKey('log-${record.hobbyId}'),
                            onPressed: onLog,
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Practised today · log another'),
                          )
                        : FilledButton.icon(
                            key: ValueKey('log-${record.hobbyId}'),
                            onPressed: onLog,
                            icon: const Icon(Icons.add_task),
                            label: const Text('Log a session'),
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

class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.orange.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_fire_department,
          size: 16,
          color: AppColors.orange,
        ),
        const SizedBox(width: 3),
        Text(
          '$days',
          semanticsLabel: '$days-day streak',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _StarterDots extends StatelessWidget {
  final HobbyRecord record;
  final DateTime now;
  const _StarterDots({required this.record, required this.now});

  @override
  Widget build(BuildContext context) {
    final progress = record.starterProgress();
    final today = record.starterDay(now) - 1;
    final done = progress.where((d) => d).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Starter week · day ${today + 1} of ${HobbyRecord.starterDays} · '
          '$done of ${HobbyRecord.starterGoal} sessions',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < progress.length; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: progress[i]
                        ? AppColors.primary
                        : i == today
                        ? AppColors.primary.withValues(alpha: .25)
                        : AppColors.outline,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InactiveHobbyTile extends StatelessWidget {
  final HobbyRecord record;
  final VoidCallback onOpen;
  const _InactiveHobbyTile({required this.record, required this.onOpen});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(hobbyGroupIcon(record.group), color: AppColors.muted),
      title: Text(record.name),
      subtitle: Text(
        record.status == HobbyStatus.paused
            ? 'Paused · ${record.sessions.length} sessions'
            : 'Tried · ${record.sessions.length} sessions',
      ),
      trailing: TextButton(
        onPressed: () => HobbyJournalService.start(
          hobbyId: record.hobbyId,
          name: record.name,
          group: record.group,
          custom: record.custom,
        ),
        child: Text(record.status == HobbyStatus.paused ? 'Resume' : 'Restart'),
      ),
      onTap: onOpen,
    ),
  );
}
