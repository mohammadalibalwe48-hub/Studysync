import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';

/// Labelled horizontal progress bar with a percentage on the right.
///
/// The fill animates from 0 → [value] on first build and whenever the
/// value changes. The filled portion uses a gradient with a soft outer
/// glow in [color] — the design system's "Glow Track" treatment.
class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.duration = const Duration(milliseconds: 900),
  });

  /// Description shown above the bar.
  final String label;

  /// Value between 0.0 and 1.0.
  final double value;

  final Color color;

  /// How long the fill animation should take.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
                    fontSize: 13,
                    color: color,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                return Stack(
                  children: <Widget>[
                    Container(color: palette.champagne),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: clamped),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double t, _) {
                        return Container(
                          width: c.maxWidth * t,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                color.withOpacity(0.85),
                                color,
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: color.withOpacity(0.45),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 0),
                              ),
                            ],
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
