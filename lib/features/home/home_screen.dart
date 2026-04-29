import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: <Widget>[
            _HeroCard(
              greeting: 'Welcome back,',
              name: displayName,
              streakDays: _streakDays ?? 0,
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Subjects', subtitle: subjects.isEmpty
                ? 'Once subjects are added, they will appear here.'
                : 'Pick a subject to keep studying.'),
            const SizedBox(height: 12),
            if (subjects.isEmpty)
              const _SubjectsEmptyState()
            else
              ...subjects.map(
                (Subject s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SubjectCard(
                    subject: s,
                    onTap: () => context.go('/subjects/${s.id}'),
                  ),
                ),
              ),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary,
            Color.lerp(scheme.primary, AppTheme.accent, 0.55) ?? scheme.primary,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            greeting,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              _HeroPill(
                icon: Icons.local_fire_department_rounded,
                label: '$streakDays day streak',
              ),
              const SizedBox(width: 10),
              const _HeroPill(
                icon: Icons.school_outlined,
                label: 'Keep going',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: palette.muted),
        ),
      ],
    );
  }
}

class _SubjectsEmptyState extends StatelessWidget {
  const _SubjectsEmptyState();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline),
      ),
      child: const EmptyState(
        compact: true,
        icon: Icons.menu_book_outlined,
        title: 'No subjects yet',
        description:
            'Subjects will show up here once they are added by your teacher.',
      ),
    );
  }
}
