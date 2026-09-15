import 'package:flutter/material.dart';

import '../search/discovery_search_page.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/filter_chip_group.dart';

import '../../theme/app_colors.dart';

import '../../models/category.dart';
import '../../models/challenge.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/challenge_repository.dart';
import '../../widgets/challenge_card.dart';
import 'category_details_page.dart';

// DISCOVER PAGE
// =================================================================

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  static const challengeRepository = ChallengeRepository();

  List<Category> categories = [];
  List<Challenge> challenges = [];

  String selectedCategory = 'All';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadChallengeData();
  }

  Future<void> loadChallengeData() async {
    try {
      final loadedCategories = await challengeRepository.loadCategories();
      final loadedChallenges = await challengeRepository.loadChallenges();

      if (!mounted) return;
      setState(() {
        categories = loadedCategories;
        challenges = loadedChallenges;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discover')),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Unable to load',
          message: 'Could not load challenges.\n\n$errorMessage',
        ),
      );
    }

    final activeChallenges = challenges
        .where((challenge) => challenge.status == 'active')
        .toList();

    final plannedChallenges = challenges
        .where((challenge) => challenge.status == 'planned')
        .toList();

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Search discovery',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscoverySearchPage()),
            ),
          ),
        ],
        title: const Text(
          'Discover',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What are you curious about?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Discover challenges and find something worth doing.',
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // CATEGORIES
              // ------------------------------------------------
              const Text(
                'Explore by Category',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              FilterChipGroup(
                options: ['All', ...categories.map((c) => c.name)],
                selected: selectedCategory,
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              ...categories
                  .where(
                    (c) =>
                        selectedCategory == 'All' || c.name == selectedCategory,
                  )
                  .map((category) {
                    return buildCategoryCard(category);
                  }),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // ACTIVE CHALLENGES
              // ------------------------------------------------
              if (activeChallenges.isNotEmpty) ...[
                const Text(
                  'Start Exploring',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 14),

                ...activeChallenges.map(
                  (challenge) => buildChallengeCard(challenge, isActive: true),
                ),
              ],

              const SizedBox(height: 28),

              // ------------------------------------------------
              // COMING SOON
              // ------------------------------------------------
              if (plannedChallenges.isNotEmpty) ...[
                const Text(
                  'Coming Soon',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 14),

                ...plannedChallenges.map(
                  (challenge) => buildChallengeCard(challenge, isActive: false),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // CHALLENGE CARD
  // =============================================================

  Widget buildChallengeCard(Challenge challenge, {required bool isActive}) {
    return ChallengeCard(
      challenge: challenge,
      isActive: isActive,
      onTap: () => openChallenge(context, challenge),
    );
  }
  // =============================================================
  // CATEGORY CARD
  // =============================================================

  Widget buildCategoryCard(Category category) {
    IconData icon = Icons.category_outlined;

    final id = category.id;

    if (id == 'food_drink') {
      icon = Icons.restaurant_outlined;
    } else if (id == 'fitness_wellness') {
      icon = Icons.self_improvement;
    } else if (id == 'travel_exploration') {
      icon = Icons.landscape_outlined;
    } else if (id == 'culture_learning') {
      icon = Icons.menu_book_outlined;
    } else if (id == 'faith_pilgrimage') {
      icon = Icons.temple_hindu_outlined;
    } else if (id == 'collecting') {
      icon = Icons.camera_alt_outlined;
    } else if (id == 'life_experiences') {
      icon = Icons.auto_awesome_outlined;
    }

    return Card(
      color: AppColors.categoryAccent(category.id).withValues(alpha: .06),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 56,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.categoryAccent(category.id).withValues(alpha: .35),
                AppColors.categoryAccent(category.id).withValues(alpha: .12),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: AppColors.categoryAccent(category.id),
            size: 30,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${category.description}\n${challenges.where((c) => c.categoryId == category.id).length} challenges',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailsPage(
                category: category,
                challenges: challenges,
              ),
            ),
          );
        },
      ),
    );
  }
}
