import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/core/supabase/supabase_client.dart';
import 'package:studysync_syria/features/curriculum/custom_lesson_models.dart';

/// Student-side data access for teacher-authored custom curriculum.
class CustomLessonQueries {
  CustomLessonQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  /// All teacher-authored lessons for a given `(subject_id, topic_id)`
  /// pair, enriched with the teacher's display name from `profiles`.
  /// Returns an empty list (never throws) when the user is signed out
  /// so callers can show the bundled curriculum without errors.
  static Future<List<StudentCustomLesson>> fetchLessonsForTopic({
    required String subjectId,
    required String topicId,
  }) async {
    if (SupabaseService.auth.currentUser == null) {
      return const <StudentCustomLesson>[];
    }
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('custom_lessons')
          .select()
          .eq('subject_id', subjectId)
          .eq('topic_id', topicId)
          .order('created_at', ascending: false);
      return _enrichWithTeacherNames(rows);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل دروس المعلّم: ${e.message}');
    }
  }

  /// All teacher-authored lessons for a subject that introduce a brand
  /// new topic (i.e. `topic_id is null`). Used by the subject screen to
  /// surface those as their own topic cards.
  static Future<List<StudentCustomLesson>> fetchNewTopicsForSubject({
    required String subjectId,
  }) async {
    if (SupabaseService.auth.currentUser == null) {
      return const <StudentCustomLesson>[];
    }
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('custom_lessons')
          .select()
          .eq('subject_id', subjectId)
          .filter('topic_id', 'is', null)
          .order('created_at', ascending: false);
      return _enrichWithTeacherNames(rows);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل المواضيع الجديدة: ${e.message}');
    }
  }

  /// MCQ questions for a single custom lesson, ordered by position.
  static Future<List<StudentCustomLessonQuestion>> fetchLessonQuestions({
    required String lessonId,
  }) async {
    if (SupabaseService.auth.currentUser == null) {
      return const <StudentCustomLessonQuestion>[];
    }
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('custom_lesson_questions')
          .select('id, position, prompt, options, correct_index, explanation')
          .eq('lesson_id', lessonId)
          .order('position', ascending: true);
      return rows
          .map(StudentCustomLessonQuestion.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل أسئلة الدرس: ${e.message}');
    }
  }

  static Future<List<StudentCustomLesson>> _enrichWithTeacherNames(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return const <StudentCustomLesson>[];
    final List<String> teacherIds = rows
        .map((Map<String, dynamic> r) => r['teacher_id'] as String)
        .toSet()
        .toList();
    Map<String, String?> nameById = <String, String?>{};
    try {
      final List<Map<String, dynamic>> profileRows = await _db
          .from('profiles')
          .select('user_id, full_name')
          .inFilter('user_id', teacherIds);
      nameById = <String, String?>{
        for (final Map<String, dynamic> p in profileRows)
          p['user_id'] as String: p['full_name'] as String?,
      };
    } on PostgrestException {
      // RLS may block the profile lookup for some students; show the
      // lesson without an attribution rather than failing the whole
      // topic render.
      nameById = const <String, String?>{};
    }
    return rows.map((Map<String, dynamic> r) {
      final String? raw = nameById[r['teacher_id'] as String];
      final String? clean =
          (raw == null || raw.trim().isEmpty) ? null : raw.trim();
      return StudentCustomLesson.fromMap(r, teacherDisplayName: clean);
    }).toList(growable: false);
  }
}

class StudentCustomLessonQuestion {
  const StudentCustomLessonQuestion({
    required this.id,
    required this.position,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory StudentCustomLessonQuestion.fromMap(Map<String, dynamic> map) {
    final dynamic raw = map['options'];
    final List<String> options = raw is List
        ? raw.map((dynamic e) => e.toString()).toList(growable: false)
        : const <String>[];
    return StudentCustomLessonQuestion(
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
