import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/supabase/supabase_client.dart';

/// Bookmarks for practice questions.
///
/// Source of truth is the `bookmarked_questions` table in Supabase, so
/// the user's saved questions follow them across devices. A
/// [SharedPreferences] cache keeps the UI responsive offline (and warm
/// on first frame after a cold start before the network round-trip
/// completes).
///
/// Read path:
///   1. Load the local cache synchronously (fast paint).
///   2. If signed in, fetch from Supabase and overwrite the cache.
///
/// Write path:
///   1. Update in-memory state (UI updates immediately).
///   2. Best-effort write to Supabase.
///   3. Best-effort write to local cache.
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

  /// Hydrates from the local cache first, then refreshes from Supabase
  /// if the user is signed in.
  Future<void> load() async {
    await _loadFromCache();
    _loaded = true;
    notifyListeners();
    await _refreshFromRemote();
  }

  Future<void> _loadFromCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? raw = prefs.getStringList(_prefsKey);
      _ids
        ..clear()
        ..addAll(raw ?? const <String>[]);
    } catch (_) {
      _ids.clear();
    }
  }

  /// Pulls the canonical set of bookmarks from Supabase. Safe to call
  /// repeatedly (e.g. on auth-state changes); silently no-ops when
  /// signed out or the network is unavailable.
  Future<void> _refreshFromRemote() async {
    if (SupabaseService.auth.currentUser == null) return;
    try {
      final List<String> remote =
          await StudySyncQueries.fetchBookmarkedQuestions();
      _ids
        ..clear()
        ..addAll(remote);
      notifyListeners();
      await _persistCache();
    } catch (_) {
      // Offline / RLS / etc.: keep whatever we already loaded from the cache.
    }
  }

  /// Public hook so the auth flow can refresh bookmarks immediately
  /// after sign-in.
  Future<void> refresh() => _refreshFromRemote();

  Future<bool> toggle(String questionId) async {
    final bool willAdd = !_ids.contains(questionId);
    if (willAdd) {
      _ids.add(questionId);
    } else {
      _ids.remove(questionId);
    }
    notifyListeners();
    // Best-effort remote write. UI already reflects the new state; if
    // the network call fails the next refresh will reconcile.
    if (SupabaseService.auth.currentUser != null) {
      try {
        if (willAdd) {
          await StudySyncQueries.addBookmark(questionId);
        } else {
          await StudySyncQueries.removeBookmark(questionId);
        }
      } catch (_) {}
    }
    await _persistCache();
    return willAdd;
  }

  Future<void> clear() async {
    _ids.clear();
    notifyListeners();
    if (SupabaseService.auth.currentUser != null) {
      try {
        await StudySyncQueries.clearBookmarks();
      } catch (_) {}
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  Future<void> _persistCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _ids.toList());
    } catch (_) {
      // Best-effort: in-memory state wins for this session.
    }
  }
}
