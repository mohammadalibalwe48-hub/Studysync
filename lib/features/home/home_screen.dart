import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/main_scaffold.dart';
import 'package:studysync_syria/core/widgets/subject_card.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _streakDays;
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
      setState(() {
        _summary = summary;
        _streakDays = summary.streakDays;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _summary = ProgressSummary.empty;
        _streakDays = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? rawEmail = AuthService.instance.currentUserEmail;
    final String? displayName = _displayNameFor(rawEmail);
    const List<Subject> subjects = Curriculum.subjects;
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
                streakDays: _streakDays ?? 0,
              ),
            ),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _ContinueCard(
                onTap: () => context.go('/quick-quiz'),
              ),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: const _SectionHeader(
                title: 'المواد',
                subtitle: 'اختر المادة لمتابعة الدراسة.',
              ),
            ),
            const SizedBox(height: 14),
            if (subjects.isEmpty)
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _SubjectsEmptyState(onRefresh: _loadProgress),
              )
            else
              ...List<Widget>.generate(subjects.length, (int i) {
                final Subject s = subjects[i];
                final double progress =
                    summary.completionBySubject[s.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 140 + i * 80),
                    child: SubjectCard(
                      subject: s,
                      progress: progress,
                      onTap: () => context.go('/subjects/${s.id}'),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: const _SectionHeader(
                title: 'أدوات سريعة',
                subtitle: 'تمرّن أو راجع أسئلة الدورات السابقة.',
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _ActionTile(
                      title: 'اختبار سريع',
                      subtitle: 'حتى 10 أسئلة مختلطة',
                      icon: Icons.flash_on_rounded,
                      tone: const Color(0xFFFF8927),
                      onTap: () => context.go('/quick-quiz'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      title: 'أسئلة الدورات',
                      subtitle: 'نماذج بكالوريا سابقة',
                      icon: Icons.menu_book_rounded,
                      tone: const Color(0xFF1E73E8),
                      onTap: () => context.go('/exam-questions'),
                    ),
                  ),
                ],
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
        color: AppTheme.surfaceContainerHigh,
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      palette.gold.withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        palette.warm.withOpacity(0.30),
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
                    color: palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  greetingLine,
                  style: const TextStyle(
                    color: AppTheme.onBackground,
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
                    color: AppTheme.onBackground.withOpacity(0.74),
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
    final AppPalette palette = AppPalette.of(context);
    return GlowPulse(
      color: palette.accent,
      minOpacity: 0.10,
      maxOpacity: 0.26,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: palette.warm,
            ),
            const SizedBox(width: 6),
            CountUp(
              value: days,
              builder: (BuildContext context, int v) {
                return Text(
                  '$v أيام دراسة',
                  style: const TextStyle(
                    color: AppTheme.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KeepGoingHeroPill extends StatelessWidget {
  const _KeepGoingHeroPill();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            palette.gold.withOpacity(0.30),
            palette.warm.withOpacity(0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.auto_awesome_rounded, size: 16, color: palette.accent),
          const SizedBox(width: 6),
          Text(
            'استمرّ',
            style: TextStyle(
              color: palette.accent,
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Icon(icon, color: tone, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: palette.muted,
                height: 1.4,
              ),
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

class _SubjectsEmptyState extends StatelessWidget {
  const _SubjectsEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: EmptyState(
        compact: true,
        icon: Icons.menu_book_outlined,
        title: 'لا توجد مواد بعد',
        description:
            'سيظهر هنا مساراك في الفيزياء والكيمياء لتبدأ رحلة الدراسة.',
        action: TextButton.icon(
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('تحديث'),
        ),
      ),
    );
  }
}
