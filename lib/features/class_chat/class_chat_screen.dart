import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/supabase/supabase_client.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/empty_state.dart';
import 'package:studysync_syria/features/class_chat/class_chat_models.dart';
import 'package:studysync_syria/features/class_chat/class_chat_queries.dart';

/// Live per-class chat screen (student side).
///
/// Combines:
///   • Persistent text chat (Supabase Realtime postgres_changes)
///   • Teacher presence indicator (Supabase Realtime presence)
///   • Live quiz overlay that pops in when the teacher pushes a quiz
class ClassChatScreen extends StatefulWidget {
  const ClassChatScreen({
    super.key,
    required this.classId,
    required this.className,
    this.teacherName,
    this.teacherId,
  });

  final String classId;
  final String className;
  final String? teacherName;
  final String? teacherId;

  @override
  State<ClassChatScreen> createState() => _ClassChatScreenState();
}

class _ClassChatScreenState extends State<ClassChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  List<ChatMessage> _messages = const <ChatMessage>[];
  bool _loading = true;
  bool _sending = false;
  String? _loadError;

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _presenceChannel;
  RealtimeChannel? _quizChannel;

  bool _teacherOnline = false;
  LiveQuizSession? _activeQuiz;
  LiveQuizResponse? _myResponse;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    for (final RealtimeChannel? ch in <RealtimeChannel?>[
      _messagesChannel,
      _presenceChannel,
      _quizChannel,
    ]) {
      try {
        ch?.unsubscribe();
      } catch (_) {/* ignore */}
    }
    super.dispose();
  }

  String? get _myUserId => SupabaseService.auth.currentUser?.id;

  Future<void> _bootstrap() async {
    try {
      final List<ChatMessage> rows = await ClassChatQueries.fetchMessages(
        classId: widget.classId,
      );
      if (!mounted) return;
      setState(() {
        _messages = rows.toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }

    _messagesChannel = ClassChatQueries.subscribeToMessages(
      classId: widget.classId,
      onInsert: _onIncomingMessage,
      onDelete: _onDeletedMessage,
    );
    _presenceChannel = ClassChatQueries.joinPresence(
      classId: widget.classId,
      role: 'student',
      displayName: null,
      onPresenceChanged: (Set<String> teacherIds) {
        if (!mounted) return;
        final bool online = widget.teacherId != null
            ? teacherIds.contains(widget.teacherId)
            : teacherIds.isNotEmpty;
        setState(() => _teacherOnline = online);
      },
    );

    // Hydrate the currently-open quiz, then watch for changes.
    try {
      final LiveQuizSession? open = await ClassChatQueries.fetchOpenQuiz(
        classId: widget.classId,
      );
      if (!mounted) return;
      if (open != null) {
        final LiveQuizResponse? mine =
            await ClassChatQueries.fetchMyResponse(sessionId: open.id);
        if (!mounted) return;
        setState(() {
          _activeQuiz = open;
          _myResponse = mine;
        });
      }
    } catch (_) {
      // Best-effort.
    }

    _quizChannel = ClassChatQueries.subscribeToQuizSessions(
      classId: widget.classId,
      onChange: _onQuizChange,
    );
  }

  void _onIncomingMessage(ChatMessage m) {
    if (!mounted) return;
    if (_messages.any((ChatMessage x) => x.id == m.id)) return;
    setState(() => _messages = <ChatMessage>[..._messages, m]);
    _scrollToBottom();
  }

  void _onDeletedMessage(String id) {
    if (!mounted) return;
    setState(() => _messages =
        _messages.where((ChatMessage m) => m.id != id).toList());
  }

  void _onQuizChange(LiveQuizSession s) {
    if (!mounted) return;
    if (s.isOpen) {
      setState(() {
        _activeQuiz = s;
        _myResponse = null;
      });
    } else {
      setState(() {
        if (_activeQuiz?.id == s.id) {
          _activeQuiz = null;
          _myResponse = null;
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final String body = _composer.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final ChatMessage sent = await ClassChatQueries.sendStudentMessage(
        classId: widget.classId,
        body: body,
      );
      _composer.clear();
      // Optimistically append in case the realtime callback fires after.
      if (!mounted) return;
      if (!_messages.any((ChatMessage m) => m.id == sent.id)) {
        setState(() => _messages = <ChatMessage>[..._messages, sent]);
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _answerQuiz(int choice) async {
    final LiveQuizSession? s = _activeQuiz;
    if (s == null || _myResponse != null) return;
    try {
      final LiveQuizResponse r = await ClassChatQueries.submitResponse(
        sessionId: s.id,
        choiceIndex: choice,
      );
      if (!mounted) return;
      setState(() => _myResponse = r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AmbientBackground(
        intensity: 0.6,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _Header(
                palette: palette,
                title: widget.className,
                teacherName: widget.teacherName,
                teacherOnline: _teacherOnline,
                onBack: () => context.pop(),
              ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    _buildMessages(palette),
                    if (_activeQuiz != null)
                      Positioned(
                        left: 14,
                        right: 14,
                        top: 8,
                        child: _LiveQuizCard(
                          palette: palette,
                          session: _activeQuiz!,
                          myResponse: _myResponse,
                          onAnswer: _answerQuiz,
                        ),
                      ),
                  ],
                ),
              ),
              _Composer(
                controller: _composer,
                sending: _sending,
                onSend: _send,
                palette: palette,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessages(AppPalette palette) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_loadError != null && _messages.isEmpty) {
      return ListView(children: <Widget>[
        const SizedBox(height: 80),
        EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذّر تحميل المحادثة',
          description: _loadError!,
        ),
      ]);
    }
    if (_messages.isEmpty) {
      return ListView(children: const <Widget>[
        SizedBox(height: 80),
        EmptyState(
          icon: Icons.forum_outlined,
          title: 'لا توجد رسائل بعد',
          description: 'كن أوّل من يبدأ النقاش في صفّك.',
        ),
      ]);
    }
    final String? me = _myUserId;
    return ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        14,
        _activeQuiz != null ? 168 : 12,
        14,
        16,
      ),
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int i) {
        final ChatMessage m = _messages[i];
        final bool isMine = me != null && m.senderId == me;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _MessageBubble(
            message: m,
            isMine: isMine,
            palette: palette,
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.title,
    required this.teacherName,
    required this.teacherOnline,
    required this.onBack,
  });

  final AppPalette palette;
  final String title;
  final String? teacherName;
  final bool teacherOnline;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: teacherOnline
                            ? palette.success
                            : palette.muted.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      teacherOnline
                          ? 'المعلّم متصل الآن'
                          : (teacherName == null ||
                                  teacherName!.trim().isEmpty)
                              ? 'المحادثة المباشرة للصف'
                              : 'المعلّم: ${teacherName!}',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.palette,
  });

  final ChatMessage message;
  final bool isMine;
  final AppPalette palette;

  String _hhmm(DateTime d) {
    final DateTime local = d.toLocal();
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool teacher = message.isTeacher;
    final Color bg = isMine
        ? scheme.primary.withOpacity(0.94)
        : teacher
            ? palette.warm.withOpacity(0.10)
            : palette.card;
    final Color textColor = isMine ? Colors.white : scheme.onSurface;
    final Color metaColor = isMine
        ? Colors.white.withOpacity(0.78)
        : palette.muted;
    final Border border = Border.all(
      color: isMine
          ? Colors.white.withOpacity(0.18)
          : teacher
              ? palette.warm.withOpacity(0.45)
              : palette.outline,
    );
    return Align(
      alignment:
          isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: isMine ? null : palette.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (teacher && !isMine) ...<Widget>[
                    Icon(
                      Icons.school_rounded,
                      size: 13,
                      color: palette.warm,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      isMine ? 'أنت' : message.displayName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isMine
                            ? Colors.white
                            : (teacher
                                ? palette.warm
                                : scheme.primary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                message.body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _hhmm(message.createdAt),
                style: TextStyle(
                  fontSize: 10.5,
                  color: metaColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.palette,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: palette.outline),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة…',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            PressableScale(
              onTap: sending ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      sending ? scheme.primary.withOpacity(0.45) : scheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveQuizCard extends StatelessWidget {
  const _LiveQuizCard({
    required this.palette,
    required this.session,
    required this.myResponse,
    required this.onAnswer,
  });

  final AppPalette palette;
  final LiveQuizSession session;
  final LiveQuizResponse? myResponse;
  final void Function(int choice) onAnswer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool answered = myResponse != null;
    return AnimatedSlide(
      offset: const Offset(0, 0),
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: 1,
        duration: const Duration(milliseconds: 220),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: palette.goldGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withOpacity(0.30),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'اختبار مباشر من المعلّم',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  if (answered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        myResponse!.isCorrect
                            ? 'إجابتك صحيحة'
                            : 'تم الاستلام',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                session.prompt,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ...List<Widget>.generate(session.options.length, (int i) {
                final bool isMyChoice = myResponse?.choiceIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: PressableScale(
                    onTap: answered ? null : () => onAnswer(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isMyChoice
                            ? Colors.white
                            : Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isMyChoice
                              ? Colors.white
                              : Colors.white.withOpacity(0.32),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isMyChoice
                                  ? scheme.primary
                                  : Colors.white.withOpacity(0.20),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                color: isMyChoice
                                    ? Colors.white
                                    : Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              session.options[i],
                              style: TextStyle(
                                color: isMyChoice
                                    ? scheme.onSurface
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
