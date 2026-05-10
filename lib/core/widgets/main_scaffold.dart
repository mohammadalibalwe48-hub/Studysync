import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
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
      extendBody: true,
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
      floatingActionButton: _CenterFab(
        onTap: () => context.go('/quick-quiz'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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

/// Center-docked sunset-orange FAB used for "quick action" — currently
/// launches the quick quiz flow. Mirrors the floating `+` button from
/// the reference design directly: a vivid orange disc punching through
/// the white floating bottom-nav rail.
class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: palette.goldGradient,
            boxShadow: palette.goldGlow,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 4,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
