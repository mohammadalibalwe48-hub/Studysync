import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/features/subjects/topic_list_screen.dart'
    show TopicStatus;

/// Single topic row inside a subject's lesson list. Modern flat
/// presentation with an index badge, status pill, and a question count.
class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.topic,
    required this.accentColor,
    required this.onTap,
    this.index,
    this.status = TopicStatus.notStarted,
  });

  final Topic topic;
  final Color accentColor;
  final VoidCallback onTap;

  /// Optional 1-indexed ordinal that becomes a numeric badge.
  final int? index;

  /// Current study state for this topic.
  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final int qCount = topic.questions.length;
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.outline, width: 1),
          boxShadow: palette.cardShadow,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: index != null
                      ? Text(
                          '$index',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Icon(
                          Icons.menu_book_outlined,
                          color: accentColor,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        topic.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        topic.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // RTL: chevron_left points "forward" in the UI flow.
                Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: palette.muted,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _Pill(
                  icon: Icons.help_outline_rounded,
                  label: '$qCount أسئلة',
                  tone: palette.muted,
                  background: scheme.surfaceContainerLow,
                ),
                const SizedBox(width: 8),
                _StatusPill(status: status, accent: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.tone,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.accent});

  final TopicStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color tone;
    final IconData icon;
    final String label;
    switch (status) {
      case TopicStatus.completed:
        tone = palette.success;
        icon = Icons.check_circle_rounded;
        label = 'مكتمل';
        break;
      case TopicStatus.inProgress:
        tone = accent;
        icon = Icons.timelapse_rounded;
        label = 'قيد الدراسة';
        break;
      case TopicStatus.notStarted:
        tone = palette.muted;
        icon = Icons.circle_outlined;
        label = 'لم يبدأ';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: tone),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
