import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
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
        appBar: AppBar(title: const Text('Subject not found')),
        body: const Center(child: Text('We could not find that subject.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} Topics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: topics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int i) {
            final Topic t = topics[i];
            return TopicCard(
              topic: t,
              accentColor: subject.color,
              onTap: () => context.go('/topics/${t.id}'),
            );
          },
        ),
      ),
    );
  }
}
