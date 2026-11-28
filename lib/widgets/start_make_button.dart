import 'package:flutter/material.dart';

import '../models/item.dart';
import '../screens/making/my_makes_page.dart';
import '../services/my_makes_service.dart';
import '../theme/app_colors.dart';
import 'reward_animations.dart';

/// On a "Make Something" project page: start it, or open your project.
class StartMakeButton extends StatefulWidget {
  final Item item;
  const StartMakeButton({super.key, required this.item});

  @override
  State<StartMakeButton> createState() => _StartMakeButtonState();
}

class _StartMakeButtonState extends State<StartMakeButton> {
  MyMake? mine;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    MyMakesService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    MyMakesService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final all = await MyMakesService.load();
    if (!mounted) return;
    setState(() {
      mine = all[widget.item.id];
      loaded = true;
    });
  }

  Future<void> _open() async {
    if (mine == null) {
      await MyMakesService.start(
        widget.item.id,
        widget.item.name,
        craft: widget.item.category,
      );
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyMakePage(makeId: widget.item.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const SizedBox(height: 56);
    final accent = AppColors.categoryAccent('making');
    final m = mine;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(Icons.brush_outlined, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              m == null
                  ? 'Make it, and keep your progress photos.'
                  : m.finished
                  ? 'You made this'
                  : 'On the go · ${m.updates.length} '
                        '${m.updates.length == 1 ? 'update' : 'updates'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          TactileScale(
            child: FilledButton(
              key: const ValueKey('start-make'),
              onPressed: _open,
              child: Text(m == null ? 'Start' : 'Open'),
            ),
          ),
        ],
      ),
    );
  }
}
