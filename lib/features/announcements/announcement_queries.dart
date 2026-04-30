import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/supabase/supabase_client.dart';
import 'package:studysync_syria/features/announcements/announcement_models.dart';

/// Student-side data access for class announcements. Only sees
/// announcements for classes the current user is enrolled in (RLS does
/// the filtering server-side; we still scope the query for clarity).
class AnnouncementQueries {
  AnnouncementQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  static String _requireUserId() {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  /// Flat inbox of all announcements across the student's classes,
  /// sorted by `created_at desc`. Each entry carries an `isRead` flag
  /// derived from `announcement_reads`.
  static Future<List<StudentAnnouncement>> fetchInbox() async {
    final String userId = _requireUserId();
    try {
      final List<Map<String, dynamic>> memberships = await _db
          .from('class_members')
          .select('class_id')
          .eq('student_id', userId);

      final List<String> classIds = memberships
          .map((Map<String, dynamic> m) => m['class_id'] as String)
          .toList();
      if (classIds.isEmpty) return const <StudentAnnouncement>[];

      final List<Map<String, dynamic>> rows = await _db
          .from('class_announcements')
          .select()
          .inFilter('class_id', classIds)
          .order('created_at', ascending: false);
      if (rows.isEmpty) return const <StudentAnnouncement>[];

      final List<String> ids = rows
          .map((Map<String, dynamic> r) => r['id'] as String)
          .toList();

      final List<Map<String, dynamic>> reads = await _db
          .from('announcement_reads')
          .select('announcement_id')
          .eq('student_id', userId)
          .inFilter('announcement_id', ids);
      final Set<String> readIds = <String>{
        for (final Map<String, dynamic> r in reads)
          r['announcement_id'] as String,
      };

      Map<String, String?> classNames = <String, String?>{};
      try {
        final List<Map<String, dynamic>> classes = await _db
            .from('classes')
            .select('id, name')
            .inFilter('id', classIds);
        classNames = <String, String?>{
          for (final Map<String, dynamic> c in classes)
            c['id'] as String: c['name'] as String?,
        };
      } on PostgrestException {
        // RLS may block; fall back to nulls.
      }

      final List<String> teacherIds = rows
          .map((Map<String, dynamic> r) => r['teacher_id'] as String)
          .toSet()
          .toList();
      Map<String, String?> teacherNames = <String, String?>{};
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
        // Same: fall back to nulls.
      }

      return rows.map((Map<String, dynamic> r) {
        final String id = r['id'] as String;
        return StudentAnnouncement(
          id: id,
          classId: r['class_id'] as String,
          className: classNames[r['class_id'] as String],
          teacherId: r['teacher_id'] as String,
          teacherName: teacherNames[r['teacher_id'] as String],
          body: (r['body'] as String?) ?? '',
          createdAt:
              DateTime.tryParse(r['created_at']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          isRead: readIds.contains(id),
        );
      }).toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الإعلانات: ${e.message}');
    }
  }

  /// Idempotent: marks the announcement as read for the current user.
  static Future<void> markAsRead({required String announcementId}) async {
    final String userId = _requireUserId();
    try {
      await _db.from('announcement_reads').upsert(
        <String, dynamic>{
          'announcement_id': announcementId,
          'student_id': userId,
        },
        onConflict: 'announcement_id,student_id',
        ignoreDuplicates: true,
      );
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحديث حالة الإعلان: ${e.message}');
    }
  }

  /// Lightweight unread-count query for the home tile badge. Returns 0
  /// on any error so the tile stays usable.
  static Future<int> fetchUnreadCount() async {
    try {
      final List<StudentAnnouncement> all = await fetchInbox();
      return all.where((StudentAnnouncement a) => !a.isRead).length;
    } catch (_) {
      return 0;
    }
  }
}
