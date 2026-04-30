import 'package:flutter/material.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/models/question.dart';

/// A self-contained practice question with selectable options and a
/// reveal-solution toggle.
///
/// Animations:
/// - Option borders/colors animate (200ms) when an answer is picked.
/// - The selected radio icon scales in via [AnimatedSwitcher].
/// - The worked solution panel uses [AnimatedSize] + [AnimatedOpacity]
///   to expand and fade in.
class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.accentColor,
    this.onAnswered,
  });

  final Question question;
  final int questionNumber;
  final Color accentColor;

  /// Called the first time the user picks an option for this question.
  /// Subsequent taps that change the selection do not re-fire.
  final void Function(int selectedIndex, bool isCorrect)? onAnswered;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  int? _selectedIndex;
  bool _showSolution = false;
  bool _reported = false;

  void _handleSelect(int i) {
    setState(() => _selectedIndex = i);
    if (_reported) return;
    _reported = true;
    final void Function(int, bool)? cb = widget.onAnswered;
    if (cb != null) {
      cb(i, i == widget.question.correctOptionIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final Question q = widget.question;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.outline, width: 0.6),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      widget.accentColor.withOpacity(0.22),
                      widget.accentColor.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.questionNumber}',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PRACTICE QUESTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: palette.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            q.prompt,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...List<Widget>.generate(q.options.length, (int i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                index: i,
                option: q.options[i],
                selectedIndex: _selectedIndex,
                correctIndex: q.correctOptionIndex,
                accentColor: widget.accentColor,
                onTap: () => _handleSelect(i),
              ),
            );
          }),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => setState(() => _showSolution = !_showSolution),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget c, Animation<double> a) =>
                  RotationTransition(turns: a, child: c),
              child: Icon(
                _showSolution
                    ? Icons.visibility_off_outlined
                    : Icons.lightbulb_outline_rounded,
                key: ValueKey<bool>(_showSolution),
                size: 18,
              ),
            ),
            label: Text(
              _showSolution ? 'Hide solution' : 'Reveal worked solution',
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _showSolution ? 1 : 0,
              child: _showSolution
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            widget.accentColor.withOpacity(0.10),
                            widget.accentColor.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.accentColor.withOpacity(0.20),
                        ),
                      ),
                      child: Text(
                        q.workedSolution,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.option,
    required this.selectedIndex,
    required this.correctIndex,
    required this.accentColor,
    required this.onTap,
  });

  final int index;
  final String option;
  final int? selectedIndex;
  final int correctIndex;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool answered = selectedIndex != null;
    final bool isSelected = selectedIndex == index;
    final bool isCorrect = index == correctIndex;

    Color borderColor = palette.outline;
    Color bg = palette.card;
    Color iconColor = palette.muted;
    IconData icon = Icons.radio_button_off_rounded;
    List<BoxShadow> shadow = const <BoxShadow>[];

    if (answered) {
      if (isCorrect) {
        borderColor = const Color(0xFF34A853);
        bg = const Color(0xFF34A853).withOpacity(0.06);
        iconColor = const Color(0xFF34A853);
        icon = Icons.check_circle_rounded;
        shadow = <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF34A853).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ];
      } else if (isSelected) {
        borderColor = Theme.of(context).colorScheme.error;
        bg = Theme.of(context).colorScheme.error.withOpacity(0.06);
        iconColor = Theme.of(context).colorScheme.error;
        icon = Icons.cancel_rounded;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: answered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor, width: answered ? 1.4 : 1),
            borderRadius: BorderRadius.circular(14),
            boxShadow: shadow,
          ),
          child: Row(
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (Widget c, Animation<double> a) =>
                    ScaleTransition(scale: a, child: c),
                child: Icon(
                  icon,
                  key: ValueKey<IconData>(icon),
                  size: 20,
                  color: iconColor,
                ),
              ),
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
