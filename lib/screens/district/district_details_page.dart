import 'package:flutter/material.dart';

import '../../models/district.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/completion_feedback.dart';
import '../../widgets/metadata_chip.dart';

class DistrictDetailsPage extends StatefulWidget {
  final District district;

  const DistrictDetailsPage({super.key, required this.district});

  @override
  State<DistrictDetailsPage> createState() => _DistrictDetailsPageState();
}

class _DistrictDetailsPageState extends State<DistrictDetailsPage> {
  bool isCompleted = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCompletion();
  }

  Future<void> loadCompletion() async {
    final completedIds = await ProgressService.getCompletedDistrictIds();
    if (!mounted) return;
    setState(() {
      isCompleted = completedIds.contains(widget.district.id);
      isLoading = false;
    });
  }

  Future<void> toggleCompletion() async {
    final completed = await ProgressService.toggleDistrict(widget.district.id);
    if (!mounted) return;
    setState(() => isCompleted = completed);
    if (completed) showCompletionFeedback(context, before: 0, after: 1);
  }

  @override
  Widget build(BuildContext context) {
    final district = widget.district;
    return Scaffold(
      appBar: AppBar(title: const Text('District Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.location_city_outlined,
            size: 72,
            color: AppColors.primary,
          ),
          const SizedBox(height: 18),
          Text(
            district.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Center(
            child: MetadataChip(label: 'District · ${district.stateName}'),
          ),
          const SizedBox(height: 20),
          Card(
            child: CheckboxListTile(
              value: isCompleted,
              onChanged: isLoading ? null : (_) => toggleCompletion(),
              title: Text(isCompleted ? 'Explored' : 'Mark as Explored'),
              subtitle: const Text(
                'District progress is separate from state visited status.',
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            district.description,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
