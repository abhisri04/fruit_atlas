import '../../widgets/dish_artwork.dart';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/share_highlight.dart';
import '../../models/app_branding.dart';
import '../../services/share_studio_service.dart';
import '../../theme/app_colors.dart';

class ShareStudioPage extends StatefulWidget {
  final List<ShareHighlightItem>? completedItems;
  final ShareStudioService service;
  final ShareStudioPreferences preferences;

  const ShareStudioPage({
    super.key,
    this.completedItems,
    this.service = const ShareStudioService(),
    this.preferences = const ShareStudioPreferences(),
  });

  @override
  State<ShareStudioPage> createState() => _ShareStudioPageState();
}

class _ShareStudioPageState extends State<ShareStudioPage> {
  ShareHighlightController? controller;
  String query = '';
  ShareHighlightCategory? category;
  Object? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        widget.completedItems == null
            ? widget.service.loadCompletedHighlights()
            : Future.value(widget.completedItems!),
        widget.preferences.load(),
      ]);
      final items = values[0] as List<ShareHighlightItem>;
      final saved =
          values[1]
              as ({
                HighlightSelectionMode mode,
                ShareCardFormat format,
                List<String> selectedReferences,
              });
      final loaded = ShareHighlightController(
        completedItems: items,
        mode: saved.mode,
        format: saved.format,
        selectedReferences: saved.selectedReferences,
      );
      if (!mounted) return;
      setState(() => controller = loaded);
      await widget.preferences.save(loaded);
    } catch (caught) {
      if (mounted) setState(() => error = caught);
    }
  }

  Future<void> _save() async {
    final value = controller;
    if (value != null) await widget.preferences.save(value);
  }

  void _change(VoidCallback action) {
    setState(action);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final value = controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Share Studio')),
      body: value != null
          ? _buildContent(value)
          : error != null
          ? _LoadError(message: error.toString(), retry: _load)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent(ShareHighlightController value) {
    final visible = value.visibleItems(query: query, category: category);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const Text(
          'My Journey',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Turn your completed experiences into a personal highlights card.',
          style: TextStyle(color: AppColors.muted, height: 1.35),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Card format'),
        const SizedBox(height: 8),
        SegmentedButton<ShareCardFormat>(
          key: const ValueKey('share-format-control'),
          segments: [
            for (final format in ShareCardFormat.values)
              ButtonSegment(value: format, label: Text(format.label)),
          ],
          selected: {value.format},
          onSelectionChanged: (selection) => _change(() {
            value.setFormat(selection.single);
          }),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Choose highlights'),
        const SizedBox(height: 8),
        SegmentedButton<HighlightSelectionMode>(
          key: const ValueKey('share-selection-mode'),
          segments: const [
            ButtonSegment(
              value: HighlightSelectionMode.auto,
              icon: Icon(Icons.auto_awesome_outlined),
              label: Text('Auto'),
            ),
            ButtonSegment(
              value: HighlightSelectionMode.manual,
              icon: Icon(Icons.touch_app_outlined),
              label: Text('Pick myself'),
            ),
          ],
          selected: {value.mode},
          onSelectionChanged: (selection) => _change(() {
            value.mode = selection.single;
          }),
        ),
        if (value.mode == HighlightSelectionMode.manual) ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '${value.selectedReferences.length} / ${value.limit} selected',
                key: const ValueKey('share-selection-count'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                key: const ValueKey('share-auto-fill'),
                onPressed: value.completedItems.isEmpty
                    ? null
                    : () => _change(value.autoFill),
                child: const Text('Auto-fill'),
              ),
              TextButton(
                key: const ValueKey('share-clear-all'),
                onPressed: value.selectedReferences.isEmpty
                    ? null
                    : () => _change(value.clear),
                child: const Text('Clear all'),
              ),
            ],
          ),
          TextField(
            key: const ValueKey('share-picker-search'),
            decoration: const InputDecoration(
              hintText: 'Search completed experiences',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (text) => setState(() => query = text),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    key: const ValueKey('share-filter-all'),
                    label: const Text('All'),
                    selected: category == null,
                    onSelected: (_) => setState(() => category = null),
                  ),
                ),
                for (final option in ShareHighlightCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      key: ValueKey('share-filter-${option.name}'),
                      avatar: Icon(_categoryIcon(option), size: 17),
                      label: Text(option.label),
                      selected: category == option,
                      onSelected: (_) => setState(() => category = option),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No completed experiences match.')),
            )
          else
            GridView.builder(
              key: const ValueKey('share-picker-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, index) {
                final item = visible[index];
                return _PickerTile(
                  item: item,
                  selected: value.selectedReferences.contains(item.reference),
                  onTap: () {
                    final changed = value.toggle(item.reference);
                    if (!changed &&
                        !value.selectedReferences.contains(item.reference)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You can select up to ${value.limit} highlights for ${value.format.label}.',
                          ),
                        ),
                      );
                      return;
                    }
                    _change(() {});
                  },
                );
              },
            ),
        ],
        const SizedBox(height: 26),
        _SectionLabel(label: 'Preview'),
        const SizedBox(height: 10),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: value.format == ShareCardFormat.story ? 300 : 360,
            ),
            child: AspectRatio(
              aspectRatio: value.format == ShareCardFormat.story ? 9 / 16 : 1,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _HighlightsPreview(
                  key: ValueKey(
                    '${value.mode.name}-${value.format.name}-${value.previewItems.map((item) => item.reference).join(',')}',
                  ),
                  items: value.previewItems,
                  format: value.format,
                  onAutoFill: value.mode == HighlightSelectionMode.manual
                      ? () => _change(value.autoFill)
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const ValueKey('share-highlights-action'),
          onPressed: value.previewItems.isEmpty ? null : () => _share(value),
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('Share my journey'),
        ),
      ],
    );
  }

  Future<void> _share(ShareHighlightController value) async {
    final lines = value.previewItems.map((item) => '• ${item.title}');
    await SharePlus.instance.share(
      ShareParams(
        text: [
          'My journey highlights',
          '',
          ...lines,
          '',
          AppBranding.shareSignature,
        ].join('\n'),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
  );
}

class _PickerTile extends StatelessWidget {
  final ShareHighlightItem item;
  final bool selected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('share-item-${item.reference}'),
      color: selected ? AppColors.accentSurface : AppColors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outline,
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _categoryColor(item.category)
                    .withValues(alpha: .14),
                child: Icon(
                  _categoryIcon(item.category),
                  color: _categoryColor(item.category),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      item.category.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightsPreview extends StatelessWidget {
  final List<ShareHighlightItem> items;
  final ShareCardFormat format;
  final VoidCallback? onAutoFill;

  const _HighlightsPreview({
    super.key,
    required this.items,
    required this.format,
    this.onAutoFill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('share-highlights-preview'),
      padding: EdgeInsets.all(format == ShareCardFormat.story ? 18 : 16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MY JOURNEY',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Life in highlights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? _EmptyPreview(onAutoFill: onAutoFill)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = ShareHighlightLayout.columns(
                        items.length,
                        format,
                      );
                      final rows = (items.length / columns).ceil();
                      final cellWidth =
                          (constraints.maxWidth - (columns - 1) * 7) / columns;
                      final cellHeight =
                          (constraints.maxHeight - (rows - 1) * 7) / rows;
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 7,
                          mainAxisSpacing: 7,
                          childAspectRatio: cellWidth / cellHeight,
                        ),
                        itemBuilder: (context, index) =>
                            _PreviewItem(item: items[index]),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            '${items.length} completed experiences',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '${AppBranding.appName} · ${AppBranding.tagline}',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final ShareHighlightItem item;
  const _PreviewItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.dish != null)
            DishArtwork(
              dish: item.dish!,
              variant: DishArtworkVariant.thumbnail,
              width: 36,
              height: 30,
            )
          else
            Icon(
              _categoryIcon(item.category),
              color: _categoryColor(item.category),
              size: 19,
            ),
          const SizedBox(height: 4),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  final VoidCallback? onAutoFill;
  const _EmptyPreview({this.onAutoFill});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          color: Colors.white70,
          size: 34,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose completed experiences\nto build your card.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        if (onAutoFill != null) ...[
          const SizedBox(height: 10),
          TextButton(onPressed: onAutoFill, child: const Text('Auto-fill')),
        ],
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _LoadError({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          const Text('Share Studio could not load.'),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

IconData _categoryIcon(ShareHighlightCategory category) => switch (category) {
  ShareHighlightCategory.fruit => Icons.eco_outlined,
  ShareHighlightCategory.dish => Icons.restaurant_outlined,
  ShareHighlightCategory.drink => Icons.local_cafe_outlined,
  ShareHighlightCategory.book => Icons.menu_book_outlined,
  ShareHighlightCategory.yoga => Icons.self_improvement,
  ShareHighlightCategory.travel => Icons.explore_outlined,
  ShareHighlightCategory.pilgrimage => Icons.temple_hindu_outlined,
};

Color _categoryColor(ShareHighlightCategory category) => switch (category) {
  ShareHighlightCategory.fruit ||
  ShareHighlightCategory.dish ||
  ShareHighlightCategory.drink => AppColors.gold,
  ShareHighlightCategory.book => const Color(0xFFDFA17D),
  ShareHighlightCategory.yoga => const Color(0xFFB69BFF),
  ShareHighlightCategory.travel => const Color(0xFF65C7F0),
  ShareHighlightCategory.pilgrimage => const Color(0xFFFF9D73),
};
