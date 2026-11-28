import 'package:flutter/material.dart';

import '../models/hobby_journal.dart';
import '../screens/hobbies/phone_down_timer_page.dart';
import '../services/hobby_journal_service.dart';
import '../theme/app_colors.dart';

/// Bottom sheet to log a practice session in a couple of taps. Returns the
/// updated record, or null if dismissed.
Future<HobbyRecord?> showLogSessionSheet(
  BuildContext context,
  HobbyRecord record,
) => showModalBottomSheet<HobbyRecord>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _LogSessionSheet(record: record),
);

class _LogSessionSheet extends StatefulWidget {
  final HobbyRecord record;
  const _LogSessionSheet({required this.record});

  @override
  State<_LogSessionSheet> createState() => _LogSessionSheetState();
}

class _LogSessionSheetState extends State<_LogSessionSheet> {
  static const _durations = [10, 20, 30, 45, 60, 90];
  int? minutes = 30;
  final note = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    setState(() => saving = true);
    final updated = await HobbyJournalService.logSession(
      widget.record.hobbyId,
      minutes: minutes,
      note: note.text,
    );
    if (mounted) Navigator.pop(context, updated);
  }

  /// Time the session for real, phone down; then log what it took.
  Future<void> _timer() async {
    final spent = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneDownTimerPage(hobbyName: widget.record.name),
      ),
    );
    if (spent == null || !mounted) return;
    setState(() => minutes = spent);
    await _log();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Log ${widget.record.name}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        const Text(
          'How long did you practise?',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in _durations)
              ChoiceChip(
                label: Text(
                  value < 60
                      ? '$value min'
                      : '${value ~/ 60}h${value % 60 == 0 ? '' : ' ${value % 60}m'}',
                ),
                selected: minutes == value,
                onSelected: (_) => setState(() => minutes = value),
              ),
            ChoiceChip(
              label: const Text('Skip time'),
              selected: minutes == null,
              onSelected: (_) => setState(() => minutes = null),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('log-session-timer'),
          onPressed: _timer,
          icon: const Icon(Icons.timer_outlined),
          label: const Text('Use a phone-down timer instead'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: note,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'A note for yourself (optional)',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('log-session-save'),
            onPressed: saving ? null : _log,
            icon: const Icon(Icons.check),
            label: const Text('Log session'),
          ),
        ),
      ],
    ),
  );
}
