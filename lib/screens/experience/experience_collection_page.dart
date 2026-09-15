import 'package:flutter/material.dart';

import '../../models/experience.dart';
import '../../models/experience_collection.dart';
import '../../models/fruit.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/circular_progress_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/experience_collection_tile.dart';
import '../../widgets/experience_tile.dart';
import '../../widgets/filter_chip_group.dart';
import '../fruit/fruit_details_page.dart';
import 'experience_details_page.dart';

/// Renders any Context -> Section -> Collection configuration while keeping
/// completion attached to the canonical Fruit or Experience record.
class ExperienceCollectionPage extends StatefulWidget {
  final ExperienceCollection collection;
  final List<Fruit> fruits;
  final List<Experience> experiences;
  final List<AtlasState> atlasStates;

  const ExperienceCollectionPage({
    super.key,
    required this.collection,
    this.fruits = const [],
    this.experiences = const [],
    this.atlasStates = const [],
  });

  @override
  State<ExperienceCollectionPage> createState() =>
      _ExperienceCollectionPageState();
}

class _ExperienceCollectionPageState extends State<ExperienceCollectionPage> {
  Set<String> completedIds = {};
  String filter = 'All';
  bool loading = true;

  bool get isFruit => widget.collection.entityType == 'fruit';
  int get total => isFruit ? widget.fruits.length : widget.experiences.length;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final ids = isFruit
        ? await ProgressService.getCompletedFruitIds()
        : await ProgressService.getCompletedExperienceIds();
    if (mounted) {
      setState(() {
        completedIds = ids;
        loading = false;
      });
    }
  }

  Future<void> setCompleted(String id, bool completed) async {
    final updated = Set<String>.from(completedIds);
    completed ? updated.add(id) : updated.remove(id);
    setState(() => completedIds = updated);
    if (isFruit) {
      await ProgressService.setCompletedFruitIds(updated);
    } else {
      await ProgressService.setCompletedExperienceIds(updated);
    }
  }

  List<String> get filterOptions => switch (widget.collection.completionVerb) {
    'tried' => const ['All', 'Tried', 'To Try'],
    'visited' => const ['All', 'Visited', 'To Visit'],
    'attended' => const ['All', 'Attended', 'To Attend'],
    'experienced' => const ['All', 'Experienced', 'To Experience'],
    _ => const ['All', 'Explored', 'To Explore'],
  };

  bool visible(String id) =>
      filter == 'All' ||
      (filter == filterOptions[1]
          ? completedIds.contains(id)
          : !completedIds.contains(id));

  @override
  Widget build(BuildContext context) {
    final fruits = widget.fruits.where((item) => visible(item.id)).toList();
    final experiences = widget.experiences
        .where((item) => visible(item.id))
        .toList();
    final memberIds = isFruit
        ? widget.fruits.map((item) => item.id).toSet()
        : widget.experiences.map((item) => item.id).toSet();
    final completed = completedIds.intersection(memberIds).length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.collection.contextName} ${widget.collection.title}',
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverList.list(
              children: [
                Icon(
                  experienceCollectionIcon(widget.collection.iconIdentifier),
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.collection.contextName} ${widget.collection.title}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressWidget(
                        progress: progress,
                        variant: ProgressSize.medium,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          '$completed of $total ${widget.collection.completionVerb}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  widget.collection.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 18),
                  FilterChipGroup(
                    options: filterOptions,
                    selected: filter,
                    onChanged: (value) => setState(() => filter = value),
                  ),
                ],
              ],
            ),
          ),
          if (loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (total == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: experienceCollectionIcon(
                  widget.collection.iconIdentifier,
                ),
                title: '0 experiences',
                message: widget.collection.emptyMessage,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList.builder(
                itemCount: isFruit ? fruits.length : experiences.length,
                itemBuilder: (context, index) => isFruit
                    ? _fruitTile(fruits[index])
                    : ExperienceTile(
                        experience: experiences[index],
                        completed: completedIds.contains(experiences[index].id),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExperienceDetailsPage(
                                experience: experiences[index],
                              ),
                            ),
                          );
                          await loadProgress();
                        },
                        onCompletionChanged: (value) =>
                            setCompleted(experiences[index].id, value),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fruitTile(Fruit fruit) {
    final completed = completedIds.contains(fruit.id);
    return Card(
      color: completed ? AppColors.completedSurface : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.eco_outlined,
          color: completed ? AppColors.primary : null,
        ),
        title: Text(
          fruit.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: completed ? AppColors.primary : AppColors.ink,
          ),
        ),
        subtitle: Text(
          '${widget.collection.contextName} verified growing relationship',
        ),
        trailing: Checkbox(
          value: completed,
          onChanged: (value) => setCompleted(fruit.id, value ?? false),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FruitDetailsPage(fruit: fruit, states: widget.atlasStates),
            ),
          );
          await loadProgress();
        },
      ),
    );
  }
}
