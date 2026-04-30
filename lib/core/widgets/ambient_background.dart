import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';

/// Ambient "golden-hour" background used app-wide.
///
/// Renders three soft, blurred radial glows behind any [child]. The
/// glows drift gently to give the surface a sense of warm directional
/// light without ever competing with foreground content.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.intensity = 1.0,
  });

  final Widget child;

  /// Multiplier for glow opacity (0..1). Useful when stacking with a
  /// hero gradient that already provides colour.
  final double intensity;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, _) {
                final double t = _controller.value * 2 * math.pi;
                return CustomPaint(
                  painter: _GlowPainter(
                    t: t,
                    palette: palette,
                    intensity: widget.intensity.clamp(0.0, 1.0),
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({
    required this.t,
    required this.palette,
    required this.intensity,
  });

  final double t;
  final AppPalette palette;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    void drawGlow(Offset center, double radius, Color color) {
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[color, color.withOpacity(0)],
          stops: const <double>[0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final double w = size.width;
    final double h = size.height;
    const double drift = 18.0;

    drawGlow(
      Offset(w * 0.92 + math.cos(t) * drift, -40 + math.sin(t) * drift),
      w * 0.7,
      palette.gold.withOpacity(0.22 * intensity),
    );
    drawGlow(
      Offset(-30 + math.cos(t + 1.2) * drift, h * 0.30 + math.sin(t + 1.2) * drift),
      w * 0.55,
      palette.warm.withOpacity(0.16 * intensity),
    );
    drawGlow(
      Offset(w * 0.50 + math.cos(t + 2.4) * drift,
          h * 1.05 + math.sin(t + 2.4) * drift),
      w * 0.75,
      palette.accent.withOpacity(0.12 * intensity),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.intensity != intensity ||
      oldDelegate.palette != palette;
}
