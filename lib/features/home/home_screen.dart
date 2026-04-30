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

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    try {
      final ProgressSummary summary =
          await StudySyncQueries.fetchProgressSummary();
      if (!mounted) return;
      setState(() => _streakDays = summary.streakDays);
    } catch (_) {
      if (!mounted) return;
      setState(() => _streakDays = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String email =
        AuthService.instance.currentUserEmail ?? 'student@example.com';
    final String displayName = _displayNameFor(email);
    const List<Subject> subjects = Curriculum.subjects;

    return MainScaffold(
      tab: MainTab.home,
      child: RefreshIndicator(
        onRefresh: _loadStreak,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            FadeSlideIn(
              child: _HeroCard(
                greeting: _greetingFor(DateTime.now()),
                name: displayName,
                streakDays: _streakDays ?? 0,
              ),
            ),
            const SizedBox(height: 28),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _SectionHeader(
                title: 'Subjects',
                subtitle: subjects.isEmpty
                    ? 'Your learning paths will appear here.'
                    : 'Pick a subject to keep studying.',
              ),
            ),
            const SizedBox(height: 14),
            if (subjects.isEmpty)
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: _SubjectsEmptyState(onRefresh: _loadStreak),
              )
            else
              ...List<Widget>.generate(subjects.length, (int i) {
                final Subject s = subjects[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 140 + i * 80),
                    child: SubjectCard(
                      subject: s,
                      onTap: () => context.go('/subjects/${s.id}'),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static String _displayNameFor(String email) {
    final int at = email.indexOf('@');
    final String raw = at <= 0 ? email : email.substring(0, at);
    if (raw.isEmpty) return 'Student';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  static String _greetingFor(DateTime now) {
    final int h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.greeting,
    required this.name,
    required this.streakDays,
  });

  final String greeting;
  final String name;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
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
            // Soft golden ambient gradient.
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
            // Decorative diffuse glow.
            Positioned(
              right: -40,
              bottom: -40,
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
                  greeting,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: AppTheme.onBackground.withOpacity(0.74),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.onBackground,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                  '$v day streak',
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
            'Keep going',
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
        title: 'No subjects yet',
        description:
            'Your teacher will add subjects for you to begin your journey.',
        action: TextButton.icon(
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Refresh'),
        ),
      ),
    );
  }
}
