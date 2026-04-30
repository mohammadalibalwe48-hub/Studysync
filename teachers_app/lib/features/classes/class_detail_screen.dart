import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';

class ClassDetailScreen extends StatefulWidget {
  const ClassDetailScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late Future<List<StudentRosterEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherQueries.fetchClassRoster(classId: widget.classId);
  }

  Future<void> _refresh() async {
    setState(() =>
        _future = TeacherQueries.fetchClassRoster(classId: widget.classId));
    await _future;
  }

  Future<void> _confirmRemove(StudentRosterEntry entry) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('إزالة الطالب'),
          content: Text(
              'هل تريد إزالة ${entry.profile.displayName} من هذا الصف؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('إزالة'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await TeacherQueries.removeStudentFromClass(
        classId: widget.classId,
        studentId: entry.profile.userId,
      );
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
              _BackBar(
                title: widget.className,
                onBack: () => context.go('/classes'),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<StudentRosterEntry>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<StudentRosterEntry>> snap) {
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
                            title: 'تعذّر تحميل القائمة',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      final List<StudentRosterEntry> roster =
                          snap.data ?? const <StudentRosterEntry>[];
                      if (roster.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.group_outlined,
                            title: 'لا يوجد طلاب بعد',
                            description:
                                'شارك رمز الانضمام مع طلابك ليظهروا هنا.',
                          ),
                        ]);
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: roster.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int i) {
                          final StudentRosterEntry e = roster[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 30),
                            child: _StudentTile(
                              entry: e,
                              palette: palette,
                              onTap: () => context.push(
                                '/students/${e.profile.userId}',
                                extra: <String, dynamic>{
                                  'name': e.profile.displayName,
                                },
                              ),
                              onRemove: () => _confirmRemove(e),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_rounded),
            tooltip: 'رجوع',
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.entry,
    required this.palette,
    required this.onTap,
    required this.onRemove,
  });

  final StudentRosterEntry entry;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  String _lastActiveLabel(DateTime? when) {
    if (when == null) return 'لم يبدأ بعد';
    final Duration delta = DateTime.now().toUtc().difference(when.toUtc());
    if (delta.inMinutes < 1) return 'نشيط الآن';
    if (delta.inMinutes < 60) return 'منذ ${delta.inMinutes} دقيقة';
    if (delta.inHours < 24) return 'منذ ${delta.inHours} ساعة';
    if (delta.inDays < 7) return 'منذ ${delta.inDays} يوم';
    return 'قبل ${delta.inDays ~/ 7} أسابيع';
  }

  @override
  Widget build(BuildContext context) {
    final int accuracyPct = (entry.accuracy * 100).round();
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: palette.gold,
                  child: Text(
                    entry.profile.displayName.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entry.profile.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _lastActiveLabel(entry.lastActiveAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.person_remove_outlined, size: 20),
                  tooltip: 'إزالة',
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    return Stack(
                      children: <Widget>[
                        Container(color: palette.champagne),
                        Container(
                          width: c.maxWidth *
                              entry.completionPercent.clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                            gradient: palette.goldGradient,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _stat('الإنجاز',
                    '${(entry.completionPercent * 100).round()}%', palette),
                const SizedBox(width: 12),
                _stat('نسبة الصح', '$accuracyPct%', palette),
                const SizedBox(width: 12),
                _stat('الدقائق', '${entry.studyMinutes}', palette),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, AppPalette palette) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: palette.champagne,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: palette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
