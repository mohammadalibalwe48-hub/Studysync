import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:studysync_syria/features/auth/auth_service.dart';
import 'package:studysync_syria/features/study_room/cloudflare_realtime_client.dart';
import 'package:studysync_syria/features/study_room/study_room_models.dart';
import 'package:studysync_syria/features/study_room/study_room_service.dart';

/// Live study-room screen.
///
/// Renders the local participant + every remote participant in a
/// responsive video grid, exposes per-tile mute toggles, and floats
/// a persistent text-chat overlay that survives audio/video toggles
/// (the chat lives on a Supabase broadcast channel; the camera lives
/// on Cloudflare Realtime).
class StudyRoomScreen extends StatefulWidget {
  const StudyRoomScreen({
    super.key,
    required this.roomId,
    required this.displayName,
    this.isHost = false,
  });

  final String roomId;
  final String displayName;
  final bool isHost;

  @override
  State<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends State<StudyRoomScreen> {
  StudyRoomService? _service;
  bool _chatOpen = false;
  String? _fatalError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Ask for camera + mic up-front. If denied we still try to
    // connect — the service drops to voice-only on its own if video
    // capture fails.
    try {
      await <Permission>[Permission.camera, Permission.microphone]
          .request();
    } catch (_) {/* not all platforms support permission_handler */}

    final String userId =
        AuthService.instance.currentUser?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final StudyRoomService svc = StudyRoomService(
      roomId: widget.roomId,
      userId: userId,
      displayName: widget.displayName,
      isHost: widget.isHost,
    );
    setState(() => _service = svc);
    svc.addListener(_onServiceUpdate);

    try {
      await svc.start();
    } on RealtimeNotConfiguredException catch (e) {
      setState(() => _fatalError = e.toString());
    } catch (e) {
      setState(() => _fatalError = e.toString());
    }
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final StudyRoomService? svc = _service;
    _service = null;
    if (svc != null) {
      svc.removeListener(_onServiceUpdate);
      unawaited(svc.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return _ErrorScaffold(
        title: widget.roomId,
        message: _fatalError!,
        onBack: () => context.pop(),
      );
    }

    final StudyRoomService? svc = _service;
    if (svc == null || !svc.isStarted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: <Widget>[
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'يجري الانضمام إلى الغرفة...',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<_GridTile> tiles = <_GridTile>[
      _GridTile.local(svc),
      for (final StudyRoomParticipant p in svc.participants)
        _GridTile.remote(p),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Video grid
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 56, 8, 96),
              child: _ParticipantGrid(tiles: tiles),
            ),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                roomId: widget.roomId,
                connectionStatus: svc.connectionStatus,
                onClose: () => context.pop(),
              ),
            ),
            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ControlBar(
                audioMuted: svc.audioMuted,
                videoMuted: svc.videoMuted,
                videoSupported: svc.videoSupported,
                isHost: widget.isHost,
                chatBadge: svc.chatMessages.isEmpty
                    ? 0
                    : (_chatOpen ? 0 : svc.chatMessages.length),
                onToggleAudio: () =>
                    svc.setLocalAudioMuted(!svc.audioMuted),
                onToggleVideo: () =>
                    svc.setLocalVideoMuted(!svc.videoMuted),
                onToggleChat: () => setState(() => _chatOpen = !_chatOpen),
                onMuteEveryone: () async {
                  await svc.hostMuteEveryone();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('تم إرسال أمر كتم الجميع.'),
                    ),
                  );
                },
                onLeave: () => context.pop(),
              ),
            ),
            // Chat overlay
            if (_chatOpen)
              Positioned(
                top: 56,
                bottom: 96,
                left: 8,
                right: 8,
                child: _ChatOverlay(
                  service: svc,
                  onClose: () => setState(() => _chatOpen = false),
                ),
              ),
            // Status banner under top bar
            if (svc.errorMessage != null)
              Positioned(
                top: 56,
                left: 12,
                right: 12,
                child: Material(
                  color: Colors.red.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      svc.errorMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 48),
                const SizedBox(height: 12),
                Text(
                  'تعذّر دخول الغرفة "$title"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('عودة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── tiles ────────────────────────────────

class _GridTile {
  _GridTile.local(StudyRoomService svc)
      : displayName = 'أنت',
        isLocal = true,
        renderer = svc.localRenderer,
        videoMuted = svc.videoMuted,
        audioMuted = svc.audioMuted,
        isHost = svc.isHost;

  _GridTile.remote(StudyRoomParticipant p)
      : displayName = p.displayName.isEmpty ? 'طالب' : p.displayName,
        isLocal = false,
        renderer = p.remoteRenderer,
        videoMuted = p.videoMuted,
        audioMuted = p.audioMuted,
        isHost = p.isHost;

  final String displayName;
  final bool isLocal;
  final RTCVideoRenderer? renderer;
  final bool videoMuted;
  final bool audioMuted;
  final bool isHost;
}

class _ParticipantGrid extends StatelessWidget {
  const _ParticipantGrid({required this.tiles});

  final List<_GridTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int n = tiles.length;
        final int columns;
        if (n <= 1) {
          columns = 1;
        } else if (n <= 4) {
          columns = 2;
        } else if (n <= 9) {
          columns = 3;
        } else {
          columns = 4;
        }
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3 / 4,
          children: <Widget>[
            for (final _GridTile t in tiles) _ParticipantTile(tile: t),
          ],
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.tile});

  final _GridTile tile;

  @override
  Widget build(BuildContext context) {
    final bool showVideo = !tile.videoMuted && tile.renderer != null;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tile.isHost
              ? Colors.amber.withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
          width: tile.isHost ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (showVideo)
            RTCVideoView(
              tile.renderer!,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: tile.isLocal,
            )
          else
            _VoiceOnlyAvatar(name: tile.displayName),
          // Bottom name + mute icons
          Positioned(
            left: 6,
            right: 6,
            bottom: 6,
            child: Row(
              children: <Widget>[
                if (tile.audioMuted)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_off_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tile.displayName + (tile.isHost ? ' ⭐' : ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceOnlyAvatar extends StatelessWidget {
  const _VoiceOnlyAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final String initial =
        name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF252525)),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD68A1A),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.mic_rounded, color: Colors.white70, size: 16),
        ],
      ),
    );
  }
}

// ──────────────────────────── chrome ───────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.roomId,
    required this.connectionStatus,
    required this.onClose,
  });

  final String roomId;
  final String connectionStatus;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: <Widget>[
          Material(
            color: Colors.black.withOpacity(0.5),
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              onPressed: onClose,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'غرفة $roomId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  connectionStatus,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.audioMuted,
    required this.videoMuted,
    required this.videoSupported,
    required this.isHost,
    required this.chatBadge,
    required this.onToggleAudio,
    required this.onToggleVideo,
    required this.onToggleChat,
    required this.onMuteEveryone,
    required this.onLeave,
  });

  final bool audioMuted;
  final bool videoMuted;
  final bool videoSupported;
  final bool isHost;
  final int chatBadge;
  final VoidCallback onToggleAudio;
  final VoidCallback onToggleVideo;
  final VoidCallback onToggleChat;
  final VoidCallback onMuteEveryone;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: Colors.black.withOpacity(0.65),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _RoundButton(
            icon: audioMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: audioMuted ? Colors.red : Colors.white24,
            onTap: onToggleAudio,
          ),
          _RoundButton(
            icon: !videoSupported || videoMuted
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            color: videoMuted ? Colors.red : Colors.white24,
            onTap: videoSupported ? onToggleVideo : () {},
            disabled: !videoSupported,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _RoundButton(
                icon: Icons.chat_bubble_rounded,
                color: Colors.white24,
                onTap: onToggleChat,
              ),
              if (chatBadge > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      chatBadge > 99 ? '99+' : '$chatBadge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (isHost)
            _RoundButton(
              icon: Icons.volume_off_rounded,
              color: Colors.amber.withOpacity(0.9),
              foreground: Colors.black,
              onTap: onMuteEveryone,
            ),
          _RoundButton(
            icon: Icons.call_end_rounded,
            color: Colors.red,
            onTap: onLeave,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.foreground = Colors.white,
    this.disabled = false,
  });

  final IconData icon;
  final Color color;
  final Color foreground;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: disabled ? null : onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: foreground),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────── chat ─────────────────────────────────

class _ChatOverlay extends StatefulWidget {
  const _ChatOverlay({required this.service, required this.onClose});

  final StudyRoomService service;
  final VoidCallback onClose;

  @override
  State<_ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<_ChatOverlay> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _ctrl.text;
    _ctrl.clear();
    await widget.service.sendChatMessage(text);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<RoomChatMessage> msgs = widget.service.chatMessages;
    return Material(
      color: Colors.black.withOpacity(0.85),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'محادثة الغرفة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: msgs.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد رسائل بعد. ابدأ المحادثة!',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: msgs.length,
                      itemBuilder: (BuildContext context, int i) {
                        final RoomChatMessage m = msgs[i];
                        final bool mine = m.userId == widget.service.userId;
                        return Align(
                          alignment: mine
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            constraints: const BoxConstraints(maxWidth: 240),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xFFD68A1A)
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  m.displayName + (m.isHost ? ' ⭐' : ''),
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.body,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
