/// Typed view of `public.class_announcements` plus the seen-count
/// aggregate we compute client-side.
class ClassAnnouncement {
  const ClassAnnouncement({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.body,
    required this.createdAt,
    required this.seenCount,
    required this.totalStudents,
  });

  factory ClassAnnouncement.fromMap(
    Map<String, dynamic> map, {
    required int seenCount,
    required int totalStudents,
  }) {
    return ClassAnnouncement(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      teacherId: map['teacher_id'] as String,
      body: (map['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      seenCount: seenCount,
      totalStudents: totalStudents,
    );
  }

  final String id;
  final String classId;
  final String teacherId;
  final String body;
  final DateTime createdAt;
  final int seenCount;
  final int totalStudents;
}

/// One row of `public.announcement_reads`, joined with `profiles` so the
/// teacher can see who actually read the announcement.
class AnnouncementReader {
  const AnnouncementReader({
    required this.studentId,
    required this.fullName,
    required this.readAt,
  });

  final String studentId;
  final String? fullName;
  final DateTime readAt;

  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty)
          ? 'طالب'
          : fullName!.trim();
}
