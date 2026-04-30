/// Student-side models for custom assignments / quizzes a teacher created.
/// Mirror the database tables in `supabase/migrations/0002_assignments.sql`.

class StudentAssignment {
  const StudentAssignment({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.dueAt,
    required this.createdAt,
    required this.className,
    required this.submissionScore,
    required this.submissionTotal,
    required this.submittedAt,
  });

  final String id;
  final String classId;
  final String title;
  final String? description;
  final String? subjectId;
  final DateTime? dueAt;
  final DateTime createdAt;
  final String? className;

  /// Null if not yet submitted.
  final int? submissionScore;
  final int? submissionTotal;
  final DateTime? submittedAt;

  bool get isSubmitted => submittedAt != null;
}

class StudentAssignmentQuestion {
  const StudentAssignmentQuestion({
    required this.id,
    required this.position,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory StudentAssignmentQuestion.fromMap(Map<String, dynamic> map) {
    final dynamic raw = map['options'];
    final List<String> options = raw is List
        ? raw.map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];
    return StudentAssignmentQuestion(
      id: map['id'] as String,
      position: (map['position'] as int?) ?? 0,
      prompt: map['prompt'] as String,
      options: options,
      correctIndex: (map['correct_index'] as int?) ?? 0,
      explanation: map['explanation'] as String?,
    );
  }

  final String id;
  final int position;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
}
