import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell widget used by [StatefulShellRoute.indexedStack].
///
/// Wraps the active branch content with a Material 3 [NavigationBar] so tabs
/// (Home / Library / Review) are always visible.
class MainScaffold extends StatelessWidget {
  /// Creates a [MainScaffold].
  const MainScaffold({
    required this.navigationShell,
    super.key,
  });

  /// The shell provided by GoRouter's [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Review',
          ),
        ],
      ),
    );
  }
}
