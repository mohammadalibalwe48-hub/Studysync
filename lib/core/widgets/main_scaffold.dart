import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One of the bottom-nav destinations in the main app shell.
enum MainTab { home, progress, profile }

/// Shared scaffold used by [HomeScreen], [ProgressScreen] and
/// [ProfileScreen] so the bottom navigation looks identical and the
/// active tab indicator stays in sync.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.tab,
    required this.child,
    this.appBar,
    this.padding = EdgeInsets.zero,
  });

  final MainTab tab;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        bottom: false,
        child: Padding(padding: padding, child: child),
      ),
      bottomNavigationBar: _MainNavBar(active: tab),
    );
  }
}

class _MainNavBar extends StatelessWidget {
  const _MainNavBar({required this.active});

  final MainTab active;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: active.index,
      onDestinationSelected: (int i) {
        final MainTab next = MainTab.values[i];
        if (next == active) return;
        switch (next) {
          case MainTab.home:
            context.go('/home');
            break;
          case MainTab.progress:
            context.go('/progress');
            break;
          case MainTab.profile:
            context.go('/profile');
            break;
        }
      },
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.insert_chart_outlined),
          selectedIcon: Icon(Icons.insert_chart_rounded),
          label: 'Progress',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
