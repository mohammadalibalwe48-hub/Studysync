import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/services/notifications_service.dart';
import 'package:studysync_syria/core/services/study_pattern_service.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';
import 'package:studysync_syria/core/widgets/stat_card.dart';

/// Per-channel opt-in / opt-out for the smart-notification system.
///
/// All three product channels share a single Android system channel
/// (importance/sound managed there); these toggles only control
/// whether the app schedules anything for them.
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  final Map<SmartNotificationChannel, bool> _enabled =
      <SmartNotificationChannel, bool>{};
  bool _loading = true;
  bool _osPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final SmartNotificationChannel ch in SmartNotificationChannel.values) {
      _enabled[ch] = await NotificationsService.instance.isEnabled(ch);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _requestOsPermission() async {
    final bool granted =
        await NotificationsService.instance.requestPermissions();
    if (!mounted) return;
    setState(() => _osPermissionGranted = granted);
    if (granted) {
      unawaited(NotificationsService.instance.refreshSchedules());
    }
  }

  Future<void> _toggle(SmartNotificationChannel ch, bool value) async {
    setState(() => _enabled[ch] = value);
    await NotificationsService.instance.setEnabled(ch, value);
  }

  Future<void> _testNow() async {
    await NotificationsService.instance.showTestNow(
      title: 'تجربة إشعار',
      body: 'إذا وصلك هذا الإشعار فإنّ الإعدادات تعمل بشكل صحيح.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('تم إرسال إشعار تجريبي.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final int? usualHour =
        StudyPatternService.instance.predictUsualHour();
    final List<StreakRisk> risks =
        StudyPatternService.instance.stalenessWarnings();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'إعدادات الإشعارات',
                subtitle: 'تذكيرات محلية ذكيّة بناءً على عاداتك',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 14, 20, 28),
                        children: <Widget>[
                          FadeSlideIn(
                            child: _StatusCard(
                              supported: NotificationsService
                                  .instance.isSupported,
                              osGranted: _osPermissionGranted,
                              usualHour: usualHour,
                              riskCount: risks.length,
                              onRequestPermission: _requestOsPermission,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 80),
                            child: const SectionHeader(
                              title: 'القنوات',
                              subtitle:
                                  'فعّل أو عطّل كل تذكير على حدة. لا شيء يُرسل '
                                  'إلى أي خادم.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List<Widget>.generate(
                            SmartNotificationChannel.values.length,
                            (int i) {
                              final SmartNotificationChannel ch =
                                  SmartNotificationChannel.values[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: FadeSlideIn(
                                  delay: Duration(
                                    milliseconds: 120 + i * 60,
                                  ),
                                  child: _ChannelTile(
                                    channel: ch,
                                    value: _enabled[ch] ?? true,
                                    onChanged: (bool v) => _toggle(ch, v),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 320),
                            child: ActionTile(
                              icon: Icons.science_outlined,
                              title: 'اختبار الإشعار',
                              subtitle: 'يرسل إشعارًا تجريبيًا فورًا',
                              tone: palette.warm,
                              onTap: _testNow,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.supported,
    required this.osGranted,
    required this.usualHour,
    required this.riskCount,
    required this.onRequestPermission,
  });

  final bool supported;
  final bool osGranted;
  final int? usualHour;
  final int riskCount;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final List<Widget> rows = <Widget>[];
    if (!supported) {
      rows.add(_row(
        scheme,
        palette,
        Icons.info_outline_rounded,
        'الإشعارات المحلية غير مدعومة على هذه المنصة.',
      ));
    } else {
      rows.add(_row(
        scheme,
        palette,
        osGranted
            ? Icons.check_circle_outline_rounded
            : Icons.lock_outline_rounded,
        osGranted
            ? 'لديك إذن النظام لإرسال الإشعارات.'
            : 'يحتاج التطبيق إذن نظام لإرسال الإشعارات.',
      ));
      rows.add(_row(
        scheme,
        palette,
        Icons.schedule_rounded,
        usualHour == null
            ? 'لا توجد بيانات كافية لاكتشاف وقت دراستك المعتاد بعد.'
            : 'وقت دراستك المعتاد: '
                '${usualHour.toString().padLeft(2, '0')}:00.',
      ));
      rows.add(_row(
        scheme,
        palette,
        Icons.warning_amber_rounded,
        riskCount == 0
            ? 'لا توجد سلاسل في خطر حاليًا.'
            : '$riskCount مادة قد تنكسر سلسلتها قريبًا.',
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: palette.goldGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'حالة الإشعارات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
          if (supported && !osGranted) ...<Widget>[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: scheme.primary,
                ),
                onPressed: onRequestPermission,
                child: const Text('طلب الإذن'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    ColorScheme scheme,
    AppPalette palette,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.channel,
    required this.value,
    required this.onChanged,
  });

  final SmartNotificationChannel channel;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconFor(channel),
              color: scheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  channel.arabicLabel,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  channel.arabicDescription,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: palette.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  IconData _iconFor(SmartNotificationChannel ch) {
    switch (ch) {
      case SmartNotificationChannel.usualStudyTime:
        return Icons.schedule_rounded;
      case SmartNotificationChannel.streakWarner:
        return Icons.local_fire_department_rounded;
      case SmartNotificationChannel.assignmentsDueDigest:
        return Icons.assignment_outlined;
    }
  }
}
