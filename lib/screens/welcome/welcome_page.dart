import 'package:flutter/material.dart';

import '../../models/app_branding.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/reveal.dart';
import '../../widgets/reward_animations.dart';

/// Shows the welcome once, then the app.
class WelcomeGate extends StatefulWidget {
  final Widget child;
  const WelcomeGate({super.key, required this.child});

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  bool? done;

  @override
  void initState() {
    super.initState();
    UserProfileService.welcomeDone().then((value) {
      if (mounted) setState(() => done = value);
    });
  }

  @override
  Widget build(BuildContext context) => switch (done) {
    null => const ColoredBox(color: AppColors.background),
    true => widget.child,
    false => WelcomePage(onDone: () => setState(() => done = true)),
  };
}

/// Three short screens: what UPLYFA is, how it works, and what you're into.
class WelcomePage extends StatefulWidget {
  final VoidCallback onDone;
  const WelcomePage({super.key, required this.onDone});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final pages = PageController();
  int page = 0;
  final picked = <String>{};

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await UserProfileService.finishWelcome(picked.toList());
    widget.onDone();
  }

  void _next() => pages.nextPage(
    duration: const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: AppGradients.gamificationHero),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('welcome-skip'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: pages,
                onPageChanged: (i) => setState(() => page = i),
                children: [
                  _intro(context),
                  _howItWorks(context),
                  _interests(context),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: i == page ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == page ? 1 : .4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: TactileScale(
                  child: FilledButton(
                    key: const ValueKey('welcome-next'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: page < 2 ? _next : _finish,
                    child: Text(
                      page < 2
                          ? 'Next'
                          : picked.isEmpty
                          ? "Let's go"
                          : "Let's go (${picked.length} picked)",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _intro(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Reveal(
          child: Icon(Icons.auto_awesome, color: AppColors.gold, size: 44),
        ),
        const SizedBox(height: 18),
        Reveal(
          index: 1,
          child: Text(
            AppBranding.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        Reveal(
          index: 2,
          child: Text(
            AppBranding.tagline,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Reveal(
          index: 3,
          child: Text(
            'Try new hobbies, taste new things, see more of India, and keep '
            'a record of it all, so you can look back on a life well lived.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .9),
              fontSize: 17,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _howItWorks(BuildContext context) {
    const steps = [
      (
        Icons.explore_outlined,
        'Find something new',
        'Hundreds of hobbies, places, dishes, books and more to try.',
      ),
      (
        Icons.check_circle_outline,
        'Mark it in one tap',
        'Tried it? Tap once. Add a photo if you like. That\'s it.',
      ),
      (
        Icons.auto_stories_outlined,
        'Build your story',
        'Your firsts, trips and progress, ready to look back on or share.',
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          for (final (i, (icon, title, body)) in steps.indexed)
            Reveal(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: AppColors.gold),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .85),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Everything stays private on your phone unless you choose to '
            'share it.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .75),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _interests(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you into?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick a few and we\'ll start you there. You can explore '
          'everything else anytime.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .85),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final interest in Interests.all)
              FilterChip(
                key: ValueKey('interest-${interest.id}'),
                label: Text(interest.label),
                selected: picked.contains(interest.id),
                showCheckmark: true,
                selectedColor: AppColors.gold,
                backgroundColor: Colors.white,
                onSelected: (on) => setState(
                  () =>
                      on ? picked.add(interest.id) : picked.remove(interest.id),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
