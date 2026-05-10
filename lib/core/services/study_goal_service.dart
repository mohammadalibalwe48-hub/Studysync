import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks daily study minutes and the user's chosen daily goal.
///
/// Each completed Pomodoro session (or any other "you studied X
/// minutes" event) calls [logMinutes]; the home-screen [DailyGoalRing]
/// then renders today's progress against [goalMinutes].
///
/// Persistence is intentionally simple — a single key per day stored in
/// [SharedPreferences] — so the data is durable across launches but
/// requires no schema or remote sync.
class StudyGoalService extends ChangeNotifier {
  StudyGoalService._();

  static final StudyGoalService instance = StudyGoalService._();
  static const String _goalKey = 'studysync.daily_goal_minutes';
  static const String _minutesPrefix = 'studysync.daily_minutes.';
  static const int defaultGoalMinutes = 60;

  int _goalMinutes = defaultGoalMinutes;
  int _todayMinutes = 0;
  bool _loaded = false;

  int get goalMinutes => _goalMinutes;
  int get todayMinutes => _todayMinutes;
  bool get isLoaded => _loaded;

  double get todayProgress {
    if (_goalMinutes <= 0) return 0;
    return (_todayMinutes / _goalMinutes).clamp(0.0, 1.0);
  }

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _goalMinutes = prefs.getInt(_goalKey) ?? defaultGoalMinutes;
      _todayMinutes = prefs.getInt(_keyForToday()) ?? 0;
    } catch (_) {
      _goalMinutes = defaultGoalMinutes;
      _todayMinutes = 0;
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setGoal(int minutes) async {
    final int clamped = minutes.clamp(15, 480);
    if (clamped == _goalMinutes) return;
    _goalMinutes = clamped;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_goalKey, clamped);
    } catch (_) {}
  }

  Future<void> logMinutes(int minutes) async {
    if (minutes <= 0) return;
    _todayMinutes += minutes;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyForToday(), _todayMinutes);
    } catch (_) {}
  }

  /// Reads the per-day minutes log for the past [days] days, oldest
  /// first. Used by the heatmap on the progress screen.
  Future<List<int>> recentDailyMinutes({int days = 28}) async {
    final List<int> result = List<int>.filled(days, 0);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();
      for (int i = 0; i < days; i++) {
        final DateTime d = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: days - 1 - i));
        result[i] = prefs.getInt(_keyForDate(d)) ?? 0;
      }
    } catch (_) {
      // best-effort, return zeros.
    }
    return result;
  }

  String _keyForToday() {
    final DateTime now = DateTime.now();
    return _keyForDate(now);
  }

  String _keyForDate(DateTime d) {
    final String mm = d.month.toString().padLeft(2, '0');
    final String dd = d.day.toString().padLeft(2, '0');
    return '$_minutesPrefix${d.year}-$mm-$dd';
  }
}
