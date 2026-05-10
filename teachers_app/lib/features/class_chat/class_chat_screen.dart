import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria_teachers/app/theme.dart';
import 'package:studysync_syria_teachers/core/supabase/supabase_client.dart';
import 'package:studysync_syria_teachers/core/widgets/ambient_background.dart';
import 'package:studysync_syria_teachers/core/widgets/animations.dart';
import 'package:studysync_syria_teachers/core/widgets/empty_state.dart';
import 'package:studysync_syria_teachers/features/class_chat/class_chat_models.dart';
import 'package:studysync_syria_teachers/features/class_chat/class_chat_queries.dart';
import 'package:studysync_syria_teachers/features/class_chat/live_quiz_composer.dart';

// Emerald used for "online" pills since the warm-gold AppPalette
// has no dedicated success colour.
const Color _kOnlineGreen = Color(0xFF2F8F4E);

/// Teacher view of the live class chat. Combines:
///   • text chat with student bubbles + own bubbles
///   • presence indicator (number of students online)
///   • live-quiz composer + real-time tally of student answers
class ClassChatScreen extends StatefulWidget {
  const ClassChatScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

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
  RealtimeChannel? _responsesChannel;

  Set<String> _onlineStudents = const <String>{};
  int _enrolledCount = 0;

  LiveQuizSession? _activeQuiz;
  final Map<String, LiveQuizResponse> _responses =
      <String, LiveQuizResponse>{};

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
      _responsesChannel,
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

    _enrolledCount = await ClassChatQueries.classStudentCount(
      classId: widget.classId,
    );
    if (mounted) setState(() {});

    _messagesChannel = ClassChatQueries.subscribeToMessages(
      classId: widget.classId,
      onInsert: (ChatMessage m) {
        if (!mounted) return;
        if (_messages.any((ChatMessage x) => x.id == m.id)) return;
        setState(() => _messages = <ChatMessage>[..._messages, m]);
        _scrollToBottom();
      },
      onDelete: (String id) {
        if (!mounted) return;
        setState(() => _messages =
            _messages.where((ChatMessage m) => m.id != id).toList());
      },
    );
    _presenceChannel = ClassChatQueries.joinPresence(
      classId: widget.classId,
      displayName: null,
      onPresenceChanged: (Set<String> online) {
        if (!mounted) return;
        setState(() => _onlineStudents = online);
      },
    );

    // Hydrate any open quiz so the teacher reconnects to the same
    // tally on app reload.
    try {
      final LiveQuizSession? open = await ClassChatQueries.fetchOpenQuiz(
        classId: widget.classId,
      );
      if (!mounted || open == null) return;
      final List<LiveQuizResponse> existing =
          await ClassChatQueries.fetchResponses(sessionId: open.id);
      if (!mounted) return;
      setState(() {
        _activeQuiz = open;
        _responses.clear();
        for (final LiveQuizResponse r in existing) {
          _responses[r.studentId] = r;
        }
      });
      _attachResponsesChannel(open.id);
    } catch (_) {
      // Best-effort.
    }
  }

  void _attachResponsesChannel(String sessionId) {
    _responsesChannel?.unsubscribe();
    _responsesChannel = ClassChatQueries.subscribeToQuizResponses(
      sessionId: sessionId,
      onResponse: (LiveQuizResponse r) {
        if (!mounted) return;
        setState(() => _responses[r.studentId] = r);
      },
    );
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
      final ChatMessage sent = await ClassChatQueries.sendTeacherMessage(
        classId: widget.classId,
        body: body,
      );
      _composer.clear();
      if (!mounted) return;
      if (!_messages.any((ChatMessage m) => m.id == sent.id)) {
        setState(() => _messages = <ChatMessage>[..._messages, sent]);
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _composeQuiz() async {
    final LiveQuizDraft? draft = await showModalBottomSheet<LiveQuizDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext _) => const LiveQuizComposer(),
    );
    if (draft == null) return;
    try {
      final LiveQuizSession s = await ClassChatQueries.startLiveQuiz(
        classId: widget.classId,
        prompt: draft.prompt,
        options: draft.options,
        correctIndex: draft.correctIndex,
      );
      if (!mounted) return;
      setState(() {
        _activeQuiz = s;
        _responses.clear();
      });
      _attachResponsesChannel(s.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _closeQuiz() async {
    final LiveQuizSession? s = _activeQuiz;
    if (s == null) return;
    try {
      await ClassChatQueries.closeLiveQuiz(sessionId: s.id);
      if (!mounted) return;
      setState(() {
        _activeQuiz = null;
        _responses.clear();
      });
      _responsesChannel?.unsubscribe();
      _responsesChannel = null;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _Header(
                palette: palette,
                title: widget.className,
                onBack: () => context.pop(),
                online: _onlineStudents.length,
                total: _enrolledCount,
                onStartQuiz: _activeQuiz == null ? _composeQuiz : null,
                onCloseQuiz: _activeQuiz != null ? _closeQuiz : null,
              ),
              if (_activeQuiz != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                  child: _LiveTallyCard(
                    palette: palette,
                    scheme: scheme,
                    session: _activeQuiz!,
                    responses: _responses.values.toList(),
                    enrolled: _enrolledCount,
                  ),
                ),
              Expanded(child: _buildMessages(palette)),
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
          description: 'ابدأ النقاش — رسائلك تصل لطلابك مباشرة.',
        ),
      ]);
    }
    final String? me = _myUserId;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: _messages.length,
      itemBuilder: (BuildContext context, int i) {
        final ChatMessage m = _messages[i];
        final bool isMine = me != null && m.senderId == me;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FadeSlideIn(
            duration: const Duration(milliseconds: 220),
            child: _MessageBubble(
              message: m,
              isMine: isMine,
              palette: palette,
            ),
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
    required this.onBack,
    required this.online,
    required this.total,
    required this.onStartQuiz,
    required this.onCloseQuiz,
  });

  final AppPalette palette;
  final String title;
  final VoidCallback onBack;
  final int online;
  final int total;
  final VoidCallback? onStartQuiz;
  final VoidCallback? onCloseQuiz;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 20,
            ),
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
                        color: online > 0
                            ? _kOnlineGreen
                            : palette.muted.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      total > 0
                          ? 'متصل الآن: $online من $total'
                          : 'متصل الآن: $online طالب',
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (onStartQuiz != null)
            ElevatedButton.icon(
              onPressed: onStartQuiz,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text(
                'اختبار مباشر',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          if (onCloseQuiz != null)
            ElevatedButton.icon(
              onPressed: onCloseQuiz,
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text(
                'إنهاء الاختبار',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.warm,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LiveTallyCard extends StatelessWidget {
  const _LiveTallyCard({
    required this.palette,
    required this.scheme,
    required this.session,
    required this.responses,
    required this.enrolled,
  });

  final AppPalette palette;
  final ColorScheme scheme;
  final LiveQuizSession session;
  final List<LiveQuizResponse> responses;
  final int enrolled;

  @override
  Widget build(BuildContext context) {
    final LiveQuizTally tally = LiveQuizTally.from(
      session.id,
      session.options.length,
      responses,
    );
    final int n = tally.totalResponses;
    final int correct = tally.totalCorrect;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: palette.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withOpacity(0.32),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              const Text(
                'اختبار مباشر مفعّل',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  enrolled > 0 ? '$n / $enrolled أجابوا' : '$n إجابة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
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
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(session.options.length, (int i) {
            final double pct = tally.percentFor(i);
            final bool isCorrect = i == session.correctIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TallyBar(
                index: i,
                label: session.options[i],
                count: tally.countByChoice[i],
                percent: pct,
                isCorrect: isCorrect,
              ),
            );
          }),
          if (n > 0) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'إجابات صحيحة: $correct من $n',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TallyBar extends StatelessWidget {
  const _TallyBar({
    required this.index,
    required this.label,
    required this.count,
    required this.percent,
    required this.isCorrect,
  });

  final int index;
  final String label;
  final int count;
  final double percent;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCorrect
                  ? Colors.white
                  : Colors.white.withOpacity(0.35),
              width: isCorrect ? 1.6 : 0.8,
            ),
          ),
          child: Text(
            String.fromCharCode(65 + index),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isCorrect
                            ? Colors.white
                            : Colors.white.withOpacity(0.92),
                        fontSize: 12.5,
                        fontWeight:
                            isCorrect ? FontWeight.w800 : FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}% · $count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCorrect
                        ? Colors.white
                        : Colors.white.withOpacity(0.65),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final Color bg = isMine
        ? scheme.primary.withOpacity(0.94)
        : palette.card;
    final Color textColor = isMine ? Colors.white : scheme.onSurface;
    final Color metaColor =
        isMine ? Colors.white.withOpacity(0.78) : palette.muted;
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
            border: Border.all(
              color: isMine
                  ? Colors.white.withOpacity(0.18)
                  : palette.outline,
            ),
            boxShadow: isMine ? null : palette.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                isMine ? 'أنت' : message.displayName,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isMine
                      ? Colors.white
                      : scheme.primary,
                ),
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
                  hintText: 'اكتب رسالة لطلابك…',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sending
                      ? scheme.primary.withOpacity(0.45)
                      : scheme.primary,
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
