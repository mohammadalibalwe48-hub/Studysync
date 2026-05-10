import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/animations.dart';

/// Primary call-to-action button used across the app.
///
/// In the redesign this is a solid indigo button (no gradient, no
/// glow) — the cleanest, most "study-app-native" treatment. Shadows
/// stay extremely subtle.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.borderRadius = 12,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool disabled = isLoading || onPressed == null;
    final VoidCallback? handler = isLoading ? null : onPressed;
    final Color background =
        disabled ? scheme.primary.withOpacity(0.50) : scheme.primary;

    return PressableScale(
      onTap: handler,
      pressedScale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: disabled
              ? const <BoxShadow>[]
              : <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey<String>('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  key: const ValueKey<String>('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 18, color: scheme.onPrimary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Vivid sunset-orange pill button used for hero CTAs ("Study Now",
/// "TO START") that need to feel celebratory. Mirrors the orange
/// pill button in the reference image.
class OrangePillButton extends StatelessWidget {
  const OrangePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool disabled = isLoading || onPressed == null;
    return PressableScale(
      onTap: isLoading ? null : onPressed,
      pressedScale: 0.96,
      child: Container(
        width: expand ? double.infinity : null,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: palette.goldGradient,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: disabled ? const <BoxShadow>[] : palette.goldGlow,
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: AppMotion.short,
          child: isLoading
              ? const SizedBox(
                  key: ValueKey<String>('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  key: const ValueKey<String>('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Dashed-outline CTA used by empty states ("+ Create a Card" pattern).
/// A thin warm-orange dashed pill with a leading `+` icon — mirrors
/// the reference's "Create a Card" button directly.
class DashedActionButton extends StatelessWidget {
  const DashedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return PressableScale(
      onTap: onPressed,
      pressedScale: 0.97,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: palette.gold,
          radius: AppRadii.pill,
          strokeWidth: 1.4,
          dashLength: 6,
          gapLength: 4,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: palette.gold),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.gold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hand-rolled dashed rounded-rectangle border painter used by
/// [DashedActionButton]. Avoids pulling in another dependency just
/// for the dashed outline.
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final double dashSpan = dashLength + gapLength;
    for (final PathMetric metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final double end = (dist + dashLength).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dashSpan;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) {
    return old.color != color ||
        old.radius != radius ||
        old.strokeWidth != strokeWidth ||
        old.dashLength != dashLength ||
        old.gapLength != gapLength;
  }
}

/// Ghost / secondary button — soft surface fill with hairline border.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onPressed,
      pressedScale: 0.97,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: scheme.onSurface),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
