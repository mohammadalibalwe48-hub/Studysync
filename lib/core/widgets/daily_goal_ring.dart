import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';

/// Apple-watch-style daily goal ring. Smoothly animates from 0 → the
/// supplied [progress] (0..1) every time the value changes.
class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({
    super.key,
    required this.progress,
    required this.minutes,
    required this.goalMinutes,
    this.size = 156,
    this.strokeWidth = 12,
  });

  final double progress;
  final int minutes;
  final int goalMinutes;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final double clamped = progress.clamp(0.0, 1.0);
    final int percent = (clamped * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Track.
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: 1,
                color: scheme.surfaceContainer,
                strokeWidth: strokeWidth,
              ),
            ),
          ),
          // Fill.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double t, _) {
              return SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: t,
                    color: scheme.primary,
                    strokeWidth: strokeWidth,
                    rounded: true,
                  ),
                ),
              );
            },
          ),
          // Center text stack.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$minutes',
                style: TextStyle(
                  fontSize: size * 0.26,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'دقيقة اليوم',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent% من $goalMinutes',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.rounded = false,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final bool rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color
      ..strokeCap = rounded ? StrokeCap.round : StrokeCap.butt;
    if (progress >= 1 && !rounded) {
      canvas.drawCircle(center, radius, paint);
      return;
    }
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    // Start at the top (-pi/2) and sweep clockwise.
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.rounded != rounded;
}
