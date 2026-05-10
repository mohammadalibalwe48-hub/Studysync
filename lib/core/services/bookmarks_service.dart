import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only bookmarks for practice questions.
///
/// Stored as a flat set of question IDs in [SharedPreferences]. The
/// data lives only on the student's device — no sync to Supabase yet —
/// which is a deliberate "save what's important" UX choice copied from
/// Anki, Quizlet's "starred" set, and Things 3's Today list.
class BookmarksService extends ChangeNotifier {
  BookmarksService._();

  static final BookmarksService instance = BookmarksService._();
  static const String _prefsKey = 'studysync.bookmarked_question_ids';

  final Set<String> _ids = <String>{};
  bool _loaded = false;

  /// Whether [load] has run at least once. UI can use this to decide
  /// between "loading" and "empty" states.
  bool get isLoaded => _loaded;

  /// All currently-bookmarked question IDs (read-only snapshot).
  Set<String> get all => Set<String>.unmodifiable(_ids);

  int get count => _ids.length;

  bool contains(String questionId) => _ids.contains(questionId);

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? raw = prefs.getStringList(_prefsKey);
      _ids
        ..clear()
        ..addAll(raw ?? const <String>[]);
    } catch (_) {
      _ids.clear();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<bool> toggle(String questionId) async {
    final bool willAdd = !_ids.contains(questionId);
    if (willAdd) {
      _ids.add(questionId);
    } else {
      _ids.remove(questionId);
    }
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _ids.toList());
    } catch (_) {
      // Best-effort: in-memory state wins for this session.
    }
    return willAdd;
  }

  Future<void> clear() async {
    _ids.clear();
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
