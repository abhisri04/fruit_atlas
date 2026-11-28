import 'package:flutter/material.dart';

import '../../models/my_garden.dart';
import '../../models/share_branding_config.dart';
import '../../models/share_highlight.dart';
import '../../services/my_garden_service.dart';
import '../../services/share_studio_service.dart';
import '../../theme/app_colors.dart';
import 'garden_sheets.dart';

const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The words that go with the card when it is shared.
String gardenShareText(MyGarden garden, {String appName = 'UPLYFA'}) {
  final growing = garden.growing.length;
  final parts = [
    growing == 1 ? '1 plant growing' : '$growing plants growing',
    for (final (plant, moment, _) in garden.milestones().take(2))
      '${moment.firstLabel.toLowerCase()} from my ${plant.name}',
  ];
  return 'My garden: ${parts.join(', ')}. Made with $appName.';
}

/// Preview and share My Garden as a story or square card.
class MyGardenSharePage extends StatefulWidget {
  final ShareStudioService service;
  final ShareBrandingConfig branding;
  const MyGardenSharePage({
    super.key,
    this.service = const ShareStudioService(),
    this.branding = const ShareBrandingConfig(),
  });

  @override
  State<MyGardenSharePage> createState() => _MyGardenSharePageState();
}

class _MyGardenSharePageState extends State<MyGardenSharePage> {
  final boundary = GlobalKey();
  ShareCardFormat format = ShareCardFormat.story;
  MyGarden? garden;
  bool sharing = false;

  @override
  void initState() {
    super.initState();
    MyGardenService.load().then((value) {
      if (mounted) setState(() => garden = value);
    });
  }

  Future<void> _share() async {
    final current = garden;
    if (current == null) return;
    setState(() => sharing = true);
    try {
      // Let photos finish loading before capturing.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await widget.service.shareCard(
        boundaryKey: boundary,
        text: gardenShareText(current, appName: widget.branding.appName),
        origin: box.localToGlobal(Offset.zero) & box.size,
        fileName: 'my-garden.png',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share your garden. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Share My Garden')),
    body: SafeArea(
      child: garden == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: RepaintBoundary(
                        key: boundary,
                        child: MyGardenShareCard(
                          garden: garden!,
                          format: format,
                          branding: widget.branding,
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Only shared when you tap Share.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    key: const ValueKey('garden-share-action'),
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

/// A garden card worth posting: photos, what grows, and the latest firsts.
class MyGardenShareCard extends StatelessWidget {
  final MyGarden garden;
  final ShareCardFormat format;
  final ShareBrandingConfig branding;

  const MyGardenShareCard({
    super.key,
    required this.garden,
    this.format = ShareCardFormat.story,
    this.branding = const ShareBrandingConfig(),
  });

  static const _green = Color(0xFF2F6F3E);
  static const _ink = Color(0xFF17301E);

  @override
  Widget build(BuildContext context) {
    final story = format == ShareCardFormat.story;
    final photos = garden.recentPhotos(limit: story ? 3 : 2);
    final growing = garden.growing.length;
    final counts = garden.typeCounts().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final firsts = garden.milestones().take(story ? 3 : 1).toList();
    final kinds = _naturalJoin([
      for (final c in counts)
        if (c.key != 'Other') c.key.toLowerCase(),
    ]);
    final since = garden.plants.values
        .map((p) => p.addedAt)
        .reduce((a, b) => b.isBefore(a) ? b : a);
    final harvests = garden.logs
        .where((l) => l.moment == GardenMoment.harvested)
        .length;

    TextStyle style(double size, {FontWeight weight = FontWeight.w500}) =>
        TextStyle(
          inherit: false,
          fontFamily: 'Roboto',
          fontSize: size,
          fontWeight: weight,
          height: 1.25,
          color: _ink,
        );

    final hero = photos.isEmpty
        ? Container(
            height: story ? 170 : 80,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.yard_outlined,
              size: story ? 72 : 48,
              color: _green,
            ),
          )
        : SizedBox(
            height: story ? 170 : 96,
            child: Row(
              children: [
                for (final (i, id) in photos.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => GardenPhoto(
                        photoId: id,
                        size: c.maxWidth,
                        height: c.maxHeight,
                        radius: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
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
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3F8EC), Color(0xFFDDEBD3)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.yard_outlined,
                          size: 18,
                          color: _green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'My Garden',
                          style: style(13, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    SizedBox(height: story ? 16 : 10),
                    hero,
                    SizedBox(height: story ? 20 : 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        growing == 1
                            ? '1 plant growing'
                            : '$growing plants growing',
                        style: style(story ? 30 : 24, weight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (kinds.isNotEmpty)
                      Text(
                        'Growing $kinds',
                        maxLines: story ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(13),
                      ),
                    SizedBox(height: story ? 22 : 12),
                    for (final (plant, moment, at) in firsts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              gardenMomentIcon(moment),
                              size: 18,
                              color: _green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${moment.firstLabel}: ${plant.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style(14, weight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              '${_monthShort[at.month - 1]} ${at.year}',
                              style: style(12),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        _stat(
                          '${_monthShort[since.month - 1]} ${since.year}',
                          'gardening since',
                          style,
                        ),
                        _stat('${garden.milestones().length}', 'firsts', style),
                        _stat('$harvests', 'harvests', style),
                      ],
                    ),
                    SizedBox(height: story ? 18 : 10),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Made with ${branding.appName} · ${branding.tagline}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(10)
                            .copyWith(color: _ink.withValues(alpha: .6)),
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

  static Widget _stat(
    String value,
    String label,
    TextStyle Function(double, {FontWeight weight}) style,
  ) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style(16, weight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style(11),
        ),
      ],
    ),
  );
}

/// "vegetables, herbs and flowers".
String _naturalJoin(List<String> items) => switch (items.length) {
  0 => '',
  1 => items.single,
  _ => '${items.take(items.length - 1).join(', ')} and ${items.last}',
};
