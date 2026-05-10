import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/services/study_pattern_service.dart';
import 'package:studysync_syria/features/assignments/assignment_models.dart';
import 'package:studysync_syria/features/assignments/assignment_queries.dart';

/// One of the smart-notification "channels" the user can opt out of
/// independently. These are different from Android system notification
/// channels — they're product-level settings.
enum SmartNotificationChannel {
  /// "You usually study at 8 PM" — anchored on the rolling pomodoro
  /// median; reschedules itself once a day.
  usualStudyTime,

  /// "Your chemistry streak is about to break" — fires at most once
  /// per subject per ~6h once a subject crosses the staleness
  /// threshold.
  streakWarner,

  /// Daily 8 AM digest summarising assignments due in the next ~36 h.
  /// Batched, never per-row.
  assignmentsDueDigest,
}

extension SmartNotificationChannelLabel on SmartNotificationChannel {
  String get arabicLabel {
    switch (this) {
      case SmartNotificationChannel.usualStudyTime:
        return 'تذكير وقت الدراسة المعتاد';
      case SmartNotificationChannel.streakWarner:
        return 'تنبيه قبل انكسار السلسلة';
      case SmartNotificationChannel.assignmentsDueDigest:
        return 'ملخّص الواجبات لليوم التالي';
    }
  }

  String get arabicDescription {
    switch (this) {
      case SmartNotificationChannel.usualStudyTime:
        return 'يلاحظ الوقت الذي تبدأ فيه عادةً ويذكّرك مرة واحدة قبل دقائق منه.';
      case SmartNotificationChannel.streakWarner:
        return 'ينبهك إذا مرّ أكثر من ٢٠ ساعة دون دراسة المادة الفعّالة.';
      case SmartNotificationChannel.assignmentsDueDigest:
        return 'إشعار مجمّع كل يوم بعدد الواجبات المستحقة قريبًا.';
    }
  }

  String get prefsKey => 'studysync.notif_channel.${name}_enabled';
}

/// Local-only behavioural notifications.
///
/// Wraps `flutter_local_notifications` with:
///
///  • One Android notification channel ("studysync_smart_v1") shared
///    across all three "smart" channels — the channel-level
///    importance/sound never changes, so the user only has to manage
///    a single Android system channel.
///  • Per-product channel toggles persisted in [SharedPreferences],
///    surfaced in the in-app notifications-settings screen.
///  • Idempotent reschedule pass that the app calls on startup, after
///    a pomodoro completes, and whenever the user changes settings.
class NotificationsService extends ChangeNotifier {
  NotificationsService._();

  static final NotificationsService instance = NotificationsService._();

  static const String _androidChannelId = 'studysync_smart_v1';
  static const String _androidChannelName = 'تذكيرات الدراسة الذكية';
  static const String _androidChannelDescription =
      'تذكيرات يولّدها التطبيق محليًا بناءً على عاداتك في الدراسة.';

  // Stable notification IDs so reschedules overwrite (not pile up).
  static const int _idUsualStudy = 1001;
  static const int _idAssignmentsDigest = 1002;
  // Streak warnings hash a stable (per-subject) ID into 1100..1199.
  static const int _streakIdBase = 1100;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _supported = false;

  /// Once true, [refreshSchedules] becomes a no-op when none of the
  /// channels are enabled — saves battery on devices that just
  /// installed the app and haven't opted in yet.
  bool get isInitialized => _initialized;

  /// Some platforms (web, headless test runners) can't schedule local
  /// notifications. We detect this once at startup and silently no-op
  /// the rest of the API rather than crashing the app.
  bool get isSupported => _supported;

  // ────────────────────────── lifecycle ──────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      // Skip on platforms where we know the plugin can't do anything —
      // notably web and any non-Android/iOS desktop in headless test.
      if (kIsWeb) {
        _initialized = true;
        _supported = false;
        return;
      }
      tz_data.initializeTimeZones();
      // Try to use the device's local zone, but fall back to UTC if
      // we can't read it (e.g. some emulators).
      try {
        tz.setLocalLocation(tz.getLocation(_guessLocalTimezoneName()));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings ios = DarwinInitializationSettings();
      const InitializationSettings settings = InitializationSettings(
        android: android,
        iOS: ios,
      );
      await _plugin.initialize(settings);
      _supported = true;
    } catch (_) {
      _supported = false;
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  String _guessLocalTimezoneName() {
    if (kIsWeb) return 'UTC';
    try {
      final String name = DateTime.now().timeZoneName;
      // `timeZoneName` is normally a short abbreviation (e.g. "+03",
      // "EET", "PST"); the timezone package wants IANA names. We try
      // a small whitelist and otherwise fall back to UTC.
      const Map<String, String> known = <String, String>{
        'EET': 'Asia/Damascus',
        'EEST': 'Asia/Damascus',
        '+03': 'Asia/Damascus',
        '+02': 'Asia/Damascus',
        'UTC': 'UTC',
        'GMT': 'UTC',
      };
      return known[name] ?? 'UTC';
    } catch (_) {
      return 'UTC';
    }
  }

  Future<bool> requestPermissions() async {
    if (!_supported) return false;
    try {
      if (Platform.isIOS) {
        return (await _plugin
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, badge: true, sound: true)) ??
            false;
      }
      if (Platform.isAndroid) {
        return (await _plugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission()) ??
            false;
      }
    } catch (_) {/* best-effort */}
    return false;
  }

  // ─────────────────────── per-channel toggles ──────────────────────

  /// Default-on for all channels. We intentionally don't hide this
  /// behind a "first-launch wizard" — the rules are local and gentle,
  /// and the user is one tap away from disabling each one.
  Future<bool> isEnabled(SmartNotificationChannel ch) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(ch.prefsKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setEnabled(SmartNotificationChannel ch, bool value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(ch.prefsKey, value);
    } catch (_) {/* best-effort */}
    notifyListeners();
    if (!value) {
      await _cancelChannel(ch);
    } else {
      await refreshSchedules();
    }
  }

  Future<void> _cancelChannel(SmartNotificationChannel ch) async {
    if (!_supported) return;
    switch (ch) {
      case SmartNotificationChannel.usualStudyTime:
        await _plugin.cancel(_idUsualStudy);
        break;
      case SmartNotificationChannel.assignmentsDueDigest:
        await _plugin.cancel(_idAssignmentsDigest);
        break;
      case SmartNotificationChannel.streakWarner:
        for (int i = 0; i < 100; i += 1) {
          await _plugin.cancel(_streakIdBase + i);
        }
        break;
    }
  }

  // ──────────────────────────── refresh ─────────────────────────────

  /// Re-evaluates every channel against the latest pattern data and
  /// (re-)schedules / cancels notifications accordingly.
  ///
  /// Idempotent: scheduling the same `id` overwrites the previous
  /// schedule, so this can be called as often as needed (every app
  /// resume, every pomodoro complete, every settings change).
  Future<void> refreshSchedules() async {
    if (!_supported) return;
    await _refreshUsualStudy();
    await _refreshStreakWarnings();
    await _refreshAssignmentsDigest();
  }

  Future<void> _refreshUsualStudy() async {
    if (!await isEnabled(SmartNotificationChannel.usualStudyTime)) {
      await _plugin.cancel(_idUsualStudy);
      return;
    }
    final int? hour = StudyPatternService.instance.predictUsualHour();
    if (hour == null) {
      await _plugin.cancel(_idUsualStudy);
      return;
    }
    final tz.TZDateTime when = _nextDailyAt(hour: hour, minute: 0);
    final String body = 'تعتاد الدراسة قرابة الساعة '
        '${hour.toString().padLeft(2, '0')}:00. ابدأ جلسة بومودورو الآن.';
    await _safeSchedule(
      id: _idUsualStudy,
      title: 'وقت الدراسة المعتاد',
      body: body,
      when: when,
      matchComponents: DateTimeComponents.time,
    );
  }

  Future<void> _refreshStreakWarnings() async {
    if (!await isEnabled(SmartNotificationChannel.streakWarner)) {
      for (int i = 0; i < 100; i += 1) {
        await _plugin.cancel(_streakIdBase + i);
      }
      return;
    }
    final List<StreakRisk> warnings =
        StudyPatternService.instance.stalenessWarnings();
    // Cancel the whole 100-slot range first so that subjects which
    // *no longer* qualify (user studied them, gap reset) don't keep
    // firing.
    for (int i = 0; i < 100; i += 1) {
      await _plugin.cancel(_streakIdBase + i);
    }
    int slot = 0;
    for (final StreakRisk w in warnings) {
      if (slot >= 100) break;
      final Subject? subject = _subjectForId(w.subjectId);
      final String name = subject?.name ?? w.subjectId;
      final String body =
          'مرّت ${w.hoursSinceLast} ساعة على آخر جلسة في $name. '
          'سلسلتك على وشك الانكسار.';
      // Fire 30 minutes from now — gives the user a tight window but
      // not a "right this second" interruption.
      final tz.TZDateTime when = tz.TZDateTime.now(tz.local)
          .add(const Duration(minutes: 30));
      await _safeSchedule(
        id: _streakIdBase + slot,
        title: 'سلسلة $name على وشك الانكسار',
        body: body,
        when: when,
      );
      slot += 1;
    }
  }

  Future<void> _refreshAssignmentsDigest() async {
    if (!await isEnabled(SmartNotificationChannel.assignmentsDueDigest)) {
      await _plugin.cancel(_idAssignmentsDigest);
      return;
    }
    int dueSoon = 0;
    try {
      final List<StudentAssignment> all =
          await StudentAssignmentQueries.fetchVisibleAssignments();
      final DateTime now = DateTime.now();
      final DateTime cutoff = now.add(const Duration(hours: 36));
      for (final StudentAssignment a in all) {
        if (a.isSubmitted) continue;
        final DateTime? due = a.dueAt;
        if (due == null) continue;
        if (due.isAfter(now) && due.isBefore(cutoff)) {
          dueSoon += 1;
        }
      }
    } catch (_) {/* best-effort, default to 0 */}

    if (dueSoon == 0) {
      // Nothing actionable today — don't spam an empty digest.
      await _plugin.cancel(_idAssignmentsDigest);
      return;
    }

    final tz.TZDateTime when = _nextDailyAt(hour: 8, minute: 0);
    final String body = dueSoon == 1
        ? 'لديك واجب واحد مستحق غدًا — جهّزه قبل الموعد.'
        : 'لديك $dueSoon واجبات مستحقة خلال الساعات القادمة.';
    await _safeSchedule(
      id: _idAssignmentsDigest,
      title: 'ملخّص الواجبات اليومي',
      body: body,
      when: when,
      matchComponents: DateTimeComponents.time,
    );
  }

  // ─────────────────────────── helpers ──────────────────────────────

  Future<void> _safeSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    DateTimeComponents? matchComponents,
  }) async {
    if (!_supported) return;
    try {
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const DarwinNotificationDetails ios = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(
        android: android,
        iOS: ios,
      );
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchComponents,
      );
    } catch (_) {/* swallow; best-effort */}
  }

  /// Show a notification *right now*. Used by the in-app "test"
  /// button so the user can verify their OS-level permission setup.
  Future<void> showTestNow({
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    try {
      const AndroidNotificationDetails android = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const DarwinNotificationDetails ios = DarwinNotificationDetails();
      const NotificationDetails details = NotificationDetails(
        android: android,
        iOS: ios,
      );
      await _plugin.show(9999, title, body, details);
    } catch (_) {/* swallow */}
  }

  Subject? _subjectForId(String id) {
    for (final Subject s in Curriculum.subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  tz.TZDateTime _nextDailyAt({required int hour, required int minute}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
