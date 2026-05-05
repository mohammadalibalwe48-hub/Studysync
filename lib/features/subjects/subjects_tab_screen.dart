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

/// "المواد" tab — full subjects list plus shared study tools (quick
/// quiz, exam questions). Pulled out of the home screen so the
/// homepage can stay focused on the daily resume-and-go flow.
class SubjectsTabScreen extends StatefulWidget {
  const SubjectsTabScreen({super.key});

  @override
  State<SubjectsTabScreen> createState() => _SubjectsTabScreenState();
}

class _SubjectsTabScreenState extends State<SubjectsTabScreen> {
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
    const List<Subject> subjects = Curriculum.subjects;
    final ProgressSummary summary = _summary ?? ProgressSummary.empty;

    return MainScaffold(
      tab: MainTab.subjects,
      child: RefreshIndicator(
        onRefresh: _loadProgress,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            const FadeSlideIn(
              child: _ScreenHeading(
                title: 'المواد',
                subtitle: 'اختر المادة لمتابعة الدروس والأسئلة.',
              ),
            ),
            const SizedBox(height: 16),
            if (subjects.isEmpty)
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
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
                    delay: Duration(milliseconds: 80 + i * 80),
                    child: SubjectCard(
                      subject: s,
                      progress: progress,
                      onTap: () => context.go('/subjects/${s.id}'),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 22),
            const FadeSlideIn(
              delay: Duration(milliseconds: 240),
              child: _SectionHeader(
                title: 'أدوات الدراسة',
                subtitle: 'تمرّن أو راجع أسئلة الدورات السابقة.',
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _ActionTile(
                      title: 'اختبار سريع',
                      subtitle: 'حتى 10 أسئلة مختلطة',
                      icon: Icons.flash_on_rounded,
                      tone: AppTheme.primary,
                      onTap: () => context.push('/quick-quiz'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      title: 'أسئلة الدورات',
                      subtitle: 'نماذج بكالوريا سابقة',
                      icon: Icons.menu_book_rounded,
                      tone: AppTheme.tertiary,
                      onTap: () => context.push('/exam-questions'),
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
}

class _ScreenHeading extends StatelessWidget {
  const _ScreenHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13.5, color: palette.muted, height: 1.5),
        ),
      ],
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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: palette.muted, height: 1.5),
        ),
      ],
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
