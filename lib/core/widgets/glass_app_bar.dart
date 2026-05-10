import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';

/// Solid top app bar used by the main shell.
///
/// In the redesign this is a plain surface bar with a hairline divider
/// — no glassmorphism, no backdrop blur. It keeps the original class
/// name to stay drop-in compatible with the rest of the codebase.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            bottom: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
        ),
        padding:
            padding.add(EdgeInsets.only(top: MediaQuery.of(context).padding.top)),
        child: Row(
          children: <Widget>[
            if (leading != null) leading!,
            if (title != null) ...<Widget>[
              if (leading != null) const SizedBox(width: 12),
              DefaultTextStyle.merge(
                style: Theme.of(context).appBarTheme.titleTextStyle ??
                    Theme.of(context).textTheme.titleLarge,
                child: title!,
              ),
            ],
            const Spacer(),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}

/// Logo + word-mark used as the leading widget in the main shell's
/// [GlassAppBar].
class GlassAppBarBrand extends StatelessWidget {
  const GlassAppBarBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: palette.goldGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Steps',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Circular avatar used as a topbar action in the main shell.
class GlassAppBarAvatar extends StatelessWidget {
  const GlassAppBarAvatar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_outline_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Circular icon-only action button used in app bars (search, settings,
/// etc.).
class GlassAppBarIconButton extends StatelessWidget {
  const GlassAppBarIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badgeCount,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    final Widget core = tooltip != null
        ? Tooltip(message: tooltip!, child: button)
        : button;
    final int? n = badgeCount;
    if (n == null || n <= 0) return core;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        core,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: scheme.error,
              shape: n > 9 ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: n > 9 ? BorderRadius.circular(9) : null,
              border: Border.all(color: scheme.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              n > 99 ? '99+' : '$n',
              style: TextStyle(
                color: scheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
