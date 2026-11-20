import 'package:flutter/material.dart';

import '../../models/hobby.dart';
import '../../models/hobby_journal.dart';
import '../../models/item.dart';
import '../../services/hobby_journal_service.dart';
import '../../services/hobby_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/hobby_icon.dart';
import '../../widgets/log_session_sheet.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';
import '../../widgets/skill_ladder.dart';

/// One tracked hobby: stats, the skill ladder, and session history.
class HobbyJournalPage extends StatefulWidget {
  final String hobbyId;
  final DateTime Function()? clock;

  const HobbyJournalPage({super.key, required this.hobbyId, this.clock});

  @override
  State<HobbyJournalPage> createState() => _HobbyJournalPageState();
}

enum _Action { pause, resume, stop, remove }

class _HobbyJournalPageState extends State<HobbyJournalPage> {
  HobbyRecord? record;
  Hobby? hobby;
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
    final loaded = await HobbyJournalService.get(widget.hobbyId);
    final catalogue = await const HobbyRepository().loadAll();
    if (!mounted) return;
    setState(() {
      record = loaded;
      hobby = catalogue.where((h) => h.id == widget.hobbyId).firstOrNull;
      loading = false;
    });
  }

  Future<void> _act(_Action action) async {
    final id = widget.hobbyId;
    switch (action) {
      case _Action.pause:
        await HobbyJournalService.setStatus(id, HobbyStatus.paused);
      case _Action.resume:
        await HobbyJournalService.setStatus(id, HobbyStatus.active);
      case _Action.stop:
        await HobbyJournalService.setStatus(id, HobbyStatus.dropped);
      case _Action.remove:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove from My Hobbies?'),
            content: const Text(
              'This deletes its session history. XP you earned stays.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        await HobbyJournalService.remove(id);
        if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Scaffold(
      appBar: AppBar(
        title: Text(r?.name ?? 'Hobby'),
        actions: [
          if (r != null)
            PopupMenuButton<_Action>(
              tooltip: 'More',
              onSelected: _act,
              itemBuilder: (_) => [
                if (r.status == HobbyStatus.active)
                  const PopupMenuItem(
                    value: _Action.pause,
                    child: Text('Pause'),
                  ),
                if (r.status != HobbyStatus.active)
                  const PopupMenuItem(
                    value: _Action.resume,
                    child: Text('Resume'),
                  ),
                if (r.status != HobbyStatus.dropped)
                  const PopupMenuItem(
                    value: _Action.stop,
                    child: Text('Stop tracking'),
                  ),
                const PopupMenuItem(
                  value: _Action.remove,
                  child: Text('Remove'),
                ),
              ],
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
          ? const Center(child: Text('This hobby is no longer tracked.'))
          : _buildBody(context, r),
    );
  }

  Widget _buildBody(BuildContext context, HobbyRecord r) {
    final ladder = hobby?.item.ladder ?? const <LadderStep>[];
    final next = r.level + 1;
    final sessions = [...r.sessions]..sort((a, b) => b.at.compareTo(a.at));
    final accent = AppColors.categoryAccent('life_experiences');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Reveal(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppGradients.category(accent),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hobbyGroupIcon(r.group),
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        HobbyJournalService.levelLabel(r.level),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (r.status != HobbyStatus.active)
                      Chip(
                        label: Text(
                          r.status == HobbyStatus.paused ? 'Paused' : 'Stopped',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HeroStat(value: r.sessions.length, label: 'sessions'),
                    _HeroStat(value: r.totalMinutes, label: 'minutes'),
                    _HeroStat(value: r.currentStreak(now), label: 'day streak'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Reveal(
          index: 1,
          child: FilledButton.icon(
            key: const ValueKey('journal-log'),
            onPressed: () => showLogSessionSheet(context, r),
            icon: const Icon(Icons.add_task),
            label: const Text('Log a session'),
          ),
        ),
        if (ladder.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text('Your path', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SkillLadder(steps: ladder, reached: r.level + 1),
          if (next < ladder.length) ...[
            const SizedBox(height: 8),
            TactileScale(
              child: OutlinedButton.icon(
                key: const ValueKey('journal-reach-next'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () =>
                    HobbyJournalService.reachLevel(r.hobbyId, next, now: now),
                icon: const Icon(Icons.flag_outlined),
                label: Text('I\'ve done this: ${ladder[next].milestone}'),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'You\'ve climbed the whole ladder. Brilliant!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
        const SizedBox(height: 26),
        Text('Sessions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          const Text(
            'No sessions yet. Log your first one above.',
            style: TextStyle(color: AppColors.muted),
          )
        else
          for (final session in sessions.take(30))
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_available_outlined),
                title: Text(_formatDate(session.at)),
                subtitle: session.note == null || session.note!.isEmpty
                    ? null
                    : Text(session.note!),
                trailing: session.minutes == null
                    ? null
                    : Text(
                        '${session.minutes} min',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
      ],
    );
  }

  String _formatDate(DateTime at) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${at.day} ${months[at.month - 1]} ${at.year}';
  }
}

class _HeroStat extends StatelessWidget {
  final int value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCount(
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: .9)),
        ),
      ],
    ),
  );
}
