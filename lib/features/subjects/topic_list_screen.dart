import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/topic_card.dart';

/// حالة دراسة الموضوع كما تظهر في قائمة المواضيع.
enum TopicStatus {
  notStarted,
  inProgress,
  completed,
}

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  Map<String, StudentProgressRow> _progressByTopic =
      <String, StudentProgressRow>{};
  bool _loadedProgress = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final List<StudentProgressRow> rows =
          await StudySyncQueries.fetchStudentProgress();
      if (!mounted) return;
      setState(() {
        _progressByTopic = <String, StudentProgressRow>{
          for (final StudentProgressRow row in rows) row.topicId: row,
        };
        _loadedProgress = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progressByTopic = <String, StudentProgressRow>{};
        _loadedProgress = true;
      });
    }
  }

  TopicStatus _statusFor(Topic topic) {
    final StudentProgressRow? row = _progressByTopic[topic.id];
    if (row == null) return TopicStatus.notStarted;
    if (row.completed) return TopicStatus.completed;
    if (row.totalAnswers > 0) return TopicStatus.inProgress;
    return TopicStatus.notStarted;
  }

  double _subjectCompletion(List<Topic> topics) {
    if (topics.isEmpty || !_loadedProgress) return 0;
    final int completed = topics.where((Topic t) {
      final StudentProgressRow? row = _progressByTopic[t.id];
      return row?.completed ?? false;
    }).length;
    return completed / topics.length;
  }

  @override
  Widget build(BuildContext context) {
    final Subject? subject = Curriculum.subjectById(widget.subjectId);
    final List<Topic> topics =
        Curriculum.topicsForSubject(widget.subjectId);

    if (subject == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                _BackBar(
                  title: 'المادة غير موجودة',
                  onBack: () => context.go('/home'),
                ),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'المادة غير موجودة',
                    description:
                        'تعذّر العثور على هذه المادة. ربما تم حذفها.',
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
                        title: 'لا توجد دروس بعد',
                        description:
                            'سيتم نشر دروس هذه المادة قريباً.',
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: topics.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int i) {
                          if (i == 0) {
                            return FadeSlideIn(
                              child: _SubjectIntro(
                                subject: subject,
                                topicCount: topics.length,
                                completion: _subjectCompletion(topics),
                                palette: palette,
                              ),
                            );
                          }
                          final int idx = i - 1;
                          final Topic t = topics[idx];
                          return FadeSlideIn(
                            delay:
                                Duration(milliseconds: 80 + idx * 70),
                            child: TopicCard(
                              topic: t,
                              accentColor: subject.color,
                              index: idx + 1,
                              status: _statusFor(t),
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
            // RTL: زر العودة يستخدم سهماً يتجه إلى اليمين.
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
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
    required this.completion,
    required this.palette,
  });

  final Subject subject;
  final int topicCount;
  final double completion;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final int percent = (completion.clamp(0, 1) * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
                      '$topicCount دروس · ${subject.description}',
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
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: completion.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: subject.color.withOpacity(0.10),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(subject.color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent٪',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: subject.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
