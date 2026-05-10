import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/glass_app_bar.dart';
import 'package:studysync_syria/core/widgets/glass_bottom_nav.dart';

/// One of the bottom-nav destinations in the main app shell.
///
/// The order matches the order of [GlassNavItem]s constructed below, so
/// please update both lists together.
enum MainTab { home, library, progress, profile }

/// Shared scaffold used by [HomeScreen], [LibraryScreen], [ProgressScreen]
/// and [ProfileScreen] so the top bar and bottom navigation look identical
/// across tabs and the active tab indicator stays in sync.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.tab,
    required this.child,
    this.appBar,
    this.padding = EdgeInsets.zero,
    this.showTopBar = true,
  });

  final MainTab tab;
  final Widget child;

  /// Optional override for the top bar. Defaults to the standard brand
  /// bar with avatar.
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry padding;

  /// Whether to render the top-app bar overlay. Set to `false` for
  /// screens that prefer their own scrolled header.
  final bool showTopBar;

  @override
  Widget build(BuildContext context) {
    final PreferredSizeWidget? topBar = appBar ??
        (showTopBar
            ? GlassAppBar(
                leading: const GlassAppBarBrand(),
                actions: <Widget>[
                  GlassAppBarIconButton(
                    icon: Icons.search_rounded,
                    tooltip: 'بحث',
                    onTap: () => context.push('/search'),
                  ),
                  const SizedBox(width: 8),
                  GlassAppBarAvatar(
                    onTap: () => context.go('/profile'),
                  ),
                ],
              )
            : null);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AmbientBackground(
        child: Column(
          children: <Widget>[
            if (topBar != null) topBar,
            Expanded(
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: tab.index,
        onTap: (int i) {
          final MainTab next = MainTab.values[i];
          if (next == tab) return;
          switch (next) {
            case MainTab.home:
              context.go('/home');
              break;
            case MainTab.library:
              context.go('/library');
              break;
            case MainTab.progress:
              context.go('/progress');
              break;
            case MainTab.profile:
              context.go('/profile');
              break;
          }
        },
        items: const <GlassNavItem>[
          GlassNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'الرئيسية',
          ),
          GlassNavItem(
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books_rounded,
            label: 'المكتبة',
          ),
          GlassNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'التقدّم',
          ),
          GlassNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
