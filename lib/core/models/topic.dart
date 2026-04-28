import 'package:studysync_syria/core/models/question.dart';

/// A study topic that belongs to a [Subject] and contains lesson content
/// plus practice questions.
class Topic {
  const Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.lessonContent,
    required this.questions,
  });

  final String id;
  final String subjectId;
  final String title;
  final String description;
  final String lessonContent;
  final List<Question> questions;
}
