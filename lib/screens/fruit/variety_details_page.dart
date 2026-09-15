import 'package:flutter/material.dart';

import '../../widgets/exploration_hero.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/metadata_chip.dart';

import '../../theme/app_colors.dart';

import '../../models/fruit.dart';
import '../../widgets/data_notice.dart';
import '../../services/progress_service.dart';

// VARIETY DETAILS PAGE
// =================================================================

class VarietyDetailsPage extends StatefulWidget {
  final FruitVariety variety;
  final Fruit fruit;
  final List<AtlasState> states;

  const VarietyDetailsPage({
    super.key,
    required this.variety,
    required this.fruit,
    required this.states,
  });

  @override
  State<VarietyDetailsPage> createState() => _VarietyDetailsPageState();
}

class _VarietyDetailsPageState extends State<VarietyDetailsPage> {
  bool isCompleted = false;
  bool isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    loadVarietyProgress();
  }

  Future<void> loadVarietyProgress() async {
    final completedIds = await ProgressService.getCompletedVarietyIds();

    final varietyId = widget.variety.id;

    if (!mounted) return;

    setState(() {
      isCompleted = varietyId != null && completedIds.contains(varietyId);
      isLoadingProgress = false;
    });
  }

  Future<void> toggleVarietyCompletion() async {
    final varietyId = widget.variety.id;

    if (varietyId == null || varietyId.isEmpty) {
      return;
    }

    final newValue = await ProgressService.toggleVariety(varietyId);

    if (!mounted) return;

    setState(() {
      isCompleted = newValue;
    });
    if (newValue) {
      showCompletionFeedback(
        context,
        before: 0,
        after: 1,
        message: 'Variety collected. A new discovery to remember.',
      );
    }
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
    final fruitStateRecords = widget.fruit.states;

    final fruitStateIds = fruitStateRecords
        .map((state) => state.stateId)
        .where((id) => id.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Variety Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExplorationHero(
                title: widget.variety.name,
                subtitle: 'Variety of ${widget.fruit.name}',
                icon: Icons.local_florist_outlined,
                accent: AppColors.orange,
              ),
              if (!isLoadingProgress)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: toggleVarietyCompletion,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.explore_outlined,
                        key: ValueKey(isCompleted),
                      ),
                    ),
                    label: Text(
                      isCompleted
                          ? 'Explored - tap to undo'
                          : 'Mark as explored',
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              const Text(
                'About this variety',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                widget.variety.notes ??
                    'No additional information is available yet.',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),

              const SizedBox(height: 28),

              const Text(
                'Growing States / UTs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const DataNotice(
                kind: NoticeKind.caution,
                message: 'Variety-specific state mapping has not been separately verified yet. The states below are the verified growing states for the parent fruit, not necessarily this specific variety.',
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fruitStateIds.map((stateId) {
                  return MetadataChip(label: stateNameFromId(stateId));
                }).toList(),
              ),

              const SizedBox(height: 28),

              const DataNotice(
                kind: NoticeKind.research,
                message: 'This is currently research-stage variety data. Variety-specific information will be expanded and independently verified as the database grows.',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
