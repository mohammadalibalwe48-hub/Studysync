/// Student-side models for teacher-authored custom curriculum.
/// Mirror the database tables in
/// `supabase/migrations/0005_custom_curriculum.sql`.

class StudentCustomLesson {
  const StudentCustomLesson({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.topicId,
    required this.topicTitle,
    required this.lessonTitle,
    required this.bodyMarkdown,
    required this.keyIdeas,
    required this.workedExampleMarkdown,
    required this.teacherDisplayName,
    required this.createdAt,
  });

  factory StudentCustomLesson.fromMap(
    Map<String, dynamic> map, {
    String? teacherDisplayName,
  }) {
    final dynamic rawIdeas = map['key_ideas'];
    final List<String> ideas = rawIdeas is List
        ? rawIdeas.map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];
    return StudentCustomLesson(
      id: map['id'] as String,
      teacherId: map['teacher_id'] as String,
      subjectId: map['subject_id'] as String,
      topicId: map['topic_id'] as String?,
      topicTitle: map['topic_title'] as String?,
      lessonTitle: map['lesson_title'] as String,
      bodyMarkdown: (map['body_markdown'] as String?) ?? '',
      keyIdeas: ideas,
      workedExampleMarkdown: map['worked_example_markdown'] as String?,
      teacherDisplayName: teacherDisplayName,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String teacherId;
  final String subjectId;

  /// Null for brand-new topics that aren't in the bundled curriculum.
  /// In that case the lesson should be exposed as its own card on the
  /// subject screen, identified by [topicTitle].
  final String? topicId;
  final String? topicTitle;

  final String lessonTitle;
  final String bodyMarkdown;
  final List<String> keyIdeas;
  final String? workedExampleMarkdown;

  /// Resolved from `profiles.full_name` for display
  /// ("أعدّه: <teacher>"). Null when the join couldn't find a name.
  final String? teacherDisplayName;
  final DateTime createdAt;
}
