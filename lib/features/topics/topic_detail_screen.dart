import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
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
      // Best-effort: don't surface errors during dispose.
    }
  }

  Future<void> _onQuestionAnswered({
    required Topic topic,
    required String questionId,
    required int selectedIndex,
    required bool isCorrect,
  }) async {
    if (!_answeredQuestionIds.add(questionId)) {
      // Already counted; just save the new attempt and move on.
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
      setState(() => _lastError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final Topic? topic = _topic;
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Topic not found')),
        body: const Center(child: Text('We could not find that topic.')),
      );
    }

    final Subject? subject = _subject;
    final Color accent = subject?.color ?? Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (subject != null) {
              context.go('/subjects/${subject.id}');
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            LessonView(topic: topic, accentColor: accent),
            const SizedBox(height: 18),
            const Text(
              'Practice questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...List<Widget>.generate(topic.questions.length, (int i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: QuestionCard(
                  question: topic.questions[i],
                  questionNumber: i + 1,
                  accentColor: accent,
                  onAnswered: (int selectedIndex, bool isCorrect) {
                    _onQuestionAnswered(
                      topic: topic,
                      questionId: topic.questions[i].id,
                      selectedIndex: selectedIndex,
                      isCorrect: isCorrect,
                    );
                  },
                ),
              );
            }),
            if (_lastError != null) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Text(
                  'Could not save your answer: $_lastError',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
