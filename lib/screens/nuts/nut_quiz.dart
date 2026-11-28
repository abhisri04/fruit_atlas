import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/nut.dart';
import '../../theme/app_colors.dart';
import 'nuts_page.dart';

/// "Nut or not?": guess what each nut really is botanically. Just for fun:
/// no score is kept, and every answer teaches something.
class NutQuiz extends StatefulWidget {
  final NutAtlas atlas;
  final int rounds;
  final Random? random;
  const NutQuiz({super.key, required this.atlas, this.rounds = 8, this.random});

  @override
  State<NutQuiz> createState() => _NutQuizState();
}

class _NutQuizState extends State<NutQuiz> {
  late List<Nut> deck;
  int index = 0;
  int right = 0;
  String? picked;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    // Surprises first: legumes, "not a nut" and seeds make the best questions.
    final nuts = [...widget.atlas.nuts]..shuffle(widget.random ?? Random());
    final surprising = nuts.where((n) => n.kind != 'Drupe seed').toList();
    final rest = nuts.where((n) => n.kind == 'Drupe seed').toList();
    deck = [...surprising.take(widget.rounds - 2), ...rest.take(2)]
      ..shuffle(widget.random ?? Random());
    index = 0;
    right = 0;
    picked = null;
  }

  @override
  Widget build(BuildContext context) {
    if (index >= deck.length) {
      return Card(
        key: const ValueKey('nut-quiz-done'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppColors.gold,
              ),
              const SizedBox(height: 10),
              Text(
                'You knew $right of ${deck.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Botany is full of surprises. Now you know a few more.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const ValueKey('nut-quiz-again'),
                onPressed: () => setState(_deal),
                icon: const Icon(Icons.refresh),
                label: const Text('Play again'),
              ),
            ],
          ),
        ),
      );
    }
    final nut = deck[index];
    final answered = picked != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Is it really a nut? Guess what each one is botanically.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1} of ${deck.length}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'What is ${nut.name.startsWith(RegExp('[AEIOU]')) ? 'an' : 'a'} ${nut.name.toLowerCase()}?',
                  key: const ValueKey('nut-quiz-question'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                for (final kind in NutAtlas.kinds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: ValueKey('nut-quiz-$kind'),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          backgroundColor: !answered
                              ? null
                              : kind == nut.kind
                              ? AppColors.completedSurface
                              : kind == picked
                              ? const Color(0xFFFDECEA)
                              : null,
                        ),
                        onPressed: answered
                            ? null
                            : () => setState(() {
                                picked = kind;
                                if (kind == nut.kind) right++;
                              }),
                        icon: NutBadge(kind: kind, size: 26),
                        label: Text(kind),
                      ),
                    ),
                  ),
                if (answered) ...[
                  const SizedBox(height: 6),
                  Text(
                    picked == nut.kind
                        ? 'Yes! ${nut.kind}.'
                        : 'It is: ${nut.kind}.',
                    key: const ValueKey('nut-quiz-answer'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(nut.fact, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: const ValueKey('nut-quiz-next'),
                      onPressed: () => setState(() {
                        index++;
                        picked = null;
                      }),
                      child: Text(
                        index + 1 == deck.length ? 'See how I did' : 'Next',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _KindGuide(),
      ],
    );
  }
}

class _KindGuide extends StatelessWidget {
  const _KindGuide();

  static const _what = {
    'True nut': 'A hard shell that does not open, with one seed: hazelnut, chestnut, acorn.',
    'Drupe seed': 'The seed inside a stone fruit, like a mango or peach: almond, walnut, cashew, coconut.',
    'Seed': 'A seed from a pod, cone or flower: Brazil nut, pine nut, makhana.',
    'Legume': 'From the pea and bean family: peanut.',
    'Not a nut':
        'Called a nut, but really a tuber or a spice: tiger nut, nutmeg.',
  };

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text(
      'What do these mean?',
      style: TextStyle(fontWeight: FontWeight.w700),
    ),
    children: [
      for (final MapEntry(:key, :value) in _what.entries)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: NutBadge(kind: key, size: 32),
          title: Text(key),
          subtitle: Text(value),
        ),
    ],
  );
}
