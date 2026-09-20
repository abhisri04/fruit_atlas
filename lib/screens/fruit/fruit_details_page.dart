import 'package:flutter/material.dart';

import '../../widgets/exploration_hero.dart';
import '../../widgets/circular_progress_widget.dart';

import '../../theme/app_colors.dart';

import '../../models/fruit.dart';
import '../../widgets/data_notice.dart';
import '../../services/progress_service.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/metadata_chip.dart';
import '../../widgets/fruit_image.dart';
import 'variety_details_page.dart';

// FRUIT DETAILS PAGE
// =================================================================

class FruitDetailsPage extends StatefulWidget {
  final Fruit fruit;
  final List<AtlasState> states;

  const FruitDetailsPage({
    super.key,
    required this.fruit,
    required this.states,
  });

  @override
  State<FruitDetailsPage> createState() => _FruitDetailsPageState();
}

class _FruitDetailsPageState extends State<FruitDetailsPage> {
  Set<String> completedVarietyIds = {};
  bool isLoadingVarietyProgress = true;
  bool showAllGrowingStates = false;

  @override
  void initState() {
    super.initState();
    loadVarietyProgress();
  }

  Future<void> loadVarietyProgress() async {
    final completedIds = await ProgressService.getCompletedVarietyIds();

    if (!mounted) return;

    setState(() {
      completedVarietyIds = completedIds;
      isLoadingVarietyProgress = false;
    });
  }

  String stateNameFromId(String id) {
    final matchingStates = widget.states.where((state) => state.id == id);

    if (matchingStates.isNotEmpty) {
      return matchingStates.first.name;
    }

    return id;
  }

  @override
  Widget build(BuildContext context) {
    final varieties = widget.fruit.varieties;

    final fruitStateRecords = widget.fruit.states;
    final visibleStateRecords = showAllGrowingStates
        ? fruitStateRecords
        : fruitStateRecords.take(6).toList();

    final completedVarietyCount = varieties.where((variety) {
      final varietyId = variety.id;

      return varietyId != null &&
          varietyId.isNotEmpty &&
          completedVarietyIds.contains(varietyId);
    }).length;

    final varietyProgress = varieties.isEmpty
        ? 0.0
        : completedVarietyCount / varieties.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Fruit Details')),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: FruitImage(
                  fruit: widget.fruit,
                  height: 210,
                  iconSize: 56,
                ),
              ),
              const SizedBox(height: 16),
              ExplorationHero(
                title: widget.fruit.name,
                subtitle: widget.fruit.scientificName.isEmpty
                    ? null
                    : widget.fruit.scientificName,
                icon: Icons.eco_outlined,
                accent: AppColors.orange,
              ),
              if (widget.fruit.shortDescription.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.fruit.shortDescription,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
              ProgressCard(
                prominent: true,
                variant: ProgressSize.medium,
                title: 'Varieties explored',
                summary:
                    '$completedVarietyCount / ${varieties.length} varieties explored',
                progress: varietyProgress,
                isLoading: isLoadingVarietyProgress,
              ),

              const SizedBox(height: 24),
              if (widget.fruit.cropGroup != null)
                buildInfoCard('Crop Group', widget.fruit.cropGroup!),

              const SizedBox(height: 20),

              const Text(
                'Verified Growing States / UTs',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                'Grown across ${fruitStateRecords.length} verified '
                '${fruitStateRecords.length == 1 ? 'state/UT' : 'states/UTs'}',
                style: const TextStyle(color: AppColors.muted),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: visibleStateRecords.map((state) {
                  final stateId = state.stateId;

                  return MetadataChip(label: stateNameFromId(stateId));
                }).toList(),
              ),

              if (fruitStateRecords.length > 6)
                TextButton.icon(
                  onPressed: () => setState(
                    () => showAllGrowingStates = !showAllGrowingStates,
                  ),
                  icon: Icon(
                    showAllGrowingStates
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  label: Text(
                    showAllGrowingStates
                        ? 'Show less'
                        : 'View all ${fruitStateRecords.length}',
                  ),
                ),

              const SizedBox(height: 24),

              const SizedBox(height: 4),
              const Text(
                'Recorded varieties',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (varieties.isEmpty)
                const Text(
                  'No varieties recorded yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...varieties.map(
                  (variety) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.eco_outlined),
                      title: Text(
                        variety.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: variety.notes != null
                          ? Text(variety.notes!)
                          : null,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.muted,
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VarietyDetailsPage(
                              variety: variety,
                              fruit: widget.fruit,
                              states: widget.states,
                            ),
                          ),
                        );

                        if (!mounted) return;

                        if (result == null) {
                          await loadVarietyProgress();
                          return;
                        }

                        await loadVarietyProgress();
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              const DataNotice(
                kind: NoticeKind.research,
                message: 'The information currently shown is based on the verified mappings available in the research-stage dataset.',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// =================================================================
