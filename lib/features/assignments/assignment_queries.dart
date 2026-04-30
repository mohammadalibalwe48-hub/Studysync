import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/core/supabase/supabase_client.dart';
import 'package:studysync_syria/features/assignments/assignment_models.dart';

/// Student-side data access for custom teacher-created assignments.
class StudentAssignmentQueries {
  StudentAssignmentQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  /// All assignments visible to the current student (RLS limits to
  /// classes they are enrolled in), enriched with their submission row
  /// (if any) and the class name.
  static Future<List<StudentAssignment>> fetchVisibleAssignments() async {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) return const <StudentAssignment>[];

    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('assignments')
          .select(
              'id, class_id, title, description, subject_id, due_at, created_at')
          .order('created_at', ascending: false);
      if (rows.isEmpty) return const <StudentAssignment>[];

      final List<String> classIds = rows
          .map((Map<String, dynamic> r) => r['class_id'] as String)
          .toSet()
          .toList();
      final List<Map<String, dynamic>> classRows = await _db
          .from('classes')
          .select('id, name')
          .inFilter('id', classIds);
      final Map<String, String> classNames = <String, String>{
        for (final Map<String, dynamic> c in classRows)
          c['id'] as String: c['name'] as String,
      };

      final List<String> assignmentIds = rows
          .map((Map<String, dynamic> r) => r['id'] as String)
          .toList();
      final List<Map<String, dynamic>> subRows = await _db
          .from('assignment_submissions')
          .select('assignment_id, score, total, submitted_at')
          .eq('student_id', user.id)
          .inFilter('assignment_id', assignmentIds);
      final Map<String, Map<String, dynamic>> submissions =
          <String, Map<String, dynamic>>{
        for (final Map<String, dynamic> s in subRows)
          s['assignment_id'] as String: s,
      };

      return rows.map((Map<String, dynamic> r) {
        final String aId = r['id'] as String;
        final Map<String, dynamic>? sub = submissions[aId];
        return StudentAssignment(
          id: aId,
          classId: r['class_id'] as String,
          title: r['title'] as String,
          description: r['description'] as String?,
          subjectId: r['subject_id'] as String?,
          dueAt: r['due_at'] == null
              ? null
              : DateTime.tryParse(r['due_at'].toString()),
          createdAt:
              DateTime.tryParse(r['created_at']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          className: classNames[r['class_id'] as String],
          submissionScore: sub == null ? null : (sub['score'] as int?),
          submissionTotal: sub == null ? null : (sub['total'] as int?),
          submittedAt: sub == null
              ? null
              : DateTime.tryParse(
                  sub['submitted_at']?.toString() ?? ''),
        );
      }).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الواجبات: ${e.message}');
    }
  }

  static Future<List<StudentAssignmentQuestion>> fetchAssignmentQuestions({
    required String assignmentId,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('assignment_questions')
          .select('id, position, prompt, options, correct_index, explanation')
          .eq('assignment_id', assignmentId)
          .order('position', ascending: true);
      return rows
          .map(StudentAssignmentQuestion.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الأسئلة: ${e.message}');
    }
  }

  /// Insert a submission row. Errors if the student already submitted
  /// (PRIMARY-key-equivalent unique constraint on (assignment_id,
  /// student_id)).
  static Future<void> submitAssignment({
    required String assignmentId,
    required int score,
    required int total,
    required List<int> answers,
  }) async {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً.');
    }
    try {
      await _db.from('assignment_submissions').upsert(<String, dynamic>{
        'assignment_id': assignmentId,
        'student_id': user.id,
        'score': score,
        'total': total,
        'answers': answers,
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'assignment_id,student_id');
    } on PostgrestException catch (e) {
      throw Exception('تعذّر إرسال الإجابات: ${e.message}');
    }
  }
}
