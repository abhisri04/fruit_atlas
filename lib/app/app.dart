import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/discover/discover_page.dart';
import '../theme/app_theme.dart';
import '../screens/home/home_page.dart';
import '../screens/my_life/my_life_page.dart';
import '../screens/hobbies/my_hobbies_page.dart';
import '../widgets/reward_feedback_host.dart';
import '../models/app_branding.dart';

// APP
// ================================================================

class FruitAtlasApp extends StatelessWidget {
  const FruitAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) =>
          RewardFeedbackHost(child: child ?? const SizedBox.shrink()),
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

class _MainNavigationPageState extends State<MainNavigationPage>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;
  // Fades the newly selected tab in. Tabs stay mounted in the IndexedStack,
  // so switching never loses scroll position or loaded state.
  late final AnimationController _tabFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  bool _exitArmed = false;
  Timer? _exitTimer;

  @override
  void dispose() {
    _exitTimer?.cancel();
    _tabFade.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    _exitTimer?.cancel();
    if (index != selectedIndex) {
      final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      reduced ? _tabFade.value = 1 : _tabFade.forward(from: 0);
    }
    setState(() {
      selectedIndex = index;
      _exitArmed = false;
    });
  }

  void _handleBack(bool didPop, Object? result) {
    if (didPop) return;

    if (selectedIndex != 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _selectDestination(0);
      return;
    }

    if (_exitArmed) {
      _exitTimer?.cancel();
      SystemNavigator.pop();
      return;
    }

    _exitTimer?.cancel();
    setState(() => _exitArmed = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Press back again to exit ${AppBranding.appName}'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _exitTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _exitArmed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        body: FadeTransition(
          opacity: CurvedAnimation(parent: _tabFade, curve: Curves.easeOut),
          child: IndexedStack(
            index: selectedIndex,
            children: [
              HomePage(isActive: selectedIndex == 0),
              const DiscoverPage(),
              const MyHobbiesPage(),
              selectedIndex == 3 ? const MyLifePage() : const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _selectDestination,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.palette_outlined),
              selectedIcon: Icon(Icons.palette),
              label: 'Hobbies',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'My Life',
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
