import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_banner_ad_host.dart';

/// App shell with bottom navigation bar wrapping the main tab routes.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  /// Map tab index to a policy-compatible screenId.
  String get _currentScreenId {
    switch (navigationShell.currentIndex) {
      case 0:
        return 'home';
      case 1:
        return 'noteInput'; // blocked by policy — no ads
      case 2:
        return 'favorites';
      case 3:
        return 'settings'; // blocked by policy — no ads
      default:
        return 'home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBannerAdHost(
        screenId: _currentScreenId,
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

