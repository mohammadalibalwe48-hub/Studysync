import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/question.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/services/bookmarks_service.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/app_button.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// Lists every question the user has saved with the bookmark button on
/// any [QuestionCard]. Tapping a row navigates to the topic screen so
/// the student can read full context around the question.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) setState(() {});
    };
    BookmarksService.instance.addListener(_listener);
  }

  @override
  void dispose() {
    BookmarksService.instance.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_BookmarkEntry> entries = _resolveBookmarks();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'محفوظاتي',
                subtitle: entries.isEmpty
                    ? 'أسئلة محفوظة'
                    : '${entries.length} سؤال',
                onBack: () => context.pop(),
                action: entries.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'مسح الكل',
                        onPressed: () async {
                          final bool ok = await _confirmClear(context);
                          if (!ok) return;
                          await BookmarksService.instance.clear();
                        },
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: Center(
                          child: EmptyState(
                            card: true,
                            icon: Icons.bookmark_border_rounded,
                            title: 'لا توجد محفوظات بعد',
                            description:
                                'اضغط أيقونة الإشارة المرجعية على أي سؤال '
                                'لحفظه هنا والعودة إليه لاحقاً.',
                            action: DashedActionButton(
                              label: 'استعرض الأسئلة',
                              icon: Icons.menu_book_rounded,
                              onPressed: () => context.go('/exam-questions'),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext c, int i) {
                          final _BookmarkEntry e = entries[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 40 * i),
                            child: _BookmarkRow(
                              entry: e,
                              onTap: () =>
                                  context.go('/topics/${e.topic.id}'),
                              onRemove: () => BookmarksService.instance
                                  .toggle(e.question.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_BookmarkEntry> _resolveBookmarks() {
    final Set<String> ids = BookmarksService.instance.all;
    if (ids.isEmpty) return const <_BookmarkEntry>[];
    final List<_BookmarkEntry> out = <_BookmarkEntry>[];
    for (final Topic t in Curriculum.topics) {
      final Subject s = Curriculum.subjects.firstWhere(
        (Subject sj) => sj.id == t.subjectId,
        orElse: () => const Subject(
          id: '',
          name: '',
          description: '',
          icon: Icons.menu_book_outlined,
          color: AppTheme.primary,
        ),
      );
      for (final Question q in t.questions) {
        if (ids.contains(q.id)) {
          out.add(_BookmarkEntry(topic: t, subject: s, question: q));
        }
      }
    }
    return out;
  }

  Future<bool> _confirmClear(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text('مسح المحفوظات؟'),
        content: const Text('سيتم حذف كل الأسئلة المحفوظة. لا يمكن التراجع.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}

class _BookmarkEntry {
  const _BookmarkEntry({
    required this.topic,
    required this.subject,
    required this.question,
  });

  final Topic topic;
  final Subject subject;
  final Question question;
}

class _BookmarkRow extends StatelessWidget {
  const _BookmarkRow({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final _BookmarkEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final Color accent = entry.subject.color;
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
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(entry.subject.icon, size: 12, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        entry.subject.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.topic.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'إزالة',
                  icon: Icon(
                    Icons.bookmark_remove_outlined,
                    color: palette.warm,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.question.prompt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
