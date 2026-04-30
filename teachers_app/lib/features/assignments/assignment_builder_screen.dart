import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/constants/topic_catalog.dart';
import 'package:studysync_syria_teachers/core/supabase/queries.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';
import 'package:studysync_syria_teachers/features/assignments/assignment_models.dart';

class AssignmentBuilderScreen extends StatefulWidget {
  const AssignmentBuilderScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  @override
  State<AssignmentBuilderScreen> createState() =>
      _AssignmentBuilderScreenState();
}

class _AssignmentBuilderScreenState extends State<AssignmentBuilderScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _subjectId;
  DateTime? _dueAt;
  bool _busy = false;
  String? _error;

  final List<DraftQuestion> _questions = <DraftQuestion>[
    DraftQuestion(),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (!mounted) return;
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (!mounted) return;
    setState(() {
      _dueAt = DateTime(picked.year, picked.month, picked.day,
          t?.hour ?? 23, t?.minute ?? 59);
    });
  }

  String? _validateQuestions() {
    for (int i = 0; i < _questions.length; i++) {
      final DraftQuestion q = _questions[i];
      if (q.prompt.trim().isEmpty) {
        return 'السؤال ${i + 1}: نص السؤال فارغ.';
      }
      final List<String> nonEmpty = q.options
          .map((String o) => o.trim())
          .where((String o) => o.isNotEmpty)
          .toList();
      if (nonEmpty.length < 2) {
        return 'السؤال ${i + 1}: أضف على الأقل خيارين.';
      }
      if (q.correctIndex < 0 ||
          q.correctIndex >= q.options.length ||
          q.options[q.correctIndex].trim().isEmpty) {
        return 'السؤال ${i + 1}: اختر إجابة صحيحة موجودة.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? err = _validateQuestions();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Strip empty options before sending and re-map `correctIndex`
      // to the correct option's NEW position in the filtered list.
      // Bounds-checking alone is insufficient: if a teacher leaves an
      // option blank BEFORE the correct one, every later index shifts
      // down by one and a naive `correct >= opts.length ? 0 : correct`
      // will silently store the wrong answer.
      final List<DraftQuestion> cleaned =
          _questions.map((DraftQuestion q) {
        final List<String> trimmed =
            q.options.map((String o) => o.trim()).toList();
        final int origCorrect =
            (q.correctIndex >= 0 && q.correctIndex < trimmed.length)
                ? q.correctIndex
                : 0;
        // Build (text, wasCorrect) pairs, drop empties, then find the
        // new index of the entry that was originally correct. This
        // tolerates duplicate option texts because we mark by position
        // rather than searching by string.
        final List<MapEntry<String, bool>> pairs = <MapEntry<String, bool>>[
          for (int i = 0; i < trimmed.length; i++)
            MapEntry<String, bool>(trimmed[i], i == origCorrect),
        ];
        final List<MapEntry<String, bool>> kept = pairs
            .where((MapEntry<String, bool> e) => e.key.isNotEmpty)
            .toList();
        final List<String> opts = kept
            .map((MapEntry<String, bool> e) => e.key)
            .toList();
        int correct = kept.indexWhere(
            (MapEntry<String, bool> e) => e.value);
        // If the correct option itself was blank (validation should
        // catch this) fall back to the first kept option.
        if (correct < 0) correct = 0;
        return DraftQuestion(
          prompt: q.prompt.trim(),
          options: opts,
          correctIndex: correct,
          explanation: q.explanation.trim(),
        );
      }).toList();

      await TeacherQueries.createAssignment(
        classId: widget.classId,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        subjectId: _subjectId,
        dueAt: _dueAt,
        questions: cleaned,
      );
      if (!mounted) return;
      context.pop(true);
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
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 16, 4),
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
                            'واجب جديد',
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
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: <Widget>[
                      _section(palette, 'تفاصيل الواجب', <Widget>[
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'عنوان الواجب',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                          validator: (String? v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'الرجاء إدخال العنوان.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'وصف اختياري',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _subjectId,
                                decoration: const InputDecoration(
                                  labelText: 'المادة',
                                  prefixIcon:
                                      Icon(Icons.menu_book_rounded),
                                ),
                                items: <DropdownMenuItem<String?>>[
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('عام'),
                                  ),
                                  ...TopicCatalog.subjectTitles.entries.map(
                                    (MapEntry<String, String> e) =>
                                        DropdownMenuItem<String?>(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                  ),
                                ],
                                onChanged: (String? v) =>
                                    setState(() => _subjectId = v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: _pickDueDate,
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'موعد التسليم',
                                    prefixIcon:
                                        Icon(Icons.event_outlined),
                                  ),
                                  child: Text(
                                    _dueAt == null
                                        ? 'بدون'
                                        : '${_dueAt!.year}/${_dueAt!.month.toString().padLeft(2, '0')}/${_dueAt!.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'الأسئلة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(
                                () => _questions.add(DraftQuestion())),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('إضافة سؤال'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (int i = 0; i < _questions.length; i++)
                        Padding(
                          // Key by the DraftQuestion identity so Flutter
                          // matches each `_QuestionEditorState` to its
                          // actual question instance. Without this, the
                          // `late final` controllers initialised from
                          // `widget.question` get reused for the wrong
                          // question after a non-last question is
                          // deleted (state corruption — same class of
                          // bug as the exam-card key fix in #12).
                          key: ObjectKey(_questions[i]),
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _QuestionEditor(
                            key: ObjectKey(_questions[i]),
                            index: i,
                            question: _questions[i],
                            palette: palette,
                            canDelete: _questions.length > 1,
                            onChanged: () => setState(() {}),
                            onDelete: () =>
                                setState(() => _questions.removeAt(i)),
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      AppButton(
                        label: 'حفظ ونشر',
                        icon: Icons.check_rounded,
                        isLoading: _busy,
                        onPressed: _busy ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(AppPalette palette, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _QuestionEditor extends StatefulWidget {
  const _QuestionEditor({
    super.key,
    required this.index,
    required this.question,
    required this.palette,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final DraftQuestion question;
  final AppPalette palette;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late final TextEditingController _promptCtrl =
      TextEditingController(text: widget.question.prompt);
  late final TextEditingController _explCtrl =
      TextEditingController(text: widget.question.explanation);
  late final List<TextEditingController> _optionCtrls = widget.question.options
      .map((String o) => TextEditingController(text: o))
      .toList();

  @override
  void dispose() {
    _promptCtrl.dispose();
    _explCtrl.dispose();
    for (final TextEditingController c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _writeBack() {
    widget.question.prompt = _promptCtrl.text;
    widget.question.explanation = _explCtrl.text;
    widget.question.options = _optionCtrls
        .map((TextEditingController c) => c.text)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = widget.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.outline),
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
                  color: palette.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سؤال ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.canDelete)
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  tooltip: 'حذف',
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _promptCtrl,
            maxLines: 2,
            onChanged: (_) => _writeBack(),
            decoration: const InputDecoration(
              labelText: 'نص السؤال',
              prefixIcon: Icon(Icons.help_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _optionCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Radio<int>(
                    value: i,
                    groupValue: widget.question.correctIndex,
                    onChanged: (int? v) {
                      if (v == null) return;
                      setState(() => widget.question.correctIndex = v);
                      widget.onChanged();
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _optionCtrls[i],
                      onChanged: (_) => _writeBack(),
                      decoration: InputDecoration(
                        labelText: 'الخيار ${i + 1}',
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_optionCtrls.length > 2)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _optionCtrls[i].dispose();
                          _optionCtrls.removeAt(i);
                          if (widget.question.correctIndex >=
                              _optionCtrls.length) {
                            widget.question.correctIndex = 0;
                          }
                          _writeBack();
                        });
                        widget.onChanged();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                ],
              ),
            ),
          if (_optionCtrls.length < 6)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _optionCtrls.add(TextEditingController());
                    _writeBack();
                  });
                  widget.onChanged();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة خيار'),
              ),
            ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _explCtrl,
            onChanged: (_) => _writeBack(),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'شرح الإجابة (اختياري)',
              prefixIcon: Icon(Icons.lightbulb_outline_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
