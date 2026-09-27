import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const FruitAtlasApp());
}

// ================================================================
// APP
// ================================================================

class FruitAtlasApp extends StatelessWidget {
  const FruitAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Atlas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
    );
  }
}

// ================================================================
// MAIN NAVIGATION
// ================================================================

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [HomePage(), DiscoverPage(), SavedPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}

// ================================================================
// HOME PAGE
// ================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> fruits = [];
  List<dynamic> states = [];

  String selectedStateId = 'UP';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadFruitAtlasData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------
  // LOAD FRUIT DATA
  // ------------------------------------------------

  Future<void> loadFruitAtlasData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/fruit_atlas_seed.json',
      );

      final data = jsonDecode(jsonString);

      setState(() {
        fruits = data['fruits'] ?? [];
        states = data['states'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ------------------------------------------------
  // SELECTED STATE NAME
  // ------------------------------------------------

  String get selectedStateName {
    final matchingStates = states.where(
      (state) => state['id'] == selectedStateId,
    );

    if (matchingStates.isNotEmpty) {
      return matchingStates.first['name'] ?? 'Selected State';
    }

    return 'Selected State';
  }

  // ------------------------------------------------
  // STATE FILTER
  // ------------------------------------------------

  List<dynamic> get fruitsForSelectedState {
    return fruits.where((fruit) {
      final fruitStates = fruit['states'] as List<dynamic>? ?? [];

      return fruitStates.any((state) {
        return state['state_id'] == selectedStateId;
      });
    }).toList();
  }

  // ------------------------------------------------
  // SEARCH
  // ------------------------------------------------

  List<dynamic> get searchResults {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    return fruits.where((fruit) {
      final fruitName = (fruit['name'] ?? '').toString().toLowerCase();

      final scientificName = (fruit['scientific_name'] ?? '')
          .toString()
          .toLowerCase();

      final varieties = fruit['varieties'] as List<dynamic>? ?? [];

      final varietyMatch = varieties.any((variety) {
        final varietyName = (variety['name'] ?? '').toString().toLowerCase();

        return varietyName.contains(query);
      });

      return fruitName.contains(query) ||
          scientificName.contains(query) ||
          varietyMatch;
    }).toList();
  }

  // ------------------------------------------------
  // OPEN FRUIT DETAILS
  // ------------------------------------------------

  void openFruitDetails(dynamic fruit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FruitDetailsPage(fruit: fruit, states: states),
      ),
    );
  }

  // ------------------------------------------------
  // BUILD
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fruit Atlas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load fruit data.\n\n$errorMessage',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fruit Atlas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text(
                'Discover India, one fruit at a time',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // SEARCH BAR
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search fruits or varieties...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();

                            setState(() {
                              searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // =================================================
              // SEARCH RESULTS
              // =================================================
              if (isSearching) ...[
                Text(
                  'Search Results',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  '${searchResults.length} fruit${searchResults.length == 1 ? '' : 's'} found',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 16),

                if (searchResults.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No fruits found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try searching for another fruit or variety.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ...searchResults.map((fruit) => buildFruitCard(fruit)),
              ]
              // =================================================
              // STATE DISCOVERY
              // =================================================
              else ...[
                const Text(
                  'Explore by State',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: selectedStateId,
                  decoration: InputDecoration(
                    labelText: 'Select State / UT',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: states.map<DropdownMenuItem<String>>((state) {
                    return DropdownMenuItem<String>(
                      value: state['id'],
                      child: Text(state['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedStateId = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Fruits of $selectedStateName',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${fruitsForSelectedState.length}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  '${fruitsForSelectedState.length} currently verified fruit mappings',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 16),

                if (fruitsForSelectedState.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No verified fruit mappings found for this location yet.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...fruitsForSelectedState.map(
                    (fruit) => buildFruitCard(fruit),
                  ),

                const SizedBox(height: 24),

                // EXPLORE INDIA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.green.shade50,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.map_outlined, size: 42),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore India',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Discover fruits across all Indian states and UTs.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // STATS
                Row(
                  children: [
                    Expanded(
                      child: buildStatCard('${fruits.length}', 'Fruits'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildStatCard('${states.length}', 'States & UTs'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FRUIT CARD
  // =============================================================

  Widget buildFruitCard(dynamic fruit) {
    final varieties = fruit['varieties'] as List<dynamic>? ?? [];

    final varietyNames = varieties
        .map((variety) => (variety['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openFruitDetails(fruit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // TEMPORARY IMAGE
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.eco_outlined, size: 34),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fruit['name'] ?? 'Unknown Fruit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      fruit['scientific_name'] ?? 'Scientific name unavailable',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),

                    if (varietyNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Varieties: ${varietyNames.join(', ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        selectedStateName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // STAT CARD
  // =============================================================

  Widget buildStatCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.grey.shade100,
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// =================================================================
// DISCOVER PAGE
// =================================================================

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<dynamic> categories = [];
  List<dynamic> challenges = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadChallengeData();
  }

  Future<void> loadChallengeData() async {
    try {
      final categoriesJson = await rootBundle.loadString(
        'assets/data/categories.json',
      );

      final challengesJson = await rootBundle.loadString(
        'assets/data/challenges.json',
      );

      final categoriesData = jsonDecode(categoriesJson);

      final challengesData = jsonDecode(challengesJson);

      setState(() {
        categories = categoriesData['categories'] ?? [];

        challenges = challengesData['challenges'] ?? [];

        isLoading = false;
      });
    } catch (e) {
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load challenges.\n\n$errorMessage',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final activeChallenges = challenges
        .where((challenge) => challenge['status'] == 'active')
        .toList();

    final plannedChallenges = challenges
        .where((challenge) => challenge['status'] == 'planned')
        .toList();

    return Scaffold(
      appBar: AppBar(
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
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

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
              // CATEGORIES
              // ------------------------------------------------
              const Text(
                'Explore by Category',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              ...categories.map((category) {
                return buildCategoryCard(category);
              }),

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

  Widget buildChallengeCard(dynamic challenge, {required bool isActive}) {
    IconData icon = Icons.emoji_events_outlined;

    final itemType = challenge['item_type'];

    if (itemType == 'fruit') {
      icon = Icons.eco_outlined;
    } else if (itemType == 'yoga_pose') {
      icon = Icons.self_improvement;
    } else if (itemType == 'nut') {
      icon = Icons.spa_outlined;
    } else if (itemType == 'state') {
      icon = Icons.map_outlined;
    } else if (itemType == 'perfume') {
      icon = Icons.local_florist_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isActive
            ? () {
                if (challenge['id'] == 'taste_fruits_of_india') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FruitChallengePage(challenge: challenge),
                    ),
                  );
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 30),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['name'] ?? 'Challenge',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      challenge['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${challenge['total_items']} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              if (isActive)
                const Icon(Icons.chevron_right, color: Colors.grey)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Soon',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // CATEGORY CARD
  // =============================================================

  Widget buildCategoryCard(dynamic category) {
    IconData icon = Icons.category_outlined;

    final id = category['id'];

    if (id == 'food_drink') {
      icon = Icons.restaurant_outlined;
    } else if (id == 'fitness_wellness') {
      icon = Icons.fitness_center_outlined;
    } else if (id == 'travel_exploration') {
      icon = Icons.public_outlined;
    } else if (id == 'culture_learning') {
      icon = Icons.menu_book_outlined;
    } else if (id == 'collecting') {
      icon = Icons.collections_outlined;
    } else if (id == 'life_experiences') {
      icon = Icons.auto_awesome_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          category['name'] ?? 'Category',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(category['description'] ?? ''),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// =================================================================
// FRUIT CHALLENGE PAGE
// =================================================================

class FruitChallengePage extends StatefulWidget {
  final dynamic challenge;

  const FruitChallengePage({super.key, required this.challenge});

  @override
  State<FruitChallengePage> createState() => _FruitChallengePageState();
}

class _FruitChallengePageState extends State<FruitChallengePage> {
  List<dynamic> fruits = [];
  bool isLoading = true;
  String? errorMessage;

  // Temporary in-memory completion tracking.
  // We will later save this permanently.
  final Set<String> completedFruitIds = {};

  @override
  void initState() {
    super.initState();
    loadFruits();
  }

  Future<void> loadFruits() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/fruit_atlas_seed.json',
      );

      final data = jsonDecode(jsonString);

      setState(() {
        fruits = data['fruits'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  double get progress {
    if (fruits.isEmpty) {
      return 0;
    }

    return completedFruitIds.length / fruits.length;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Taste All Fruits of India')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Taste All Fruits of India')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load fruits.\n\n$errorMessage',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Taste All Fruits of India')),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // PROGRESS
              // ------------------------------------------------

              Text(
                '${completedFruitIds.length} / ${fruits.length}',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${(progress * 100).round()}% complete',
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: progress, minHeight: 10),
              ),

              const SizedBox(height: 28),

              const Text(
                'Your Fruits',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'Taste a fruit and mark it as completed.',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // FRUIT CHECKLIST
              // ------------------------------------------------
              ...fruits.map((fruit) {
                final fruitId = (fruit['id'] ?? fruit['name']).toString();

                final isCompleted = completedFruitIds.contains(fruitId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_outlined),
                    ),

                    title: Text(
                      fruit['name'] ?? 'Unknown Fruit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),

                    subtitle: Text(
                      fruit['scientific_name'] ?? '',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),

                    trailing: Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            completedFruitIds.add(fruitId);
                          } else {
                            completedFruitIds.remove(fruitId);
                          }
                        });
                      },
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // DEEPER EXPLORATION MESSAGE
              // ------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want to go deeper?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      'Some fruits have many varieties. Once you have tasted a fruit, you can explore its varieties and track those separately.',
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Variety tracking coming next.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// SAVED PAGE
// =================================================================

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Your saved challenges will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// FRUIT DETAILS PAGE
// =================================================================

class FruitDetailsPage extends StatelessWidget {
  final dynamic fruit;
  final List<dynamic> states;

  const FruitDetailsPage({
    super.key,
    required this.fruit,
    required this.states,
  });

  String stateNameFromId(String id) {
    final matchingStates = states.where((state) => state['id'] == id);

    if (matchingStates.isNotEmpty) {
      return matchingStates.first['name'] ?? id;
    }

    return id;
  }

  @override
  Widget build(BuildContext context) {
    final varieties = fruit['varieties'] as List<dynamic>? ?? [];

    final fruitStateRecords = fruit['states'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Fruit Details')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.eco_outlined, size: 80),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              fruit['name'] ?? 'Unknown Fruit',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              fruit['scientific_name'] ?? 'Scientific name unavailable',
              style: const TextStyle(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            if (fruit['crop_group'] != null)
              buildInfoCard('Crop Group', fruit['crop_group']),

            const SizedBox(height: 20),

            const Text(
              'Recorded Varieties',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (varieties.isEmpty)
              const Text(
                'No varieties recorded yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...varieties.map(
                (variety) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.eco_outlined),
                    title: Text(
                      variety['name'] ?? 'Unknown variety',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: variety['notes'] != null
                        ? Text(variety['notes'])
                        : null,
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VarietyDetailsPage(
                            variety: variety,
                            fruit: fruit,
                            states: states,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 24),

            const Text(
              'Verified Growing States / UTs',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fruitStateRecords.map((state) {
                final stateId = state['state_id']?.toString() ?? '';

                return Chip(label: Text(stateNameFromId(stateId)));
              }).toList(),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The information currently shown is based on the verified mappings available in the research-stage dataset.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// VARIETY DETAILS PAGE
// =================================================================

class VarietyDetailsPage extends StatelessWidget {
  final dynamic variety;
  final dynamic fruit;
  final List<dynamic> states;

  const VarietyDetailsPage({
    super.key,
    required this.variety,
    required this.fruit,
    required this.states,
  });

  String stateNameFromId(String id) {
    final matchingStates = states.where((state) => state['id'] == id);

    if (matchingStates.isNotEmpty) {
      return matchingStates.first['name'] ?? id;
    }

    return id;
  }

  @override
  Widget build(BuildContext context) {
    final fruitStateRecords = fruit['states'] as List<dynamic>? ?? [];

    final fruitStateIds = fruitStateRecords
        .map((state) => state['state_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Variety Details')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.eco_outlined, size: 80),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              variety['name'] ?? 'Unknown Variety',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Variety of ${fruit['name'] ?? 'Unknown Fruit'}',
              style: const TextStyle(fontSize: 17, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            if (variety['notes'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About this variety',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      variety['notes'],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            const Text(
              'Growing States / UTs',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Variety-specific state mapping has not been separately verified yet. The states below are the verified growing states for the parent fruit, not necessarily this specific variety.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fruitStateIds.map((stateId) {
                return Chip(label: Text(stateNameFromId(stateId)));
              }).toList(),
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is currently research-stage variety data. Variety-specific information will be expanded and independently verified as the database grows.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
