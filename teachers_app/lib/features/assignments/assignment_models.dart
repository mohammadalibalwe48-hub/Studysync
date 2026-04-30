/// Shared models for custom assignments / quizzes between teacher and
/// student apps. Mirror the database tables in
/// `supabase/migrations/0002_assignments.sql`.

class Assignment {
  const Assignment({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.dueAt,
    required this.createdAt,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      teacherId: map['teacher_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      subjectId: map['subject_id'] as String?,
      dueAt: map['due_at'] == null
          ? null
          : DateTime.tryParse(map['due_at'].toString()),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String classId;
  final String teacherId;
  final String title;
  final String? description;
  final String? subjectId;
  final DateTime? dueAt;
  final DateTime createdAt;
}

class AssignmentQuestion {
  const AssignmentQuestion({
    required this.id,
    required this.assignmentId,
    required this.position,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory AssignmentQuestion.fromMap(Map<String, dynamic> map) {
    final dynamic raw = map['options'];
    final List<String> options = raw is List
        ? raw.map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];
    return AssignmentQuestion(
      id: map['id'] as String,
      assignmentId: map['assignment_id'] as String,
      position: (map['position'] as int?) ?? 0,
      prompt: map['prompt'] as String,
      options: options,
      correctIndex: (map['correct_index'] as int?) ?? 0,
      explanation: map['explanation'] as String?,
    );
  }

  final String id;
  final String assignmentId;
  final int position;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
}

/// Editable, in-memory question used by the assignment builder before
/// persistence.
class DraftQuestion {
  DraftQuestion({
    String? prompt,
    List<String>? options,
    int? correctIndex,
    String? explanation,
  })  : prompt = prompt ?? '',
        options = options ??
            <String>[
              '',
              '',
              '',
              '',
            ],
        correctIndex = correctIndex ?? 0,
        explanation = explanation ?? '';

  String prompt;
  List<String> options;
  int correctIndex;
  String explanation;

  Map<String, dynamic> toInsertRow({
    required String assignmentId,
    required int position,
  }) {
    return <String, dynamic>{
      'assignment_id': assignmentId,
      'position': position,
      'prompt': prompt.trim(),
      'options': options.map((String o) => o.trim()).toList(),
      'correct_index': correctIndex,
      'explanation': explanation.trim().isEmpty ? null : explanation.trim(),
    };
  }
}

class AssignmentSubmissionSummary {
  const AssignmentSubmissionSummary({
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.total,
    required this.submittedAt,
  });

  final String studentId;
  final String studentName;
  final int score;
  final int total;
  final DateTime submittedAt;

  double get accuracy => total == 0 ? 0 : score / total;
}
