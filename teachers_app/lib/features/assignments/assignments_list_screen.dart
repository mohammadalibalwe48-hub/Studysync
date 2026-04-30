import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';
import 'package:studysync_syria_teachers/features/assignments/assignment_models.dart';

class AssignmentsListScreen extends StatefulWidget {
  const AssignmentsListScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  late Future<List<Assignment>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        TeacherQueries.fetchAssignmentsForClass(classId: widget.classId);
  }

  Future<void> _refresh() async {
    setState(() => _future =
        TeacherQueries.fetchAssignmentsForClass(classId: widget.classId));
    await _future;
  }

  Future<void> _confirmDelete(Assignment a) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('حذف الواجب'),
        content: Text('هل تريد حذف "${a.title}"؟ لا يمكن التراجع عن هذا.'),
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
      await TeacherQueries.deleteAssignment(assignmentId: a.id);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'الواجبات',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.className,
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<Assignment>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Assignment>> snap) {
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
                            title: 'تعذّر تحميل الواجبات',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      final List<Assignment> items =
                          snap.data ?? const <Assignment>[];
                      if (items.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'لا توجد واجبات بعد',
                            description: 'أنشئ واجبًا لطلابك لتبدأ.',
                          ),
                        ]);
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (BuildContext context, int i) {
                          final Assignment a = items[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 30),
                            child: _AssignmentCard(
                              assignment: a,
                              palette: palette,
                              onTap: () => context.push(
                                '/assignments/${a.id}/submissions',
                                extra: <String, dynamic>{
                                  'title': a.title,
                                  'classId': a.classId,
                                },
                              ),
                              onDelete: () => _confirmDelete(a),
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
                  label: 'إنشاء واجب جديد',
                  icon: Icons.add_rounded,
                  onPressed: () async {
                    final bool? created = await context.push<bool>(
                      '/classes/${widget.classId}/assignments/new',
                      extra: <String, dynamic>{
                        'className': widget.className,
                      },
                    );
                    if (created == true) await _refresh();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.palette,
    required this.onTap,
    required this.onDelete,
  });

  final Assignment assignment;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _dueLabel(DateTime? d) {
    if (d == null) return 'بدون موعد تسليم';
    final DateTime now = DateTime.now().toUtc();
    final DateTime due = d.toUtc();
    if (due.isBefore(now)) return 'انتهى الموعد';
    final Duration delta = due.difference(now);
    if (delta.inHours < 24) return 'متبقي ${delta.inHours} ساعة';
    return 'متبقي ${delta.inDays} يوم';
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
                  child: const Icon(Icons.assignment_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    assignment.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon:
                      const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'حذف',
                ),
              ],
            ),
            if (assignment.description != null &&
                assignment.description!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                assignment.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: palette.muted,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(Icons.schedule_rounded,
                    size: 14, color: palette.muted),
                const SizedBox(width: 4),
                Text(
                  _dueLabel(assignment.dueAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
