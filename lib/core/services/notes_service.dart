import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/supabase/supabase_client.dart';

/// A single markdown-backed study note attached to a topic.
@immutable
class StudyNote {
  const StudyNote({
    required this.id,
    required this.topicId,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String topicId;
  final String title;
  final String body;
  final DateTime updatedAt;

  StudyNote copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
  }) {
    return StudyNote(
      id: id,
      topicId: topicId,
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'topicId': topicId,
        'title': title,
        'body': body,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static StudyNote fromJson(Map<String, Object?> j) => StudyNote(
        id: j['id']! as String,
        topicId: j['topicId']! as String,
        title: j['title']! as String,
        body: j['body']! as String,
        updatedAt:
            DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
                DateTime.now(),
      );

  static StudyNote fromSupabaseRow(Map<String, dynamic> row) => StudyNote(
        id: row['id'] as String,
        topicId: row['topic_id'] as String,
        title: (row['title'] as String?) ?? '',
        body: (row['body'] as String?) ?? '',
        updatedAt:
            DateTime.tryParse(row['updated_at']?.toString() ?? '') ??
                DateTime.now(),
      );
}

/// Notes service backed by Supabase, with a local cache for offline.
///
/// Markdown is stored as raw text so it survives a re-render cycle.
/// Highlights are encoded inside the markdown using the convention
/// `==text==`, which the editor renders as a yellow highlight pill.
///
/// The cache persists notes between launches and lets us paint
/// instantly while the remote read is in flight; on every successful
/// remote read the cache is overwritten with the canonical set so
/// stale entries from a previous device can't linger.
class NotesService extends ChangeNotifier {
  NotesService._();
  static final NotesService instance = NotesService._();

  static const String _key = 'studysync.notes.v1';
  final List<StudyNote> _notes = <StudyNote>[];
  bool _loaded = false;

  List<StudyNote> get all =>
      List<StudyNote>.unmodifiable(_notes
        ..sort((StudyNote a, StudyNote b) =>
            b.updatedAt.compareTo(a.updatedAt)));

  List<StudyNote> forTopic(String topicId) =>
      _notes.where((StudyNote n) => n.topicId == topicId).toList()
        ..sort((StudyNote a, StudyNote b) =>
            b.updatedAt.compareTo(a.updatedAt));

  int get count => _notes.length;

  Future<void> load() async {
    if (!_loaded) {
      await _loadFromCache();
      _loaded = true;
      notifyListeners();
    }
    await _refreshFromRemote();
  }

  Future<void> _loadFromCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(raw) as List<dynamic>;
        _notes
          ..clear()
          ..addAll(list
              .whereType<Map<String, dynamic>>()
              .map(StudyNote.fromJson));
      } catch (_) {
        // Corrupt cache — start fresh.
      }
    }
  }

  Future<void> _refreshFromRemote() async {
    if (SupabaseService.auth.currentUser == null) return;
    try {
      final List<Map<String, dynamic>> rows =
          await StudySyncQueries.fetchStudyNotes();
      _notes
        ..clear()
        ..addAll(rows.map(StudyNote.fromSupabaseRow));
      notifyListeners();
      await _persist();
    } catch (_) {
      // Offline / RLS / etc.: keep cached state.
    }
  }

  /// Public hook so the auth flow can pull notes immediately after
  /// sign-in.
  Future<void> refresh() => _refreshFromRemote();

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(_notes.map((StudyNote n) => n.toJson()).toList()),
    );
  }

  Future<StudyNote> create({
    required String topicId,
    required String title,
    required String body,
  }) async {
    final String trimmedTitle = title.trim().isEmpty ? 'ملاحظة' : title.trim();
    StudyNote n = StudyNote(
      // Used as the optimistic id until the server returns the canonical
      // UUID. We replace the in-memory entry with the server row below.
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      topicId: topicId,
      title: trimmedTitle,
      body: body,
      updatedAt: DateTime.now(),
    );
    _notes.add(n);
    notifyListeners();

    if (SupabaseService.auth.currentUser != null) {
      try {
        final Map<String, dynamic> row = await StudySyncQueries.upsertStudyNote(
          topicId: topicId,
          title: trimmedTitle,
          body: body,
        );
        final StudyNote canonical = StudyNote.fromSupabaseRow(row);
        final int idx = _notes.indexWhere((StudyNote x) => x.id == n.id);
        if (idx != -1) {
          _notes[idx] = canonical;
        } else {
          _notes.add(canonical);
        }
        n = canonical;
        notifyListeners();
      } catch (_) {
        // Keep the optimistic entry locally; the next refresh will
        // reconcile.
      }
    }

    await _persist();
    return n;
  }

  Future<void> update(
    String id, {
    String? title,
    String? body,
  }) async {
    final int i = _notes.indexWhere((StudyNote n) => n.id == id);
    if (i == -1) return;
    _notes[i] = _notes[i].copyWith(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    if (SupabaseService.auth.currentUser != null) {
      try {
        final StudyNote n = _notes[i];
        // Only push to Supabase when the id is a server-issued UUID.
        // Optimistic ids (created while signed out) are migrated by the
        // next refresh.
        final bool looksLikeServerId =
            n.id.contains('-') && n.id.length >= 32;
        if (looksLikeServerId) {
          final Map<String, dynamic> row =
              await StudySyncQueries.upsertStudyNote(
            id: n.id,
            topicId: n.topicId,
            title: n.title,
            body: n.body,
          );
          _notes[i] = StudyNote.fromSupabaseRow(row);
          notifyListeners();
        }
      } catch (_) {}
    }

    await _persist();
  }

  Future<void> remove(String id) async {
    _notes.removeWhere((StudyNote n) => n.id == id);
    notifyListeners();
    if (SupabaseService.auth.currentUser != null) {
      try {
        // Same UUID heuristic as above — optimistic ids never made it
        // to the server, so there's nothing to delete remotely.
        if (id.contains('-') && id.length >= 32) {
          await StudySyncQueries.deleteStudyNote(id);
        }
      } catch (_) {}
    }
    await _persist();
  }
}
