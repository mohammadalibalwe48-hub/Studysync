import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
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
        appBar: AppBar(
          title: const Text('Subject not found'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: const SafeArea(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Subject not found',
            description:
                'We could not find that subject. It may have been removed.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: topics.isEmpty
            ? const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No topics yet',
                description:
                    'Topics for this subject will appear here once they are '
                    'published.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
