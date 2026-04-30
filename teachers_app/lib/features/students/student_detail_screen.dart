import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/constants/topic_catalog.dart';
import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.displayName,
  });

  final String studentId;
  final String displayName;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _Snapshot {
  _Snapshot(this.progress, this.attempts, this.studyMinutes);
  final List<StudentProgressDetail> progress;
  final List<QuestionAttemptDetail> attempts;
  final int studyMinutes;
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Future<_Snapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Snapshot> _load() async {
    final List<StudentProgressDetail> progress =
        await TeacherQueries.fetchStudentProgress(studentId: widget.studentId);
    final List<QuestionAttemptDetail> attempts =
        await TeacherQueries.fetchStudentRecentAttempts(
      studentId: widget.studentId,
      limit: 25,
    );
    final int minutes = await TeacherQueries.fetchStudentStudyMinutes(
      studentId: widget.studentId,
    );
    return _Snapshot(progress, attempts, minutes);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
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
              _BackBar(
                title: widget.displayName,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<_Snapshot>(
                    future: _future,
                    builder: (BuildContext context,
                        AsyncSnapshot<_Snapshot> snap) {
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
                            title: 'تعذّر تحميل تفاصيل الطالب',
                            description: snap.error
                                .toString()
                                .replaceFirst('Exception: ', ''),
                          ),
                        ]);
                      }
                      final _Snapshot data = snap.data!;
                      final int correct = data.progress.fold<int>(
                          0, (int a, StudentProgressDetail p) => a + p.correctAnswers);
                      final int total = data.progress.fold<int>(
                          0, (int a, StudentProgressDetail p) => a + p.totalAnswers);
                      final int completed = data.progress
                          .where((StudentProgressDetail p) => p.completed)
                          .length;

                      return ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 8, 20, 28),
                        children: <Widget>[
                          FadeSlideIn(
                            child: _StatsRow(
                              palette: palette,
                              completed: completed,
                              tracked: data.progress.length,
                              correct: correct,
                              total: total,
                              minutes: data.studyMinutes,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionTitle('التقدّم حسب الموضوع'),
                          const SizedBox(height: 8),
                          if (data.progress.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: EmptyState(
                                icon: Icons.menu_book_outlined,
                                title: 'لا يوجد تقدّم بعد',
                                description:
                                    'سيظهر تقدّم الطالب فور بدئه بالحلّ.',
                              ),
                            ),
                          ...data.progress.map(
                            (StudentProgressDetail p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ProgressRow(
                                  detail: p, palette: palette),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionTitle('آخر المحاولات'),
                          const SizedBox(height: 8),
                          if (data.attempts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('لا توجد محاولات حديثة.'),
                            ),
                          ...data.attempts.take(15).map(
                                (QuestionAttemptDetail a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _AttemptRow(
                                      attempt: a, palette: palette),
                                ),
                              ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.palette,
    required this.completed,
    required this.tracked,
    required this.correct,
    required this.total,
    required this.minutes,
  });

  final AppPalette palette;
  final int completed;
  final int tracked;
  final int correct;
  final int total;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final int completionPct =
        tracked == 0 ? 0 : ((completed / tracked) * 100).round();
    final int accPct =
        total == 0 ? 0 : ((correct / total) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.outline),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _stat(palette, 'الإنجاز', '$completionPct%')),
          Container(
              width: 1,
              height: 40,
              color: palette.outline.withOpacity(0.6)),
          Expanded(child: _stat(palette, 'نسبة الصح', '$accPct%')),
          Container(
              width: 1,
              height: 40,
              color: palette.outline.withOpacity(0.6)),
          Expanded(child: _stat(palette, 'الدقائق', '$minutes')),
        ],
      ),
    );
  }

  Widget _stat(AppPalette palette, String label, String value) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: palette.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.detail, required this.palette});
  final StudentProgressDetail detail;
  final AppPalette palette;
  @override
  Widget build(BuildContext context) {
    final int accPct = (detail.accuracy * 100).round();
    final String topicTitle = TopicCatalog.topicTitle(detail.topicId);
    final String subjectTitle = TopicCatalog.subjectTitle(detail.subjectId);
    final Color subjectColor = detail.subjectId == TopicCatalog.physicsId
        ? const Color(0xFF1E73E8)
        : const Color(0xFF7B3FE4);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              detail.subjectId == TopicCatalog.physicsId
                  ? Icons.bolt_rounded
                  : Icons.science_rounded,
              color: subjectColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  topicTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$subjectTitle • ${detail.completed ? "مكتمل" : "قيد الدراسة"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '$accPct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${detail.correctAnswers}/${detail.totalAnswers}',
                style: TextStyle(
                  fontSize: 11,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.attempt, required this.palette});
  final QuestionAttemptDetail attempt;
  final AppPalette palette;
  @override
  Widget build(BuildContext context) {
    final Color tone = attempt.isCorrect
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outline),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            attempt.isCorrect
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: tone,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attempt.topicId == null
                  ? attempt.questionId
                  : TopicCatalog.topicTitle(attempt.topicId!),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            _relative(attempt.createdAt),
            style: TextStyle(fontSize: 11, color: palette.muted),
          ),
        ],
      ),
    );
  }

  String _relative(DateTime when) {
    final Duration delta = DateTime.now().toUtc().difference(when.toUtc());
    if (delta.inMinutes < 1) return 'الآن';
    if (delta.inMinutes < 60) return 'منذ ${delta.inMinutes} د';
    if (delta.inHours < 24) return 'منذ ${delta.inHours} س';
    return 'منذ ${delta.inDays} ي';
  }
}
