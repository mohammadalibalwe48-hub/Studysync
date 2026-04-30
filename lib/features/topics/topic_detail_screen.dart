import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/question_card.dart';
import 'package:studysync_syria/features/topics/lesson_view.dart';

class TopicDetailScreen extends StatefulWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final String topicId;

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final DateTime _startedAt = DateTime.now();
  final Set<String> _answeredQuestionIds = <String>{};
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  String? _lastError;

  Topic? _topic;
  Subject? _subject;

  @override
  void initState() {
    super.initState();
    _topic = Curriculum.topicById(widget.topicId);
    if (_topic != null) {
      _subject = Curriculum.subjectById(_topic!.subjectId);
    }
  }

  @override
  void dispose() {
    _maybeRecordSession();
    super.dispose();
  }

  Future<void> _maybeRecordSession() async {
    if (_totalAnswers == 0) return;
    final Topic? topic = _topic;
    if (topic == null) return;
    final int minutes =
        DateTime.now().difference(_startedAt).inSeconds ~/ 60;
    try {
      await StudySyncQueries.createStudySession(
        subjectId: topic.subjectId,
        topicId: topic.id,
        durationMinutes: minutes < 1 ? 1 : minutes,
      );
    } catch (_) {
      // أفضل جهد ممكن: لا نظهر الأخطاء أثناء التخلّص من الشاشة.
    }
  }

  Future<void> _onQuestionAnswered({
    required Topic topic,
    required String questionId,
    required int selectedIndex,
    required bool isCorrect,
  }) async {
    if (!_answeredQuestionIds.add(questionId)) {
      // سُجّل سابقاً؛ نحفظ المحاولة الجديدة فقط.
    } else {
      _totalAnswers += 1;
      if (isCorrect) _correctAnswers += 1;
    }

    final bool topicCompleted =
        _answeredQuestionIds.length >= topic.questions.length;

    try {
      await StudySyncQueries.saveQuestionAttempt(
        questionId: questionId,
        selectedOptionIndex: selectedIndex,
        isCorrect: isCorrect,
        subjectId: topic.subjectId,
        topicId: topic.id,
      );
      await StudySyncQueries.upsertStudentProgress(
        subjectId: topic.subjectId,
        topicId: topic.id,
        completed: topicCompleted,
        correctAnswers: _correctAnswers,
        totalAnswers: _totalAnswers,
      );
      if (!mounted) return;
      setState(() => _lastError = null);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _lastError = 'تعذّر حفظ إجابتك حالياً. تابع الدراسة دون قلق.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Topic? topic = _topic;
    if (topic == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                _BackBar(
                  title: 'الدرس غير موجود',
                  onBack: () => context.go('/home'),
                ),
                const Expanded(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'الدرس غير موجود',
                    description:
                        'تعذّر العثور على هذا الدرس. ربما تم حذفه.',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Subject? subject = _subject;
    final Color accent =
        subject?.color ?? Theme.of(context).colorScheme.primary;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _BackBar(
                title: topic.title,
                onBack: () {
                  if (subject != null) {
                    context.go('/subjects/${subject.id}');
                  } else {
                    context.go('/home');
                  }
                },
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: <Widget>[
                    FadeSlideIn(
                      child: LessonView(topic: topic, accentColor: accent),
                    ),
                    if (topic.keyIdeas.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: KeyIdeasSection(
                          ideas: topic.keyIdeas,
                          accentColor: accent,
                        ),
                      ),
                    ],
                    if (topic.workedExample != null) ...<Widget>[
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: WorkedExampleSection(
                          content: topic.workedExample!,
                          accentColor: accent,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    if (topic.questions.isEmpty)
                      const FadeSlideIn(
                        delay: Duration(milliseconds: 100),
                        child: EmptyState(
                          compact: true,
                          icon: Icons.quiz_outlined,
                          title: 'لا توجد أسئلة بعد',
                          description:
                              'سيتم إضافة أسئلة تدريبية لهذا الدرس قريباً.',
                        ),
                      )
                    else ...<Widget>[
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.fact_check_rounded,
                              color: accent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'اختبر نفسك',
                              style:
                                  Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List<Widget>.generate(topic.questions.length,
                          (int i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: FadeSlideIn(
                            delay:
                                Duration(milliseconds: 220 + i * 80),
                            child: QuestionCard(
                              question: topic.questions[i],
                              questionNumber: i + 1,
                              accentColor: accent,
                              onAnswered:
                                  (int selectedIndex, bool isCorrect) {
                                _onQuestionAnswered(
                                  topic: topic,
                                  questionId: topic.questions[i].id,
                                  selectedIndex: selectedIndex,
                                  isCorrect: isCorrect,
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _lastError != null
                          ? Padding(
                              key: ValueKey<String>(_lastError!),
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color:
                                      scheme.errorContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: scheme.error.withOpacity(0.30),
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: scheme.error,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _lastError!,
                                        style:
                                            TextStyle(color: scheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
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
