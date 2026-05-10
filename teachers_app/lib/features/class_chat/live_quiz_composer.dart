import 'package:flutter/material.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';

// Emerald used to highlight the "correct answer" picker since the
// warm-gold AppPalette has no dedicated success colour.
const Color _kOnlineGreen = Color(0xFF2F8F4E);

/// Bottom-sheet style composer for a teacher-pushed live quiz.
/// Returns a `_QuizDraft` on confirm, or null on cancel.
class LiveQuizComposer extends StatefulWidget {
  const LiveQuizComposer({super.key});

  @override
  State<LiveQuizComposer> createState() => _LiveQuizComposerState();
}

class LiveQuizDraft {
  const LiveQuizDraft({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class _LiveQuizComposerState extends State<LiveQuizComposer> {
  final TextEditingController _prompt = TextEditingController();
  final List<TextEditingController> _opts = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correct = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _prompt.dispose();
    for (final TextEditingController c in _opts) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit {
    if (_prompt.text.trim().isEmpty) return false;
    int filled = 0;
    for (final TextEditingController c in _opts) {
      if (c.text.trim().isNotEmpty) filled += 1;
    }
    if (filled < 2) return false;
    if (_opts[_correct].text.trim().isEmpty) return false;
    return true;
  }

  void _submit() {
    if (!_canSubmit || _submitting) return;
    setState(() => _submitting = true);
    final List<String> opts = _opts
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
    int correctInFiltered = 0;
    int seen = 0;
    for (int i = 0; i < _opts.length; i++) {
      if (_opts[i].text.trim().isEmpty) continue;
      if (i == _correct) {
        correctInFiltered = seen;
        break;
      }
      seen += 1;
    }
    Navigator.of(context).pop(LiveQuizDraft(
      prompt: _prompt.text.trim(),
      options: opts,
      correctIndex: correctInFiltered,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: palette.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'إنشاء اختبار مباشر',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _prompt,
                minLines: 2,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'نص السؤال',
                  hintText: 'مثال: ما وحدة قياس التيار الكهربائي؟',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'الخيارات (حدد الإجابة الصحيحة)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 8),
              ...List<Widget>.generate(_opts.length, (int i) {
                final bool isCorrect = _correct == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => setState(() => _correct = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? _kOnlineGreen
                                : palette.outline.withOpacity(0.30),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCorrect
                                  ? _kOnlineGreen
                                  : palette.outline,
                            ),
                          ),
                          child: Icon(
                            isCorrect
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            color: isCorrect ? Colors.white : palette.muted,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _opts[i],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'الخيار ${String.fromCharCode(65 + i)}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: palette.outline),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _submitting ? 'جارٍ النشر…' : 'بثّ السؤال للصف',
                      icon: Icons.bolt_rounded,
                      onPressed: _canSubmit && !_submitting ? _submit : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
