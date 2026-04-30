import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/features/subjects/topic_list_screen.dart'
    show TopicStatus;

/// بطاقة درس داخل قائمة دروس مادة معينة. تعرض عنوان الدرس، وصفه، عدد
/// الأسئلة المتاحة فيه، وحالته الدراسية.
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

  /// رقم ترتيبي اختياري (بدءاً من 1) يُعرض كميدالية مرافقة للأيقونة.
  final int? index;

  /// حالة الدرس الدراسية الحالية: لم يبدأ / قيد الدراسة / مكتمل.
  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final int qCount = topic.questions.length;
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.outline, width: 0.6),
          boxShadow: palette.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        accentColor.withOpacity(0.20),
                        accentColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withOpacity(0.20),
                      width: 0.6,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: index != null
                      ? Text(
                          '$index',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Icon(
                          Icons.menu_book_outlined,
                          color: accentColor,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        topic.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                const SizedBox(width: 8),
                // RTL: استخدم سهم اليمين للتعبير عن "الانتقال إلى التفاصيل".
                Icon(
                  Icons.chevron_left_rounded,
                  size: 22,
                  color: palette.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _Pill(
                  icon: Icons.quiz_outlined,
                  label: '$qCount أسئلة',
                  tone: palette.muted,
                  background: palette.champagne,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
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
    final ({String label, Color tone, IconData icon}) v = switch (status) {
      TopicStatus.notStarted => (
          label: 'لم يبدأ',
          tone: Theme.of(context).colorScheme.onSurfaceVariant,
          icon: Icons.lock_clock_outlined,
        ),
      TopicStatus.inProgress => (
          label: 'قيد الدراسة',
          tone: accent,
          icon: Icons.hourglass_bottom_rounded,
        ),
      TopicStatus.completed => (
          label: 'مكتمل',
          tone: const Color(0xFF34A853),
          icon: Icons.check_circle_rounded,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: v.tone.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: v.tone.withOpacity(0.25), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(v.icon, size: 14, color: v.tone),
          const SizedBox(width: 6),
          Text(
            v.label,
            style: TextStyle(
              color: v.tone,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
