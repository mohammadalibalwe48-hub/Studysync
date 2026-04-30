import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/question.dart';
import 'package:studysync_syria/core/models/subject.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/supabase/queries.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';

/// شاشة "اختبار سريع" — تختار حتى 10 أسئلة عشوائياً من جميع الدروس
/// (الفيزياء + الكيمياء)، تعرضها واحداً تلو الآخر، ثم تظهر النتيجة مع
/// إمكانية إعادة الاختبار أو مراجعة الأخطاء.
class QuickQuizScreen extends StatefulWidget {
  const QuickQuizScreen({super.key});

  @override
  State<QuickQuizScreen> createState() => _QuickQuizScreenState();
}

class _QuickQuizScreenState extends State<QuickQuizScreen> {
  /// الحدّ الأعلى لعدد أسئلة الاختبار السريع.
  static const int _maxQuestions = 10;

  late List<_QuizItem> _items;
  int _index = 0;
  int? _selectedOption;
  bool _revealed = false;
  final List<_QuizAnswer> _answers = <_QuizAnswer>[];
  bool _showReviewWrong = false;

  @override
  void initState() {
    super.initState();
    _items = _buildQuiz();
  }

  List<_QuizItem> _buildQuiz() {
    final List<_QuizItem> all = <_QuizItem>[];
    for (final Topic topic in Curriculum.topics) {
      final Subject? subject = Curriculum.subjectById(topic.subjectId);
      if (subject == null) continue;
      for (final Question q in topic.questions) {
        all.add(_QuizItem(question: q, topic: topic, subject: subject));
      }
    }
    all.shuffle(Random());
    return all.take(_maxQuestions).toList(growable: false);
  }

  void _restart() {
    setState(() {
      _items = _buildQuiz();
      _index = 0;
      _selectedOption = null;
      _revealed = false;
      _answers.clear();
      _showReviewWrong = false;
    });
  }

  Future<void> _selectOption(int i) async {
    if (_revealed) return;
    final _QuizItem item = _items[_index];
    final bool correct = i == item.question.correctOptionIndex;
    setState(() {
      _selectedOption = i;
      _revealed = true;
      _answers.add(_QuizAnswer(
        item: item,
        selectedIndex: i,
        isCorrect: correct,
      ));
    });

    // أفضل جهد ممكن لحفظ المحاولة على Supabase. لا نقاطع تجربة الطالب
    // إن فشل الحفظ.
    try {
      await StudySyncQueries.saveQuestionAttempt(
        questionId: item.question.id,
        selectedOptionIndex: i,
        isCorrect: correct,
        subjectId: item.subject.id,
        topicId: item.topic.id,
      );
    } catch (_) {
      // تجاهل الخطأ بصمت — كانت محاولة "أفضل جهد ممكن" فقط.
    }
  }

  void _next() {
    if (_index >= _items.length - 1) {
      setState(() => _index = _items.length);
      return;
    }
    setState(() {
      _index += 1;
      _selectedOption = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _BackBar(
                title: 'اختبار سريع',
                onBack: () => context.go('/home'),
              ),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.quiz_outlined,
        title: 'لا توجد أسئلة متاحة',
        description: 'سيتم توفير أسئلة قريباً.',
      );
    }
    if (_index >= _items.length) {
      return _ResultView(
        answers: _answers,
        showWrong: _showReviewWrong,
        onRetry: _restart,
        onReviewWrong: () => setState(() => _showReviewWrong = true),
        onBack: () => setState(() => _showReviewWrong = false),
      );
    }
    return _QuestionView(
      item: _items[_index],
      total: _items.length,
      indexZeroBased: _index,
      selectedOption: _selectedOption,
      revealed: _revealed,
      onSelect: _selectOption,
      onNext: _next,
    );
  }
}

class _QuizItem {
  const _QuizItem({
    required this.question,
    required this.topic,
    required this.subject,
  });

  final Question question;
  final Topic topic;
  final Subject subject;
}

class _QuizAnswer {
  const _QuizAnswer({
    required this.item,
    required this.selectedIndex,
    required this.isCorrect,
  });

  final _QuizItem item;
  final int selectedIndex;
  final bool isCorrect;
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.item,
    required this.total,
    required this.indexZeroBased,
    required this.selectedOption,
    required this.revealed,
    required this.onSelect,
    required this.onNext,
  });

  final _QuizItem item;
  final int total;
  final int indexZeroBased;
  final int? selectedOption;
  final bool revealed;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Color accent = item.subject.color;
    final Question q = item.question;
    final double progress = (indexZeroBased + 1) / total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: <Widget>[
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.outline, width: 0.6),
              boxShadow: palette.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.subject.name,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'سؤال ${indexZeroBased + 1} من $total',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: accent.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  q.prompt,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ...List<Widget>.generate(q.options.length, (int i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnswerTile(
                      index: i,
                      option: q.options[i],
                      selectedIndex: selectedOption,
                      correctIndex: q.correctOptionIndex,
                      revealed: revealed,
                      accentColor: accent,
                      onTap: () => onSelect(i),
                    ),
                  );
                }),
                if (revealed) ...<Widget>[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withOpacity(0.20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              selectedOption ==
                                      q.correctOptionIndex
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: selectedOption ==
                                      q.correctOptionIndex
                                  ? const Color(0xFF34A853)
                                  : Theme.of(context).colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedOption == q.correctOptionIndex
                                  ? 'إجابة صحيحة'
                                  : 'إجابة خاطئة',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selectedOption ==
                                        q.correctOptionIndex
                                    ? const Color(0xFF34A853)
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.workedSolution,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: revealed ? onNext : null,
                    child: Text(
                      indexZeroBased + 1 >= total ? 'إنهاء' : 'التالي',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.index,
    required this.option,
    required this.selectedIndex,
    required this.correctIndex,
    required this.revealed,
    required this.accentColor,
    required this.onTap,
  });

  final int index;
  final String option;
  final int? selectedIndex;
  final int correctIndex;
  final bool revealed;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool isSelected = selectedIndex == index;
    final bool isCorrect = index == correctIndex;
    Color border = palette.outline;
    Color bg = palette.card;
    Color iconColor = palette.muted;
    IconData icon = Icons.radio_button_off_rounded;
    if (revealed) {
      if (isCorrect) {
        border = const Color(0xFF34A853);
        bg = const Color(0xFF34A853).withOpacity(0.06);
        iconColor = const Color(0xFF34A853);
        icon = Icons.check_circle_rounded;
      } else if (isSelected) {
        border = Theme.of(context).colorScheme.error;
        bg = Theme.of(context).colorScheme.error.withOpacity(0.06);
        iconColor = Theme.of(context).colorScheme.error;
        icon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      border = accentColor;
      bg = accentColor.withOpacity(0.04);
      iconColor = accentColor;
      icon = Icons.radio_button_checked_rounded;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: revealed ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: border, width: revealed ? 1.4 : 1),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.answers,
    required this.showWrong,
    required this.onRetry,
    required this.onReviewWrong,
    required this.onBack,
  });

  final List<_QuizAnswer> answers;
  final bool showWrong;
  final VoidCallback onRetry;
  final VoidCallback onReviewWrong;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final int score =
        answers.where((_QuizAnswer a) => a.isCorrect).length;
    final int total = answers.length;
    final int accuracy =
        total == 0 ? 0 : ((score / total) * 100).round();
    final List<_QuizAnswer> wrong = answers
        .where((_QuizAnswer a) => !a.isCorrect)
        .toList(growable: false);

    if (showWrong) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onBack,
                icon:
                    const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              ),
              Text(
                'مراجعة الأخطاء',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (wrong.isEmpty)
            const EmptyState(
              compact: true,
              icon: Icons.celebration_rounded,
              title: 'لا أخطاء!',
              description: 'أحسنت — أجبت على كل الأسئلة بشكل صحيح.',
            )
          else
            for (final _QuizAnswer a in wrong)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _WrongAnswerCard(answer: a),
              ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: <Widget>[
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: palette.goldGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: palette.goldGlow,
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                const Text(
                  'انتهى الاختبار 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _ResultStat(
                      label: 'النتيجة',
                      value: '$score / $total',
                    ),
                    _ResultStat(
                      label: 'نسبة الصح',
                      value: '$accuracy٪',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة الاختبار'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: wrong.isEmpty ? null : onReviewWrong,
                  icon: const Icon(Icons.fact_check_rounded),
                  label: const Text('مراجعة الأخطاء'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WrongAnswerCard extends StatelessWidget {
  const _WrongAnswerCard({required this.answer});

  final _QuizAnswer answer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Question q = answer.item.question;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: answer.item.subject.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  answer.item.subject.name,
                  style: TextStyle(
                    color: answer.item.subject.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.item.topic.title,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.prompt,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _AnswerLine(
            label: 'إجابتك:',
            text: q.options[answer.selectedIndex],
            tone: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 6),
          _AnswerLine(
            label: 'الإجابة الصحيحة:',
            text: q.options[q.correctOptionIndex],
            tone: const Color(0xFF34A853),
          ),
          const SizedBox(height: 10),
          Text(
            q.workedSolution,
            style: TextStyle(
              fontSize: 13,
              color: palette.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.text,
    required this.tone,
  });

  final String label;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: tone,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, height: 1.5),
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
