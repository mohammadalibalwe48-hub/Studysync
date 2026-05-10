import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/services/study_goal_service.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// Lightweight Pomodoro / Focus Timer.
///
/// Provides three quick presets (25 / 50 / 90 minutes) and a primary
/// start/pause control. When a session completes its full duration, the
/// elapsed minutes are logged to [StudyGoalService] so the home-screen
/// daily-goal ring fills in automatically.
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const List<int> _presets = <int>[25, 50, 90];

  int _durationMinutes = 25;
  int _remainingSeconds = 25 * 60;
  Timer? _ticker;
  bool _running = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _setPreset(int minutes) {
    if (_running) return;
    setState(() {
      _durationMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds = math.max(0, _remainingSeconds - 1);
      });
      if (_remainingSeconds <= 0) {
        _onSessionComplete();
      }
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _durationMinutes * 60;
    });
  }

  Future<void> _onSessionComplete() async {
    _ticker?.cancel();
    setState(() => _running = false);
    await StudyGoalService.instance.logMinutes(_durationMinutes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'انتهت الجلسة! تمّت إضافة $_durationMinutes دقيقة لهدفك اليومي.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final double progress = _durationMinutes == 0
        ? 0
        : 1 - (_remainingSeconds / (_durationMinutes * 60));
    return Scaffold(
      backgroundColor: scheme.surface,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'مؤقّت التركيز',
                subtitle: 'بومودورو لجلسات دراسة فعّالة',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: <Widget>[
                    Center(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 260,
                              height: 260,
                              child: CustomPaint(
                                painter: _RingPainter(
                                  progress: 1,
                                  color: scheme.surfaceContainer,
                                  strokeWidth: 16,
                                ),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 240),
                              builder: (BuildContext c, double t, _) {
                                return SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: CustomPaint(
                                    painter: _RingPainter(
                                      progress: t,
                                      color: scheme.primary,
                                      strokeWidth: 16,
                                      rounded: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                    height: 1,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _running ? 'استمر بالعمل' : 'جلسة جاهزة',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (final int p in _presets) ...<Widget>[
                          _PresetChip(
                            minutes: p,
                            selected: _durationMinutes == p,
                            onTap: () => _setPreset(p),
                          ),
                          if (p != _presets.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('إعادة'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _toggle,
                            icon: Icon(
                              _running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(_running ? 'إيقاف' : 'ابدأ'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: palette.outline, width: 1),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'تقنية بومودورو: ادرس بتركيز كامل لمدة قصيرة، ثم خذ '
                              'استراحة قصيرة لتجديد طاقتك. سيتم إضافة وقت الجلسة '
                              'إلى هدف اليوم تلقائياً.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          '$minutes دقيقة',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? scheme.onPrimary : scheme.onSurface,
          ),
        ),
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
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
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
