import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';

/// Static curriculum data for the app.
///
/// All sample subjects, topics, lessons, and questions have been cleared.
/// Real content is expected to come from Supabase (or future seed files);
/// the screens render empty-state UI when these lists are empty.
class Curriculum {
  Curriculum._();

  /// All subjects offered to the student.
  static const List<Subject> subjects = <Subject>[];

  /// All topics across every subject.
  static const List<Topic> topics = <Topic>[];

  static Subject? subjectById(String id) {
    for (final Subject s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  static List<Topic> topicsForSubject(String subjectId) {
    return topics.where((Topic t) => t.subjectId == subjectId).toList();
  }

  static Topic? topicById(String id) {
    for (final Topic t in topics) {
      if (t.id == id) return t;
    }
    return null;
  }
}
