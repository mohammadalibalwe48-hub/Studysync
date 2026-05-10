import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/services/study_goal_service.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/main_scaffold.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';
import 'package:studysync_syria/core/widgets/stat_card.dart';
import 'package:studysync_syria/core/widgets/streak_badge.dart';
import 'package:studysync_syria/core/widgets/subject_card.dart';
import 'package:studysync_syria/features/announcements/announcement_queries.dart';
import 'package:studysync_syria/features/auth/auth_service.dart';
import 'package:studysync_syria/features/classes/join_class_dialog.dart';

/// Modern home dashboard.
///
/// Layout (top → bottom):
///  1. Greeting block with the student's first name and today's date.
///  2. "Today" hero with the daily-goal ring and headline streak +
///     accuracy stats.
///  3. Continue-learning quick action.
///  4. Subjects grid (Physics / Chemistry).
///  5. Practice quick actions (quick quiz, exam questions, flashcards,
///     focus timer).
///  6. Class actions (join class, assignments, announcements).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProgressSummary? _summary;
  int _unreadAnnouncements = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadUnread();
    StudyGoalService.instance.addListener(_onGoalChanged);
  }

  @override
  void dispose() {
    StudyGoalService.instance.removeListener(_onGoalChanged);
    super.dispose();
  }

  void _onGoalChanged() {
    if (mounted) setState(() {});
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

  Future<void> _loadUnread() async {
    final int count = await AnnouncementQueries.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _unreadAnnouncements = count);
  }

  Future<void> _refreshAll() async {
    await Future.wait<void>(<Future<void>>[
      _loadProgress(),
      _loadUnread(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final String? rawEmail = AuthService.instance.currentUserEmail;
    final String? displayName = _displayNameFor(rawEmail);
    const List<Subject> subjects = Curriculum.subjects;
    final ProgressSummary summary = _summary ?? ProgressSummary.empty;
    final StudyGoalService goal = StudyGoalService.instance;
    final int accuracy =
        (summary.correctAnswerRate * 100).clamp(0, 100).round();

    return MainScaffold(
      tab: MainTab.home,
      child: RefreshIndicator(
        color: scheme.primary,
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: <Widget>[
            FadeSlideIn(
              child: _GreetingHeader(
                name: displayName,
                streakDays: summary.streakDays,
              ),
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: _AiHeroCard(
                onStudyNow: () => context.go('/quick-quiz'),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _StatsRow(
                accuracyPercent: accuracy,
                revisionMinutes: goal.todayMinutes,
                completionPercent: (summary.completionPercent * 100)
                    .clamp(0, 100)
                    .round(),
              ),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: SectionHeader(
                title: 'المواد',
                subtitle: 'اختر المادة لمتابعة الدراسة.',
                actionLabel: 'الكل',
                onAction: () => context.go('/library'),
              ),
            ),
            const SizedBox(height: 12),
            ...List<Widget>.generate(subjects.length, (int i) {
              final Subject s = subjects[i];
              final double progress =
                  summary.completionBySubject[s.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeSlideIn(
                  delay: Duration(milliseconds: 180 + i * 80),
                  child: SubjectCard(
                    subject: s,
                    progress: progress,
                    onTap: () => context.go('/subjects/${s.id}'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 280),
              child: const SectionHeader(
                title: 'تدريب',
                subtitle: 'مارس واختبر نفسك بأساليب مختلفة.',
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: <Widget>[
                  _SquareTile(
                    title: 'اختبار سريع',
                    subtitle: '10 أسئلة مختلطة',
                    icon: Icons.flash_on_rounded,
                    tone: scheme.primary,
                    onTap: () => context.go('/quick-quiz'),
                  ),
                  _SquareTile(
                    title: 'أسئلة الدورات',
                    subtitle: 'بكالوريا سابقة',
                    icon: Icons.menu_book_rounded,
                    tone: AppTheme.tertiary,
                    onTap: () => context.go('/exam-questions'),
                  ),
                  _SquareTile(
                    title: 'بطاقات تذكيرية',
                    subtitle: 'راجع المفاهيم بسرعة',
                    icon: Icons.style_rounded,
                    tone: const Color(0xFF8B5CF6),
                    onTap: () => context.push('/flashcards'),
                  ),
                  _SquareTile(
                    title: 'مؤقّت التركيز',
                    subtitle: 'بومودورو 25 دقيقة',
                    icon: Icons.timer_outlined,
                    tone: palette.success,
                    onTap: () => context.push('/pomodoro'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 380),
              child: const SectionHeader(
                title: 'صفّي ومهامي',
                subtitle: 'انضم لصفّك وتابع الواجبات والإعلانات.',
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 420),
              child: ActionTile(
                title: 'الانضمام إلى صفّ',
                subtitle: 'أدخل رمز الدعوة من معلّمك',
                icon: Icons.group_add_outlined,
                tone: scheme.primary,
                onTap: () async {
                  final String? joined = await showDialog<String>(
                    context: context,
                    builder: (_) => const JoinClassDialog(),
                  );
                  if (joined == null || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم الانضمام إلى $joined')),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 460),
              child: ActionTile(
                title: 'الواجبات',
                subtitle: 'تابع واجباتك المستحقّة',
                icon: Icons.assignment_outlined,
                tone: AppTheme.tertiary,
                onTap: () => context.push('/assignments'),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: ActionTile(
                title: 'الإعلانات',
                subtitle: 'آخر إعلانات معلّميك',
                icon: Icons.campaign_outlined,
                tone: palette.warm,
                onTap: () async {
                  await context.push('/announcements');
                  if (!mounted) return;
                  await _loadUnread();
                },
                trailing: _unreadAnnouncements == 0
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$_unreadAnnouncements',
                          style: TextStyle(
                            color: scheme.onError,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.name, required this.streakDays});

  final String? name;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String greeting = _greetingText(DateTime.now());
    final String dateLine = _formatArabicDate(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                dateLine,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name == null ? greeting : '$greeting، $name',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'هيا نواصل التقدم خطوة بخطوة.',
                style: TextStyle(
                  fontSize: 13,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ),
        if (streakDays > 0) ...<Widget>[
          const SizedBox(width: 8),
          StreakBadge(days: streakDays),
        ],
      ],
    );
  }

  static String _greetingText(DateTime now) {
    final int h = now.hour;
    if (h < 12) return 'صباح الخير';
    if (h < 17) return 'مساء النور';
    return 'مساء الخير';
  }

  static String _formatArabicDate(DateTime d) {
    const List<String> weekdays = <String>[
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    const List<String> months = <String>[
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final String wd = weekdays[(d.weekday - 1) % 7];
    final String mo = months[(d.month - 1) % 12];
    return '$wd، ${d.day} $mo';
  }
}

/// Big orange "AI Recommendation" hero — sparkle icon, two-line copy,
/// pill-style "Study Now" button.
class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({required this.onStudyNow});

  final VoidCallback onStudyNow;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: palette.goldGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: palette.goldGlow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'توصية الذكاء',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'راجع "التيار الكهربائي" — لقد أتقنت 75% من المفاهيم الأساسية.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                PressableScale(
                  onTap: onStudyNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.play_arrow_rounded,
                          color: AppTheme.sunOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ابدأ الآن',
                          style: TextStyle(
                            color: AppTheme.sunOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three pill stats — Average, Revision time, Progression — that
/// echo the screenshot's tight stat row directly under the hero.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.accuracyPercent,
    required this.revisionMinutes,
    required this.completionPercent,
  });

  final int accuracyPercent;
  final int revisionMinutes;
  final int completionPercent;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String revisionLabel = revisionMinutes >= 60
        ? '${(revisionMinutes / 60).toStringAsFixed(1)} س'
        : '${revisionMinutes} د';

    return Row(
      children: <Widget>[
        Expanded(
          child: _StatPill(
            icon: Icons.check_circle_rounded,
            tone: palette.accent,
            value: '$accuracyPercent%',
            label: 'الدقة',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.access_time_rounded,
            tone: palette.success,
            value: revisionLabel,
            label: 'مراجعة',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.donut_small_rounded,
            tone: palette.info,
            value: '$completionPercent%',
            label: 'التقدّم',
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color tone;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareTile extends StatelessWidget {
  const _SquareTile({
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.outline, width: 1),
          boxShadow: palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: tone, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
