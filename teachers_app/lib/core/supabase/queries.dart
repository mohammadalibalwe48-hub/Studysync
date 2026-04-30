import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria_teachers/core/supabase/supabase_client.dart';
import 'package:studysync_syria_teachers/features/assignments/assignment_models.dart';

/// One row from `public.classes` enriched with the count of joined
/// students.
class TeacherClass {
  const TeacherClass({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.createdAt,
    required this.studentCount,
  });

  factory TeacherClass.fromMap(
    Map<String, dynamic> map, {
    required int studentCount,
  }) {
    return TeacherClass(
      id: map['id'] as String,
      name: map['name'] as String,
      joinCode: map['join_code'] as String,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      studentCount: studentCount,
    );
  }

  final String id;
  final String name;
  final String joinCode;
  final DateTime createdAt;
  final int studentCount;
}

/// One row of `public.profiles`, narrowed to the fields a teacher cares
/// about for a roster entry.
class StudentProfile {
  const StudentProfile({
    required this.userId,
    required this.fullName,
    required this.joinedAt,
  });

  final String userId;
  final String? fullName;
  final DateTime joinedAt;

  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty) ? 'طالب' : fullName!.trim();
}

/// Aggregated per-student stats used in roster cards.
class StudentRosterEntry {
  const StudentRosterEntry({
    required this.profile,
    required this.completedTopics,
    required this.totalTopicsTracked,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.studyMinutes,
    required this.lastActiveAt,
  });

  final StudentProfile profile;
  final int completedTopics;
  final int totalTopicsTracked;
  final int correctAnswers;
  final int totalAnswers;
  final int studyMinutes;
  final DateTime? lastActiveAt;

  double get completionPercent => totalTopicsTracked == 0
      ? 0
      : completedTopics / totalTopicsTracked;

  double get accuracy =>
      totalAnswers == 0 ? 0 : correctAnswers / totalAnswers;
}

class StudentProgressDetail {
  const StudentProgressDetail({
    required this.subjectId,
    required this.topicId,
    required this.completed,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.updatedAt,
  });

  factory StudentProgressDetail.fromMap(Map<String, dynamic> map) {
    return StudentProgressDetail(
      subjectId: map['subject_id'] as String,
      topicId: map['topic_id'] as String,
      completed: (map['completed'] as bool?) ?? false,
      correctAnswers: (map['correct_answers'] as int?) ?? 0,
      totalAnswers: (map['total_answers'] as int?) ?? 0,
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String subjectId;
  final String topicId;
  final bool completed;
  final int correctAnswers;
  final int totalAnswers;
  final DateTime updatedAt;

  double get accuracy =>
      totalAnswers == 0 ? 0 : correctAnswers / totalAnswers;
}

class QuestionAttemptDetail {
  const QuestionAttemptDetail({
    required this.questionId,
    required this.subjectId,
    required this.topicId,
    required this.isCorrect,
    required this.createdAt,
  });

  factory QuestionAttemptDetail.fromMap(Map<String, dynamic> map) {
    return QuestionAttemptDetail(
      questionId: map['question_id'] as String,
      subjectId: map['subject_id'] as String?,
      topicId: map['topic_id'] as String?,
      isCorrect: map['is_correct'] as bool,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String questionId;
  final String? subjectId;
  final String? topicId;
  final bool isCorrect;
  final DateTime createdAt;
}

class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();
  @override
  String toString() => 'NotAuthenticatedException';
}

/// All Supabase queries the teachers app needs.
class TeacherQueries {
  TeacherQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  static String _requireUserId() {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  // ───────────────────────── classes ─────────────────────────

  static Future<List<TeacherClass>> fetchClasses() async {
    final String teacherId = _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('classes')
          .select()
          .eq('teacher_id', teacherId)
          .order('created_at', ascending: false);

      if (rows.isEmpty) return const <TeacherClass>[];

      // Pull membership counts per class in one round-trip.
      final List<String> classIds =
          rows.map((Map<String, dynamic> r) => r['id'] as String).toList();
      final List<Map<String, dynamic>> members = await _db
          .from('class_members')
          .select('class_id')
          .inFilter('class_id', classIds);

      final Map<String, int> counts = <String, int>{};
      for (final Map<String, dynamic> m in members) {
        final String id = m['class_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
      }

      return rows
          .map((Map<String, dynamic> r) => TeacherClass.fromMap(
                r,
                studentCount: counts[r['id'] as String] ?? 0,
              ))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الصفوف: ${e.message}');
    }
  }

  /// Creates a class with a freshly generated 6-character join code.
  ///
  /// Retries on the (extremely unlikely) collision of the unique join code.
  static Future<TeacherClass> createClass({required String name}) async {
    final String teacherId = _requireUserId();
    if (name.trim().isEmpty) {
      throw ArgumentError('class name is required');
    }
    try {
      for (int attempt = 0; attempt < 5; attempt++) {
        final String code = _generateJoinCode();
        try {
          final Map<String, dynamic> row = await _db
              .from('classes')
              .insert(<String, dynamic>{
                'teacher_id': teacherId,
                'name': name.trim(),
                'join_code': code,
              })
              .select()
              .single();
          return TeacherClass.fromMap(row, studentCount: 0);
        } on PostgrestException catch (e) {
          // 23505 = unique_violation. Try a different code.
          if (e.code == '23505') continue;
          rethrow;
        }
      }
      throw Exception('تعذّر توليد رمز انضمام فريد. حاول مرّة أخرى.');
    } on PostgrestException catch (e) {
      throw Exception('تعذّر إنشاء الصف: ${e.message}');
    }
  }

  static Future<void> deleteClass({required String classId}) async {
    _requireUserId();
    try {
      await _db.from('classes').delete().eq('id', classId);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر حذف الصف: ${e.message}');
    }
  }

  // ───────────────────────── roster ─────────────────────────

  static Future<List<StudentRosterEntry>> fetchClassRoster({
    required String classId,
  }) async {
    _requireUserId();
    try {
      // 1. Members of the class.
      final List<Map<String, dynamic>> members = await _db
          .from('class_members')
          .select('student_id, joined_at')
          .eq('class_id', classId);
      if (members.isEmpty) return const <StudentRosterEntry>[];

      final List<String> studentIds = members
          .map((Map<String, dynamic> m) => m['student_id'] as String)
          .toList();

      // 2. Profiles for those students.
      final List<Map<String, dynamic>> profileRows = await _db
          .from('profiles')
          .select('user_id, full_name')
          .inFilter('user_id', studentIds);
      final Map<String, String?> nameById = <String, String?>{
        for (final Map<String, dynamic> p in profileRows)
          p['user_id'] as String: p['full_name'] as String?,
      };

      // 3. Progress rows.
      final List<Map<String, dynamic>> progressRows = await _db
          .from('student_progress')
          .select()
          .inFilter('user_id', studentIds);

      // 4. Study sessions (sum of duration + max created_at).
      final List<Map<String, dynamic>> sessionRows = await _db
          .from('study_sessions')
          .select('user_id, duration_minutes, created_at')
          .inFilter('user_id', studentIds);

      final Map<String, _StudentAgg> agg = <String, _StudentAgg>{
        for (final String id in studentIds) id: _StudentAgg(),
      };

      for (final Map<String, dynamic> row in progressRows) {
        final String uid = row['user_id'] as String;
        final _StudentAgg a = agg[uid] ?? _StudentAgg();
        a.totalTopicsTracked++;
        if ((row['completed'] as bool?) ?? false) a.completedTopics++;
        a.correctAnswers += (row['correct_answers'] as int?) ?? 0;
        a.totalAnswers += (row['total_answers'] as int?) ?? 0;
        final DateTime updated =
            DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        if (a.lastActiveAt == null || updated.isAfter(a.lastActiveAt!)) {
          a.lastActiveAt = updated;
        }
        agg[uid] = a;
      }

      for (final Map<String, dynamic> row in sessionRows) {
        final String uid = row['user_id'] as String;
        final _StudentAgg a = agg[uid] ?? _StudentAgg();
        a.studyMinutes += (row['duration_minutes'] as int?) ?? 0;
        final DateTime created =
            DateTime.tryParse(row['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        if (a.lastActiveAt == null || created.isAfter(a.lastActiveAt!)) {
          a.lastActiveAt = created;
        }
        agg[uid] = a;
      }

      return members.map((Map<String, dynamic> m) {
        final String uid = m['student_id'] as String;
        final _StudentAgg a = agg[uid] ?? _StudentAgg();
        return StudentRosterEntry(
          profile: StudentProfile(
            userId: uid,
            fullName: nameById[uid],
            joinedAt: DateTime.tryParse(m['joined_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ),
          completedTopics: a.completedTopics,
          totalTopicsTracked: a.totalTopicsTracked,
          correctAnswers: a.correctAnswers,
          totalAnswers: a.totalAnswers,
          studyMinutes: a.studyMinutes,
          lastActiveAt: a.lastActiveAt,
        );
      }).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل قائمة الطلاب: ${e.message}');
    }
  }

  static Future<void> removeStudentFromClass({
    required String classId,
    required String studentId,
  }) async {
    _requireUserId();
    try {
      await _db
          .from('class_members')
          .delete()
          .eq('class_id', classId)
          .eq('student_id', studentId);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر إزالة الطالب: ${e.message}');
    }
  }

  // ───────────────────────── per-student detail ─────────────────────────

  static Future<List<StudentProgressDetail>> fetchStudentProgress({
    required String studentId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('student_progress')
          .select()
          .eq('user_id', studentId)
          .order('updated_at', ascending: false);
      return rows
          .map(StudentProgressDetail.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل تقدّم الطالب: ${e.message}');
    }
  }

  static Future<List<QuestionAttemptDetail>> fetchStudentRecentAttempts({
    required String studentId,
    int limit = 50,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('question_attempts')
          .select()
          .eq('user_id', studentId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows
          .map(QuestionAttemptDetail.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل المحاولات: ${e.message}');
    }
  }

  static Future<int> fetchStudentStudyMinutes({
    required String studentId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('study_sessions')
          .select('duration_minutes')
          .eq('user_id', studentId);
      int total = 0;
      for (final Map<String, dynamic> r in rows) {
        total += (r['duration_minutes'] as int?) ?? 0;
      }
      return total;
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل دقائق الدراسة: ${e.message}');
    }
  }

  // ───────────────────────── assignments ─────────────────────────

  static Future<List<Assignment>> fetchAssignmentsForClass({
    required String classId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('assignments')
          .select()
          .eq('class_id', classId)
          .order('created_at', ascending: false);
      return rows.map(Assignment.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الواجبات: ${e.message}');
    }
  }

  static Future<Assignment> createAssignment({
    required String classId,
    required String title,
    String? description,
    String? subjectId,
    DateTime? dueAt,
    required List<DraftQuestion> questions,
  }) async {
    final String teacherId = _requireUserId();
    if (title.trim().isEmpty) {
      throw ArgumentError('title required');
    }
    if (questions.isEmpty) {
      throw Exception('يجب إضافة سؤال واحد على الأقل.');
    }
    try {
      final Map<String, dynamic> row = await _db
          .from('assignments')
          .insert(<String, dynamic>{
            'class_id': classId,
            'teacher_id': teacherId,
            'title': title.trim(),
            'description': (description ?? '').trim().isEmpty
                ? null
                : description!.trim(),
            'subject_id': subjectId,
            'due_at': dueAt?.toUtc().toIso8601String(),
          })
          .select()
          .single();

      final Assignment assignment = Assignment.fromMap(row);

      final List<Map<String, dynamic>> questionRows = <Map<String, dynamic>>[
        for (int i = 0; i < questions.length; i++)
          questions[i].toInsertRow(assignmentId: assignment.id, position: i),
      ];
      await _db.from('assignment_questions').insert(questionRows);
      return assignment;
    } on PostgrestException catch (e) {
      throw Exception('تعذّر إنشاء الواجب: ${e.message}');
    }
  }

  static Future<void> deleteAssignment({required String assignmentId}) async {
    _requireUserId();
    try {
      await _db.from('assignments').delete().eq('id', assignmentId);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر حذف الواجب: ${e.message}');
    }
  }

  static Future<List<AssignmentQuestion>> fetchAssignmentQuestions({
    required String assignmentId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('assignment_questions')
          .select()
          .eq('assignment_id', assignmentId)
          .order('position', ascending: true);
      return rows
          .map(AssignmentQuestion.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الأسئلة: ${e.message}');
    }
  }

  static Future<List<AssignmentSubmissionSummary>> fetchAssignmentSubmissions({
    required String assignmentId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('assignment_submissions')
          .select('student_id, score, total, submitted_at')
          .eq('assignment_id', assignmentId)
          .order('submitted_at', ascending: false);
      if (rows.isEmpty) {
        return const <AssignmentSubmissionSummary>[];
      }

      final List<String> studentIds = rows
          .map((Map<String, dynamic> r) => r['student_id'] as String)
          .toSet()
          .toList();
      final List<Map<String, dynamic>> profileRows = await _db
          .from('profiles')
          .select('user_id, full_name')
          .inFilter('user_id', studentIds);
      final Map<String, String?> nameById = <String, String?>{
        for (final Map<String, dynamic> p in profileRows)
          p['user_id'] as String: p['full_name'] as String?,
      };

      return rows.map((Map<String, dynamic> r) {
        final String sid = r['student_id'] as String;
        final String? raw = nameById[sid];
        return AssignmentSubmissionSummary(
          studentId: sid,
          studentName: (raw == null || raw.trim().isEmpty)
              ? 'طالب'
              : raw.trim(),
          score: (r['score'] as int?) ?? 0,
          total: (r['total'] as int?) ?? 0,
          submittedAt:
              DateTime.tryParse(r['submitted_at']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
      }).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل التسليمات: ${e.message}');
    }
  }

  // ───────────────────────── utils ─────────────────────────

  static String _generateJoinCode() {
    // Avoid look-alike characters (0/O, 1/I/L).
    const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final Random rng = Random.secure();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < 6; i++) {
      buf.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }
}

class _StudentAgg {
  int completedTopics = 0;
  int totalTopicsTracked = 0;
  int correctAnswers = 0;
  int totalAnswers = 0;
  int studyMinutes = 0;
  DateTime? lastActiveAt;
}
