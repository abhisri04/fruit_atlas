import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

import '../../models/category.dart';
import '../../models/challenge.dart';
import '../../navigation/challenge_navigation.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/exploration_hero.dart';
import '../../widgets/filter_chip_group.dart';

class CategoryDetailsPage extends StatefulWidget {
  final Category category;
  final List<Challenge> challenges;

  const CategoryDetailsPage({
    super.key,
    required this.category,
    required this.challenges,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  String selected = 'All';
  Category get category => widget.category;
  List<Challenge> get challenges => widget.challenges;
  @override
  Widget build(BuildContext context) {
    final categoryChallenges = challenges
        .where(
          (challenge) =>
              challenge.categoryId == category.id &&
              (selected == 'All' ||
                  (selected == 'Active'
                      ? challenge.status == 'active'
                      : challenge.status != 'active')),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExplorationHero(
              title: category.name,
              subtitle: category.description,
              icon: Icons.explore_outlined,
              accent: AppColors.categoryAccent(category.id),
            ),
            FilterChipGroup(
              options: const ['All', 'Active', 'Coming Soon'],
              selected: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
            if (categoryChallenges.isEmpty)
              const Text(
                'No challenges are available in this category yet.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              ...categoryChallenges.map(
                (challenge) => ChallengeCard(
                  challenge: challenge,
                  isActive: challenge.status == 'active',
                  onTap: () => openChallenge(context, challenge),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
