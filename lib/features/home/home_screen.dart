import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/main_scaffold.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';

/// "الرئيسية" tab — a focused dashboard that just covers the daily
/// "resume and go" flow.
///
/// Subjects, study tools, and class-related actions live in their own
/// dedicated tabs ([SubjectsTabScreen], [ClassroomScreen]) so this
/// screen can stay calm: a personal hero, a single primary call to
/// action, and an at-a-glance progress summary.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProgressSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final ProgressSummary summary =
          await StudySyncQueries.fetchProgressSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } catch (_) {
      if (!mounted) return;
      setState(() => _summary = ProgressSummary.empty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? rawEmail = AuthService.instance.currentUserEmail;
    final String? displayName = _displayNameFor(rawEmail);
    final ProgressSummary summary = _summary ?? ProgressSummary.empty;

    return MainScaffold(
      tab: MainTab.home,
      child: RefreshIndicator(
        onRefresh: _loadProgress,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            FadeSlideIn(
              child: _HeroCard(
                name: displayName,
                streakDays: summary.streakDays,
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _ContinueCard(
                onTap: () => context.push('/quick-quiz'),
              ),
            ),
            const SizedBox(height: 20),
            const FadeSlideIn(
              delay: Duration(milliseconds: 140),
              child: _SectionHeader(
                title: 'لمحة سريعة',
                subtitle: 'متابعة مختصرة لتقدّمك اليوم.',
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _GlanceRow(summary: summary),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: _ShortcutsRow(
                onSubjects: () => context.go('/subjects'),
                onClassroom: () => context.go('/classroom'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _displayNameFor(String? email) {
    if (email == null || email.isEmpty) return null;
    final int at = email.indexOf('@');
    final String raw = at <= 0 ? email : email.substring(0, at);
    if (raw.isEmpty) return null;
    return raw[0].toUpperCase() + raw.substring(1);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name, required this.streakDays});

  final String? name;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String greetingLine =
        name == null ? 'أهلاً بك 👋' : 'أهلاً $name 👋';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: palette.goldGradient,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accent.withOpacity(0.30),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            // Subtle radial highlight for depth.
            Positioned(
              right: -40,
              top: -40,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        Colors.white.withOpacity(0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'فيزياء وكيمياء — بكالوريا سوريا',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  greetingLine,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'هيا نتابع رحلتك مع الفيزياء والكيمياء.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    _StreakHeroPill(days: streakDays),
                    const SizedBox(width: 10),
                    const _KeepGoingHeroPill(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakHeroPill extends StatelessWidget {
  const _StreakHeroPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.local_fire_department_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          CountUp(
            value: days,
            builder: (BuildContext context, int v) {
              return Text(
                '$v أيام دراسة',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KeepGoingHeroPill extends StatelessWidget {
  const _KeepGoingHeroPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.40), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'استمرّ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.outline, width: 0.6),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: palette.goldGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.accent.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'تابع من حيث توقفت',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ابدأ رحلتك مع الفيزياء والكيمياء',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_left_rounded,
              size: 26,
              color: palette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: palette.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _GlanceRow extends StatelessWidget {
  const _GlanceRow({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _GlanceCard(
            label: 'الإنجاز',
            value: '${(summary.completionPercent * 100).round()}%',
            icon: Icons.check_circle_outline_rounded,
            tone: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlanceCard(
            label: 'نسبة الصح',
            value: '${(summary.correctAnswerRate * 100).round()}%',
            icon: Icons.gps_fixed_rounded,
            tone: AppTheme.tertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlanceCard(
            label: 'دقائق',
            value: '${summary.studyMinutes}',
            icon: Icons.schedule_rounded,
            tone: AppTheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _GlanceCard extends StatelessWidget {
  const _GlanceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: palette.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutsRow extends StatelessWidget {
  const _ShortcutsRow({
    required this.onSubjects,
    required this.onClassroom,
  });

  final VoidCallback onSubjects;
  final VoidCallback onClassroom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Shortcut(
            title: 'المواد',
            subtitle: 'الفيزياء والكيمياء',
            icon: Icons.menu_book_rounded,
            tone: AppTheme.primary,
            onTap: onSubjects,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Shortcut(
            title: 'صفّي',
            subtitle: 'الواجبات والإعلانات',
            icon: Icons.groups_rounded,
            tone: AppTheme.secondary,
            onTap: onClassroom,
          ),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.outline, width: 0.6),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    tone.withOpacity(0.20),
                    tone.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: tone, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.muted,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
