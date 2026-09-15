import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Keeps headers scrollable and creates checklist rows only near the viewport.
class ExperienceList extends StatelessWidget {
  final List<Widget> header, footer;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  const ExperienceList({
    super.key,
    required this.header,
    required this.itemCount,
    required this.itemBuilder,
    this.footer = const [],
  });
  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverList.list(children: header),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.page),
        sliver: SliverList.list(children: footer),
      ),
    ],
  );
}
