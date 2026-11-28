import 'package:flutter/material.dart';

import '../../models/india_passport_share_data.dart';
import '../../models/share_branding_config.dart';
import '../../models/share_highlight.dart';
import '../../services/india_map_repository.dart';
import '../../services/share_studio_service.dart';
import '../../services/state_travel_service.dart';
import '../../widgets/india_passport_share_card.dart';

class IndiaPassportSharePage extends StatefulWidget {
  final StateTravelService travel;
  final List<IndiaMapRegion> regions;
  final ShareStudioService service;
  final ShareBrandingConfig branding;
  final String? displayName;
  const IndiaPassportSharePage({
    super.key,
    required this.travel,
    required this.regions,
    this.service = const ShareStudioService(),
    this.branding = const ShareBrandingConfig(),
    this.displayName,
  });
  @override
  State<IndiaPassportSharePage> createState() => _IndiaPassportSharePageState();
}

class _IndiaPassportSharePageState extends State<IndiaPassportSharePage> {
  final boundary = GlobalKey();
  ShareCardFormat format = ShareCardFormat.story;
  bool sharing = false;
  @override
  void initState() {
    super.initState();
    StateTravelService.changes.addListener(_reload);
  }

  void _reload() {
    widget.travel.load();
  }

  @override
  void dispose() {
    StateTravelService.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _share() async {
    setState(() => sharing = true);
    try {
      // Let pending map/ring updates finish before capturing the card only.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await widget.service.shareCard(
        boundaryKey: boundary,
        text: IndiaPassportShareData(widget.travel).shareText,
        origin: box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share your passport. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('India Passport')),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: ListenableBuilder(
                  listenable: widget.travel,
                  builder: (_, _) => RepaintBoundary(
                    key: boundary,
                    child: IndiaPassportShareCard(
                      data: IndiaPassportShareData(widget.travel),
                      regions: widget.regions,
                      format: format,
                      branding: widget.branding,
                      displayName: widget.displayName,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const ValueKey('passport-share-action'),
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
