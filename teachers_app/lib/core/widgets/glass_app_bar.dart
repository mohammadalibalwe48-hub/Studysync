import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:studysync_syria_teachers/app/theme.dart';

/// Frosted-glass top-app bar used by the main shell. Renders a 70%
/// translucent surface with a 20px backdrop blur, edged with a hairline
/// white border for a premium "glass finish" look.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            border: const Border(
              bottom: BorderSide(color: Color(0x331A1A1A), width: 0.4),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A1A1A1A),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: palette.goldGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.accent.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (Rect bounds) =>
              palette.goldGradient.createShader(bounds),
          child: const Text(
            'Steps',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
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
    final AppPalette palette = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.champagne,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.6),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A1A1A1A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person_rounded,
            size: 20,
            color: palette.muted,
          ),
        ),
      ),
    );
  }
}
