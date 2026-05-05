import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/main_scaffold.dart';
import 'package:studysync_syria/features/announcements/announcement_queries.dart';
import 'package:studysync_syria/features/classes/join_class_dialog.dart';

/// "صفّي" tab — class/teacher-related actions.
///
/// This is everything that used to be crowded onto the home screen as
/// independent tiles: joining a teacher's class, the assignments
/// inbox, and the announcements inbox. Each entry routes off to a
/// dedicated full-screen flow when tapped.
class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({super.key});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  int _unreadAnnouncements = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    final int count = await AnnouncementQueries.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _unreadAnnouncements = count);
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      tab: MainTab.classroom,
      child: RefreshIndicator(
        onRefresh: _loadUnread,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            const FadeSlideIn(
              child: _ScreenHeading(
                title: 'صفّي',
                subtitle:
                    'ابقَ على تواصل مع معلّمك: انضمّ إلى صف، تابع الواجبات، '
                    'واقرأ آخر الإعلانات.',
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: _JoinClassTile(
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
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: _AssignmentsTile(
                onTap: () => context.push('/assignments'),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _AnnouncementsTile(
                unreadCount: _unreadAnnouncements,
                onTap: () async {
                  await context.push('/announcements');
                  if (!mounted) return;
                  await _loadUnread();
                },
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

class _JoinClassTile extends StatelessWidget {
  const _JoinClassTile({required this.onTap});
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: palette.goldGradient,
                borderRadius: BorderRadius.circular(14),
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
                Icons.vpn_key_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'الانضمام إلى صف معلّم',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'أدخل رمز الانضمام لمتابعة معلّمك لتقدّمك.',
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
            Icon(Icons.chevron_left_rounded,
                size: 22, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

class _AssignmentsTile extends StatelessWidget {
  const _AssignmentsTile({required this.onTap});
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: palette.info.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.assignment_outlined,
                color: palette.info,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'الواجبات',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'الواجبات التي أنشأها معلّمك للصف.',
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
            Icon(Icons.chevron_left_rounded,
                size: 22, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsTile extends StatelessWidget {
  const _AnnouncementsTile({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.secondary.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.campaign_outlined,
                color: scheme.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'الإعلانات',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'إعلانات معلّميك لكل الصفوف.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unreadCount جديد',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_left_rounded,
                  size: 22, color: palette.muted),
          ],
        ),
      ),
    );
  }
}
