import 'package:flutter/material.dart';

import '../models/hobby_journal.dart';
import '../models/item.dart';
import '../screens/hobbies/hobby_journal_page.dart';
import '../services/hobby_journal_service.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

/// On a hobby's details page: start tracking it in My Hobbies with a 7-day
/// starter, or open its journal if already tracked.
class HobbyStartButton extends StatefulWidget {
  final Item item;

  const HobbyStartButton({super.key, required this.item});

  @override
  State<HobbyStartButton> createState() => _HobbyStartButtonState();
}

class _HobbyStartButtonState extends State<HobbyStartButton> {
  HobbyRecord? record;
  bool loading = true;

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
    final loaded = await HobbyJournalService.get(widget.item.id);
    if (mounted) {
      setState(() {
        record = loaded;
        loading = false;
      });
    }
  }

  Future<void> _start() async {
    await HobbyJournalService.start(
      hobbyId: widget.item.id,
      name: widget.item.category ?? widget.item.name,
      group: widget.item.filterGroup,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to My Hobbies. Your 7-day starter begins today!'),
      ),
    );
  }

  void _open() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HobbyJournalPage(hobbyId: widget.item.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox(height: 48);
    final tracked = record != null && record!.status == HobbyStatus.active;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: tracked
          ? Container(
              key: const ValueKey('hobby-tracked'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'In My Hobbies',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: _open,
                    child: const Text('Open journal'),
                  ),
                ],
              ),
            )
          : SizedBox(
              key: const ValueKey('hobby-start'),
              width: double.infinity,
              child: TactileScale(
                child: FilledButton.tonalIcon(
                  key: const ValueKey('hobby-start-button'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 52),
                  ),
                  onPressed: _start,
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: Text(
                    record != null
                        ? 'Restart tracking'
                        : widget.item.challengeId == 'play_great_games'
                        ? 'Play it regularly · track in My Hobbies'
                        : 'Start this hobby · 7-day starter',
                  ),
                ),
              ),
            ),
    );
  }
}
