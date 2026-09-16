import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'circular_progress_widget.dart';

class ExplorationSectionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int completedCount;
  final int totalCount;
  final bool initiallyExpanded;
  final bool showProgress;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const ExplorationSectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.completedCount,
    required this.totalCount,
    this.initiallyExpanded = false,
    this.showProgress = true,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  State<ExplorationSectionCard> createState() => _ExplorationSectionCardState();
}

class _ExplorationSectionCardState extends State<ExplorationSectionCard> {
  final headerKey = GlobalKey();
  late bool isExpanded = widget.initiallyExpanded;

  void toggle() {
    setState(() => isExpanded = !isExpanded);
    if (!isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final headerContext = headerKey.currentContext;
        if (headerContext != null) {
          Scrollable.ensureVisible(
            headerContext,
            alignment: 0.05,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final extent = widget.subtitle == null ? 66.0 : 78.0;
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 10),
          sliver: SliverPersistentHeader(
            pinned: isExpanded,
            delegate: _SectionHeaderDelegate(
              extent: extent,
              child: KeyedSubtree(
                key: headerKey,
                child: _SectionHeader(
                  icon: widget.icon,
                  title: widget.title,
                  subtitle: widget.subtitle,
                  completedCount: widget.completedCount,
                  totalCount: widget.totalCount,
                  showProgress: widget.showProgress,
                  isExpanded: isExpanded,
                  onTap: toggle,
                ),
              ),
            ),
          ),
        ),
        if (isExpanded)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            sliver: SliverList.builder(
              itemCount: widget.itemCount,
              itemBuilder: widget.itemBuilder,
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final int completedCount;
  final int totalCount;
  final bool isExpanded;
  final bool showProgress;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.completedCount,
    required this.totalCount,
    required this.isExpanded,
    required this.showProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    return Material(
      color: AppColors.surface,
      elevation: isExpanded ? 2 : 0,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (showProgress) ...[
                Text(
                  '$completedCount / $totalCount',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                CircularProgressWidget(
                  progress: progress,
                  variant: ProgressSize.compact,
                ),
              ],
              Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;
  const _SectionHeaderDelegate({required this.extent, required this.child});
  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;
  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) => true;
}
