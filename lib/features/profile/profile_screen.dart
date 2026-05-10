import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/services/study_goal_service.dart';
import 'package:studysync_syria/core/services/theme_service.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/main_scaffold.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';
import 'package:studysync_syria/core/widgets/stat_card.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';

/// Modern profile screen.
///
/// Sections:
///  • Avatar header with the user's initials and email.
///  • Quick stats grid (streak / accuracy / topics completed).
///  • Settings list (theme, daily goal, bookmarks, sign out).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProgressSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
    ThemeService.instance.addListener(_listener);
    StudyGoalService.instance.addListener(_listener);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_listener);
    StudyGoalService.instance.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    try {
      final ProgressSummary s =
          await StudySyncQueries.fetchProgressSummary();
      if (!mounted) return;
      setState(() => _summary = s);
    } catch (_) {
      if (!mounted) return;
      setState(() => _summary = ProgressSummary.empty);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final String? email = AuthService.instance.currentUserEmail;
    final ProgressSummary summary = _summary ?? ProgressSummary.empty;
    final int accuracy =
        (summary.correctAnswerRate * 100).clamp(0, 100).round();

    return MainScaffold(
      tab: MainTab.profile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: <Widget>[
          FadeSlideIn(
            child: _ProfileHeader(email: email),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: const SectionHeader(
              title: 'إحصائياتي',
              subtitle: 'نظرة سريعة على مسيرتك حتى الآن.',
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: <Widget>[
                StatCard(
                  icon: Icons.local_fire_department_rounded,
                  label: 'السلسلة',
                  value: summary.streakDays,
                  suffix: 'يوم',
                  color: palette.warm,
                ),
                StatCard(
                  icon: Icons.verified_rounded,
                  label: 'الدقة',
                  value: accuracy,
                  suffix: '%',
                  color: palette.success,
                ),
                StatCard(
                  icon: Icons.task_alt_rounded,
                  label: 'مكتمل',
                  value: summary.completedTopics,
                  suffix: '/ ${summary.totalTopicsTracked}',
                  color: scheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: const SectionHeader(
              title: 'الإعدادات',
              subtitle: 'خصّص تجربتك في التطبيق.',
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: ActionTile(
              icon: _themeIcon(ThemeService.instance.mode),
              title: 'المظهر',
              subtitle: _themeLabel(ThemeService.instance.mode),
              tone: scheme.primary,
              onTap: () => ThemeService.instance.cycle(),
              trailing: Icon(
                Icons.swap_horiz_rounded,
                color: palette.muted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: ActionTile(
              icon: Icons.flag_rounded,
              title: 'الهدف اليومي',
              subtitle: '${StudyGoalService.instance.goalMinutes} دقيقة من الدراسة',
              tone: AppTheme.tertiary,
              onTap: _editGoal,
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 320),
            child: ActionTile(
              icon: Icons.bookmark_rounded,
              title: 'المحفوظات',
              subtitle: 'أسئلة حفظتها للمراجعة',
              tone: palette.warm,
              onTap: () => context.push('/bookmarks'),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: ActionTile(
              icon: Icons.notifications_active_outlined,
              title: 'الإشعارات',
              subtitle: 'إدارة التذكيرات وتنبيهات الدراسة',
              tone: scheme.primary,
              onTap: () => context.push('/notifications'),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 400),
            child: ActionTile(
              icon: Icons.logout_rounded,
              title: 'تسجيل الخروج',
              subtitle: 'إنهاء الجلسة الحالية',
              tone: scheme.error,
              onTap: _signOut,
            ),
          ),
          const SizedBox(height: 24),
          FadeSlideIn(
            delay: const Duration(milliseconds: 460),
            child: Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'Educational Steps Platform',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'منصّة الخطوات التعليمية',
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'فاتح — اضغط للتغيير';
      case ThemeMode.dark:
        return 'داكن — اضغط للتغيير';
      case ThemeMode.system:
        return 'تلقائي حسب النظام — اضغط للتغيير';
    }
  }

  Future<void> _editGoal() async {
    final int? value = await showDialog<int>(
      context: context,
      builder: (BuildContext c) => _GoalDialog(
        initial: StudyGoalService.instance.goalMinutes,
      ),
    );
    if (value == null) return;
    await StudyGoalService.instance.setGoal(value);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String initials = _initials(email);
    final String displayName = _displayName(email);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.goldGlow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1,
              ),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? 'طالب ضيف',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.86),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? email) {
    if (email == null || email.isEmpty) return 'ST';
    final int at = email.indexOf('@');
    final String raw = at <= 0 ? email : email.substring(0, at);
    if (raw.isEmpty) return 'ST';
    final List<String> parts = raw.split(RegExp(r'[._-]+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return raw[0].toUpperCase() +
        (raw.length > 1 ? raw[1].toUpperCase() : '');
  }

  static String _displayName(String? email) {
    if (email == null || email.isEmpty) return 'مرحباً بك';
    final int at = email.indexOf('@');
    final String raw = at <= 0 ? email : email.substring(0, at);
    if (raw.isEmpty) return 'مرحباً بك';
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.initial});
  final int initial;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late int _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الهدف اليومي'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$_value دقيقة',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _value.toDouble(),
            min: 15,
            max: 180,
            divisions: 33,
            label: '$_value دقيقة',
            onChanged: (double v) =>
                setState(() => _value = v.round()),
          ),
          const Text(
            'كم دقيقة تخطّط للدراسة في كل يوم؟',
            style: TextStyle(fontSize: 12.5),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
