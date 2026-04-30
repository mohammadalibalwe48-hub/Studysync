import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/features/assignments/assignment_models.dart';
import 'package:studysync_syria/features/assignments/assignment_queries.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  late Future<List<StudentAssignment>> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentAssignmentQueries.fetchVisibleAssignments();
  }

  Future<void> _refresh() async {
    setState(() =>
        _future = StudentAssignmentQueries.fetchVisibleAssignments());
    await _future;
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
                        'الواجبات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<StudentAssignment>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<StudentAssignment>> snap) {
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
                      final List<StudentAssignment> items =
                          snap.data ?? const <StudentAssignment>[];
                      if (items.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.assignment_outlined,
                            title: 'لا توجد واجبات حاليًا',
                            description:
                                'انضم إلى صف معلّم لتظهر هنا واجباتك.',
                          ),
                        ]);
                      }
                      // Pending first, then submitted.
                      final List<StudentAssignment> pending = items
                          .where((StudentAssignment a) => !a.isSubmitted)
                          .toList();
                      final List<StudentAssignment> submitted = items
                          .where((StudentAssignment a) => a.isSubmitted)
                          .toList();
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: <Widget>[
                          if (pending.isNotEmpty) ...<Widget>[
                            _SectionHeader(
                              palette: palette,
                              title: 'بحاجة إلى الحل',
                            ),
                            for (int i = 0; i < pending.length; i++)
                              FadeSlideIn(
                                delay:
                                    Duration(milliseconds: 60 + i * 30),
                                child: _AssignmentCard(
                                  assignment: pending[i],
                                  palette: palette,
                                  onTap: () async {
                                    final bool? changed =
                                        await context.push<bool>(
                                      '/assignments/${pending[i].id}',
                                      extra: pending[i],
                                    );
                                    if (changed == true) await _refresh();
                                  },
                                ),
                              ),
                          ],
                          if (submitted.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            _SectionHeader(
                              palette: palette,
                              title: 'تم تسليمها',
                            ),
                            for (int i = 0; i < submitted.length; i++)
                              FadeSlideIn(
                                delay:
                                    Duration(milliseconds: 60 + i * 30),
                                child: _AssignmentCard(
                                  assignment: submitted[i],
                                  palette: palette,
                                  onTap: () => context.push(
                                    '/assignments/${submitted[i].id}',
                                    extra: submitted[i],
                                  ),
                                ),
                              ),
                          ],
                        ],
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.palette, required this.title});
  final AppPalette palette;
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: palette.muted,
          letterSpacing: 0.4,
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
  });
  final StudentAssignment assignment;
  final AppPalette palette;
  final VoidCallback onTap;

  String _dueLabel() {
    if (assignment.dueAt == null) return 'بدون موعد تسليم';
    final DateTime now = DateTime.now().toUtc();
    final DateTime due = assignment.dueAt!.toUtc();
    if (due.isBefore(now)) return 'انتهى الموعد';
    final Duration delta = due.difference(now);
    if (delta.inHours < 24) return 'متبقي ${delta.inHours} ساعة';
    return 'متبقي ${delta.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final bool submitted = assignment.isSubmitted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.outline),
            boxShadow: palette.cardShadow,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: palette.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  submitted
                      ? Icons.check_circle_outline_rounded
                      : Icons.assignment_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      <String>[
                        if (assignment.className != null)
                          assignment.className!,
                        _dueLabel(),
                      ].join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (submitted)
                Text(
                  '${assignment.submissionScore}/${assignment.submissionTotal}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
