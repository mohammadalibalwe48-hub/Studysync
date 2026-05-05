import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/animations.dart';

/// A primary brand-gradient call-to-action button used across the app.
///
/// The button has:
/// - Indigo → violet linear gradient.
/// - White label for premium legibility on the saturated background.
/// - Soft indigo glow shadow that grows on press.
/// - Press-scale haptic-feel via [PressableScale].
/// - Built-in loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 56,
    this.borderRadius = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool disabled = isLoading || onPressed == null;
    final VoidCallback? handler = isLoading ? null : onPressed;
    final Color labelColor =
        disabled ? Colors.white.withOpacity(0.7) : Colors.white;

    return PressableScale(
      onTap: handler,
      pressedScale: 0.97,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: disabled ? 0.55 : 1.0,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: palette.goldGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.accent.withOpacity(disabled ? 0.10 : 0.30),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey<String>('loading'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey<String>('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: labelColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (icon != null) ...<Widget>[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20, color: labelColor),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Ghost / secondary button style — soft champagne fill with a hairline
/// gold-tone border, gold label.
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
    final AppPalette palette = AppPalette.of(context);
    return PressableScale(
      onTap: onPressed,
      pressedScale: 0.97,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: palette.champagne,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.gold.withOpacity(0.55), width: 1.2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 18, color: palette.accent),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
