import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria_teachers/core/supabase/supabase_client.dart';
import 'package:studysync_syria_teachers/features/assignments/assignment_models.dart';
import 'package:studysync_syria_teachers/features/curriculum/curriculum_models.dart';

/// Teacher-side data access for custom-curriculum lessons + their
/// MCQ questions. Mirrors the shape of `TeacherQueries` for assignments.
class CurriculumQueries {
  CurriculumQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  static String _requireUserId() {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً.');
    }
    return user.id;
  }

  // ───────────────────────── lessons ─────────────────────────

  /// All custom lessons authored by the current teacher, newest first.
  static Future<List<CustomLesson>> fetchOwnLessons() async {
    final String teacherId = _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('custom_lessons')
          .select()
          .eq('teacher_id', teacherId)
          .order('updated_at', ascending: false);
      return rows.map(CustomLesson.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الدروس: ${e.message}');
    }
  }

  /// Inserts a new lesson row owned by the current teacher and returns it.
  /// Pass [topicId] = null for a brand-new topic; in that case
  /// [topicTitle] becomes the user-facing title.
  static Future<CustomLesson> createLesson({
    required String subjectId,
    required String? topicId,
    required String? topicTitle,
    required String lessonTitle,
    required String bodyMarkdown,
    required List<String> keyIdeas,
    required String? workedExampleMarkdown,
  }) async {
    final String teacherId = _requireUserId();
    if (lessonTitle.trim().isEmpty) {
      throw Exception('الرجاء إدخال عنوان الدرس.');
    }
    if (subjectId.trim().isEmpty) {
      throw Exception('الرجاء اختيار المادة.');
    }
    try {
      final Map<String, dynamic> row = await _db
          .from('custom_lessons')
          .insert(<String, dynamic>{
            'teacher_id': teacherId,
            'subject_id': subjectId,
            'topic_id': (topicId == null || topicId.trim().isEmpty)
                ? null
                : topicId.trim(),
            'topic_title': (topicTitle == null || topicTitle.trim().isEmpty)
                ? null
                : topicTitle.trim(),
            'lesson_title': lessonTitle.trim(),
            'body_markdown': bodyMarkdown,
            'key_ideas': keyIdeas
                .map((String s) => s.trim())
                .where((String s) => s.isNotEmpty)
                .toList(),
            'worked_example_markdown':
                (workedExampleMarkdown == null ||
                        workedExampleMarkdown.trim().isEmpty)
                    ? null
                    : workedExampleMarkdown,
          })
          .select()
          .single();
      return CustomLesson.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر حفظ الدرس: ${e.message}');
    }
  }

  /// Updates an existing lesson. RLS scopes this to the teacher who
  /// owns the row.
  static Future<CustomLesson> updateLesson({
    required String lessonId,
    required String subjectId,
    required String? topicId,
    required String? topicTitle,
    required String lessonTitle,
    required String bodyMarkdown,
    required List<String> keyIdeas,
    required String? workedExampleMarkdown,
  }) async {
    _requireUserId();
    if (lessonTitle.trim().isEmpty) {
      throw Exception('الرجاء إدخال عنوان الدرس.');
    }
    try {
      final Map<String, dynamic> row = await _db
          .from('custom_lessons')
          .update(<String, dynamic>{
            'subject_id': subjectId,
            'topic_id': (topicId == null || topicId.trim().isEmpty)
                ? null
                : topicId.trim(),
            'topic_title': (topicTitle == null || topicTitle.trim().isEmpty)
                ? null
                : topicTitle.trim(),
            'lesson_title': lessonTitle.trim(),
            'body_markdown': bodyMarkdown,
            'key_ideas': keyIdeas
                .map((String s) => s.trim())
                .where((String s) => s.isNotEmpty)
                .toList(),
            'worked_example_markdown':
                (workedExampleMarkdown == null ||
                        workedExampleMarkdown.trim().isEmpty)
                    ? null
                    : workedExampleMarkdown,
          })
          .eq('id', lessonId)
          .select()
          .single();
      return CustomLesson.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحديث الدرس: ${e.message}');
    }
  }

  static Future<void> deleteLesson({required String lessonId}) async {
    _requireUserId();
    try {
      await _db.from('custom_lessons').delete().eq('id', lessonId);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر حذف الدرس: ${e.message}');
    }
  }

  // ───────────────────────── lesson questions ─────────────────────────

  static Future<List<CustomLessonQuestion>> fetchLessonQuestions({
    required String lessonId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('custom_lesson_questions')
          .select()
          .eq('lesson_id', lessonId)
          .order('position', ascending: true);
      return rows
          .map(CustomLessonQuestion.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الأسئلة: ${e.message}');
    }
  }

  /// Replaces every question for a lesson with the new list, in order.
  /// Idempotent: callers always pass the full desired set, so we delete
  /// then insert in one round-trip pair.
  static Future<void> setLessonQuestions({
    required String lessonId,
    required List<DraftQuestion> questions,
  }) async {
    _requireUserId();
    try {
      await _db
          .from('custom_lesson_questions')
          .delete()
          .eq('lesson_id', lessonId);
      if (questions.isEmpty) return;
      final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
        for (int i = 0; i < questions.length; i++)
          <String, dynamic>{
            'lesson_id': lessonId,
            'position': i,
            'prompt': questions[i].prompt.trim(),
            'options': questions[i]
                .options
                .map((String o) => o.trim())
                .toList(),
            'correct_index': questions[i].correctIndex,
            'explanation': questions[i].explanation.trim().isEmpty
                ? null
                : questions[i].explanation.trim(),
          },
      ];
      await _db.from('custom_lesson_questions').insert(rows);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر حفظ الأسئلة: ${e.message}');
    }
  }
}
