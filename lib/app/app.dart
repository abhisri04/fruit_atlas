import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/discover/discover_page.dart';
import '../theme/app_theme.dart';
import '../screens/home/home_page.dart';
import '../screens/my_life/my_life_page.dart';
import '../screens/saved/saved_page.dart';

// APP
// ================================================================

class FruitAtlasApp extends StatelessWidget {
  const FruitAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Atlas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
  bool _exitArmed = false;
  Timer? _exitTimer;

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  void _selectDestination(int index) {
    _exitTimer?.cancel();
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
        content: Text('Press back again to exit Fruit Atlas'),
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
        body: IndexedStack(
          index: selectedIndex,
          children: [
            HomePage(isActive: selectedIndex == 0),
            const DiscoverPage(),
            selectedIndex == 2 ? const SavedPage() : const SizedBox.shrink(),
            selectedIndex == 3 ? const MyLifePage() : const SizedBox.shrink(),
          ],
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
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Saved',
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
