import 'package:flutter/material.dart';

import '../../models/experience.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/metadata_chip.dart';

class ExperienceDetailsPage extends StatefulWidget {
  final Experience experience;

  const ExperienceDetailsPage({super.key, required this.experience});

  @override
  State<ExperienceDetailsPage> createState() => _ExperienceDetailsPageState();
}

class _ExperienceDetailsPageState extends State<ExperienceDetailsPage> {
  bool isCompleted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCompletion();
  }

  Future<void> loadCompletion() async {
    final completedIds = await ProgressService.getCompletedExperienceIds();
    if (!mounted) return;
    setState(() {
      isCompleted = completedIds.contains(widget.experience.id);
      isLoading = false;
    });
  }

  Future<void> toggleCompletion() async {
    final beforeIds = await ProgressService.getCompletedExperienceIds();
    final completed = await ProgressService.toggleExperience(
      widget.experience.id,
    );
    if (!mounted) return;
    setState(() => isCompleted = completed);
    showCompletionFeedback(
      context,
      before: beforeIds.length,
      after: beforeIds.length + (completed ? 1 : -1),
      challengeId: 'all_experiences',
    );
  }

  @override
  Widget build(BuildContext context) {
    final experience = widget.experience;
    return Scaffold(
      appBar: AppBar(title: const Text('Experience Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.explore_outlined, size: 72, color: AppColors.primary),
          const SizedBox(height: 18),
          Text(
            experience.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Center(
            child: MetadataChip(
              label: '${experience.typeLabel} · ${experience.locationLabel}',
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: CheckboxListTile(
              value: isCompleted,
              onChanged: isLoading ? null : (_) => toggleCompletion(),
              title: Text(isCompleted ? 'Experienced' : 'Mark as Experienced'),
              subtitle: const Text(
                'This is separate from whether you have visited the state.',
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            experience.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Location'),
                  subtitle: Text(experience.locationLabel),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Part of'),
                  subtitle: Text('Explore ${experience.stateName}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
