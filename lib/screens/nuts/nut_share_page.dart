import 'package:flutter/material.dart';

import '../../models/nut.dart';
import '../../models/share_branding_config.dart';
import '../../models/share_highlight.dart';
import '../../services/nut_service.dart';
import '../../services/share_studio_service.dart';
import '../../theme/app_colors.dart';
import 'nut_detail_page.dart';

/// What you've tasted, ready for a card.
class NutPassport {
  final NutAtlas atlas;
  final Set<String> tried;
  final Map<String, NutTasting> tastings;
  const NutPassport(this.atlas, this.tried, this.tastings);

  Set<String> get origins => atlas.originCountries(tried);
  Set<String> get continents => {
    for (final c in origins) atlas.country(c).continent,
  };

  /// Most recent first.
  List<(Nut, NutTasting?)> get latest {
    final list = [
      for (final n in atlas.nuts)
        if (tried.contains(n.id)) (n, tastings[n.id]),
    ];
    list.sort(
      (a, b) =>
          (b.$2?.at ?? DateTime(2000)).compareTo(a.$2?.at ?? DateTime(2000)),
    );
    return list;
  }

  String shareText({String appName = 'UPLYFA'}) {
    final n = tried.length;
    final c = origins.length;
    return "I've tasted $n ${n == 1 ? 'nut' : 'nuts'} from "
        '$c ${c == 1 ? 'country' : 'countries'}. Made with $appName.';
  }
}

/// Preview and share "My nut passport".
class NutSharePage extends StatefulWidget {
  final ShareStudioService service;
  final ShareBrandingConfig branding;
  const NutSharePage({
    super.key,
    this.service = const ShareStudioService(),
    this.branding = const ShareBrandingConfig(),
  });

  @override
  State<NutSharePage> createState() => _NutSharePageState();
}

class _NutSharePageState extends State<NutSharePage> {
  final boundary = GlobalKey();
  ShareCardFormat format = ShareCardFormat.story;
  NutPassport? passport;
  bool sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = NutPassport(
      await NutService.atlas(),
      await NutService.triedIds(),
      await NutService.tastings(),
    );
    if (mounted) setState(() => passport = p);
  }

  Future<void> _share() async {
    final p = passport;
    if (p == null) return;
    setState(() => sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await widget.service.shareCard(
        boundaryKey: boundary,
        text: p.shareText(appName: widget.branding.appName),
        origin: box.localToGlobal(Offset.zero) & box.size,
        fileName: 'my-nut-passport.png',
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
    appBar: AppBar(title: const Text('Share my nut passport')),
    body: SafeArea(
      child: passport == null
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
                        : (v) => setState(() => format = v.single),
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
                        child: NutPassportCard(
                          passport: passport!,
                          format: format,
                          branding: widget.branding,
                        ),
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Only shared when you tap Share.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    key: const ValueKey('nut-share-action'),
                    onPressed: sharing || passport!.tried.isEmpty
                        ? null
                        : _share,
                    icon: const Icon(Icons.ios_share),
                    label: Text(
                      passport!.tried.isEmpty
                          ? 'Taste a nut to share'
                          : sharing
                          ? 'Preparing…'
                          : 'Share',
                    ),
                  ),
                ),
              ],
            ),
    ),
  );
}

/// The card: how many nuts, how many countries, their flags, your latest.
class NutPassportCard extends StatelessWidget {
  final NutPassport passport;
  final ShareCardFormat format;
  final ShareBrandingConfig branding;
  const NutPassportCard({
    super.key,
    required this.passport,
    this.format = ShareCardFormat.story,
    this.branding = const ShareBrandingConfig(),
  });

  static const _brown = Color(0xFF7A4B22);
  static const _ink = Color(0xFF2E1D0E);

  @override
  Widget build(BuildContext context) {
    final story = format == ShareCardFormat.story;
    final p = passport;
    final n = p.tried.length;
    final origins = p.origins.toList();
    final latest = p.latest.take(story ? 4 : 2).toList();

    TextStyle style(double size, {FontWeight weight = FontWeight.w500}) =>
        TextStyle(
          inherit: false,
          fontFamily: 'Roboto',
          fontSize: size,
          fontWeight: weight,
          height: 1.25,
          color: _ink,
        );

    return AspectRatio(
      aspectRatio: story ? 9 / 16 : 1,
      child: FittedBox(
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
                  colors: [Color(0xFFFBF3E6), Color(0xFFEBD5B5)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.spa_outlined, size: 18, color: _brown),
                        const SizedBox(width: 6),
                        Text(
                          'My Nut Passport',
                          style: style(13, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                    SizedBox(height: story ? 26 : 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        n == 0
                            ? 'Ready to taste the world'
                            : '$n ${n == 1 ? 'nut' : 'nuts'} tasted',
                        style: style(story ? 34 : 26, weight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (n > 0)
                      Text(
                        'from ${origins.length} '
                        '${origins.length == 1 ? 'country' : 'countries'} on '
                        '${p.continents.length} '
                        '${p.continents.length == 1 ? 'continent' : 'continents'}',
                        style: style(14),
                      ),
                    SizedBox(height: story ? 20 : 10),
                    if (origins.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final c in origins.take(story ? 24 : 12))
                            Text(
                              p.atlas.country(c).flag,
                              style: TextStyle(
                                inherit: false,
                                fontSize: story ? 26 : 20,
                              ),
                            ),
                        ],
                      ),
                    SizedBox(height: story ? 22 : 10),
                    for (final (nut, t) in latest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: _brown,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t?.note?.isNotEmpty == true
                                    ? '${nut.name} · ${t!.note}'
                                    : nut.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style(14, weight: FontWeight.w700),
                              ),
                            ),
                            if (t != null)
                              Text(nutDate(t.at), style: style(11)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Align(
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
}
