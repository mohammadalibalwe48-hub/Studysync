import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/constants/curriculum.dart';
import 'package:studysync_syria/core/models/topic.dart';
import 'package:studysync_syria/core/services/notes_service.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// Listing screen for all study notes the user has captured.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    NotesService.instance.load();
    NotesService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    NotesService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<StudyNote> notes = NotesService.instance.all;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'ملاحظاتي',
                subtitle: 'مكتبة الملاحظات بصيغة ماركداون مع التظليل',
                onBack: () => context.go('/library'),
              ),
              Expanded(
                child: notes.isEmpty
                    ? const EmptyState(
                        icon: Icons.sticky_note_2_outlined,
                        title: 'ابدأ ملاحظاتك',
                        description:
                            'دوّن أفكارك ومراجعاتك بصيغة ماركداون '
                            'وأبرز ما يهمّك بأقواس == نص ==.',
                      )
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 14, 16, 96),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (BuildContext _, int i) {
                          final StudyNote n = notes[i];
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 + i * 50),
                            child: _NoteCard(
                              note: n,
                              onTap: () => _openEditor(note: n),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ملاحظة جديدة'),
        elevation: 6,
      ),
    );
  }

  Future<void> _openEditor({StudyNote? note}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _NoteEditorSheet(note: note),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final StudyNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final Topic? topic = Curriculum.topicById(note.topicId);
    final String preview = note.body.replaceAll(RegExp(r'[#*=_>\-]'), '');
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.outline, width: 1),
          boxShadow: palette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (topic != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: palette.outline, width: 1),
                    ),
                    child: Text(
                      topic.title,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet markdown editor with live preview & highlight insertion.
class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({this.note});

  final StudyNote? note;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.note?.title ?? '');
  late final TextEditingController _body =
      TextEditingController(text: widget.note?.body ?? _kStarter);
  late String _topicId =
      widget.note?.topicId ?? Curriculum.topics.first.id;
  bool _preview = false;

  static const String _kStarter =
      '# عنوان الملاحظة\n\n'
      'اكتب هنا فكرتك الأساسية. يمكنك استخدام **عريض**، *مائل*، '
      'أو إبراز جزء مهم بـ ==النص الذي تريد==.\n\n'
      '- نقطة أولى\n'
      '- نقطة ثانية\n';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  /// Convert our `==text==` highlight syntax into raw markdown that
  /// flutter_markdown can render: a bold span we colour later via the
  /// stylesheet's strong style — combined with a soft warm background
  /// applied to lines that contain a highlight.  Keeping it simple.
  String _renderableMarkdown(String src) {
    return src.replaceAllMapped(
      RegExp(r'==([^=]+)=='),
      (Match m) => '**${m.group(1)}**',
    );
  }

  Future<void> _insertHighlight() async {
    final TextSelection sel = _body.selection;
    if (!sel.isValid) return;
    final String selected = sel.textInside(_body.text);
    if (selected.isEmpty) {
      // Insert empty highlight markers at cursor.
      final int pos = sel.baseOffset.clamp(0, _body.text.length).toInt();
      final String next = _body.text.substring(0, pos) +
          '====' +
          _body.text.substring(pos);
      _body
        ..text = next
        ..selection = TextSelection.collapsed(offset: pos + 2);
      setState(() {});
      return;
    }
    final String next = _body.text.replaceRange(
      sel.start,
      sel.end,
      '==$selected==',
    );
    _body.text = next;
    setState(() {});
  }

  Future<void> _save() async {
    final String title = _title.text.trim().isEmpty
        ? 'ملاحظة'
        : _title.text.trim();
    if (widget.note == null) {
      await NotesService.instance.create(
        topicId: _topicId,
        title: title,
        body: _body.text,
      );
    } else {
      await NotesService.instance.update(
        widget.note!.id,
        title: title,
        body: _body.text,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final double height = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: palette.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 6),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _title,
                        decoration: const InputDecoration(
                          hintText: 'عنوان الملاحظة',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (widget.note != null)
                      IconButton(
                        tooltip: 'حذف',
                        onPressed: () async {
                          await NotesService.instance.remove(widget.note!.id);
                          if (mounted) Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.delete_outline_rounded,
                            color: scheme.error),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final Topic t in Curriculum.topics)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(t.title),
                            selected: _topicId == t.id,
                            onSelected: (_) =>
                                setState(() => _topicId = t.id),
                            selectedColor: scheme.primaryContainer,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _topicId == t.id
                                  ? scheme.onPrimaryContainer
                                  : palette.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _Toolbar(
                preview: _preview,
                onTogglePreview: () =>
                    setState(() => _preview = !_preview),
                onHighlight: _insertHighlight,
                onBold: () => _wrap('**', '**'),
                onItalic: () => _wrap('*', '*'),
                onBullet: () => _insertLine('- '),
                onHeading: () => _insertLine('## '),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _preview
                      ? _MarkdownPreview(
                          source: _renderableMarkdown(_body.text),
                          highlightSource: _body.text,
                        )
                      : TextField(
                          controller: _body,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText: 'اكتب ملاحظتك بصيغة ماركداون…',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.7,
                            color: scheme.onSurface,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('حفظ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _wrap(String left, String right) {
    final TextSelection sel = _body.selection;
    if (!sel.isValid) return;
    final String selected = sel.textInside(_body.text);
    final String next = _body.text.replaceRange(
      sel.start,
      sel.end,
      '$left$selected$right',
    );
    _body
      ..text = next
      ..selection = TextSelection.collapsed(
          offset: sel.start + left.length + selected.length);
    setState(() {});
  }

  void _insertLine(String prefix) {
    final TextSelection sel = _body.selection;
    final int pos = sel.baseOffset.clamp(0, _body.text.length).toInt();
    final int lineStart =
        _body.text.lastIndexOf('\n', pos > 0 ? pos - 1 : 0) + 1;
    final String next =
        '${_body.text.substring(0, lineStart)}$prefix${_body.text.substring(lineStart)}';
    _body
      ..text = next
      ..selection = TextSelection.collapsed(offset: pos + prefix.length);
    setState(() {});
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.preview,
    required this.onTogglePreview,
    required this.onHighlight,
    required this.onBold,
    required this.onItalic,
    required this.onBullet,
    required this.onHeading,
  });

  final bool preview;
  final VoidCallback onTogglePreview;
  final VoidCallback onHighlight;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onBullet;
  final VoidCallback onHeading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outline, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _ToolbarButton(
              icon: Icons.title_rounded,
              tooltip: 'عنوان فرعي',
              onTap: onHeading,
            ),
            _ToolbarButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'عريض',
              onTap: onBold,
            ),
            _ToolbarButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'مائل',
              onTap: onItalic,
            ),
            _ToolbarButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'قائمة',
              onTap: onBullet,
            ),
            _ToolbarButton(
              icon: Icons.brush_rounded,
              tooltip: 'تظليل',
              onTap: onHighlight,
              tone: AppTheme.streakAmber,
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: preview
                  ? Icons.edit_note_rounded
                  : Icons.visibility_rounded,
              tooltip: preview ? 'تحرير' : 'معاينة',
              onTap: onTogglePreview,
              filled: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tone,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? tone;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = tone ?? scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: filled ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 18,
                color: filled ? scheme.onPrimary : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({
    required this.source,
    required this.highlightSource,
  });

  final String source;
  final String highlightSource;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    // Render the converted markdown plus a soft "highlights summary"
    // pulled directly from the original text so users see exactly which
    // phrases they marked.
    final List<String> highlights = <String>[
      for (final Match m in RegExp(r'==([^=]+)==').allMatches(highlightSource))
        m.group(1) ?? ''
    ];
    return Markdown(
      data: source +
          (highlights.isEmpty
              ? ''
              : '\n\n---\n\n**أبرز ما ظللته:**\n\n' +
                  highlights.map((String h) => '- $h').join('\n')),
      padding: EdgeInsets.zero,
      shrinkWrap: false,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
            fontSize: 14.5, height: 1.7, color: scheme.onSurface),
        h1: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface),
        h2: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface),
        strong: TextStyle(
          fontWeight: FontWeight.w800,
          color: scheme.onPrimaryContainer,
          backgroundColor: scheme.primaryContainer,
        ),
        listBullet: TextStyle(
            fontSize: 14.5, color: scheme.onSurface),
        blockquote: TextStyle(
            fontSize: 14, color: scheme.onSurfaceVariant),
        code: TextStyle(
          fontFamily: 'monospace',
          color: scheme.onPrimaryContainer,
          backgroundColor: scheme.primaryContainer,
        ),
      ),
    );
  }
}
