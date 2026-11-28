import 'package:flutter/material.dart';

import '../../models/district.dart';
import '../../models/india_location_registry.dart';
import '../../models/state_travel_status.dart';
import '../../services/district_repository.dart';
import '../../services/progress_service.dart';
import '../../services/state_travel_service.dart';
import '../../theme/app_colors.dart';
import '../district/district_details_page.dart';

/// Places (districts) inside a state: tick the ones you've been to. Ticking
/// one also stamps the state, since you were there.
Future<void> showStatePlacesSheet(
  BuildContext context, {
  required String stateId,
  required StateTravelService travel,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _StatePlacesSheet(stateId: stateId, travel: travel),
);

class _StatePlacesSheet extends StatefulWidget {
  final String stateId;
  final StateTravelService travel;
  const _StatePlacesSheet({required this.stateId, required this.travel});

  @override
  State<_StatePlacesSheet> createState() => _StatePlacesSheetState();
}

class _StatePlacesSheetState extends State<_StatePlacesSheet> {
  List<District>? districts;
  Set<String> done = {};
  String query = '';

  String get name => IndiaLocationRegistry.nameFor(widget.stateId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await const DistrictRepository().getForState(widget.stateId);
    final completed = await ProgressService.getCompletedDistrictIds();
    if (!mounted) return;
    setState(() {
      districts = [...list]..sort((a, b) => a.name.compareTo(b.name));
      done = completed;
    });
  }

  Future<void> _toggle(District d) async {
    final nowDone = await ProgressService.toggleDistrict(d.id);
    if (!mounted) return;
    setState(() => nowDone ? done.add(d.id) : done.remove(d.id));
    if (nowDone &&
        widget.travel.statusFor(widget.stateId) != TravelStatus.visited) {
      await widget.travel.setStatus(widget.stateId, TravelStatus.visited);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name is stamped in your passport too')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = districts;
    final q = query.trim().toLowerCase();
    final shown = all == null
        ? const <District>[]
        : [
            for (final d in all)
              if (q.isEmpty || d.name.toLowerCase().contains(q)) d,
          ];
    final visited = all?.where((d) => done.contains(d.id)).length ?? 0;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Places in $name',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            all == null
                ? 'Loading…'
                : '$visited of ${all.length} '
                      '${all.length == 1 ? 'district' : 'districts'} visited',
            key: const ValueKey('places-count'),
            style: const TextStyle(color: AppColors.muted),
          ),
          if (all != null && all.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: visited / all.length,
                minHeight: 8,
                color: AppColors.passportVisited,
                backgroundColor: AppColors.outline,
              ),
            ),
          ],
          if ((all?.length ?? 0) > 10) ...[
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('places-search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search districts',
              ),
              onChanged: (value) => setState(() => query = value),
            ),
          ],
          const SizedBox(height: 6),
          if (all != null && all.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No places listed for this area yet.'),
            ),
          for (final d in shown)
            ListTile(
              key: ValueKey('place-${d.id}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: IconButton(
                key: ValueKey('place-toggle-${d.id}'),
                tooltip: done.contains(d.id) ? 'Visited' : 'Mark as visited',
                icon: Icon(
                  done.contains(d.id)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: done.contains(d.id)
                      ? AppColors.passportVisited
                      : AppColors.muted,
                ),
                onPressed: () => _toggle(d),
              ),
              title: Text(d.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DistrictDetailsPage(district: d),
                  ),
                );
                _load();
              },
            ),
        ],
      ),
    );
  }
}
