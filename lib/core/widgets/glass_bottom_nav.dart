import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/animations.dart';

/// One destination in the [GlassBottomNav].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating frosted-glass bottom navigation used by the main shell.
///
/// The active tab uses an animated gold indicator pill, scales up
/// subtly, and the icon swaps to its filled variant. The whole bar
/// floats above the content with a top border-radius and a soft amber
/// upward glow.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            border: const Border(
              top: BorderSide(color: Color(0x55FFFFFF), width: 0.6),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.accent.withOpacity(0.10),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset * 0.6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(items.length, (int i) {
              return Expanded(
                child: _NavCell(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color activeColor = palette.accent;
    final Color inactiveColor = palette.muted;

    return PressableScale(
      onTap: onTap,
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: <Color>[
                    activeColor.withOpacity(0.18),
                    palette.warm.withOpacity(0.10),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: activeColor.withOpacity(0.20),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (Widget c, Animation<double> a) =>
                  ScaleTransition(scale: a, child: c),
              child: Icon(
                active ? item.activeIcon : item.icon,
                key: ValueKey<bool>(active),
                size: 24,
                color: active ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.6,
                color: active ? activeColor : inactiveColor,
              ),
              child: Text(item.label.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
