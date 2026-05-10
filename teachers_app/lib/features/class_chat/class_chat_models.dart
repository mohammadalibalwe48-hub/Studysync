// Typed views of the per-class chat / live-quiz tables introduced in
// migration `0007_class_chat_presence.sql`.

/// One row of `public.class_messages`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.classId,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(
    Map<String, dynamic> map, {
    required String? senderName,
  }) {
    return ChatMessage(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      senderId: map['sender_id'] as String,
      senderRole: ((map['sender_role'] as String?) ?? 'student') == 'teacher'
          ? ChatSenderRole.teacher
          : ChatSenderRole.student,
      senderName: senderName,
      body: (map['body'] as String?) ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String classId;
  final String senderId;
  final ChatSenderRole senderRole;
  final String? senderName;
  final String body;
  final DateTime createdAt;

  bool get isTeacher => senderRole == ChatSenderRole.teacher;

  String get displayName {
    if (senderName != null && senderName!.trim().isNotEmpty) {
      return senderName!.trim();
    }
    return isTeacher ? 'المعلّم' : 'طالب';
  }

  ChatMessage copyWith({String? senderName}) {
    return ChatMessage(
      id: id,
      classId: classId,
      senderId: senderId,
      senderRole: senderRole,
      senderName: senderName ?? this.senderName,
      body: body,
      createdAt: createdAt,
    );
  }
}

enum ChatSenderRole { student, teacher }

/// One row of `public.live_quiz_sessions`.
class LiveQuizSession {
  const LiveQuizSession({
    required this.id,
    required this.classId,
    required this.teacherId,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.status,
    required this.startedAt,
    required this.endedAt,
  });

  factory LiveQuizSession.fromMap(Map<String, dynamic> map) {
    final dynamic raw = map['options'];
    final List<String> opts = raw is List
        ? raw.map((dynamic e) => e?.toString() ?? '').toList(growable: false)
        : const <String>[];
    return LiveQuizSession(
      id: map['id'] as String,
      classId: map['class_id'] as String,
      teacherId: map['teacher_id'] as String,
      prompt: (map['prompt'] as String?) ?? '',
      options: opts,
      correctIndex: (map['correct_index'] as int?) ?? 0,
      status: ((map['status'] as String?) ?? 'open') == 'open'
          ? LiveQuizStatus.open
          : LiveQuizStatus.closed,
      startedAt: DateTime.tryParse(map['started_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.tryParse(map['ended_at']!.toString()),
    );
  }

  final String id;
  final String classId;
  final String teacherId;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final LiveQuizStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isOpen => status == LiveQuizStatus.open;
}

enum LiveQuizStatus { open, closed }

/// One row of `public.live_quiz_responses`.
class LiveQuizResponse {
  const LiveQuizResponse({
    required this.sessionId,
    required this.studentId,
    required this.choiceIndex,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory LiveQuizResponse.fromMap(Map<String, dynamic> map) {
    return LiveQuizResponse(
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      choiceIndex: (map['choice_index'] as int?) ?? 0,
      isCorrect: (map['is_correct'] as bool?) ?? false,
      answeredAt: DateTime.tryParse(map['answered_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String sessionId;
  final String studentId;
  final int choiceIndex;
  final bool isCorrect;
  final DateTime answeredAt;
}

/// Aggregate tally of responses per option for a given session.
class LiveQuizTally {
  const LiveQuizTally({
    required this.sessionId,
    required this.totalResponses,
    required this.totalCorrect,
    required this.countByChoice,
  });

  factory LiveQuizTally.empty(String sessionId, int optionCount) {
    return LiveQuizTally(
      sessionId: sessionId,
      totalResponses: 0,
      totalCorrect: 0,
      countByChoice: List<int>.filled(optionCount, 0, growable: false),
    );
  }

  factory LiveQuizTally.from(
    String sessionId,
    int optionCount,
    Iterable<LiveQuizResponse> responses,
  ) {
    final List<int> counts =
        List<int>.filled(optionCount, 0, growable: false);
    int correct = 0;
    int total = 0;
    for (final LiveQuizResponse r in responses) {
      if (r.choiceIndex < counts.length) counts[r.choiceIndex] += 1;
      if (r.isCorrect) correct += 1;
      total += 1;
    }
    return LiveQuizTally(
      sessionId: sessionId,
      totalResponses: total,
      totalCorrect: correct,
      countByChoice: counts,
    );
  }

  final String sessionId;
  final int totalResponses;
  final int totalCorrect;
  final List<int> countByChoice;

  double percentFor(int optionIndex) {
    if (totalResponses == 0) return 0;
    if (optionIndex < 0 || optionIndex >= countByChoice.length) return 0;
    return countByChoice[optionIndex] / totalResponses;
  }
}
