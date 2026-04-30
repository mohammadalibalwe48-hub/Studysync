import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/features/curriculum/custom_lesson_card.dart';
import 'package:studysync_syria/features/curriculum/custom_lesson_models.dart';

/// Full-screen view of a single teacher-authored "new topic" lesson.
/// Reached from the subject screen; the lesson must be passed as the
/// route's `extra` payload (we don't reload from the network so deep
/// links without payload bounce back to the subject list).
class CustomTopicDetailScreen extends StatelessWidget {
  const CustomTopicDetailScreen({super.key, required this.lesson});

  final StudentCustomLesson lesson;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color accent = lesson.subjectId == 'physics'
        ? const Color(0xFF1E73E8)
        : lesson.subjectId == 'chemistry'
            ? const Color(0xFF7B3FE4)
            : scheme.primary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                          Icons.arrow_forward_ios_rounded, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        lesson.topicTitle ?? lesson.lessonTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: <Widget>[
                    if (lesson.topicTitle != null &&
                        lesson.topicTitle!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TopicHeader(
                          title: lesson.topicTitle!,
                          accent: accent,
                          teacherName: lesson.teacherDisplayName,
                        ),
                      ),
                    FadeSlideIn(
                      child: CustomLessonCard(
                        lesson: lesson,
                        accentColor: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback when someone deep-links to /custom-lesson/<id> without a
/// pre-loaded lesson payload. Just shows an explanation rather than
/// silently bouncing.
class CustomTopicDetailMissingScreen extends StatelessWidget {
  const CustomTopicDetailMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                          Icons.arrow_forward_ios_rounded, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        'الدرس غير متوفّر',
                        style:
                            Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'الدرس غير متوفّر',
                  description:
                      'افتح الدرس من قائمة المواضيع لرؤية محتواه.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({
    required this.title,
    required this.accent,
    required this.teacherName,
  });

  final String title;
  final Color accent;
  final String? teacherName;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  accent.withOpacity(0.22),
                  accent.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_stories_rounded,
              color: accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (teacherName != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    'موضوع جديد · أعدّه: $teacherName',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
