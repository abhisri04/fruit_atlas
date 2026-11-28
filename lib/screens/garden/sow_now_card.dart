import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/challenge.dart';
import '../../models/item.dart';
import '../../services/asset_data_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reward_animations.dart';
import '../challenge/checklist_item_details_page.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Plants that suit [month], skipping "any time" plants so the list stays
/// seasonal. Reads `sow_months` from the raw catalogue.
List<Map<String, dynamic>> plantsForMonth(
  List<Map<String, dynamic>> plants,
  int month,
) => [
  for (final plant in plants)
    if ((plant['sow_months'] as List<dynamic>).length < 12 &&
        (plant['sow_months'] as List<dynamic>).contains(month))
      plant,
];

/// Up to [count] in-season plants, taking turns across kinds (flowers,
/// vegetables, herbs…) so one kind doesn't fill the list.
List<Map<String, dynamic>> seasonalMix(
  List<Map<String, dynamic>> plants,
  int month, {
  int count = 8,
}) {
  final byKind = <String, List<Map<String, dynamic>>>{};
  for (final plant in plantsForMonth(plants, month)) {
    byKind.putIfAbsent('${plant['filter_group']}', () => []).add(plant);
  }
  // Flowers first: the kind most people picture when they start.
  final kinds = byKind.keys.toList()
    ..sort(
      (a, b) => (a == 'Flowers' ? 0 : 1).compareTo(b == 'Flowers' ? 0 : 1),
    );
  final mixed = <Map<String, dynamic>>[];
  for (var round = 0; mixed.length < count; round++) {
    var added = false;
    for (final kind in kinds) {
      final list = byKind[kind]!;
      if (round < list.length && mixed.length < count) {
        mixed.add(list[round]);
        added = true;
      }
    }
    if (!added) break;
  }
  return mixed;
}

/// "What to sow this month": a gentle, seasonal nudge on the Garden hub.
class SowNowCard extends StatefulWidget {
  final DateTime Function()? clock;
  const SowNowCard({super.key, this.clock});

  @override
  State<SowNowCard> createState() => _SowNowCardState();
}

class _SowNowCardState extends State<SowNowCard> {
  List<Map<String, dynamic>> plants = [];
  Challenge? challenge;

  DateTime get now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/data/garden_plants.json'),
    ) as Map<String, dynamic>;
    final challenges = await const AssetDataService().loadChallenges();
    if (!mounted) return;
    setState(() {
      plants = (raw['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      challenge = challenges
          .where((c) => c.id == 'explore_garden_plants')
          .firstOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('garden');
    final now = this.now;
    final suggestions = seasonalMix(plants, now.month);
    return Container(
      key: const ValueKey('sow-now-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: .25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'What to sow in ${_months[now.month - 1]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (plants.isEmpty)
            const SizedBox(height: 32)
          else if (suggestions.isEmpty)
            const Text(
              'A quiet month for sowing. Tend what you have, or pick an '
              'any-time plant like mint or money plant.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final plant in suggestions)
                  TactileScale(
                    child: ActionChip(
                      key: ValueKey('sow-now-${plant['id']}'),
                      avatar: Icon(Icons.eco_outlined, size: 16, color: accent),
                      label: Text(plant['name'] as String),
                      onPressed: challenge == null
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChecklistItemDetailsPage(
                                  challenge: challenge!,
                                  item: Item.fromJson(plant),
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          const Text(
            'Approximate for most of India. Check with a local nursery for '
            'your area.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
