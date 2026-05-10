import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';

/// Friendly empty-state placeholder. Modern flat layout: a subtle
/// circular icon tile, a title and a one-line helper, with an optional
/// call-to-action button.
///
/// Use [card] = `true` to render the empty state inside a soft white
/// card with a hairline outline — the "No revision cards yet" pattern
/// from the reference image. Combine with [DashedActionButton] in
/// [action] to recreate the orange dashed-pill CTA exactly.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.compact = false,
    this.card = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  final bool compact;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);

    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 60 : 80,
          height: compact ? 60 : 80,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(
              compact ? AppRadii.md : AppRadii.lg,
            ),
          ),
          child: Icon(
            icon,
            color: scheme.primary,
            size: compact ? 28 : 38,
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: palette.muted,
          ),
        ),
        if (action != null) ...<Widget>[
          const SizedBox(height: 16),
          action!,
        ],
      ],
    );

    if (!card) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: content,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: palette.outline, width: 1),
        boxShadow: palette.cardShadow,
      ),
      child: content,
    );
  }
}
