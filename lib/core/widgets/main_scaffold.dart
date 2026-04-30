import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/glass_app_bar.dart';
import 'package:studysync_syria/core/widgets/glass_bottom_nav.dart';

/// One of the bottom-nav destinations in the main app shell.
enum MainTab { home, progress, profile }

/// Shared scaffold used by [HomeScreen], [ProgressScreen] and
/// [ProfileScreen] so the floating glass top bar and bottom navigation
/// look identical across tabs and the active tab indicator stays in
/// sync. Adds the ambient golden-hour background behind every screen.
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

  /// Optional override for the top bar. Defaults to the standard glass
  /// brand bar with avatar.
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
                  GlassAppBarAvatar(
                    onTap: () => context.go('/profile'),
                  ),
                ],
              )
            : null);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topBar?.preferredSize.height ?? 0,
                    bottom: 96,
                  ),
                  child: Padding(padding: padding, child: child),
                ),
              ),
              if (topBar != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: topBar,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: GlassBottomNav(
            currentIndex: tab.index,
            onTap: (int i) {
              final MainTab next = MainTab.values[i];
              if (next == tab) return;
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
            items: const <GlassNavItem>[
              GlassNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              GlassNavItem(
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: 'Progress',
              ),
              GlassNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
