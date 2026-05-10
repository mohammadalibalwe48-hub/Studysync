import 'package:flutter/material.dart';

/// Calm solid-colour scaffold background used app-wide.
///
/// In the previous "Radiant Achievement" design this widget rendered
/// three drifting golden glows behind every screen. The Focus & Flow
/// redesign drops the animated glows entirely — modern study apps
/// (Notion, Quizlet, Things 3, Linear) use calm, almost-flat
/// backgrounds so the content does the talking. We keep the widget so
/// every screen that already uses it carries on rendering correctly,
/// just without the moving lights.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    // Kept for backwards-compat with older callers.
    this.intensity = 1.0,
  });

  final Widget child;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: child,
    );
  }
}
