import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/supabase/supabase_client.dart';
import 'package:studysync_syria/features/class_chat/class_chat_models.dart';

/// Student-side data access + realtime subscriptions for the
/// per-class chat, the "teacher is online" presence indicator, and the
/// teacher-pushed live quizzes.
///
/// Mirrors the static-method style used by [AnnouncementQueries].
class ClassChatQueries {
  ClassChatQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  static String _requireUserId() {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  // ───────────────────── classes / teachers ─────────────────────

  /// Lightweight list of classes the current student is enrolled in,
  /// joined with the teacher's display name for the chat list.
  static Future<List<StudentClassSummary>> fetchMyClasses() async {
    final String userId = _requireUserId();
    try {
      final List<Map<String, dynamic>> memberships = await _db
          .from('class_members')
          .select('class_id')
          .eq('student_id', userId);
      final List<String> classIds = memberships
          .map((Map<String, dynamic> m) => m['class_id'] as String)
          .toList();
      if (classIds.isEmpty) return const <StudentClassSummary>[];

      final List<Map<String, dynamic>> classes = await _db
          .from('classes')
          .select('id, name, teacher_id')
          .inFilter('id', classIds);

      final List<String> teacherIds = classes
          .map((Map<String, dynamic> c) => c['teacher_id'] as String)
          .toSet()
          .toList();
      Map<String, String?> teacherNames = <String, String?>{};
      if (teacherIds.isNotEmpty) {
        try {
          final List<Map<String, dynamic>> profiles = await _db
              .from('profiles')
              .select('user_id, full_name')
              .inFilter('user_id', teacherIds);
          teacherNames = <String, String?>{
            for (final Map<String, dynamic> p in profiles)
              p['user_id'] as String: p['full_name'] as String?,
          };
        } on PostgrestException {
          // RLS may hide; fall through with empty names.
        }
      }

      // Most-recent class_messages.created_at per class for "last
      // activity" sorting. Best-effort — falls back to created_at on
      // the class row if there are no messages yet.
      final Map<String, DateTime?> lastActivityByClass = <String, DateTime?>{};
      try {
        final List<Map<String, dynamic>> recents = await _db
            .from('class_messages')
            .select('class_id, created_at')
            .inFilter('class_id', classIds)
            .order('created_at', ascending: false)
            .limit(200);
        for (final Map<String, dynamic> r in recents) {
          final String cid = r['class_id'] as String;
          if (lastActivityByClass.containsKey(cid)) continue;
          lastActivityByClass[cid] =
              DateTime.tryParse(r['created_at']?.toString() ?? '');
        }
      } on PostgrestException {
        // RLS may hide; ignore.
      }

      final List<StudentClassSummary> out = classes
          .map((Map<String, dynamic> c) {
            final String cid = c['id'] as String;
            final String tid = c['teacher_id'] as String;
            return StudentClassSummary(
              classId: cid,
              className: (c['name'] as String?) ?? 'الصف',
              teacherId: tid,
              teacherName: teacherNames[tid],
              unreadCount: 0,
              lastActivityAt: lastActivityByClass[cid],
              isTeacherOnline: false,
            );
          })
          .toList(growable: true);
      out.sort((StudentClassSummary a, StudentClassSummary b) {
        final DateTime aT = a.lastActivityAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final DateTime bT = b.lastActivityAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        return bT.compareTo(aT);
      });
      return List<StudentClassSummary>.unmodifiable(out);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل صفوفك: ${e.message}');
    }
  }

  // ───────────────────── messages: history + send ─────────────────────

  /// Most recent [limit] messages for [classId], oldest-first so they
  /// can be appended directly to a chat ListView.
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
        // RLS may hide cross-user profiles; render with role fallback.
      }

      final List<ChatMessage> out = rows
          .map((Map<String, dynamic> r) => ChatMessage.fromMap(
                r,
                senderName: nameById[r['sender_id'] as String],
              ))
          .toList(growable: true);
      // Convert newest-first → oldest-first for the chat list.
      out.sort((ChatMessage a, ChatMessage b) =>
          a.createdAt.compareTo(b.createdAt));
      return List<ChatMessage>.unmodifiable(out);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل المحادثة: ${e.message}');
    }
  }

  /// Sends [body] as the current student. The DB trigger validates
  /// membership; we still scope the role explicitly to make the
  /// intention obvious.
  static Future<ChatMessage> sendStudentMessage({
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
            'sender_role': 'student',
            'body': trimmed,
          })
          .select()
          .single();
      // Best-effort hydrate with my own profile name.
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

  /// Subscribes to INSERT events on `class_messages` for [classId].
  /// Returns the channel; caller must `unsubscribe` on dispose.
  static RealtimeChannel subscribeToMessages({
    required String classId,
    required void Function(ChatMessage message) onInsert,
    void Function(String messageId)? onDelete,
  }) {
    final RealtimeChannel ch =
        _db.channel('class:$classId:messages');
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
              // Best-effort hydrate the sender's display name via a
              // microtask query — the caller may also re-render once
              // names land.
              _hydrateSenderName(m).then((ChatMessage hydrated) {
                onInsert(hydrated);
              });
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

  // ─────────────────────────── presence ───────────────────────────

  /// Subscribes the current user to the class presence channel and
  /// tracks themselves as online with [role] + [displayName].
  ///
  /// [onPresenceChanged] is invoked with the set of teacher user-ids
  /// currently online in this class so the student app can light up
  /// the "teacher online" badge.
  static RealtimeChannel joinPresence({
    required String classId,
    required String role,
    required String? displayName,
    required void Function(Set<String> onlineTeacherIds) onPresenceChanged,
  }) {
    final String userId = _requireUserId();
    final RealtimeChannel ch = _db.channel(
      'class:$classId:presence',
      opts: const RealtimeChannelConfig(self: true),
    );

    void emitState() {
      final Map<String, List<Presence>> state = ch.presenceState().fold(
            <String, List<Presence>>{},
            (Map<String, List<Presence>> acc, SinglePresenceState s) {
          acc[s.key] = s.presences;
          return acc;
        },
      );
      final Set<String> teachers = <String>{};
      for (final List<Presence> entries in state.values) {
        for (final Presence p in entries) {
          if ((p.payload['role'] as String?) == 'teacher') {
            final String? uid = p.payload['user_id'] as String?;
            if (uid != null) teachers.add(uid);
          }
        }
      }
      onPresenceChanged(teachers);
    }

    ch
        .onPresenceSync((_) => emitState())
        .onPresenceJoin((_) => emitState())
        .onPresenceLeave((_) => emitState())
        .subscribe(
      (RealtimeSubscribeStatus status, Object? error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await ch.track(<String, dynamic>{
            'user_id': userId,
            'role': role,
            'name': displayName,
            'online_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      },
    );
    return ch;
  }

  // ───────────────────────── live quizzes ─────────────────────────

  /// Returns the currently-open quiz session for [classId], or null.
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
      if (row == null) return null;
      return LiveQuizSession.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الاختبار المباشر: ${e.message}');
    }
  }

  /// Returns the current student's response to [sessionId] if any.
  static Future<LiveQuizResponse?> fetchMyResponse({
    required String sessionId,
  }) async {
    final String userId = _requireUserId();
    try {
      final Map<String, dynamic>? row = await _db
          .from('live_quiz_responses')
          .select()
          .eq('session_id', sessionId)
          .eq('student_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return LiveQuizResponse.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل إجابتك: ${e.message}');
    }
  }

  /// Submits the student's choice for [sessionId]. The DB trigger
  /// stamps `is_correct` based on the session's `correct_index`.
  static Future<LiveQuizResponse> submitResponse({
    required String sessionId,
    required int choiceIndex,
  }) async {
    final String userId = _requireUserId();
    try {
      final Map<String, dynamic> row = await _db
          .from('live_quiz_responses')
          .insert(<String, dynamic>{
            'session_id': sessionId,
            'student_id': userId,
            'choice_index': choiceIndex,
            // is_correct is overwritten by the trigger, but the
            // column is NOT NULL so we must send a placeholder.
            'is_correct': false,
          })
          .select()
          .single();
      return LiveQuizResponse.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تسجيل إجابتك: ${e.message}');
    }
  }

  /// Subscribes to INSERT/UPDATE on `live_quiz_sessions` for [classId].
  static RealtimeChannel subscribeToQuizSessions({
    required String classId,
    required void Function(LiveQuizSession session) onChange,
  }) {
    final RealtimeChannel ch =
        _db.channel('class:$classId:quiz-sessions');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_quiz_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'class_id',
            value: classId,
          ),
          callback: (PostgresChangePayload p) {
            onChange(LiveQuizSession.fromMap(p.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'live_quiz_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'class_id',
            value: classId,
          ),
          callback: (PostgresChangePayload p) {
            onChange(LiveQuizSession.fromMap(p.newRecord));
          },
        )
        .subscribe();
    return ch;
  }
}
