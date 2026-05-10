import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/services/bookmarks_service.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/main_scaffold.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';
import 'package:studysync_syria/core/widgets/stat_card.dart';
import 'package:studysync_syria/core/widgets/subject_card.dart';

/// "Library" tab — the single, organised entry point for everything a
/// student studies. Lists every subject, surfaces practice tools, and
/// links to the user's saved questions and recent class assignments.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  ProgressSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
    BookmarksService.instance.addListener(_onBookmarkChange);
  }

  @override
  void dispose() {
    BookmarksService.instance.removeListener(_onBookmarkChange);
    super.dispose();
  }

  void _onBookmarkChange() {
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final ProgressSummary summary = _summary ?? ProgressSummary.empty;
    final int bookmarks = BookmarksService.instance.count;
    return MainScaffold(
      tab: MainTab.library,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: <Widget>[
          FadeSlideIn(
            child: const ScreenHeading(
              title: 'المكتبة',
              subtitle: 'كلّ مادة، كلّ درس، وأدوات المراجعة في مكان واحد.',
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: const SectionHeader(
              title: 'المواد',
              subtitle: 'اختر المادة لاستعراض الدروس وأسئلة التدريب.',
            ),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(Curriculum.subjects.length, (int i) {
            final Subject s = Curriculum.subjects[i];
            final int topicCount = Curriculum.topicsForSubject(s.id).length;
            final double progress = summary.completionBySubject[s.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 100 + i * 80),
                child: _SubjectRowCard(
                  subject: s,
                  topicCount: topicCount,
                  progress: progress,
                  onTap: () => context.go('/subjects/${s.id}'),
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: const SectionHeader(
              title: 'أدوات الدراسة',
              subtitle: 'أساليب مختلفة لترسيخ المعلومات.',
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: <Widget>[
                _ToolTile(
                  icon: Icons.flash_on_rounded,
                  title: 'اختبار سريع',
                  subtitle: '10 أسئلة مختلطة',
                  tone: scheme.primary,
                  onTap: () => context.go('/quick-quiz'),
                ),
                _ToolTile(
                  icon: Icons.menu_book_rounded,
                  title: 'أسئلة الدورات',
                  subtitle: 'بكالوريا سابقة',
                  tone: AppTheme.tertiary,
                  onTap: () => context.go('/exam-questions'),
                ),
                _ToolTile(
                  icon: Icons.style_rounded,
                  title: 'بطاقات تذكيرية',
                  subtitle: 'مفاهيم أساسية',
                  tone: const Color(0xFF8C5A38), // mocha
                  onTap: () => context.push('/flashcards'),
                ),
                _ToolTile(
                  icon: Icons.timer_outlined,
                  title: 'مؤقّت التركيز',
                  subtitle: 'بومودورو',
                  tone: palette.success,
                  onTap: () => context.push('/pomodoro'),
                ),
                _ToolTile(
                  icon: Icons.bookmark_rounded,
                  title: 'محفوظاتي',
                  subtitle: bookmarks == 0
                      ? 'أسئلة محفوظة'
                      : '$bookmarks سؤال',
                  tone: palette.warm,
                  onTap: () => context.push('/bookmarks'),
                ),
                _ToolTile(
                  icon: Icons.search_rounded,
                  title: 'بحث',
                  subtitle: 'في كل الدروس',
                  tone: scheme.onSurfaceVariant,
                  onTap: () => context.push('/search'),
                ),
                _ToolTile(
                  icon: Icons.edit_note_rounded,
                  title: 'ملاحظاتي',
                  subtitle: 'ماركداون مع تظليل',
                  tone: const Color(0xFFD68A1A),
                  onTap: () => context.push('/notes'),
                ),
                _ToolTile(
                  icon: Icons.emoji_events_rounded,
                  title: 'لوحة المتصدرين',
                  subtitle: 'تنافس مع أصدقائك',
                  tone: const Color(0xFFE2862F),
                  onTap: () => context.push('/leaderboard'),
                ),
                _ToolTile(
                  icon: Icons.account_tree_rounded,
                  title: 'الخريطة الذهنية',
                  subtitle: 'روابط المنهج بصريًا',
                  tone: const Color(0xFFC9602B),
                  onTap: () => context.push('/mind-map'),
                ),
                _ToolTile(
                  icon: Icons.grid_view_rounded,
                  title: 'الجدول الدوري',
                  subtitle: 'العناصر الكيميائية',
                  tone: const Color(0xFF8C5A38),
                  onTap: () => context.push('/periodic-table'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: const SectionHeader(
              title: 'صفّي ومهامي',
              subtitle: 'تابع الواجبات والإعلانات الواردة.',
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 400),
            child: ActionTile(
              title: 'الواجبات',
              subtitle: 'استعرض واجباتك القادمة وقدّم إجاباتك',
              icon: Icons.assignment_outlined,
              tone: scheme.primary,
              onTap: () => context.push('/assignments'),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 440),
            child: ActionTile(
              title: 'الإعلانات',
              subtitle: 'كل ما يكتبه معلموك في صفّك',
              icon: Icons.campaign_outlined,
              tone: palette.warm,
              onTap: () => context.push('/announcements'),
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 480),
            child: ActionTile(
              title: 'الدردشة المباشرة للصف',
              subtitle: 'تواصل مع معلّمك وزملائك في الوقت نفسه',
              icon: Icons.forum_rounded,
              tone: scheme.primary,
              onTap: () => context.push('/my-classes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectRowCard extends StatelessWidget {
  const _SubjectRowCard({
    required this.subject,
    required this.topicCount,
    required this.progress,
    required this.onTap,
  });

  final Subject subject;
  final int topicCount;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SubjectCard(
      subject: Subject(
        id: subject.id,
        name: subject.name,
        description: '$topicCount دروس · ${subject.description}',
        icon: subject.icon,
        color: subject.color,
      ),
      progress: progress,
      onTap: onTap,
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
