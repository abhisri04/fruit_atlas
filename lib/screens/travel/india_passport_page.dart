import 'package:flutter/material.dart';

import '../../models/india_location_registry.dart';
import '../../models/state_travel_status.dart';
import '../../services/india_map_repository.dart';
import '../../services/state_travel_service.dart';
import '../../services/state_exploration_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/india_passport_map.dart';
import '../../widgets/india_passport_ring.dart';
import '../share/india_passport_share_page.dart';
import 'explore_india_page.dart';

class IndiaPassportPage extends StatefulWidget {
  final StateTravelService? travelService;
  const IndiaPassportPage({super.key, this.travelService});
  @override
  State<IndiaPassportPage> createState() => _IndiaPassportPageState();
}

class _IndiaPassportPageState extends State<IndiaPassportPage> {
  late final travel = widget.travelService ?? StateTravelService();
  final controller = TransformationController();
  List<IndiaMapRegion>? regions;
  String? error;
  String? selectedId;
  bool list = false;
  String query = '';
  TravelStatus? filter;
  IndiaExplorationSummary? exploration;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await travel.load();
      final map = await IndiaMapRepository.load();
      final summary = await const StateExplorationRepository().loadProgress();
      if (mounted) {
        setState(() {
          regions = map;
          exploration = summary;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to load your passport. Please retry.');
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    if (widget.travelService == null) travel.dispose();
    super.dispose();
  }

  Future<void> _select(String id) async {
    setState(() => selectedId = id);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: ListenableBuilder(
              listenable: travel,
              builder: (_, _) {
                final status = travel.statusFor(id);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      IndiaLocationRegistry.nameFor(id),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        status.label,
                        key: ValueKey(status),
                        style: TextStyle(
                          color: passportColor(
                            status == TravelStatus.none
                                ? TravelStatus.visited
                                : status,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          key: const ValueKey('passport-visited'),
                          label: Text(
                            'Visited',
                            style: TextStyle(
                              color: status == TravelStatus.visited
                                  ? AppColors.surface
                                  : AppColors.ink,
                              fontFamily: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontFamily,
                            ),
                          ),
                          selected: status == TravelStatus.visited,
                          onSelected: (selected) => _update(
                            id,
                            selected ? TravelStatus.visited : TravelStatus.none,
                          ),
                        ),
                        FilterChip(
                          key: const ValueKey('passport-wanted'),
                          label: Text(
                            'Want to Visit',
                            style: TextStyle(
                              color: status == TravelStatus.wantToVisit
                                  ? AppColors.surface
                                  : (status == TravelStatus.visited
                                        ? AppColors.muted
                                        : AppColors.ink),
                              fontFamily: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontFamily,
                            ),
                          ),
                          selected: status == TravelStatus.wantToVisit,
                          onSelected: status == TravelStatus.visited
                              ? null
                              : (selected) => _update(
                                  id,
                                  selected
                                      ? TravelStatus.wantToVisit
                                      : TravelStatus.none,
                                ),
                        ),
                        if (status != TravelStatus.none)
                          TextButton(
                            key: const ValueKey('passport-clear'),
                            onPressed: () => _update(id, TravelStatus.none),
                            child: const Text('Remove status'),
                          ),
                      ],
                    ),
                    if (status == TravelStatus.visited)
                      const Text(
                        'Tap Visited again to remove it and choose Want to Visit.',
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '${exploration?.counts[id] ?? 0} experiences explored',
                      key: const ValueKey('passport-state-exploration'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('passport-explore'),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        'Explore ${IndiaLocationRegistry.nameFor(id)}',
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await openStateExploration(context, id);
                        final summary = await const StateExplorationRepository()
                            .loadProgress();
                        if (mounted) setState(() => exploration = summary);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => selectedId = null);
  }

  Future<void> _update(String id, TravelStatus status) async {
    try {
      await travel.setStatus(id, status);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Please try the action again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('India Passport'),
      actions: [
        IconButton(
          key: const ValueKey('passport-share'),
          tooltip: 'Share India Passport',
          icon: const Icon(Icons.ios_share),
          onPressed: regions == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IndiaPassportSharePage(
                      travel: travel,
                      regions: regions!,
                    ),
                  ),
                ),
        ),
      ],
    ),
    body: regions == null
        ? Center(
            child: error == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
          )
        : SafeArea(
            child: ListenableBuilder(
              listenable: travel,
              builder: (_, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IndiaPassportRing(
                          ratio:
                              travel.visitedCount /
                              IndiaLocationRegistry.allLocationIds.length,
                        ),
                        const SizedBox(width: 24),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${travel.visitedCount} of 36 visited',
                                key: const ValueKey('passport-visited-count'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'States & UTs visited',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${travel.wantToVisitCount} want to visit',
                                key: const ValueKey('passport-wanted-count'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Map'),
                        icon: Icon(Icons.map_outlined),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('List'),
                        icon: Icon(Icons.list),
                      ),
                    ],
                    selected: {list},
                    onSelectionChanged: (value) =>
                        setState(() => list = value.single),
                  ),
                  const SizedBox(height: 8),
                  if (list)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        key: const ValueKey('passport-search'),
                        decoration: const InputDecoration(
                          labelText: 'Search States & UTs',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            setState(() => query = value.trim().toLowerCase()),
                      ),
                    ),
                  if (list)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        runSpacing: 4,
                        children: [
                          for (final status in [
                            null,
                            TravelStatus.visited,
                            TravelStatus.wantToVisit,
                            TravelStatus.none,
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                key: ValueKey(
                                  'passport-filter-${status?.value ?? 'all'}',
                                ),
                                label: Text(
                                  status?.label ?? 'All',
                                  style: TextStyle(
                                    color: filter == status
                                        ? AppColors.surface
                                        : AppColors.ink,
                                    fontFamily: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.fontFamily,
                                  ),
                                ),
                                selected: filter == status,
                                onSelected: (_) =>
                                    setState(() => filter = status),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: list
                        ? ListView(
                            children: [
                              if (!IndiaLocationRegistry.locations.any(
                                (location) =>
                                    location.name.toLowerCase().contains(
                                      query,
                                    ) &&
                                    (filter == null ||
                                        travel.statusFor(location.id) ==
                                            filter),
                              ))
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No States or UTs match your search and filter.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              for (final location
                                  in IndiaLocationRegistry.locations.where(
                                    (location) =>
                                        location.name.toLowerCase().contains(
                                          query,
                                        ) &&
                                        (filter == null ||
                                            travel.statusFor(location.id) ==
                                                filter),
                                  ))
                                ListTile(
                                  key: ValueKey(
                                    'passport-state-${location.id}',
                                  ),
                                  title: Text(location.name),
                                  subtitle: Text(
                                    '${exploration?.counts[location.id] ?? 0} experiences explored',
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      travel.statusFor(location.id).label,
                                      style: TextStyle(
                                        color: AppColors.ink,
                                        fontFamily: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.fontFamily,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _select(location.id),
                                ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: IndiaPassportMap(
                                    regions: regions!,
                                    travel: travel,
                                    selectedId: selectedId,
                                    onSelect: _select,
                                    controller: controller,
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IconButton.filled(
                                    tooltip: 'Reset map view',
                                    onPressed: () =>
                                        controller.value = Matrix4.identity(),
                                    icon: const Icon(Icons.center_focus_strong),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  if (!list)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Pinch to zoom • Drag to pan • Use List for small regions',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 14,
                      children: [
                        for (final status in TravelStatus.values)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 12,
                                color: passportColor(status),
                              ),
                              const SizedBox(width: 4),
                              Text(status.label),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text('Map attribution'),
                          content: Text(
                            '© OpenStreetMap contributors\nhttps://www.openstreetmap.org/copyright\n\nBoundaries: Vardhan Systems, ODbL 1.0. General travel visualization; not an official or survey map.',
                          ),
                        ),
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
