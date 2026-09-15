import 'package:flutter/material.dart';

import '../services/progress_service.dart';

class SavedChallengeButton extends StatefulWidget {
  final String challengeId;
  final ValueChanged<bool>? onChanged;

  const SavedChallengeButton({
    super.key,
    required this.challengeId,
    this.onChanged,
  });

  @override
  State<SavedChallengeButton> createState() => _SavedChallengeButtonState();
}

class _SavedChallengeButtonState extends State<SavedChallengeButton> {
  static final changes = ValueNotifier<int>(0);
  bool isSaved = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    changes.addListener(loadSavedState);
    loadSavedState();
  }

  @override
  void dispose() {
    changes.removeListener(loadSavedState);
    super.dispose();
  }

  Future<void> loadSavedState() async {
    final saved = await ProgressService.isChallengeSaved(widget.challengeId);
    if (!mounted) return;
    setState(() {
      isSaved = saved;
      isLoading = false;
    });
  }

  Future<void> toggleSaved() async {
    final saved = await ProgressService.toggleSavedChallenge(
      widget.challengeId,
    );
    changes.value++;
    if (!mounted) return;
    setState(() => isSaved = saved);
    widget.onChanged?.call(saved);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isLoading ? null : toggleSaved,
      tooltip: isSaved ? 'Remove from Saved' : 'Save challenge',
      icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
    );
  }
}
