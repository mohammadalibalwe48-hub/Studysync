import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/topic_card.dart';

class TopicListScreen extends StatelessWidget {
  const TopicListScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final Subject? subject = Curriculum.subjectById(subjectId);
    final List<Topic> topics = Curriculum.topicsForSubject(subjectId);

    if (subject == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                _BackBar(
                  title: 'Subject not found',
                  onBack: () => context.go('/home'),
                ),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Subject not found',
                    description:
                        'We could not find that subject. It may have been '
                        'removed.',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _BackBar(
                title: subject.name,
                onBack: () => context.go('/home'),
              ),
              Expanded(
                child: topics.isEmpty
                    ? const EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'No topics yet',
                        description:
                            'Topics for this subject will appear here once '
                            'they are published.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: topics.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int i) {
                          if (i == 0) {
                            return FadeSlideIn(
                              child: _SubjectIntro(
                                subject: subject,
                                topicCount: topics.length,
                                palette: palette,
                              ),
                            );
                          }
                          final int idx = i - 1;
                          final Topic t = topics[idx];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 80 + idx * 70),
                            child: TopicCard(
                              topic: t,
                              accentColor: subject.color,
                              index: idx + 1,
                              onTap: () => context.go('/topics/${t.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectIntro extends StatelessWidget {
  const _SubjectIntro({
    required this.subject,
    required this.topicCount,
    required this.palette,
  });

  final Subject subject;
  final int topicCount;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  subject.color.withOpacity(0.22),
                  subject.color.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(subject.icon, color: subject.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$topicCount ${topicCount == 1 ? 'topic' : 'topics'} '
                  '· ${subject.description}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: palette.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
