import 'dart:math' as math;
import 'package:flutter/material.dart';

/// "Lavender dawn" ambient background used app-wide.
///
/// Renders three slow-drifting indigo/violet/orange blobs over a
/// faintly tinted lavender surface so every screen has a subtle,
/// gradient-glow atmosphere without ever feeling neon or busy. The
/// blobs are heavily blurred, low-opacity, and only animate over ~30
/// seconds, so they read as gentle "colour wash" rather than motion
/// noise. In dark mode the same blobs sit on a deep night-violet
/// canvas, dimmer.
///
/// Set [intensity] to 0 to disable the moving glows on screens that
/// already have their own hero header (kept for backwards-compat).
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;
  final double intensity;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLight = scheme.brightness == Brightness.light;
    final double k = widget.intensity.clamp(0.0, 1.0).toDouble();

    // Lead with two indigo/lavender blobs (matching the new primary)
    // and keep one warm sunset blob so the brand orange still glows
    // through. Light mode reads as "morning haze on lavender"; dark
    // mode dims the same tones on a night-violet canvas.
    final Color blobA = isLight
        ? const Color(0xFFB7A8FF) // lavender-300
        : const Color(0xFF4F3FA8); // dim indigo
    final Color blobB = isLight
        ? const Color(0xFF8472F0) // indigo-light
        : const Color(0xFF3D2E8F); // dim violet
    final Color blobC = isLight
        ? const Color(0xFFFF9A4F) // warm orange highlight
        : const Color(0xFF8A4A1F); // dim sunset

    final Color baseTop = isLight
        ? const Color(0xFFF7F4FF) // matches AppTheme.background
        : const Color(0xFF11102A); // matches dark surface
    final Color baseBottom = isLight
        ? const Color(0xFFEFE9FF) // deeper lavender at the bottom edge
        : const Color(0xFF0B0A20);

    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? _) {
        final double t = _c.value * 2 * math.pi;
        return Stack(
          children: <Widget>[
            // Soft radial cream → honey base. Stays still so the
            // floating blobs feel additive on top.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[baseTop, baseBottom],
                  ),
                ),
              ),
            ),
            // Three drifting violet/indigo blobs with a warm orange
            // accent so the brand pairing stays present.
            _Blob(
              color: blobA.withOpacity(isLight ? 0.55 * k : 0.40 * k),
              size: 360,
              dx: 0.18 + 0.06 * math.sin(t),
              dy: 0.10 + 0.05 * math.cos(t * 0.85),
            ),
            _Blob(
              color: blobB.withOpacity(isLight ? 0.42 * k : 0.32 * k),
              size: 320,
              dx: 0.78 + 0.08 * math.cos(t * 0.7),
              dy: 0.32 + 0.06 * math.sin(t * 0.95),
            ),
            _Blob(
              color: blobC.withOpacity(isLight ? 0.22 * k : 0.18 * k),
              size: 420,
              dx: 0.45 + 0.10 * math.sin(t * 1.15 + 1.2),
              dy: 0.85 + 0.04 * math.cos(t * 0.6),
            ),
            Positioned.fill(child: widget.child),
          ],
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
    required this.dx,
    required this.dy,
  });

  final Color color;
  final double size;

  /// Fractional position (0.0–1.0) of the blob centre.
  final double dx;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        final double cx = w * dx - size / 2;
        final double cy = h * dy - size / 2;
        return Positioned(
          left: cx,
          top: cy,
          width: size,
          height: size,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[color, color.withOpacity(0)],
                  stops: const <double>[0.0, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
