/// Student-side view of `public.class_announcements`, enriched with the
/// class name and (best-effort) the teacher's display name, plus an
/// `isRead` flag computed from `announcement_reads`.
class StudentAnnouncement {
  const StudentAnnouncement({
    required this.id,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String classId;
  final String? className;
  final String teacherId;
  final String? teacherName;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  StudentAnnouncement copyWith({bool? isRead}) {
    return StudentAnnouncement(
      id: id,
      classId: classId,
      className: className,
      teacherId: teacherId,
      teacherName: teacherName,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
