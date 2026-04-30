import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';
import 'package:studysync_syria_teachers/features/assignments/assignment_models.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  const AssignmentSubmissionsScreen({
    super.key,
    required this.assignmentId,
    required this.title,
  });

  final String assignmentId;
  final String title;

  @override
  State<AssignmentSubmissionsScreen> createState() =>
      _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState
    extends State<AssignmentSubmissionsScreen> {
  late Future<List<AssignmentSubmissionSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherQueries.fetchAssignmentSubmissions(
        assignmentId: widget.assignmentId);
  }

  Future<void> _refresh() async {
    setState(() => _future = TeacherQueries.fetchAssignmentSubmissions(
        assignmentId: widget.assignmentId));
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'التسليمات',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            widget.title,
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
                  child: FutureBuilder<List<AssignmentSubmissionSummary>>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<AssignmentSubmissionSummary>>
                            snap) {
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
                            title: 'تعذّر تحميل التسليمات',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      final List<AssignmentSubmissionSummary> items =
                          snap.data ??
                              const <AssignmentSubmissionSummary>[];
                      if (items.isEmpty) {
                        return ListView(children: const <Widget>[
                          SizedBox(height: 100),
                          EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'لا توجد تسليمات بعد',
                            description:
                                'سيظهر هنا الطلاب الذين سلّموا الواجب.',
                          ),
                        ]);
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int i) {
                          final AssignmentSubmissionSummary s = items[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 30),
                            child: _SubmissionTile(
                              submission: s, palette: palette,
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

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({required this.submission, required this.palette});
  final AssignmentSubmissionSummary submission;
  final AppPalette palette;
  @override
  Widget build(BuildContext context) {
    final int pct = (submission.accuracy * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: palette.gold,
            child: Text(
              submission.studentName.characters.first,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  submission.studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(submission.submittedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${submission.score}/${submission.total}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
