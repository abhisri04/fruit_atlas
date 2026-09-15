import 'package:flutter/material.dart';

import '../../models/challenge.dart';
import '../../navigation/challenge_navigation.dart';
import '../../services/challenge_repository.dart';
import '../../services/progress_service.dart';
import '../../widgets/challenge_card.dart';
import '../../widgets/empty_state.dart';
import '../discover/discover_page.dart';

// SAVED PAGE
// =================================================================

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  static const repository = ChallengeRepository();
  List<Challenge> savedChallenges = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSavedChallenges();
  }

  Future<void> loadSavedChallenges() async {
    try {
      final challenges = await repository.loadChallenges();
      final savedIds = await ProgressService.getSavedChallengeIds();
      if (!mounted) return;
      setState(() {
        savedChallenges = challenges
            .where((challenge) => savedIds.contains(challenge.id))
            .toList();
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> openSavedChallenge(Challenge challenge) async {
    await openChallenge(context, challenge);
    await loadSavedChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load',
              message: 'Could not load saved challenges.\n\n$errorMessage',
            )
          : savedChallenges.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border,
              title: 'Keep your next adventure close',
              message: 'Save challenges to access them quickly.',
              actionLabel: 'Discover challenges',
              onAction: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DiscoverPage()),
                );
                await loadSavedChallenges();
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedChallenges.length,
              itemBuilder: (context, index) {
                final challenge = savedChallenges[index];
                return ChallengeCard(
                  challenge: challenge,
                  isActive: challenge.status == 'active',
                  onSavedChanged: (_) => loadSavedChallenges(),
                  onTap: () => openSavedChallenge(challenge),
                );
              },
            ),
    );
  }
}

// =================================================================
