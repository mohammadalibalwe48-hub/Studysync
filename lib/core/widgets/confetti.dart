import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight, dependency-free confetti burst painter.
///
/// Used after a quiz is completed successfully to celebrate the win
/// without pulling in another package.  The colours are pulled from the
/// brand warm palette so the celebration matches the rest of the UI.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.duration = const Duration(milliseconds: 1800),
    this.particleCount = 90,
    this.colors = const <Color>[
      Color(0xFFF5B544), // honey
      Color(0xFFE2862F), // sunset
      Color(0xFFD68A1A), // saffron
      Color(0xFFC9602B), // clay
      Color(0xFFFFC371), // peach
    ],
  });

  final Duration duration;
  final int particleCount;
  final List<Color> colors;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final math.Random rnd = math.Random();
    _particles = List<_Particle>.generate(widget.particleCount, (int i) {
      final double angle =
          rnd.nextDouble() * math.pi - math.pi / 2; // upward fan
      final double speed = 320 + rnd.nextDouble() * 380;
      return _Particle(
        color: widget.colors[i % widget.colors.length],
        angle: angle,
        speed: speed,
        rotation: rnd.nextDouble() * math.pi,
        spin: (rnd.nextDouble() - 0.5) * 8,
        size: 6 + rnd.nextDouble() * 6,
        life: 0.7 + rnd.nextDouble() * 0.3,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            t: _c.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.rotation,
    required this.spin,
    required this.size,
    required this.life,
  });

  final Color color;
  final double angle;
  final double speed;
  final double rotation;
  final double spin;
  final double size;
  final double life;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.t});

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset origin = Offset(size.width / 2, size.height * 0.55);
    const double gravity = 720;
    for (final _Particle p in particles) {
      final double localT = (t / p.life).clamp(0.0, 1.0).toDouble();
      final double dx = math.cos(p.angle) * p.speed * localT;
      final double dy = math.sin(p.angle) * p.speed * localT +
          0.5 * gravity * localT * localT;
      final Offset pos = origin + Offset(dx, dy);
      final double alpha = (1.0 - localT).clamp(0.0, 1.0).toDouble();

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotation + p.spin * t);
      final Paint paint = Paint()
        ..color = p.color.withOpacity(alpha);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.5,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
