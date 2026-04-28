import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/widgets/question_card.dart';
import 'package:studysync_syria/features/topics/lesson_view.dart';

class TopicDetailScreen extends StatelessWidget {
  const TopicDetailScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final Topic? topic = Curriculum.topicById(topicId);
    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Topic not found')),
        body: const Center(child: Text('We could not find that topic.')),
      );
    }

    final Subject? subject = Curriculum.subjectById(topic.subjectId);
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
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
