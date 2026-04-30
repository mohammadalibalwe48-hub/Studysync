import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/models/topic.dart';

/// عرض الدرس النصي في أعلى صفحة تفاصيل الدرس.
///
/// يتضمّن العرض شارة "درس"، عنوان الدرس، شرح موجز، شريحة لونية رأسية
/// بلون المادة، ثم نصّ الدرس الكامل.
class LessonView extends StatelessWidget {
  const LessonView({
    super.key,
    required this.topic,
    required this.accentColor,
  });

  final Topic topic;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  accentColor,
                  accentColor.withOpacity(0.30),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'الدرس',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic.description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: palette.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  topic.lessonContent,
                  style: const TextStyle(fontSize: 15, height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// قسم "القوانين والأفكار المهمة" — قائمة من نقاط نصية بارزة.
class KeyIdeasSection extends StatelessWidget {
  const KeyIdeasSection({
    super.key,
    required this.ideas,
    required this.accentColor,
  });

  final List<String> ideas;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_rounded, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'القوانين والأفكار المهمة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < ideas.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ideas[i],
                    style: const TextStyle(fontSize: 14.5, height: 1.6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// قسم "مثال محلول" — يعرض شرحاً تطبيقياً موزوناً مع الحلّ خطوة بخطوة.
class WorkedExampleSection extends StatelessWidget {
  const WorkedExampleSection({
    super.key,
    required this.content,
    required this.accentColor,
  });

  final String content;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 0.8,
        ),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.functions_rounded, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'مثال محلول',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 14.5, height: 1.7),
          ),
        ],
      ),
    );
  }
}
