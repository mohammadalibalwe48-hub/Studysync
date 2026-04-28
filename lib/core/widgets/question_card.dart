import 'package:flutter/material.dart';

import 'package:studysync_syria/core/models/question.dart';

/// A self-contained practice question with selectable options and a
/// reveal-solution toggle. State is local to this widget — answers are not
/// persisted in the frontend-only version.
class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.accentColor,
  });

  final Question question;
  final int questionNumber;
  final Color accentColor;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  int? _selectedIndex;
  bool _showSolution = false;

  @override
  Widget build(BuildContext context) {
    final Question q = widget.question;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.questionNumber}',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Practice question',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.prompt,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 14),
          ...List<Widget>.generate(q.options.length, (int i) {
            final bool isSelected = _selectedIndex == i;
            final bool isCorrect = i == q.correctOptionIndex;
            Color borderColor = Colors.black.withOpacity(0.12);
            Color bg = Colors.white;

            if (_selectedIndex != null) {
              if (isCorrect) {
                borderColor = Colors.green;
                bg = Colors.green.withOpacity(0.06);
              } else if (isSelected && !isCorrect) {
                borderColor = Colors.red;
                bg = Colors.red.withOpacity(0.06);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: isSelected
                            ? widget.accentColor
                            : Colors.black.withOpacity(0.4),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(q.options[i])),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _showSolution = !_showSolution),
            icon: Icon(
              _showSolution ? Icons.visibility_off_outlined : Icons.lightbulb_outline,
              size: 18,
            ),
            label: Text(
              _showSolution ? 'Hide solution' : 'Reveal worked solution',
            ),
          ),
          if (_showSolution)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                q.workedSolution,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}
