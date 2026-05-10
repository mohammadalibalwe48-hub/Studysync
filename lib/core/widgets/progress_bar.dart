import 'package:flutter/material.dart';

/// Labelled horizontal progress bar with a percentage on the right.
///
/// In the redesign the bar is a flat single-tone fill with rounded
/// caps. No glow, no gradient — keeps the focus on the data.
class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.duration = const Duration(milliseconds: 720),
  });

  final String label;
  final double value;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: scheme.onSurface,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: clamped),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double t, _) {
                return Text(
                  '${(t * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: color,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                return Stack(
                  children: <Widget>[
                    Container(color: scheme.surfaceContainer),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: clamped),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double t, _) {
                        return Container(
                          width: c.maxWidth * t,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
