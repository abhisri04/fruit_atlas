import 'package:flutter/material.dart';

import '../../models/india_location_registry.dart';
import '../../models/state_travel_status.dart';
import '../../services/india_map_repository.dart';
import '../../services/state_exploration_repository.dart';
import '../../services/state_travel_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/india_passport_map.dart';
import '../../widgets/india_passport_ring.dart';
import '../share/india_passport_share_page.dart';
import 'explore_india_page.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/asset_data_service.dart';
import 'passport_stats_page.dart';
import 'state_places_sheet.dart';
import '../../services/district_repository.dart';
import '../../services/progress_service.dart';
import 'trip_edit_page.dart';
import 'trips_page.dart';
import '../../services/travel_extras.dart';

/// India Passport: a full-screen map of the states and UTs you've been to.
/// Pinch to zoom, search to fly to any state, tap to mark it.
class IndiaPassportPage extends StatefulWidget {
  final StateTravelService? travelService;
  const IndiaPassportPage({super.key, this.travelService});
  @override
  State<IndiaPassportPage> createState() => _IndiaPassportPageState();
}

class _IndiaPassportPageState extends State<IndiaPassportPage>
    with SingleTickerProviderStateMixin {
  late final travel = widget.travelService ?? StateTravelService();
  final controller = TransformationController();
  final search = TextEditingController();
  final searchFocus = FocusNode();
  late final AnimationController fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  Animation<Matrix4>? flight;
  List<IndiaMapRegion>? regions;
  String? error;
  String? selectedId;
  Size mapSize = Size.zero;
  IndiaExplorationSummary? exploration;
  Map<String, Set<String>> placesByState = {};
  Set<String> placesDone = {};

  @override
  void initState() {
    super.initState();
    fly.addListener(() {
      if (flight case final f?) controller.value = f.value;
    });
    search.addListener(() => setState(() {}));
    searchFocus.addListener(() => setState(() {}));
    _load();
    _loadPlaces();
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

  Future<void> _loadPlaces() async {
    final districts = await const DistrictRepository().loadDistricts();
    final done = await ProgressService.getCompletedDistrictIds();
    if (!mounted) return;
    setState(() {
      placesByState = {};
      for (final d in districts) {
        placesByState.putIfAbsent(d.stateId, () => {}).add(d.id);
      }
      placesDone = done;
    });
  }

  @override
  void dispose() {
    fly.dispose();
    controller.dispose();
    search.dispose();
    searchFocus.dispose();
    if (widget.travelService == null) travel.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- camera

  void _animateTo(Matrix4 target) {
    flight = Matrix4Tween(
      begin: controller.value.clone(),
      end: target,
    ).animate(CurvedAnimation(parent: fly, curve: Curves.easeInOutCubic));
    fly.forward(from: 0);
  }

  /// The camera that frames [id], leaving room for the card at the bottom.
  Matrix4? _frame(String id) {
    final region = regions?.where((r) => r.stateId == id).firstOrNull;
    if (region == null || mapSize.isEmpty) return null;
    final bounds = IndiaPassportMap.fittedPath(region, mapSize).getBounds();
    final focus = Offset(mapSize.width / 2, mapSize.height * .36);
    final scale = [
      mapSize.width * .5 / bounds.width.clamp(0.5, double.infinity),
      mapSize.height * .32 / bounds.height.clamp(0.5, double.infinity),
    ].reduce((a, b) => a < b ? a : b).clamp(1.0, IndiaPassportMap.maxZoom);
    final t = focus - bounds.center * scale;
    return Matrix4.identity()
      ..translateByDouble(t.dx, t.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _zoomBy(double factor, {Offset? at}) {
    final current = controller.value;
    final zoom = current.getMaxScaleOnAxis();
    final target = (zoom * factor).clamp(1.0, IndiaPassportMap.maxZoom);
    if (target == 1.0) return _animateTo(Matrix4.identity());
    // Keep the point under the finger (or the centre) where it is.
    final scene =
        at ??
        MatrixUtils.transformPoint(
          Matrix4.inverted(current),
          mapSize.center(Offset.zero),
        );
    final screen = MatrixUtils.transformPoint(current, scene);
    final t = screen - scene * target;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(t.dx, t.dy, 0, 1)
        ..scaleByDouble(target, target, 1, 1),
    );
  }

  void _doubleTap(Offset scene) {
    final zoom = controller.value.getMaxScaleOnAxis();
    if (zoom >= IndiaPassportMap.maxZoom * .8) {
      _animateTo(Matrix4.identity());
    } else {
      _zoomBy(2.2, at: scene);
    }
  }

  // ---------------------------------------------------------------- select

  void _select(String id, {bool flyTo = true}) {
    searchFocus.unfocus();
    search.clear();
    setState(() => selectedId = id);
    if (flyTo) {
      if (_frame(id) case final target?) _animateTo(target);
    }
  }

  void _tapSelect(String id) {
    final region = regions?.where((r) => r.stateId == id).firstOrNull;
    final small =
        region != null &&
        IndiaPassportMap.fittedPath(region, mapSize).getBounds().width *
                controller.value.getMaxScaleOnAxis() <
            48;
    _select(id, flyTo: small);
  }

  void _deselect() => setState(() => selectedId = null);

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

  List<IndiaLocation> _matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final list = IndiaLocationRegistry.locations
        .where((l) => l.name.toLowerCase().contains(q))
        .toList();
    // Names that start with the query first.
    list.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(q) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(q) ? 0 : 1;
      return aStarts != bStarts
          ? aStarts.compareTo(bStarts)
          : a.name.compareTo(b.name);
    });
    return list;
  }

  // ---------------------------------------------------------------- list

  Future<void> _openList() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StateListSheet(
        travel: travel,
        exploration: exploration,
        onUpdate: _update,
      ),
    );
    if (picked != null && mounted) _select(picked);
  }

  void _openTrips() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const TripsPage()));

  void _openExploreIndia() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ExploreIndiaPage()));

  Future<void> _openGardens() async {
    final visits = (await const AssetDataService().loadChallenges())
        .where((c) => c.id == 'explore_garden_visits')
        .firstOrNull;
    if (visits != null && mounted) await openChallenge(context, visits);
  }

  void _openStats() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          PassportStatsPage(travel: travel, extras: loadPassportExtras),
    ),
  );

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('India Passport'),
      actions: [
        PopupMenuButton<String>(
          key: const ValueKey('passport-more'),
          tooltip: 'More',
          enabled: regions != null,
          onSelected: (value) {
            switch (value) {
              case 'list':
                _openList();
              case 'explore':
                _openExploreIndia();
              case 'share':
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => IndiaPassportSharePage(
                      travel: travel,
                      regions: regions!,
                    ),
                  ),
                );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              key: ValueKey('passport-list'),
              value: 'list',
              child: ListTile(
                leading: Icon(Icons.format_list_bulleted),
                title: Text('All states & UTs'),
              ),
            ),
            PopupMenuItem(
              key: ValueKey('passport-explore-india'),
              value: 'explore',
              child: ListTile(
                leading: Icon(Icons.explore_outlined),
                title: Text('Things to do, by state'),
              ),
            ),
            PopupMenuItem(
              key: ValueKey('passport-share'),
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.ios_share),
                title: Text('Share my passport'),
              ),
            ),
          ],
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
        : ListenableBuilder(
            listenable: travel,
            builder: (context, _) => Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      mapSize = constraints.biggest;
                      return IndiaPassportMap(
                        regions: regions!,
                        travel: travel,
                        selectedId: selectedId,
                        onSelect: _tapSelect,
                        controller: controller,
                        onDoubleTapAt: _doubleTap,
                        onTapEmpty: () {
                          searchFocus.unfocus();
                          _deselect();
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: _searchBar(context),
                ),
                Positioned(
                  right: 12,
                  top: 76,
                  child: _ZoomControls(
                    onIn: () => _zoomBy(2),
                    onOut: () => _zoomBy(.5),
                    onReset: () {
                      _deselect();
                      _animateTo(Matrix4.identity());
                    },
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: SafeArea(
                    top: false,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween(
                          begin: const Offset(0, .25),
                          end: Offset.zero,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: selectedId == null
                          ? _summary(context)
                          : _stateCard(context, selectedId!),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );

  Widget _searchBar(BuildContext context) {
    final results = _matches(search.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 4,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(28),
          color: AppColors.surface,
          child: TextField(
            key: const ValueKey('passport-search'),
            controller: search,
            focusNode: searchFocus,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (results.isNotEmpty) _select(results.first.id);
            },
            decoration: InputDecoration(
              hintText: 'Search states & UTs',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: search.clear,
                    ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (search.text.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 4,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(18),
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No state or UT matches "${search.text.trim()}"',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final l in results)
                          ListTile(
                            key: ValueKey('passport-result-${l.id}'),
                            dense: true,
                            leading: Icon(
                              Icons.circle,
                              size: 12,
                              color: passportColor(travel.statusFor(l.id)),
                            ),
                            title: Text(l.name),
                            subtitle: Text(
                              [
                                IndiaLocationRegistry.isUnionTerritory(l.id)
                                    ? 'Union Territory'
                                    : 'State',
                                if (travel.statusFor(l.id) != TravelStatus.none)
                                  travel.statusFor(l.id).label,
                              ].join(' · '),
                            ),
                            onTap: () => _select(l.id),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summary(BuildContext context) => Material(
    key: const ValueKey('passport-summary'),
    elevation: 6,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(22),
    color: AppColors.surface,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              InkWell(
                key: const ValueKey('passport-ring'),
                customBorder: const CircleBorder(),
                onTap: _openStats,
                child: IndiaPassportRing(
                  ratio:
                      travel.visitedCount /
                      IndiaLocationRegistry.allLocationIds.length,
                  size: 54,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${travel.visitedCount} of 36 visited',
                      key: const ValueKey('passport-visited-count'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${travel.wantToVisitCount} want to visit',
                      key: const ValueKey('passport-wanted-count'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap a state, or search, to mark it',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('passport-all'),
                onPressed: _openList,
                child: const Text('All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (key, icon, label, onTap) in [
                  (
                    'passport-trips',
                    Icons.luggage_outlined,
                    'Trips',
                    _openTrips,
                  ),
                  (
                    'passport-stats',
                    Icons.insights_outlined,
                    'My numbers',
                    _openStats,
                  ),
                  (
                    'passport-explore-states',
                    Icons.explore_outlined,
                    'Things to do',
                    _openExploreIndia,
                  ),
                  (
                    'passport-gardens',
                    Icons.park_outlined,
                    'Famous gardens',
                    _openGardens,
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      key: ValueKey(key),
                      avatar: Icon(icon, size: 18, color: AppColors.primary),
                      label: Text(label),
                      onPressed: onTap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _stateCard(BuildContext context, String id) {
    final status = travel.statusFor(id);
    final visited = status == TravelStatus.visited;
    final wanted = status == TravelStatus.wantToVisit;
    final name = IndiaLocationRegistry.nameFor(id);
    return Material(
      key: ValueKey('passport-card-$id'),
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        [
                          IndiaLocationRegistry.isUnionTerritory(id)
                              ? 'Union Territory'
                              : 'State',
                          '${exploration?.counts[id] ?? 0} things done',
                          if (placesByState[id] case final places?)
                            '${places.where(placesDone.contains).length} of '
                                '${places.length} places',
                        ].join(' · '),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('passport-close'),
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: _deselect,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('passport-visited'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: visited
                        ? AppColors.passportVisited
                        : AppColors.primary,
                  ),
                  onPressed: () => _update(
                    id,
                    visited ? TravelStatus.none : TravelStatus.visited,
                  ),
                  icon: Icon(visited ? Icons.check_circle : Icons.check),
                  label: Text(visited ? 'Visited' : 'Mark as visited'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!visited)
                  OutlinedButton.icon(
                    key: const ValueKey('passport-wanted'),
                    onPressed: () => _update(
                      id,
                      wanted ? TravelStatus.none : TravelStatus.wantToVisit,
                    ),
                    icon: Icon(wanted ? Icons.favorite : Icons.favorite_border),
                    label: Text(wanted ? 'On your list' : 'Want to visit'),
                  ),
                if (status != TravelStatus.none)
                  TextButton(
                    key: const ValueKey('passport-clear'),
                    onPressed: () => _update(id, TravelStatus.none),
                    child: const Text('Unmark'),
                  ),
                if (placesByState[id]?.isNotEmpty ?? false)
                  TextButton.icon(
                    key: const ValueKey('passport-places'),
                    icon: const Icon(Icons.place_outlined),
                    label: Text('Places in $name'),
                    onPressed: () async {
                      await showStatePlacesSheet(
                        context,
                        stateId: id,
                        travel: travel,
                      );
                      await _loadPlaces();
                    },
                  ),
                TextButton.icon(
                  key: const ValueKey('passport-log-trip'),
                  icon: const Icon(Icons.luggage_outlined),
                  label: const Text('Log a trip'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TripEditPage(initialStates: [id]),
                    ),
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('passport-explore'),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('Things to do in $name'),
                  onPressed: () async {
                    await openStateExploration(context, id);
                    final summary = await const StateExplorationRepository()
                        .loadProgress();
                    if (mounted) setState(() => exploration = summary);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final VoidCallback onIn;
  final VoidCallback onOut;
  final VoidCallback onReset;
  const _ZoomControls({
    required this.onIn,
    required this.onOut,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) => Material(
    elevation: 4,
    shadowColor: Colors.black26,
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('passport-zoom-in'),
          tooltip: 'Zoom in',
          icon: const Icon(Icons.add),
          onPressed: onIn,
        ),
        IconButton(
          key: const ValueKey('passport-zoom-out'),
          tooltip: 'Zoom out',
          icon: const Icon(Icons.remove),
          onPressed: onOut,
        ),
        IconButton(
          key: const ValueKey('passport-reset'),
          tooltip: 'Show all of India',
          icon: const Icon(Icons.zoom_out_map),
          onPressed: onReset,
        ),
      ],
    ),
  );
}

/// Every state and UT, with filters and a one-tap visited mark. Tapping a
/// row flies the map there.
class _StateListSheet extends StatefulWidget {
  final StateTravelService travel;
  final IndiaExplorationSummary? exploration;
  final Future<void> Function(String id, TravelStatus status) onUpdate;
  const _StateListSheet({
    required this.travel,
    required this.exploration,
    required this.onUpdate,
  });

  @override
  State<_StateListSheet> createState() => _StateListSheetState();
}

class _StateListSheetState extends State<_StateListSheet> {
  String query = '';
  TravelStatus? filter;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: .8,
    maxChildSize: .95,
    builder: (context, scroll) => ListenableBuilder(
      listenable: widget.travel,
      builder: (context, _) {
        final travel = widget.travel;
        final rows = IndiaLocationRegistry.locations
            .where(
              (l) =>
                  l.name.toLowerCase().contains(query) &&
                  (filter == null || travel.statusFor(l.id) == filter),
            )
            .toList();
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          children: [
            TextField(
              key: const ValueKey('passport-list-search'),
              decoration: const InputDecoration(
                labelText: 'Search States & UTs',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final status in [
                  null,
                  TravelStatus.visited,
                  TravelStatus.wantToVisit,
                  TravelStatus.none,
                ])
                  ChoiceChip(
                    key: ValueKey('passport-filter-${status?.value ?? 'all'}'),
                    label: Text(status?.label ?? 'All'),
                    selected: filter == status,
                    onSelected: (_) => setState(() => filter = status),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No States or UTs match your search and filter.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final l in rows)
              ListTile(
                key: ValueKey('passport-state-${l.id}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Icon(
                  Icons.circle,
                  size: 12,
                  color: passportColor(travel.statusFor(l.id)),
                ),
                title: Text(l.name),
                subtitle: Text(
                  '${widget.exploration?.counts[l.id] ?? 0} things done',
                ),
                trailing: IconButton(
                  key: ValueKey('passport-toggle-${l.id}'),
                  tooltip: travel.statusFor(l.id) == TravelStatus.visited
                      ? 'Visited'
                      : 'Mark as visited',
                  icon: Icon(
                    travel.statusFor(l.id) == TravelStatus.visited
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: travel.statusFor(l.id) == TravelStatus.visited
                        ? AppColors.passportVisited
                        : AppColors.muted,
                  ),
                  onPressed: () => widget.onUpdate(
                    l.id,
                    travel.statusFor(l.id) == TravelStatus.visited
                        ? TravelStatus.none
                        : TravelStatus.visited,
                  ),
                ),
                onTap: () => Navigator.pop(context, l.id),
              ),
          ],
        );
      },
    ),
  );
}
