import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/constants/topic_catalog.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';
import 'package:studysync_syria_teachers/features/curriculum/curriculum_models.dart';
import 'package:studysync_syria_teachers/features/curriculum/curriculum_queries.dart';

class CurriculumListScreen extends StatefulWidget {
  const CurriculumListScreen({super.key});

  @override
  State<CurriculumListScreen> createState() => _CurriculumListScreenState();
}

class _CurriculumListScreenState extends State<CurriculumListScreen> {
  late Future<List<CustomLesson>> _future;

  /// Null = "كل المواد". Otherwise filter to lessons whose subject_id
  /// matches.
  String? _subjectFilter;

  @override
  void initState() {
    super.initState();
    _future = CurriculumQueries.fetchOwnLessons();
  }

  Future<void> _refresh() async {
    setState(() => _future = CurriculumQueries.fetchOwnLessons());
    await _future;
  }

  Future<void> _confirmDelete(CustomLesson lesson) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('حذف الدرس'),
        content: Text(
          'هل تريد حذف "${lesson.lessonTitle}"؟ لا يمكن التراجع عن هذا.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CurriculumQueries.deleteLesson(lessonId: lesson.id);
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openEditor({CustomLesson? lesson}) async {
    final bool? changed = await context.push<bool>(
      lesson == null
          ? '/curriculum/new'
          : '/curriculum/${lesson.id}',
      extra: lesson,
    );
    if (changed == true) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'المنهج',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: <Widget>[
                    _SubjectChip(
                      label: 'الكل',
                      selected: _subjectFilter == null,
                      palette: palette,
                      onTap: () => setState(() => _subjectFilter = null),
                    ),
                    const SizedBox(width: 8),
                    for (final MapEntry<String, String> e
                        in TopicCatalog.subjectTitles.entries) ...<Widget>[
                      _SubjectChip(
                        label: e.value,
                        selected: _subjectFilter == e.key,
                        palette: palette,
                        onTap: () =>
                            setState(() => _subjectFilter = e.key),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<CustomLesson>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<CustomLesson>> snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return ListView(children: <Widget>[
                          const SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'تعذّر تحميل الدروس',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      final List<CustomLesson> all =
                          snap.data ?? const <CustomLesson>[];
                      final List<CustomLesson> items = _subjectFilter == null
                          ? all
                          : all
                              .where((CustomLesson l) =>
                                  l.subjectId == _subjectFilter)
                              .toList();
                      if (items.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'لا توجد دروس بعد',
                            description:
                                'أنشئ درسًا ليظهر لطلابك إلى جانب المنهج.',
                          ),
                        ]);
                      }
                      return ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int i) {
                          final CustomLesson l = items[i];
                          return FadeSlideIn(
                            delay:
                                Duration(milliseconds: 60 + i * 30),
                            child: _LessonCard(
                              lesson: l,
                              palette: palette,
                              onTap: () => _openEditor(lesson: l),
                              onDelete: () => _confirmDelete(l),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: AppButton(
                  label: 'إنشاء درس جديد',
                  icon: Icons.add_rounded,
                  onPressed: () => _openEditor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? palette.gold : palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? palette.gold : palette.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : palette.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.palette,
    required this.onTap,
    required this.onDelete,
  });

  final CustomLesson lesson;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get _topicLabel {
    final String? id = lesson.topicId;
    if (id != null && TopicCatalog.topicTitles.containsKey(id)) {
      return TopicCatalog.topicTitle(id);
    }
    final String? raw = lesson.topicTitle;
    if (raw != null && raw.trim().isNotEmpty) return raw.trim();
    return 'موضوع جديد';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.outline),
          boxShadow: palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: palette.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lesson.lessonTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                  tooltip: 'حذف',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _Pill(
                  label: TopicCatalog.subjectTitle(lesson.subjectId),
                  palette: palette,
                ),
                _Pill(label: _topicLabel, palette: palette),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.palette});
  final String label;
  final AppPalette palette;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: palette.champagne,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.outline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: palette.muted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
