import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/app_button.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/features/assignments/assignment_models.dart';
import 'package:studysync_syria/features/assignments/assignment_queries.dart';

/// Lets a student take a teacher-created assignment one question at a
/// time, and submit. If they have already submitted (read from the
/// passed-in [StudentAssignment]), the screen renders a read-only
/// review of their score.
class TakeAssignmentScreen extends StatefulWidget {
  const TakeAssignmentScreen({super.key, required this.assignment});

  final StudentAssignment assignment;

  @override
  State<TakeAssignmentScreen> createState() => _TakeAssignmentScreenState();
}

class _TakeAssignmentScreenState extends State<TakeAssignmentScreen> {
  late Future<List<StudentAssignmentQuestion>> _future;
  int _index = 0;
  final List<int> _answers = <int>[];
  bool _busy = false;
  String? _error;
  bool _submitted = false;
  int? _finalScore;
  int? _finalTotal;

  @override
  void initState() {
    super.initState();
    _future = StudentAssignmentQueries.fetchAssignmentQuestions(
        assignmentId: widget.assignment.id);
    _submitted = widget.assignment.isSubmitted;
    if (_submitted) {
      _finalScore = widget.assignment.submissionScore;
      _finalTotal = widget.assignment.submissionTotal;
    }
  }

  Future<void> _submit(List<StudentAssignmentQuestion> questions) async {
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (i < _answers.length && _answers[i] == questions[i].correctIndex) {
        score++;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await StudentAssignmentQueries.submitAssignment(
        assignmentId: widget.assignment.id,
        score: score,
        total: questions.length,
        answers: _answers,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitted = true;
        _finalScore = score;
        _finalTotal = questions.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: FutureBuilder<List<StudentAssignmentQuestion>>(
            future: _future,
            builder: (BuildContext context,
                AsyncSnapshot<List<StudentAssignmentQuestion>> snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'تعذّر تحميل الأسئلة',
                    description: snap.error
                        .toString()
                        .replaceFirst('Exception: ', ''),
                  ),
                );
              }
              final List<StudentAssignmentQuestion> qs =
                  snap.data ?? const <StudentAssignmentQuestion>[];
              if (qs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.help_outline_rounded,
                    title: 'لا توجد أسئلة في هذا الواجب',
                    description: 'أبلغ معلّمك إن استمر الأمر.',
                  ),
                );
              }

              if (_submitted &&
                  _finalScore != null &&
                  _finalTotal != null) {
                return _ResultView(
                  palette: palette,
                  title: widget.assignment.title,
                  score: _finalScore!,
                  total: _finalTotal!,
                  onClose: () => context.pop(true),
                );
              }

              if (_answers.length < qs.length) {
                _answers.addAll(
                    List<int>.filled(qs.length - _answers.length, -1));
              }

              final StudentAssignmentQuestion q = qs[_index];
              final bool answered = _answers[_index] >= 0;
              final bool isLast = _index == qs.length - 1;
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 16, 0),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.assignment.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'سؤال ${_index + 1} من ${qs.length}',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_index + 1) / qs.length,
                        backgroundColor: palette.outline,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.gold,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: palette.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.outline),
                          ),
                          child: Text(
                            q.prompt,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (int i = 0; i < q.options.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _OptionTile(
                              palette: palette,
                              text: q.options[i],
                              selected: _answers[_index] == i,
                              onTap: () {
                                setState(() => _answers[_index] = i);
                              },
                            ),
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: <Widget>[
                        if (_index > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => _index -= 1),
                              child: const Text('السابق'),
                            ),
                          ),
                        if (_index > 0) const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            label: isLast ? 'إرسال الواجب' : 'التالي',
                            icon: isLast
                                ? Icons.send_rounded
                                : Icons.arrow_forward_rounded,
                            isLoading: _busy,
                            onPressed: !answered || _busy
                                ? null
                                : () {
                                    if (isLast) {
                                      _submit(qs);
                                    } else {
                                      setState(() => _index += 1);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.palette,
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final AppPalette palette;
  final String text;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? palette.gold.withValues(alpha: 0.15)
              : palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? palette.gold : palette.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? palette.gold : palette.muted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.palette,
    required this.title,
    required this.score,
    required this.total,
    required this.onClose,
  });
  final AppPalette palette;
  final String title;
  final int score;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final int pct = total == 0 ? 0 : (100 * score / total).round();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: palette.goldGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 56,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'تم تسليم الواجب',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '$score / $total',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'العودة',
            icon: Icons.arrow_back_rounded,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
