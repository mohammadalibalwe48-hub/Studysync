import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/features/curriculum/custom_lesson_models.dart';
import 'package:studysync_syria/features/curriculum/custom_lesson_queries.dart';

/// Collapsible card that renders a single teacher-authored lesson under
/// the bundled lesson on the topic detail screen. Matches the visual
/// language of `LessonView` / `KeyIdeasSection` / `WorkedExampleSection`
/// without reusing their internal layouts (so we don't have to thread
/// fake `Topic` objects through them).
class CustomLessonCard extends StatefulWidget {
  const CustomLessonCard({
    super.key,
    required this.lesson,
    required this.accentColor,
  });

  final StudentCustomLesson lesson;
  final Color accentColor;

  @override
  State<CustomLessonCard> createState() => _CustomLessonCardState();
}

class _CustomLessonCardState extends State<CustomLessonCard> {
  bool _expanded = false;
  Future<List<StudentCustomLessonQuestion>>? _questionsFuture;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded && _questionsFuture == null) {
        _questionsFuture = CustomLessonQueries.fetchLessonQuestions(
          lessonId: widget.lesson.id,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final StudentCustomLesson lesson = widget.lesson;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          widget.accentColor,
                          widget.accentColor.withOpacity(0.30),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'درس من المعلّم',
                            style: TextStyle(
                              color: widget.accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.lessonTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (lesson.teacherDisplayName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'أعدّه: ${lesson.teacherDisplayName!}',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (lesson.bodyMarkdown.trim().isNotEmpty) ...<Widget>[
                    Text(
                      lesson.bodyMarkdown,
                      style:
                          const TextStyle(fontSize: 15, height: 1.7),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (lesson.keyIdeas.isNotEmpty) ...<Widget>[
                    _KeyIdeasInline(
                      ideas: lesson.keyIdeas,
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (lesson.workedExampleMarkdown != null &&
                      lesson.workedExampleMarkdown!.trim().isNotEmpty) ...<Widget>[
                    _WorkedExampleInline(
                      content: lesson.workedExampleMarkdown!,
                      accentColor: widget.accentColor,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _LessonQuestions(
                    future: _questionsFuture!,
                    accentColor: widget.accentColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyIdeasInline extends StatelessWidget {
  const _KeyIdeasInline({
    required this.ideas,
    required this.accentColor,
  });

  final List<String> ideas;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.lightbulb_rounded,
                color: accentColor, size: 18),
            const SizedBox(width: 6),
            Text(
              'القوانين والأفكار المهمة',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < ideas.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ideas[i],
                  style: const TextStyle(fontSize: 14, height: 1.55),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WorkedExampleInline extends StatelessWidget {
  const _WorkedExampleInline({
    required this.content,
    required this.accentColor,
  });

  final String content;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.functions_rounded,
                  color: accentColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'مثال محلول',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _LessonQuestions extends StatelessWidget {
  const _LessonQuestions({
    required this.future,
    required this.accentColor,
  });

  final Future<List<StudentCustomLessonQuestion>> future;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StudentCustomLessonQuestion>>(
      future: future,
      builder: (BuildContext context,
          AsyncSnapshot<List<StudentCustomLessonQuestion>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        if (snap.hasError) {
          return Text(
            snap.error.toString().replaceFirst('Exception: ', ''),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 13,
            ),
          );
        }
        final List<StudentCustomLessonQuestion> qs =
            snap.data ?? const <StudentCustomLessonQuestion>[];
        if (qs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.quiz_outlined, color: accentColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  'أسئلة المعلّم',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < qs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CustomLessonQuestionTile(
                  index: i,
                  question: qs[i],
                  accentColor: accentColor,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CustomLessonQuestionTile extends StatefulWidget {
  const _CustomLessonQuestionTile({
    required this.index,
    required this.question,
    required this.accentColor,
  });

  final int index;
  final StudentCustomLessonQuestion question;
  final Color accentColor;

  @override
  State<_CustomLessonQuestionTile> createState() =>
      _CustomLessonQuestionTileState();
}

class _CustomLessonQuestionTileState
    extends State<_CustomLessonQuestionTile> {
  int? _selected;

  bool get _revealed => _selected != null;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.champagne,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'سؤال ${widget.index + 1}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: widget.accentColor,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.question.prompt,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < widget.question.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _OptionRow(
                index: i,
                label: widget.question.options[i],
                selected: _selected == i,
                revealed: _revealed,
                isCorrect: i == widget.question.correctIndex,
                onTap: _revealed
                    ? null
                    : () => setState(() => _selected = i),
                accentColor: widget.accentColor,
              ),
            ),
          if (_revealed && widget.question.explanation != null &&
              widget.question.explanation!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.outline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: widget.accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.question.explanation!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.index,
    required this.label,
    required this.selected,
    required this.revealed,
    required this.isCorrect,
    required this.onTap,
    required this.accentColor,
  });

  final int index;
  final String label;
  final bool selected;
  final bool revealed;
  final bool isCorrect;
  final VoidCallback? onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Color border = palette.outline;
    Color bg = scheme.surface;
    if (revealed && isCorrect) {
      border = Colors.green.shade400;
      bg = Colors.green.withOpacity(0.08);
    } else if (revealed && selected && !isCorrect) {
      border = scheme.error;
      bg = scheme.error.withOpacity(0.08);
    } else if (selected) {
      border = accentColor;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? accentColor.withOpacity(0.18)
                    : Colors.transparent,
                border: Border.all(
                  color: selected ? accentColor : palette.outline,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                String.fromCharCode(0x0623 + index),
                // 0x0623 = ا. We just need a visually distinct
                // single-character bullet; switch to digit if rendering
                // looks off on some devices.
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? accentColor : palette.muted,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (revealed && isCorrect)
              Icon(Icons.check_circle_rounded,
                  color: Colors.green.shade600, size: 18),
            if (revealed && selected && !isCorrect)
              Icon(Icons.cancel_rounded, color: scheme.error, size: 18),
          ],
        ),
      ),
    );
  }
}
