import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/constants/topic_catalog.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/app_button.dart';
import 'package:studysync_syria_teachers/features/assignments/assignment_models.dart';
import 'package:studysync_syria_teachers/features/curriculum/curriculum_models.dart';
import 'package:studysync_syria_teachers/features/curriculum/curriculum_queries.dart';

/// Sentinel value used in the topic dropdown to mean "I want to add a
/// brand-new topic that isn't in the catalog". Picking this reveals a
/// free-text field for [topic_title].
const String _kNewTopicSentinel = '__new__';

class LessonEditorScreen extends StatefulWidget {
  const LessonEditorScreen({super.key, this.existing});

  /// `null` → create flow. Non-null → edit flow that pre-fills the
  /// fields and calls update on save.
  final CustomLesson? existing;

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  final TextEditingController _lessonTitleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  final TextEditingController _newTopicTitleCtrl = TextEditingController();
  final TextEditingController _workedExampleCtrl = TextEditingController();
  final TextEditingController _newKeyIdeaCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String _subjectId;

  /// Either a real `topic_id` from [TopicCatalog.topicTitles], or
  /// [_kNewTopicSentinel] when the teacher is introducing a new topic.
  late String _topicChoice;

  final List<String> _keyIdeas = <String>[];
  final List<DraftQuestion> _questions = <DraftQuestion>[DraftQuestion()];

  bool _busy = false;
  bool _loadingExistingQuestions = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final CustomLesson? existing = widget.existing;
    _subjectId = existing?.subjectId ?? TopicCatalog.physicsId;
    if (existing == null) {
      _topicChoice = _kNewTopicSentinel;
    } else {
      final String? id = existing.topicId;
      if (id != null && TopicCatalog.topicTitles.containsKey(id)) {
        _topicChoice = id;
      } else {
        _topicChoice = _kNewTopicSentinel;
        _newTopicTitleCtrl.text = existing.topicTitle ?? '';
      }
      _lessonTitleCtrl.text = existing.lessonTitle;
      _bodyCtrl.text = existing.bodyMarkdown;
      _workedExampleCtrl.text = existing.workedExampleMarkdown ?? '';
      _keyIdeas.addAll(existing.keyIdeas);
      _loadExistingQuestions(existing.id);
    }
  }

  @override
  void dispose() {
    _lessonTitleCtrl.dispose();
    _bodyCtrl.dispose();
    _newTopicTitleCtrl.dispose();
    _workedExampleCtrl.dispose();
    _newKeyIdeaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingQuestions(String lessonId) async {
    setState(() => _loadingExistingQuestions = true);
    try {
      final List<CustomLessonQuestion> rows =
          await CurriculumQueries.fetchLessonQuestions(lessonId: lessonId);
      if (!mounted) return;
      setState(() {
        _questions
          ..clear()
          ..addAll(rows.map((CustomLessonQuestion q) => DraftQuestion(
                prompt: q.prompt,
                options: List<String>.from(q.options),
                correctIndex: q.correctIndex,
                explanation: q.explanation ?? '',
              )));
        if (_questions.isEmpty) _questions.add(DraftQuestion());
        _loadingExistingQuestions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingExistingQuestions = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String? _validateQuestions() {
    for (int i = 0; i < _questions.length; i++) {
      final DraftQuestion q = _questions[i];
      if (q.prompt.trim().isEmpty) {
        // An empty question is fine if it is the only one and the rest
        // of the lesson has content (lessons can be lecture-only).
        if (_questions.length == 1) return null;
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

  /// Strip empty options before sending and re-map [correctIndex] to
  /// the kept option's new position. Same fix-up logic as the
  /// assignment builder — see the comment block in
  /// `assignment_builder_screen.dart::_submit` for the rationale.
  List<DraftQuestion> _cleanedQuestions() {
    return _questions
        .where((DraftQuestion q) => q.prompt.trim().isNotEmpty)
        .map((DraftQuestion q) {
      final List<String> trimmed =
          q.options.map((String o) => o.trim()).toList();
      final int origCorrect =
          (q.correctIndex >= 0 && q.correctIndex < trimmed.length)
              ? q.correctIndex
              : 0;
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
        (MapEntry<String, bool> e) => e.value,
      );
      if (correct < 0) correct = 0;
      return DraftQuestion(
        prompt: q.prompt.trim(),
        options: opts,
        correctIndex: correct,
        explanation: q.explanation.trim(),
      );
    }).toList();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? err = _validateQuestions();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final bool isNewTopic = _topicChoice == _kNewTopicSentinel;
    if (isNewTopic && _newTopicTitleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'الرجاء إدخال عنوان الموضوع الجديد.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final List<DraftQuestion> cleaned = _cleanedQuestions();
      final String? topicId = isNewTopic ? null : _topicChoice;
      final String? topicTitle =
          isNewTopic ? _newTopicTitleCtrl.text.trim() : null;
      final String workedExample = _workedExampleCtrl.text.trim();
      final CustomLesson lesson;
      if (widget.existing == null) {
        lesson = await CurriculumQueries.createLesson(
          subjectId: _subjectId,
          topicId: topicId,
          topicTitle: topicTitle,
          lessonTitle: _lessonTitleCtrl.text,
          bodyMarkdown: _bodyCtrl.text,
          keyIdeas: _keyIdeas,
          workedExampleMarkdown:
              workedExample.isEmpty ? null : workedExample,
        );
      } else {
        lesson = await CurriculumQueries.updateLesson(
          lessonId: widget.existing!.id,
          subjectId: _subjectId,
          topicId: topicId,
          topicTitle: topicTitle,
          lessonTitle: _lessonTitleCtrl.text,
          bodyMarkdown: _bodyCtrl.text,
          keyIdeas: _keyIdeas,
          workedExampleMarkdown:
              workedExample.isEmpty ? null : workedExample,
        );
      }
      await CurriculumQueries.setLessonQuestions(
        lessonId: lesson.id,
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
    final bool isEdit = widget.existing != null;
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
                      child: Text(
                        isEdit ? 'تعديل درس' : 'درس جديد',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loadingExistingQuestions)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: LinearProgressIndicator(),
                ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: <Widget>[
                      _section(palette, 'تفاصيل الدرس', <Widget>[
                        DropdownButtonFormField<String>(
                          value: _subjectId,
                          decoration: const InputDecoration(
                            labelText: 'المادة',
                            prefixIcon: Icon(Icons.menu_book_rounded),
                          ),
                          items: <DropdownMenuItem<String>>[
                            for (final MapEntry<String, String> e
                                in TopicCatalog.subjectTitles.entries)
                              DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                          ],
                          onChanged: (String? v) {
                            if (v == null) return;
                            setState(() => _subjectId = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _topicChoice,
                          decoration: const InputDecoration(
                            labelText: 'الموضوع',
                            prefixIcon: Icon(Icons.topic_outlined),
                          ),
                          items: <DropdownMenuItem<String>>[
                            for (final MapEntry<String, String> e
                                in TopicCatalog.topicTitles.entries)
                              DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            const DropdownMenuItem<String>(
                              value: _kNewTopicSentinel,
                              child: Text('+ موضوع جديد'),
                            ),
                          ],
                          onChanged: (String? v) {
                            if (v == null) return;
                            setState(() => _topicChoice = v);
                          },
                        ),
                        if (_topicChoice == _kNewTopicSentinel) ...<Widget>[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newTopicTitleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'عنوان الموضوع الجديد',
                              prefixIcon: Icon(Icons.add_rounded),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lessonTitleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'عنوان الدرس',
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
                          controller: _bodyCtrl,
                          maxLines: 8,
                          minLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'نص الدرس',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 18),
                      _section(palette, 'القوانين والأفكار المهمة',
                          <Widget>[
                        _KeyIdeasEditor(
                          ideas: _keyIdeas,
                          controller: _newKeyIdeaCtrl,
                          palette: palette,
                          onAdd: (String text) {
                            final String trimmed = text.trim();
                            if (trimmed.isEmpty) return;
                            setState(() {
                              _keyIdeas.add(trimmed);
                              _newKeyIdeaCtrl.clear();
                            });
                          },
                          onRemove: (int i) =>
                              setState(() => _keyIdeas.removeAt(i)),
                        ),
                      ]),
                      const SizedBox(height: 18),
                      _section(palette, 'مثال محلول (اختياري)',
                          <Widget>[
                        TextFormField(
                          controller: _workedExampleCtrl,
                          maxLines: 6,
                          minLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'نص المثال',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.functions_rounded),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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
                          // Same ObjectKey trick as assignment builder
                          // — see comment in
                          // `assignment_builder_screen.dart` near line
                          // 316. Without this, deleting a non-last
                          // question reuses the wrong controller.
                          key: ObjectKey(_questions[i]),
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _QuestionEditor(
                            key: ObjectKey(_questions[i]),
                            index: i,
                            question: _questions[i],
                            palette: palette,
                            canDelete: _questions.length > 1,
                            onChanged: () => setState(() {}),
                            onDelete: () => setState(
                                () => _questions.removeAt(i)),
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      AppButton(
                        label: isEdit ? 'حفظ التعديلات' : 'حفظ ونشر',
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

  Widget _section(
    AppPalette palette,
    String title,
    List<Widget> children,
  ) {
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

class _KeyIdeasEditor extends StatelessWidget {
  const _KeyIdeasEditor({
    required this.ideas,
    required this.controller,
    required this.palette,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> ideas;
  final TextEditingController controller;
  final AppPalette palette;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (ideas.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (int i = 0; i < ideas.length; i++)
                InputChip(
                  label: Text(ideas[i]),
                  onDeleted: () => onRemove(i),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                ),
            ],
          ),
        if (ideas.isNotEmpty) const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'أضف قانوناً أو فكرة',
                  prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                  isDense: true,
                ),
                onSubmitted: onAdd,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => onAdd(controller.text),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة'),
            ),
          ],
        ),
      ],
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
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
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
                      setState(
                          () => widget.question.correctIndex = v);
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
                      icon:
                          const Icon(Icons.close_rounded, size: 18),
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
