import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/widgets/animations.dart';

/// Hero subject card — large lavender/blossom panel with completion
/// chip, subject title, "X notes" subtitle, an arrow-CTA button, and
/// a mascot slot on the trailing side. Mirrors the layout of the
/// reference design directly.
///
/// The subject's [Subject.color] is used as the card tint (with a low
/// alpha so the indigo primary still leads the page); the mascot slot
/// shows a large stylised icon for now and will be replaced with a
/// dedicated illustration once the asset ships.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.progress,
    this.notesCount,
    this.mascot,
  });

  final Subject subject;
  final VoidCallback onTap;

  /// Completion fraction in 0..1. Null means "no data".
  final double? progress;

  /// Optional override for the small "X notes" subtitle. Default 0.
  final int? notesCount;

  /// Optional override for the trailing mascot illustration. When
  /// null, falls back to a large stylised icon based on
  /// [Subject.icon].
  final Widget? mascot;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final Color tone = subject.color;
    final double? p = progress;
    final int percent =
        p == null ? 0 : (p.clamp(0, 1) * 100).round();
    final int notes = notesCount ?? 0;

    final Color cardBg = Color.alphaBlend(
      tone.withOpacity(0.18),
      scheme.surfaceContainerLowest,
    );
    final Color tintBg = Color.alphaBlend(
      tone.withOpacity(0.32),
      scheme.surfaceContainerLowest,
    );
    final Color labelColor = scheme.onSurface;

    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: palette.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            // Soft tone wash bleeding from the trailing edge so the
            // mascot half of the card reads slightly warmer.
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tintBg,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Top row — completion chip + ⋯ menu icon.
                        Row(
                          children: <Widget>[
                            _CompletionChip(
                              percent: percent,
                              tone: tone,
                            ),
                            const Spacer(),
                          ],
                        ),
                        const Spacer(),
                        // Subject title — large and bold.
                        Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: labelColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notes == 0 ? 'لا توجد ملاحظات' : '$notes ملاحظة',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bottom-left circular arrow CTA.
                        _ArrowBadge(tone: tone),
                      ],
                    ),
                  ),
                  // Trailing mascot slot. Until illustrations ship,
                  // we render a giant stylised icon glow.
                  SizedBox(
                    width: 110,
                    child: Center(child: mascot ?? _MascotPlaceholder(tone: tone, icon: subject.icon)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionChip extends StatelessWidget {
  const _CompletionChip({required this.percent, required this.tone});
  final int percent;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tone.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.menu_book_rounded, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'مُنجز',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowBadge extends StatelessWidget {
  const _ArrowBadge({required this.tone});
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tone.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_outward_rounded,
        size: 20,
        color: tone,
      ),
    );
  }
}

class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder({required this.tone, required this.icon});
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surfaceContainerLowest.withOpacity(0.7),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tone.withOpacity(0.30),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        Icon(icon, size: 56, color: tone),
      ],
    );
  }
}
