import 'dart:ui';

import 'package:flutter/material.dart';

/// Reusable glassmorphism panel — a 70% white tint behind a 20px
/// backdrop blur, edged with a hairline white border.
///
/// Used for floating navigation bars, hero overlays and the topbar.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.tint,
    this.borderColor,
    this.blurSigma = 18,
    this.boxShadow,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final Color? borderColor;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular(28);
    final Color tintColor =
        tint ?? Colors.white.withOpacity(0.78);
    final Color border =
        borderColor ?? Colors.white.withOpacity(0.55);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: radius,
            border: Border.all(color: border, width: 0.6),
            boxShadow: boxShadow,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
