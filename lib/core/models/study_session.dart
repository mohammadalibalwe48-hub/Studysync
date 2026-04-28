/// Represents a single study session a student completes for a topic.
///
/// Used as a placeholder structure now; later it will be persisted
/// remotely so progress can be tracked across devices.
class StudySession {
  const StudySession({
    required this.id,
    required this.topicId,
    required this.startedAt,
    required this.endedAt,
    required this.questionsAnswered,
    required this.questionsCorrect,
  });

  final String id;
  final String topicId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int questionsAnswered;
  final int questionsCorrect;

  Duration get duration => endedAt.difference(startedAt);

  double get accuracy =>
      questionsAnswered == 0 ? 0 : questionsCorrect / questionsAnswered;
}
