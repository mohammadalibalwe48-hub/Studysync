import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

/// Local-only notes service backed by shared_preferences.
///
/// Markdown is stored as raw text so it survives a re-render cycle.
/// Highlights are encoded inside the markdown using the convention
/// `==text==`, which the editor renders as a yellow highlight pill.
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
    if (_loaded) return;
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
    _loaded = true;
    notifyListeners();
  }

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
    final StudyNote n = StudyNote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      topicId: topicId,
      title: title.trim().isEmpty ? 'ملاحظة' : title.trim(),
      body: body,
      updatedAt: DateTime.now(),
    );
    _notes.add(n);
    notifyListeners();
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
    await _persist();
  }

  Future<void> remove(String id) async {
    _notes.removeWhere((StudyNote n) => n.id == id);
    notifyListeners();
    await _persist();
  }
}
