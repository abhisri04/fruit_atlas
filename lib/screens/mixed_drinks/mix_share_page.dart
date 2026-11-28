import 'package:flutter/material.dart';

import '../../models/mixed_drink.dart';
import '../../models/share_branding_config.dart';
import '../../models/share_highlight.dart';
import '../../services/drink_mix_service.dart';
import '../../services/share_studio_service.dart';
import '../../theme/app_colors.dart';
import 'mix_widgets.dart';

/// What you've mixed, ready for a card.
class MixBook {
  final DrinkBook book;
  final Set<String> made;
  final Map<String, DrinkMade> records;
  const MixBook(this.book, this.made, this.records);

  Set<String> get origins => book.originCountries(made);
  int get mocktails =>
      book.drinks.where((d) => made.contains(d.id) && !d.isCocktail).length;
  int get cocktails =>
      book.drinks.where((d) => made.contains(d.id) && d.isCocktail).length;

  /// Most recent first.
  List<(MixedDrink, DrinkMade?)> get latest {
    final list = [
      for (final d in book.drinks)
        if (made.contains(d.id)) (d, records[d.id]),
    ];
    list.sort(
      (a, b) =>
          (b.$2?.at ?? DateTime(2000)).compareTo(a.$2?.at ?? DateTime(2000)),
    );
    return list;
  }

  String shareText({String appName = 'UPLYFA'}) {
    final n = made.length;
    final c = origins.length;
    return "I've mixed $n ${n == 1 ? 'drink' : 'drinks'} from "
        '$c ${c == 1 ? 'country' : 'countries'} at home. Made with $appName.';
  }
}

/// Preview and share "My mix book".
class MixSharePage extends StatefulWidget {
  final ShareStudioService service;
  final ShareBrandingConfig branding;
  const MixSharePage({
    super.key,
    this.service = const ShareStudioService(),
    this.branding = const ShareBrandingConfig(),
  });

  @override
  State<MixSharePage> createState() => _MixSharePageState();
}

class _MixSharePageState extends State<MixSharePage> {
  final boundary = GlobalKey();
  ShareCardFormat format = ShareCardFormat.story;
  MixBook? book;
  bool sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = MixBook(
      await DrinkMixService.book(),
      await DrinkMixService.madeIds(),
      await DrinkMixService.made(),
    );
    if (mounted) setState(() => book = b);
  }

  Future<void> _share() async {
    final b = book;
    if (b == null) return;
    setState(() => sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await widget.service.shareCard(
        boundaryKey: boundary,
        text: b.shareText(appName: widget.branding.appName),
        origin: box.localToGlobal(Offset.zero) & box.size,
        fileName: 'my-mix-book.png',
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
    appBar: AppBar(title: const Text('Share my mix book')),
    body: SafeArea(
      child: book == null
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
                        child: MixBookCard(
                          book: book!,
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
                    key: const ValueKey('mix-share-action'),
                    onPressed: sharing || book!.made.isEmpty ? null : _share,
                    icon: const Icon(Icons.ios_share),
                    label: Text(
                      book!.made.isEmpty
                          ? 'Make a drink to share'
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

/// The card: how many drinks, from how many countries, and your latest.
class MixBookCard extends StatelessWidget {
  final MixBook book;
  final ShareCardFormat format;
  final ShareBrandingConfig branding;
  const MixBookCard({
    super.key,
    required this.book,
    this.format = ShareCardFormat.story,
    this.branding = const ShareBrandingConfig(),
  });

  static const _accent = Color(0xFF2E8B6E);
  static const _ink = Color(0xFF12322A);

  @override
  Widget build(BuildContext context) {
    final story = format == ShareCardFormat.story;
    final p = book;
    final n = p.made.length;
    final origins = p.origins.toList();
    final latest = p.latest.take(story ? 5 : 2).toList();
    final split = [
      if (p.mocktails > 0)
        '${p.mocktails} ${p.mocktails == 1 ? 'mocktail' : 'mocktails'}',
      if (p.cocktails > 0)
        '${p.cocktails} ${p.cocktails == 1 ? 'cocktail' : 'cocktails'}',
    ].join(' · ');

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
                  colors: [Color(0xFFEFFAF4), Color(0xFFFFE3C7)],
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
                          Icons.local_bar_outlined,
                          size: 18,
                          color: _accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'My Mix Book',
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
                            ? 'Ready to mix'
                            : '$n ${n == 1 ? 'drink' : 'drinks'} made',
                        style: style(story ? 34 : 26, weight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (n > 0)
                      Text(
                        '$split · recipes from ${origins.length} '
                        '${origins.length == 1 ? 'country' : 'countries'}',
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
                              p.book.country(c).flag,
                              style: TextStyle(
                                inherit: false,
                                fontSize: story ? 26 : 20,
                              ),
                            ),
                        ],
                      ),
                    SizedBox(height: story ? 22 : 10),
                    for (final (drink, r) in latest)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: _accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r?.note?.isNotEmpty == true
                                    ? '${drink.name} · ${r!.note}'
                                    : drink.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style(14, weight: FontWeight.w700),
                              ),
                            ),
                            if (r != null)
                              Text(mixDate(r.at), style: style(11)),
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
