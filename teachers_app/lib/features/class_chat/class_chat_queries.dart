import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/supabase/supabase_client.dart';
import 'package:studysync_syria_teachers/features/class_chat/class_chat_models.dart';

/// Teacher-side chat / live-quiz data access.
class ClassChatQueries {
  ClassChatQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  static String _requireUserId() {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  // ───────────────────── messages ─────────────────────

  static Future<List<ChatMessage>> fetchMessages({
    required String classId,
    int limit = 100,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('class_messages')
          .select()
          .eq('class_id', classId)
          .order('created_at', ascending: false)
          .limit(limit);
      if (rows.isEmpty) return const <ChatMessage>[];

      final List<String> senderIds = rows
          .map((Map<String, dynamic> r) => r['sender_id'] as String)
          .toSet()
          .toList();
      Map<String, String?> nameById = <String, String?>{};
      try {
        final List<Map<String, dynamic>> profiles = await _db
            .from('profiles')
            .select('user_id, full_name')
            .inFilter('user_id', senderIds);
        nameById = <String, String?>{
          for (final Map<String, dynamic> p in profiles)
            p['user_id'] as String: p['full_name'] as String?,
        };
      } on PostgrestException {
        // RLS may hide.
      }

      final List<ChatMessage> out = rows
          .map((Map<String, dynamic> r) => ChatMessage.fromMap(
                r,
                senderName: nameById[r['sender_id'] as String],
              ))
          .toList(growable: true);
      out.sort((ChatMessage a, ChatMessage b) =>
          a.createdAt.compareTo(b.createdAt));
      return List<ChatMessage>.unmodifiable(out);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل المحادثة: ${e.message}');
    }
  }

  static Future<ChatMessage> sendTeacherMessage({
    required String classId,
    required String body,
  }) async {
    final String userId = _requireUserId();
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('body is required');
    }
    try {
      final Map<String, dynamic> row = await _db
          .from('class_messages')
          .insert(<String, dynamic>{
            'class_id': classId,
            'sender_id': userId,
            'sender_role': 'teacher',
            'body': trimmed,
          })
          .select()
          .single();
      String? myName;
      try {
        final Map<String, dynamic>? profile = await _db
            .from('profiles')
            .select('full_name')
            .eq('user_id', userId)
            .maybeSingle();
        myName = profile?['full_name'] as String?;
      } on PostgrestException {
        // ignore.
      }
      return ChatMessage.fromMap(row, senderName: myName);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر إرسال الرسالة: ${e.message}');
    }
  }

  static Future<void> deleteMessage({required String messageId}) async {
    _requireUserId();
    try {
      await _db.from('class_messages').delete().eq('id', messageId);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر حذف الرسالة: ${e.message}');
    }
  }

  static RealtimeChannel subscribeToMessages({
    required String classId,
    required void Function(ChatMessage message) onInsert,
    void Function(String messageId)? onDelete,
  }) {
    final RealtimeChannel ch = _db.channel('class:$classId:messages-t');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'class_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'class_id',
            value: classId,
          ),
          callback: (PostgresChangePayload payload) {
            try {
              final ChatMessage m =
                  ChatMessage.fromMap(payload.newRecord, senderName: null);
              _hydrateSenderName(m).then(onInsert);
            } catch (e, st) {
              debugPrint('class_messages insert decode failed: $e\n$st');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'class_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'class_id',
            value: classId,
          ),
          callback: (PostgresChangePayload payload) {
            final String? id = payload.oldRecord['id'] as String?;
            if (id != null) onDelete?.call(id);
          },
        )
        .subscribe();
    return ch;
  }

  static Future<ChatMessage> _hydrateSenderName(ChatMessage m) async {
    try {
      final Map<String, dynamic>? p = await _db
          .from('profiles')
          .select('full_name')
          .eq('user_id', m.senderId)
          .maybeSingle();
      return m.copyWith(senderName: p?['full_name'] as String?);
    } catch (_) {
      return m;
    }
  }

  // ───────────────────── presence ─────────────────────

  /// The teacher joins the class presence channel as `role=teacher`.
  /// [onPresenceChanged] is invoked with the set of student user-ids
  /// currently online so the teacher UI can show participant pills.
  static RealtimeChannel joinPresence({
    required String classId,
    required String? displayName,
    required void Function(Set<String> onlineStudentIds) onPresenceChanged,
  }) {
    final String userId = _requireUserId();
    final RealtimeChannel ch = _db.channel(
      'class:$classId:presence',
      opts: const RealtimeChannelConfig(self: true),
    );

    void emit() {
      final Set<String> students = <String>{};
      for (final SinglePresenceState s in ch.presenceState()) {
        for (final Presence p in s.presences) {
          if ((p.payload['role'] as String?) == 'student') {
            final String? uid = p.payload['user_id'] as String?;
            if (uid != null) students.add(uid);
          }
        }
      }
      onPresenceChanged(students);
    }

    ch
        .onPresenceSync((_) => emit())
        .onPresenceJoin((_) => emit())
        .onPresenceLeave((_) => emit())
        .subscribe(
      (RealtimeSubscribeStatus status, Object? error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await ch.track(<String, dynamic>{
            'user_id': userId,
            'role': 'teacher',
            'name': displayName,
            'online_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      },
    );
    return ch;
  }

  // ───────────────────── live quizzes ─────────────────────

  /// Pushes a new live quiz to [classId]. Closes any other open quiz
  /// in the same class first so the student UI never sees two.
  static Future<LiveQuizSession> startLiveQuiz({
    required String classId,
    required String prompt,
    required List<String> options,
    required int correctIndex,
  }) async {
    final String teacherId = _requireUserId();
    try {
      // Close any open quiz for this class.
      await _db
          .from('live_quiz_sessions')
          .update(<String, dynamic>{
            'status': 'closed',
            'ended_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('class_id', classId)
          .eq('status', 'open');

      final Map<String, dynamic> row = await _db
          .from('live_quiz_sessions')
          .insert(<String, dynamic>{
            'class_id': classId,
            'teacher_id': teacherId,
            'prompt': prompt.trim(),
            'options': options,
            'correct_index': correctIndex,
            'status': 'open',
          })
          .select()
          .single();
      return LiveQuizSession.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر بدء الاختبار المباشر: ${e.message}');
    }
  }

  static Future<LiveQuizSession> closeLiveQuiz({
    required String sessionId,
  }) async {
    _requireUserId();
    try {
      final Map<String, dynamic> row = await _db
          .from('live_quiz_sessions')
          .update(<String, dynamic>{
            'status': 'closed',
            'ended_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();
      return LiveQuizSession.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر إنهاء الاختبار: ${e.message}');
    }
  }

  static Future<LiveQuizSession?> fetchOpenQuiz({
    required String classId,
  }) async {
    _requireUserId();
    try {
      final Map<String, dynamic>? row = await _db
          .from('live_quiz_sessions')
          .select()
          .eq('class_id', classId)
          .eq('status', 'open')
          .order('started_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : LiveQuizSession.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الاختبار المباشر: ${e.message}');
    }
  }

  static Future<List<LiveQuizResponse>> fetchResponses({
    required String sessionId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('live_quiz_responses')
          .select()
          .eq('session_id', sessionId);
      return rows.map(LiveQuizResponse.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الإجابات: ${e.message}');
    }
  }

  static RealtimeChannel subscribeToQuizResponses({
    required String sessionId,
    required void Function(LiveQuizResponse response) onResponse,
  }) {
    final RealtimeChannel ch =
        _db.channel('quiz:$sessionId:responses');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_quiz_responses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (PostgresChangePayload p) {
            try {
              onResponse(LiveQuizResponse.fromMap(p.newRecord));
            } catch (e, st) {
              debugPrint('quiz response decode failed: $e\n$st');
            }
          },
        )
        .subscribe();
    return ch;
  }

  // Convenience: how many students are enrolled in this class?
  static Future<int> classStudentCount({required String classId}) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('class_members')
          .select('student_id')
          .eq('class_id', classId);
      return rows.length;
    } on PostgrestException {
      return 0;
    }
  }
}
