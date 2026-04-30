/// Shared models for teacher-authored custom curriculum (lessons +
/// MCQs) between the teachers and student apps. Mirror the database
/// tables in `supabase/migrations/0005_custom_curriculum.sql`.

class CustomLesson {
  const CustomLesson({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.topicId,
    required this.topicTitle,
    required this.lessonTitle,
    required this.bodyMarkdown,
    required this.keyIdeas,
    required this.workedExampleMarkdown,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomLesson.fromMap(Map<String, dynamic> map) {
    final dynamic rawIdeas = map['key_ideas'];
    final List<String> ideas = rawIdeas is List
        ? rawIdeas.map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];
    return CustomLesson(
      id: map['id'] as String,
      teacherId: map['teacher_id'] as String,
      subjectId: map['subject_id'] as String,
      topicId: map['topic_id'] as String?,
      topicTitle: map['topic_title'] as String?,
      lessonTitle: map['lesson_title'] as String,
      bodyMarkdown: (map['body_markdown'] as String?) ?? '',
      keyIdeas: ideas,
      workedExampleMarkdown: map['worked_example_markdown'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String teacherId;
  final String subjectId;

  /// Null means "this is a brand-new topic the teacher invented" — i.e.
  /// it isn't in the bundled curriculum. Pair with [topicTitle] for
  /// display.
  final String? topicId;
  final String? topicTitle;

  final String lessonTitle;
  final String bodyMarkdown;
  final List<String> keyIdeas;
  final String? workedExampleMarkdown;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CustomLessonQuestion {
  const CustomLessonQuestion({
    required this.id,
    required this.lessonId,
    required this.position,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory CustomLessonQuestion.fromMap(Map<String, dynamic> map) {
    final dynamic raw = map['options'];
    final List<String> options = raw is List
        ? raw.map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];
    return CustomLessonQuestion(
      id: map['id'] as String,
      lessonId: map['lesson_id'] as String,
      position: (map['position'] as int?) ?? 0,
      prompt: map['prompt'] as String,
      options: options,
      correctIndex: (map['correct_index'] as int?) ?? 0,
      explanation: map['explanation'] as String?,
    );
  }

  final String id;
  final String lessonId;
  final int position;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
}
