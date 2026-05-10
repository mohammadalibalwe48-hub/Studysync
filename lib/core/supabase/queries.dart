import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/core/supabase/supabase_client.dart';

/// One row from `public.student_progress`.
class StudentProgressRow {
  const StudentProgressRow({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.topicId,
    required this.completed,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.updatedAt,
  });

  factory StudentProgressRow.fromMap(Map<String, dynamic> map) {
    return StudentProgressRow(
      id: map['id'] as String,
      userId: map['user_id'] as String,
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

  final String id;
  final String userId;
  final String subjectId;
  final String topicId;
  final bool completed;
  final int correctAnswers;
  final int totalAnswers;
  final DateTime updatedAt;

  double get accuracy =>
      totalAnswers == 0 ? 0 : correctAnswers / totalAnswers;
}

/// One row from `public.question_attempts`.
class QuestionAttemptRow {
  const QuestionAttemptRow({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.subjectId,
    required this.topicId,
    required this.selectedOptionIndex,
    required this.isCorrect,
    required this.createdAt,
  });

  factory QuestionAttemptRow.fromMap(Map<String, dynamic> map) {
    return QuestionAttemptRow(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      questionId: map['question_id'] as String,
      subjectId: map['subject_id'] as String?,
      topicId: map['topic_id'] as String?,
      selectedOptionIndex: map['selected_option_index'] as int,
      isCorrect: map['is_correct'] as bool,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String userId;
  final String questionId;
  final String? subjectId;
  final String? topicId;
  final int selectedOptionIndex;
  final bool isCorrect;
  final DateTime createdAt;
}

/// One row from `public.study_sessions`.
class StudySessionRow {
  const StudySessionRow({
    required this.id,
    required this.userId,
    required this.subjectId,
    required this.topicId,
    required this.durationMinutes,
    required this.createdAt,
  });

  factory StudySessionRow.fromMap(Map<String, dynamic> map) {
    return StudySessionRow(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      subjectId: map['subject_id'] as String?,
      topicId: map['topic_id'] as String?,
      durationMinutes: (map['duration_minutes'] as int?) ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String userId;
  final String? subjectId;
  final String? topicId;
  final int durationMinutes;
  final DateTime createdAt;
}

/// Aggregated dashboard data for the Progress screen.
class ProgressSummary {
  const ProgressSummary({
    required this.completedTopics,
    required this.totalTopicsTracked,
    required this.correctAnswers,
    required this.totalAnswers,
    required this.studyMinutes,
    required this.streakDays,
    required this.completionBySubject,
  });

  final int completedTopics;
  final int totalTopicsTracked;
  final int correctAnswers;
  final int totalAnswers;
  final int studyMinutes;
  final int streakDays;

  /// `subject_id` -> completion percent (0.0–1.0).
  final Map<String, double> completionBySubject;

  double get completionPercent => totalTopicsTracked == 0
      ? 0
      : completedTopics / totalTopicsTracked;

  double get correctAnswerRate =>
      totalAnswers == 0 ? 0 : correctAnswers / totalAnswers;

  static const ProgressSummary empty = ProgressSummary(
    completedTopics: 0,
    totalTopicsTracked: 0,
    correctAnswers: 0,
    totalAnswers: 0,
    studyMinutes: 0,
    streakDays: 0,
    completionBySubject: <String, double>{},
  );
}

/// Thrown when a query is attempted while no user is signed in.
class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();

  @override
  String toString() =>
      'NotAuthenticatedException: no Supabase session is available.';
}

/// All Supabase database queries for StudySync Syria.
///
/// Rules enforced here:
/// - Every query is scoped to the current authenticated user. The UI
///   never passes a `user_id` directly.
/// - Errors are caught and re-thrown as typed exceptions so callers can
///   surface them to the UI.
/// - No silent failures.
class StudySyncQueries {
  StudySyncQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  static String _requireUserId() {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) {
      throw const NotAuthenticatedException();
    }
    return user.id;
  }

  // ---------------------------------------------------------------------------
  // student_progress
  // ---------------------------------------------------------------------------

  /// Fetches all topic progress rows for the current user.
  static Future<List<StudentProgressRow>> fetchStudentProgress() async {
    final String userId = _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('student_progress')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return rows.map(StudentProgressRow.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load progress: ${e.message}');
    }
  }

  /// Inserts or updates the progress row for `(user, topic)`.
  ///
  /// The unique constraint on `(user_id, topic_id)` makes this idempotent.
  static Future<StudentProgressRow> upsertStudentProgress({
    required String subjectId,
    required String topicId,
    bool? completed,
    int? correctAnswers,
    int? totalAnswers,
  }) async {
    final String userId = _requireUserId();
    final Map<String, dynamic> payload = <String, dynamic>{
      'user_id': userId,
      'subject_id': subjectId,
      'topic_id': topicId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (completed != null) 'completed': completed,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
      if (totalAnswers != null) 'total_answers': totalAnswers,
    };
    try {
      final Map<String, dynamic> row = await _db
          .from('student_progress')
          .upsert(payload, onConflict: 'user_id,topic_id')
          .select()
          .single();
      return StudentProgressRow.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save progress: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // question_attempts
  // ---------------------------------------------------------------------------

  /// Records a single answered question for the current user.
  static Future<QuestionAttemptRow> saveQuestionAttempt({
    required String questionId,
    required int selectedOptionIndex,
    required bool isCorrect,
    String? subjectId,
    String? topicId,
  }) async {
    final String userId = _requireUserId();
    try {
      final Map<String, dynamic> row = await _db
          .from('question_attempts')
          .insert(<String, dynamic>{
            'user_id': userId,
            'question_id': questionId,
            'subject_id': subjectId,
            'topic_id': topicId,
            'selected_option_index': selectedOptionIndex,
            'is_correct': isCorrect,
          })
          .select()
          .single();
      return QuestionAttemptRow.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save answer: ${e.message}');
    }
  }

  /// Fetches recent question attempts, optionally filtered by topic.
  static Future<List<QuestionAttemptRow>> fetchQuestionAttempts({
    String? topicId,
    int limit = 100,
  }) async {
    final String userId = _requireUserId();
    try {
      final base =
          _db.from('question_attempts').select().eq('user_id', userId);
      final filtered = topicId == null ? base : base.eq('topic_id', topicId);
      final List<Map<String, dynamic>> rows = await filtered
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(QuestionAttemptRow.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load answers: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // study_sessions
  // ---------------------------------------------------------------------------

  /// Records that the current user studied a topic for `durationMinutes`.
  static Future<StudySessionRow> createStudySession({
    String? subjectId,
    String? topicId,
    required int durationMinutes,
  }) async {
    final String userId = _requireUserId();
    try {
      final Map<String, dynamic> row = await _db
          .from('study_sessions')
          .insert(<String, dynamic>{
            'user_id': userId,
            'subject_id': subjectId,
            'topic_id': topicId,
            'duration_minutes': durationMinutes,
          })
          .select()
          .single();
      return StudySessionRow.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save study session: ${e.message}');
    }
  }

  /// Fetches recent study sessions for the current user.
  static Future<List<StudySessionRow>> fetchStudySessions({
    int limit = 100,
  }) async {
    final String userId = _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('study_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(StudySessionRow.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load study sessions: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // dashboard summary
  // ---------------------------------------------------------------------------

  /// Aggregates progress, accuracy, study time and streak for the
  /// authenticated user.
  ///
  /// This is intended for the Progress screen — it is a few small reads,
  /// not a heavy server-side aggregation, so we keep it client-side and
  /// cheap.
  static Future<ProgressSummary> fetchProgressSummary() async {
    _requireUserId();
    try {
      final List<StudentProgressRow> progress = await fetchStudentProgress();
      final List<StudySessionRow> sessions =
          await fetchStudySessions(limit: 365);

      final int completed = progress.where((StudentProgressRow p) => p.completed).length;
      final int totalCorrect =
          progress.fold<int>(0, (int sum, StudentProgressRow p) => sum + p.correctAnswers);
      final int totalAnswers =
          progress.fold<int>(0, (int sum, StudentProgressRow p) => sum + p.totalAnswers);
      final int studyMinutes =
          sessions.fold<int>(0, (int sum, StudySessionRow s) => sum + s.durationMinutes);

      final Map<String, List<StudentProgressRow>> bySubject =
          <String, List<StudentProgressRow>>{};
      for (final StudentProgressRow row in progress) {
        bySubject.putIfAbsent(row.subjectId, () => <StudentProgressRow>[]).add(row);
      }
      final Map<String, double> completionBySubject = <String, double>{
        for (final MapEntry<String, List<StudentProgressRow>> entry
            in bySubject.entries)
          entry.key: entry.value.isEmpty
              ? 0
              : entry.value.where((StudentProgressRow p) => p.completed).length /
                  entry.value.length,
      };

      return ProgressSummary(
        completedTopics: completed,
        totalTopicsTracked: progress.length,
        correctAnswers: totalCorrect,
        totalAnswers: totalAnswers,
        studyMinutes: studyMinutes,
        streakDays: _computeStreakDays(sessions),
        completionBySubject: completionBySubject,
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to load progress summary: ${e.message}');
    }
  }

  /// Counts consecutive days (ending today, in UTC) that contain at
  /// least one study session.
  static int _computeStreakDays(List<StudySessionRow> sessions) {
    if (sessions.isEmpty) return 0;
    final Set<String> days = <String>{
      for (final StudySessionRow s in sessions)
        _dateKey(s.createdAt.toUtc()),
    };
    int streak = 0;
    DateTime cursor = DateTime.now().toUtc();
    while (days.contains(_dateKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // bookmarked_questions
  // ---------------------------------------------------------------------------

  /// Fetches all bookmarked question IDs for the current user.
  static Future<List<String>> fetchBookmarkedQuestions() async {
    final String userId = _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('bookmarked_questions')
          .select('question_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map((Map<String, dynamic> r) => r['question_id'] as String)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load bookmarks: ${e.message}');
    }
  }

  /// Adds a bookmark for the current user. Idempotent.
  static Future<void> addBookmark(String questionId) async {
    final String userId = _requireUserId();
    try {
      await _db.from('bookmarked_questions').upsert(
        <String, dynamic>{'user_id': userId, 'question_id': questionId},
        onConflict: 'user_id,question_id',
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to bookmark question: ${e.message}');
    }
  }

  /// Removes a bookmark for the current user. Idempotent.
  static Future<void> removeBookmark(String questionId) async {
    final String userId = _requireUserId();
    try {
      await _db
          .from('bookmarked_questions')
          .delete()
          .eq('user_id', userId)
          .eq('question_id', questionId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to remove bookmark: ${e.message}');
    }
  }

  /// Removes every bookmark for the current user.
  static Future<void> clearBookmarks() async {
    final String userId = _requireUserId();
    try {
      await _db.from('bookmarked_questions').delete().eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to clear bookmarks: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // study_notes
  // ---------------------------------------------------------------------------

  /// Fetches every study note for the current user, newest first.
  static Future<List<Map<String, dynamic>>> fetchStudyNotes() async {
    final String userId = _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('study_notes')
          .select('id, topic_id, title, body, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return rows;
    } on PostgrestException catch (e) {
      throw Exception('Failed to load notes: ${e.message}');
    }
  }

  /// Inserts or updates a study note. When [id] is null a new row is
  /// created; otherwise the matching row (scoped to the current user) is
  /// updated. Returns the canonical row from the server.
  static Future<Map<String, dynamic>> upsertStudyNote({
    String? id,
    required String topicId,
    required String title,
    required String body,
  }) async {
    final String userId = _requireUserId();
    final Map<String, dynamic> payload = <String, dynamic>{
      'user_id': userId,
      'topic_id': topicId,
      'title': title,
      'body': body,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (id != null) 'id': id,
    };
    try {
      final Map<String, dynamic> row = await _db
          .from('study_notes')
          .upsert(payload)
          .select('id, topic_id, title, body, updated_at')
          .single();
      return row;
    } on PostgrestException catch (e) {
      throw Exception('Failed to save note: ${e.message}');
    }
  }

  /// Deletes a study note owned by the current user.
  static Future<void> deleteStudyNote(String id) async {
    final String userId = _requireUserId();
    try {
      await _db
          .from('study_notes')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete note: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // student_preferences
  // ---------------------------------------------------------------------------

  /// Fetches the preferences row for the current user. Returns null when
  /// no row has been written yet (treat that as "use defaults").
  static Future<Map<String, dynamic>?> fetchStudentPreferences() async {
    final String userId = _requireUserId();
    try {
      return await _db
          .from('student_preferences')
          .select('daily_goal_minutes, theme_mode, notification_prefs')
          .eq('user_id', userId)
          .maybeSingle();
    } on PostgrestException catch (e) {
      throw Exception('Failed to load preferences: ${e.message}');
    }
  }

  /// Updates the daily-goal preference for the current user. Inserts
  /// the row if it doesn't exist yet.
  static Future<void> setDailyGoalMinutes(int minutes) async {
    final String userId = _requireUserId();
    try {
      await _db.from('student_preferences').upsert(
        <String, dynamic>{
          'user_id': userId,
          'daily_goal_minutes': minutes,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to save daily goal: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // leaderboard
  // ---------------------------------------------------------------------------

  /// Fetches the top [limit] users by study minutes over the last 7
  /// days. Backed by the `leaderboard_top` SECURITY DEFINER RPC so this
  /// works even though students can only read their own rows in
  /// `study_sessions`.
  static Future<List<LeaderboardEntry>> fetchLeaderboard({
    int limit = 20,
  }) async {
    _requireUserId();
    try {
      final List<dynamic> rows = await _db.rpc(
        'leaderboard_top',
        params: <String, dynamic>{'_limit': limit},
      ) as List<dynamic>;
      return rows
          .whereType<Map<String, dynamic>>()
          .map(LeaderboardEntry.fromMap)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to load leaderboard: ${e.message}');
    }
  }
}

/// One row of the weekly leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.studyMinutes,
    required this.isSelf,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['user_id'] as String,
      displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
          ? map['display_name'] as String
          : 'طالب',
      studyMinutes: (map['study_minutes'] as int?) ?? 0,
      isSelf: (map['is_self'] as bool?) ?? false,
    );
  }

  final String userId;
  final String displayName;
  final int studyMinutes;
  final bool isSelf;
}
