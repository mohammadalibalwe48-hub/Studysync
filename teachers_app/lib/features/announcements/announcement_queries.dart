import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/supabase/supabase_client.dart';
import 'package:studysync_syria_teachers/features/announcements/announcement_models.dart';

/// Teacher-side data access for `class_announcements` and
/// `announcement_reads`. Mirrors the [TeacherQueries] style — static
/// methods, `_requireUserId`, all errors surfaced as Arabic
/// `Exception('تعذّر …')`.
class AnnouncementQueries {
  AnnouncementQueries._();

  static SupabaseClient get _db => SupabaseService.client;

  static String _requireUserId() {
    final User? user = SupabaseService.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  /// All announcements posted to a class, newest first, augmented with
  /// the seen count (read_count / total enrolled).
  static Future<List<ClassAnnouncement>> fetchClassAnnouncements({
    required String classId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> rows = await _db
          .from('class_announcements')
          .select()
          .eq('class_id', classId)
          .order('created_at', ascending: false);

      if (rows.isEmpty) return const <ClassAnnouncement>[];

      final List<String> ids = rows
          .map((Map<String, dynamic> r) => r['id'] as String)
          .toList();

      final List<Map<String, dynamic>> reads = await _db
          .from('announcement_reads')
          .select('announcement_id')
          .inFilter('announcement_id', ids);

      final Map<String, int> seenCounts = <String, int>{};
      for (final Map<String, dynamic> r in reads) {
        final String aid = r['announcement_id'] as String;
        seenCounts[aid] = (seenCounts[aid] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> members = await _db
          .from('class_members')
          .select('student_id')
          .eq('class_id', classId);
      final int totalStudents = members.length;

      return rows
          .map((Map<String, dynamic> r) => ClassAnnouncement.fromMap(
                r,
                seenCount: seenCounts[r['id'] as String] ?? 0,
                totalStudents: totalStudents,
              ))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل الإعلانات: ${e.message}');
    }
  }

  static Future<ClassAnnouncement> createAnnouncement({
    required String classId,
    required String body,
  }) async {
    final String teacherId = _requireUserId();
    if (body.trim().isEmpty) {
      throw ArgumentError('body is required');
    }
    try {
      final Map<String, dynamic> row = await _db
          .from('class_announcements')
          .insert(<String, dynamic>{
            'class_id': classId,
            'teacher_id': teacherId,
            'body': body.trim(),
          })
          .select()
          .single();
      final List<Map<String, dynamic>> members = await _db
          .from('class_members')
          .select('student_id')
          .eq('class_id', classId);
      return ClassAnnouncement.fromMap(
        row,
        seenCount: 0,
        totalStudents: members.length,
      );
    } on PostgrestException catch (e) {
      throw Exception('تعذّر نشر الإعلان: ${e.message}');
    }
  }

  static Future<void> deleteAnnouncement({
    required String announcementId,
  }) async {
    _requireUserId();
    try {
      await _db
          .from('class_announcements')
          .delete()
          .eq('id', announcementId);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر حذف الإعلان: ${e.message}');
    }
  }

  /// Students who have read the given announcement, joined with
  /// `profiles.full_name`. Newest reads first.
  static Future<List<AnnouncementReader>> fetchAnnouncementReaders({
    required String announcementId,
  }) async {
    _requireUserId();
    try {
      final List<Map<String, dynamic>> reads = await _db
          .from('announcement_reads')
          .select('student_id, read_at')
          .eq('announcement_id', announcementId)
          .order('read_at', ascending: false);

      if (reads.isEmpty) return const <AnnouncementReader>[];

      final List<String> studentIds = reads
          .map((Map<String, dynamic> r) => r['student_id'] as String)
          .toList();

      Map<String, String?> nameByStudent = <String, String?>{};
      try {
        final List<Map<String, dynamic>> profiles = await _db
            .from('profiles')
            .select('user_id, full_name')
            .inFilter('user_id', studentIds);
        nameByStudent = <String, String?>{
          for (final Map<String, dynamic> p in profiles)
            p['user_id'] as String: p['full_name'] as String?,
        };
      } on PostgrestException {
        // RLS may block the join — fall back to empty names.
      }

      return reads
          .map((Map<String, dynamic> r) => AnnouncementReader(
                studentId: r['student_id'] as String,
                fullName: nameByStudent[r['student_id'] as String],
                readAt: DateTime.tryParse(
                        r['read_at']?.toString() ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
              ))
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw Exception('تعذّر تحميل قائمة القرّاء: ${e.message}');
    }
  }
}
