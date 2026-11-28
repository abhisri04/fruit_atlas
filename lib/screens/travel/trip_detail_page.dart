import 'package:flutter/material.dart';

import '../../models/india_location_registry.dart';
import '../../models/share_branding_config.dart';
import '../../models/share_highlight.dart';
import '../../models/trip.dart';
import '../../services/india_map_repository.dart';
import '../../services/share_studio_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/india_passport_map.dart';
import 'trip_edit_page.dart';
import 'trips_page.dart';

/// One trip: photo, dates, places, the memory, and a share card.
class TripDetailPage extends StatefulWidget {
  final String tripId;
  const TripDetailPage({super.key, required this.tripId});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  Trip? trip;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    TripService.changes.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    TripService.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final log = await TripService.load();
    if (!mounted) return;
    setState(() {
      trip = log.trips.where((t) => t.id == widget.tripId).firstOrNull;
      loading = false;
    });
  }

  Future<void> _delete(Trip t) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${t.title}?'),
        content: const Text(
          'The trip and its photo are removed. Your India Passport stamps '
          'stay, because you were still there.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const ValueKey('trip-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await TripService.delete(t.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = trip;
    if (loading || t == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : const Text('This trip is no longer here.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(t.title),
        actions: [
          IconButton(
            key: const ValueKey('trip-share'),
            tooltip: 'Share this trip',
            icon: const Icon(Icons.ios_share),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripSharePage(trip: t)),
            ),
          ),
          PopupMenuButton<String>(
            key: const ValueKey('trip-more'),
            onSelected: (value) async {
              if (value == 'edit') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TripEditPage(trip: t)),
                );
              } else if (value == 'delete') {
                await _delete(t);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                key: ValueKey('trip-edit'),
                value: 'edit',
                child: Text('Edit trip'),
              ),
              PopupMenuItem(
                key: ValueKey('trip-delete'),
                value: 'delete',
                child: Text('Delete trip'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          if (t.photoId != null) ...[
            LayoutBuilder(
              builder: (context, c) => TripPhoto(
                photoId: t.photoId,
                width: c.maxWidth,
                height: 220,
                radius: 20,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${tripRange(t)} · ${t.days == 1 ? '1 day' : '${t.days} days'}',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (t.companions?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              'With ${t.companions}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in t.stateIds)
                Chip(
                  avatar: const Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: AppColors.passportVisited,
                  ),
                  label: Text(IndiaLocationRegistry.nameFor(id)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 220, child: TripMap(stateIds: t.stateIds)),
          if (t.note?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.caution,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(t.note!, style: const TextStyle(height: 1.45)),
            ),
          ],
        ],
      ),
    );
  }
}

/// India with a trip's places highlighted.
class TripMap extends StatelessWidget {
  final List<String> stateIds;
  final Color background;
  const TripMap({
    super.key,
    required this.stateIds,
    this.background = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: IndiaMapRepository.load(),
    builder: (context, snapshot) => ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: background,
        child: snapshot.data == null
            ? const SizedBox.expand()
            : Padding(
                padding: const EdgeInsets.all(10),
                child: CustomPaint(
                  painter: _TripMapPainter(snapshot.data!, stateIds.toSet()),
                  child: const SizedBox.expand(),
                ),
              ),
      ),
    ),
  );
}

class _TripMapPainter extends CustomPainter {
  final List<IndiaMapRegion> regions;
  final Set<String> highlight;
  _TripMapPainter(this.regions, this.highlight);

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final path = IndiaPassportMap.fittedPath(region, size);
      final on = highlight.contains(region.stateId);
      canvas.drawPath(
        path,
        Paint()
          ..color = on
              ? AppColors.passportSelected
              : AppColors.passportUnmarked.withValues(
                  alpha: region.stateId == 'lakshadweep' ? .2 : 1,
                ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.navyRaised
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6,
      );
      if (on && path.getBounds().width < 6) {
        // Tiny places get a dot so they're visible.
        canvas.drawCircle(
          path.getBounds().center,
          4,
          Paint()..color = AppColors.passportSelected,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TripMapPainter old) =>
      old.highlight != highlight || old.regions != regions;
}

/// Share a trip as a story or square card.
class TripSharePage extends StatefulWidget {
  final Trip trip;
  final ShareStudioService service;
  final ShareBrandingConfig branding;
  const TripSharePage({
    super.key,
    required this.trip,
    this.service = const ShareStudioService(),
    this.branding = const ShareBrandingConfig(),
  });

  @override
  State<TripSharePage> createState() => _TripSharePageState();
}

class _TripSharePageState extends State<TripSharePage> {
  final boundary = GlobalKey();
  ShareCardFormat format = ShareCardFormat.story;
  bool sharing = false;

  Future<void> _share() async {
    setState(() => sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      final t = widget.trip;
      await widget.service.shareCard(
        boundaryKey: boundary,
        text:
            '${t.title}: ${t.days == 1 ? '1 day' : '${t.days} days'} in '
            '${t.stateIds.map(IndiaLocationRegistry.nameFor).join(', ')}. '
            'Made with ${widget.branding.appName}.',
        origin: box.localToGlobal(Offset.zero) & box.size,
        fileName: 'trip.png',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to share. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Share trip')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<ShareCardFormat>(
              segments: [
                for (final value in ShareCardFormat.values)
                  ButtonSegment(value: value, label: Text(value.label)),
              ],
              selected: {format},
              onSelectionChanged: sharing
                  ? null
                  : (values) => setState(() => format = values.single),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RepaintBoundary(
                  key: boundary,
                  child: TripShareCard(
                    trip: widget.trip,
                    format: format,
                    branding: widget.branding,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const ValueKey('trip-share-action'),
              onPressed: sharing ? null : _share,
              icon: const Icon(Icons.ios_share),
              label: Text(sharing ? 'Preparing…' : 'Share'),
            ),
          ),
        ],
      ),
    ),
  );
}

class TripShareCard extends StatelessWidget {
  final Trip trip;
  final ShareCardFormat format;
  final ShareBrandingConfig branding;
  const TripShareCard({
    super.key,
    required this.trip,
    this.format = ShareCardFormat.story,
    this.branding = const ShareBrandingConfig(),
  });

  @override
  Widget build(BuildContext context) {
    final story = format == ShareCardFormat.story;
    TextStyle style(double size, {FontWeight weight = FontWeight.w500}) =>
        TextStyle(
          inherit: false,
          fontFamily: 'Roboto',
          fontSize: size,
          fontWeight: weight,
          height: 1.25,
          color: Colors.white,
        );
    return AspectRatio(
      aspectRatio: story ? 9 / 16 : 1,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 360,
          height: story ? 640 : 360,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: AppColors.navy,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.luggage_outlined,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'My trip',
                          style: style(13, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    SizedBox(height: story ? 14 : 8),
                    if (trip.photoId != null && story) ...[
                      LayoutBuilder(
                        builder: (context, c) => TripPhoto(
                          photoId: trip.photoId,
                          width: c.maxWidth,
                          height: 180,
                          radius: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      trip.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style(story ? 28 : 22, weight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tripRange(trip)} · '
                      '${trip.days == 1 ? '1 day' : '${trip.days} days'}',
                      style: style(13)
                          .copyWith(color: Colors.white.withValues(alpha: .8)),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TripMap(
                        stateIds: trip.stateIds,
                        background: AppColors.navyRaised,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      trip.stateIds
                          .map(IndiaLocationRegistry.nameFor)
                          .join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style(
                        13,
                        weight: FontWeight.w700,
                      ).copyWith(color: AppColors.gold),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Made with ${branding.appName} · ${branding.tagline}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(
                          10,
                        ).copyWith(color: Colors.white.withValues(alpha: .6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
