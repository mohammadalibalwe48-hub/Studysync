import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the user's study behaviour locally so we can power smart
/// notifications without a backend.
///
/// Two streams are recorded:
///
///  • A rolling buffer of pomodoro **start times** (last 30). The most
///    common hour-of-day across that buffer becomes the "you usually
///    study at HH:00" reminder anchor.
///  • The most-recent study timestamp **per subject** (so we can warn
///    when a streak is about to break — we treat anything older than
///    20 hours on an active subject as at-risk).
///
/// Everything persists in [SharedPreferences]. No Supabase, no PII.
class StudyPatternService extends ChangeNotifier {
  StudyPatternService._();

  static final StudyPatternService instance = StudyPatternService._();

  static const String _prefsKeyStarts = 'studysync.study_starts_v1';
  static const String _prefsKeyLastBySubject =
      'studysync.last_study_by_subject_v1';

  /// Cap on the rolling window of start timestamps. Big enough for the
  /// median to be stable, small enough that a habit shift (e.g. summer
  /// → school year) takes only ~2 weeks to migrate the prediction.
  static const int _maxStarts = 30;

  /// A subject is considered "at risk of breaking the streak" once
  /// this many hours have passed since its last study session.
  static const Duration streakWarningThreshold = Duration(hours: 20);

  final List<DateTime> _starts = <DateTime>[];
  final Map<String, DateTime> _lastBySubject = <String, DateTime>{};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Snapshot copy of the rolling pomodoro start buffer.
  List<DateTime> get pomodoroStarts =>
      List<DateTime>.unmodifiable(_starts);

  /// Snapshot copy of the per-subject last study map.
  Map<String, DateTime> get lastStudyBySubject =>
      Map<String, DateTime>.unmodifiable(_lastBySubject);

  /// Loads persisted history. Safe to call multiple times.
  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? rawStarts = prefs.getStringList(_prefsKeyStarts);
      _starts
        ..clear()
        ..addAll(<DateTime>[
          for (final String s in rawStarts ?? const <String>[])
            if (DateTime.tryParse(s) != null) DateTime.parse(s),
        ]);
      final String? rawMap = prefs.getString(_prefsKeyLastBySubject);
      _lastBySubject.clear();
      if (rawMap != null && rawMap.isNotEmpty) {
        final Object? decoded = jsonDecode(rawMap);
        if (decoded is Map) {
          for (final MapEntry<dynamic, dynamic> e in decoded.entries) {
            final String? subjectId = e.key is String ? e.key as String : null;
            final String? iso = e.value is String ? e.value as String : null;
            final DateTime? parsed =
                iso == null ? null : DateTime.tryParse(iso);
            if (subjectId != null && parsed != null) {
              _lastBySubject[subjectId] = parsed;
            }
          }
        }
      }
    } catch (_) {
      _starts.clear();
      _lastBySubject.clear();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Records that the user just hit "Start" on a pomodoro / focus
  /// timer. Optionally tied to a [subjectId] so we can compute the
  /// per-subject streak warning.
  Future<void> recordStudyStart({String? subjectId, DateTime? at}) async {
    final DateTime when = at ?? DateTime.now();
    _starts.add(when);
    while (_starts.length > _maxStarts) {
      _starts.removeAt(0);
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      _lastBySubject[subjectId] = when;
    }
    notifyListeners();
    await _persist();
  }

  /// Records a generic study session for a subject (e.g. flashcards,
  /// quiz). Doesn't touch the pomodoro buffer; only updates the
  /// per-subject "last touched" time.
  Future<void> recordSubjectActivity(String subjectId, {DateTime? at}) async {
    if (subjectId.isEmpty) return;
    _lastBySubject[subjectId] = at ?? DateTime.now();
    notifyListeners();
    await _persist();
  }

  /// The hour-of-day (0–23) that best predicts the user's study time.
  ///
  /// Returns `null` if we don't yet have enough data to make a
  /// prediction (we want at least 5 starts before nagging the user).
  int? predictUsualHour() {
    if (_starts.length < 5) return null;
    final List<int> counts = List<int>.filled(24, 0);
    for (final DateTime t in _starts) {
      counts[t.hour] += 1;
    }
    int bestHour = 0;
    int bestCount = -1;
    for (int h = 0; h < 24; h += 1) {
      if (counts[h] > bestCount) {
        bestCount = counts[h];
        bestHour = h;
      }
    }
    return bestCount <= 1 ? null : bestHour;
  }

  /// Subjects whose last activity was longer ago than
  /// [streakWarningThreshold] but shorter than 48 h. We don't warn
  /// once a streak has already broken — there's nothing to save.
  List<StreakRisk> stalenessWarnings({DateTime? now}) {
    final DateTime ref = now ?? DateTime.now();
    final List<StreakRisk> out = <StreakRisk>[];
    for (final MapEntry<String, DateTime> e in _lastBySubject.entries) {
      final Duration delta = ref.difference(e.value);
      if (delta >= streakWarningThreshold && delta < const Duration(hours: 48)) {
        out.add(StreakRisk(subjectId: e.key, hoursSinceLast: delta.inHours));
      }
    }
    out.sort((StreakRisk a, StreakRisk b) =>
        b.hoursSinceLast.compareTo(a.hoursSinceLast));
    return out;
  }

  /// Wipes everything (used by sign-out or "clear my data").
  Future<void> reset() async {
    _starts.clear();
    _lastBySubject.clear();
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyStarts);
      await prefs.remove(_prefsKeyLastBySubject);
    } catch (_) {/* best-effort */}
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKeyStarts,
        <String>[for (final DateTime t in _starts) t.toIso8601String()],
      );
      await prefs.setString(
        _prefsKeyLastBySubject,
        jsonEncode(<String, String>{
          for (final MapEntry<String, DateTime> e in _lastBySubject.entries)
            e.key: e.value.toIso8601String(),
        }),
      );
    } catch (_) {/* best-effort */}
  }
}

/// One subject that's at risk of dropping out of the user's active
/// streak. Surfaced via a smart notification and (optionally) the
/// home-screen "your <subject> streak is about to break" banner.
class StreakRisk {
  const StreakRisk({
    required this.subjectId,
    required this.hoursSinceLast,
  });

  final String subjectId;
  final int hoursSinceLast;
}
