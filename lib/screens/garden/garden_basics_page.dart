import 'package:flutter/material.dart';

import '../../models/challenge.dart';
import '../../models/item.dart';
import '../../services/asset_data_service.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/reveal.dart';
import '../challenge/checklist_item_details_page.dart';
import 'garden_sheets.dart';

/// Garden skills as a readable guide: start here, then grow from there.
class GardenBasicsPage extends StatefulWidget {
  const GardenBasicsPage({super.key});

  @override
  State<GardenBasicsPage> createState() => _GardenBasicsPageState();
}

class _GardenBasicsPageState extends State<GardenBasicsPage> {
  Challenge? challenge;
  List<Item> skills = [];
  Set<String> learned = {};

  static const _sections = [
    ('Basics', 'Start here', 'Six things that make everything else easier.'),
    ('Care', 'Keep plants happy', 'Small habits once your plants are growing.'),
    ('Grow more', 'Grow more', 'Make new plants and bigger harvests.'),
    ('Advanced', 'When you are ready', 'Projects for curious gardeners.'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await GardenCatalogue.skillsChallenge();
    final items = await const AssetDataService().loadChallengeItems(c);
    final done = await ProgressService.getChallengeItemIds(c.progressKey);
    if (!mounted) return;
    setState(() {
      challenge = c;
      skills = items;
      learned = done;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.categoryAccent('garden');
    final c = challenge;
    return Scaffold(
      appBar: AppBar(title: const Text('Gardening basics')),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                Text(
                  '${learned.length} of ${skills.length} learned · '
                  'tick them off as you go',
                  style: const TextStyle(color: AppColors.muted),
                ),
                for (final (si, (group, title, subtitle)) in _sections.indexed)
                  if (skills.any((s) => s.filterGroup == group)) ...[
                    const SizedBox(height: 20),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    for (final skill in skills.where(
                      (s) => s.filterGroup == group,
                    ))
                      Reveal(
                        index: si,
                        child: Card(
                          key: ValueKey('basics-${skill.id}'),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              learned.contains(skill.id)
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: learned.contains(skill.id)
                                  ? accent
                                  : AppColors.muted,
                            ),
                            title: Text(skill.name),
                            subtitle: Text(skill.description ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChecklistItemDetailsPage(
                                    challenge: c,
                                    item: skill,
                                  ),
                                ),
                              );
                              _load();
                            },
                          ),
                        ),
                      ),
                  ],
              ],
            ),
    );
  }
}
