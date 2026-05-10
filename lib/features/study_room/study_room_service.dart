import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:studysync_syria/core/supabase/supabase_client.dart';
import 'package:studysync_syria/features/study_room/cloudflare_realtime_client.dart';
import 'package:studysync_syria/features/study_room/study_room_models.dart';

/// Orchestrates a single study-room session for the current user:
///
///  • Spins up a `flutter_webrtc` PeerConnection with our local
///    camera + mic.
///  • Pushes those tracks to a Cloudflare Realtime SFU session via
///    [CloudflareRealtimeClient].
///  • Joins a Supabase Realtime broadcast channel keyed on the room
///    id so we can advertise our `cfSessionId` to peers, receive
///    theirs, and exchange chat messages + host control events.
///  • Pulls each peer's tracks back from the SFU as they appear and
///    binds them to per-tile [RTCVideoRenderer]s.
///
/// All UI consumes this via [ChangeNotifier] notifications; the
/// service owns the renderers and disposes them on [dispose].
class StudyRoomService extends ChangeNotifier {
  StudyRoomService({
    required this.roomId,
    required this.userId,
    required this.displayName,
    this.isHost = false,
    this.mode = RoomMode.discussion,
    CloudflareRealtimeClient? client,
  }) : _client = client ?? CloudflareRealtimeClient();

  final String roomId;
  final String userId;
  final String displayName;
  final bool isHost;
  final RoomMode mode;

  final CloudflareRealtimeClient _client;

  /// Whether non-host participants are allowed to unmute themselves.
  /// Lecture rooms lock students; the host can grant per-user unmute
  /// via [grantUnmute].
  bool get _audioLocked =>
      mode == RoomMode.lecture && !isHost && !_unmuteGranted;
  bool get _videoLocked =>
      mode == RoomMode.lecture && !isHost && !_unmuteGranted;

  bool _unmuteGranted = false;

  bool get audioLocked => _audioLocked;
  bool get videoLocked => _videoLocked;

  // ─────────────────────────── state ────────────────────────────────

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  String? _cfSessionId;
  RealtimeChannel? _channel;

  /// Local renderer (always shown as the user's own tile when video
  /// is enabled).
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  /// Other participants in this room, keyed by their user id.
  final Map<String, StudyRoomParticipant> _participants =
      <String, StudyRoomParticipant>{};

  /// Persistent chat scrollback for this room (newest last).
  final List<RoomChatMessage> _chat = <RoomChatMessage>[];

  /// Hosts in [RoomMode.lecture] see this as a queue of students
  /// requesting to speak. Cleared when the host grants or dismisses.
  final Map<String, RaisedHand> _raisedHands = <String, RaisedHand>{};

  bool _myHandRaised = false;

  bool _audioMuted = false;
  bool _videoMuted = false;
  bool _videoSupported = true;
  String _connectionStatus = 'idle';
  String? _errorMessage;

  /// Set once [start] completes successfully.
  bool _started = false;

  // ────────────────────────── accessors ─────────────────────────────

  bool get isStarted => _started;
  bool get audioMuted => _audioMuted;
  bool get videoMuted => _videoMuted;
  bool get videoSupported => _videoSupported;
  String get connectionStatus => _connectionStatus;
  String? get errorMessage => _errorMessage;
  String? get cfSessionId => _cfSessionId;
  bool get isConfigured => _client.isConfigured;

  List<StudyRoomParticipant> get participants =>
      List<StudyRoomParticipant>.unmodifiable(_participants.values);

  List<RoomChatMessage> get chatMessages =>
      List<RoomChatMessage>.unmodifiable(_chat);

  List<RaisedHand> get raisedHands {
    final List<RaisedHand> hands = _raisedHands.values.toList();
    hands.sort((RaisedHand a, RaisedHand b) =>
        a.raisedAt.compareTo(b.raisedAt));
    return List<RaisedHand>.unmodifiable(hands);
  }

  bool get myHandRaised => _myHandRaised;

  // ────────────────────────── lifecycle ─────────────────────────────

  /// Joins the room. Camera-on-by-default per spec; if camera capture
  /// fails we transparently fall back to voice-only.
  ///
  /// In [RoomMode.voice] the camera is never requested. In
  /// [RoomMode.lecture] non-hosts join with mic+cam disabled and
  /// cannot toggle them until the host grants unmute.
  Future<void> start({bool? startWithVideo}) async {
    if (_started) return;
    _setStatus('initialising');
    try {
      if (!_client.isConfigured) {
        throw const RealtimeNotConfiguredException();
      }
      await localRenderer.initialize();
      final bool wantVideo = _resolveInitialVideo(startWithVideo);
      await _initLocalMedia(startWithVideo: wantVideo);
      // Apply lecture-mode initial mute for non-hosts.
      if (mode == RoomMode.lecture && !isHost) {
        _audioMuted = true;
        _videoMuted = true;
        for (final MediaStreamTrack t
            in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
          t.enabled = false;
        }
      }
      await _initPeerConnection();
      await _publishToCloudflare();
      _joinSupabaseChannel();
      _started = true;
      _setStatus('connected');
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus('failed');
      rethrow;
    }
  }

  bool _resolveInitialVideo(bool? requested) {
    if (mode == RoomMode.voice) return false;
    if (mode == RoomMode.lecture && !isHost) return false;
    return requested ?? true;
  }

  Future<void> _initLocalMedia({required bool startWithVideo}) async {
    final Map<String, dynamic> constraints = <String, dynamic>{
      'audio': true,
      'video': startWithVideo
          ? <String, dynamic>{
              'mandatory': <String, dynamic>{
                'minWidth': 320,
                'minHeight': 240,
                'minFrameRate': 15,
              },
              'facingMode': 'user',
            }
          : false,
    };

    try {
      _localStream =
          await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      // Camera failure — retry as audio-only.
      _videoSupported = false;
      _videoMuted = true;
      _localStream = await navigator.mediaDevices.getUserMedia(
        const <String, dynamic>{'audio': true, 'video': false},
      );
    }

    final List<MediaStreamTrack> videoTracks =
        _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (videoTracks.isEmpty) {
      _videoSupported = false;
      _videoMuted = true;
    }
    localRenderer.srcObject = _localStream;
    notifyListeners();
  }

  Future<void> _initPeerConnection() async {
    final Map<String, dynamic> config = <String, dynamic>{
      'iceServers': <Map<String, dynamic>>[
        <String, dynamic>{
          'urls': 'stun:stun.cloudflare.com:3478',
        },
      ],
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
    };
    final RTCPeerConnection pc = await createPeerConnection(config);
    _pc = pc;
    pc.onConnectionState = (RTCPeerConnectionState state) {
      _setStatus('peer:${state.toString().split('.').last}');
    };

    // Add local tracks as send-only transceivers so each gets a
    // unique MID we can pass to the SFU.
    for (final MediaStreamTrack track in _localStream?.getTracks() ??
        const <MediaStreamTrack>[]) {
      await pc.addTransceiver(
        track: track,
        kind: track.kind == 'audio'
            ? RTCRtpMediaType.RTCRtpMediaTypeAudio
            : RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.SendOnly,
          streams: <MediaStream>[_localStream!],
        ),
      );
    }
  }

  Future<void> _publishToCloudflare() async {
    final RTCPeerConnection pc = _pc!;
    final RTCSessionDescription offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    final List<RTCRtpTransceiver> tx = await pc.getTransceivers();
    final List<NewTrackRequest> tracks = <NewTrackRequest>[];
    String? audioTrackName;
    String? videoTrackName;
    for (final RTCRtpTransceiver t in tx) {
      final String kind = t.sender.track?.kind ?? '';
      if (kind.isEmpty) continue;
      final String name = kind == 'audio' ? 'mic' : 'cam';
      if (kind == 'audio') {
        audioTrackName = name;
      } else {
        videoTrackName = name;
      }
      tracks.add(NewTrackRequest(
        location: 'local',
        mid: t.mid,
        trackName: name,
      ));
    }

    final NewSessionResponse session = await _client.createSession(
      sdpOffer: offer.sdp,
      tracks: tracks,
    );
    _cfSessionId = session.sessionId;
    if (session.sdpAnswer != null) {
      await pc.setRemoteDescription(
        RTCSessionDescription(session.sdpAnswer, 'answer'),
      );
    }

    // Cache our published track names so we broadcast them to peers.
    _myAudioTrackName = audioTrackName ?? 'mic';
    _myVideoTrackName = videoTrackName ?? 'cam';
  }

  String _myAudioTrackName = 'mic';
  String _myVideoTrackName = 'cam';

  // ───────────────────── Supabase signalling ────────────────────────

  void _joinSupabaseChannel() {
    final RealtimeChannel ch = SupabaseService.client.channel(
      'study_room:$roomId',
      opts: const RealtimeChannelConfig(self: false),
    );
    _channel = ch;

    ch.onBroadcast(
      event: 'presence',
      callback: (Map<String, dynamic> raw) {
        final RoomPresencePayload p = RoomPresencePayload.fromJson(raw);
        if (p.userId.isEmpty || p.userId == userId) return;
        unawaited(_onPeerPresence(p));
      },
    );
    ch.onBroadcast(
      event: 'chat',
      callback: (Map<String, dynamic> raw) {
        try {
          _chat.add(RoomChatMessage(
            id: (raw['id'] as String?) ?? DateTime.now().toIso8601String(),
            userId: (raw['userId'] as String?) ?? '',
            displayName: (raw['displayName'] as String?) ?? '',
            body: (raw['body'] as String?) ?? '',
            sentAt: DateTime.tryParse(raw['sentAt'] as String? ?? '') ??
                DateTime.now(),
            isHost: (raw['isHost'] as bool?) ?? false,
          ));
          notifyListeners();
        } catch (_) {/* ignore malformed chat events */}
      },
    );
    ch.onBroadcast(
      event: 'host_mute_all',
      callback: (Map<String, dynamic> raw) {
        // Anyone in the room receives the order; we only respect it
        // if it came from a real host. We trust the broadcast — an
        // attacker who can post on the channel can also do worse.
        _unmuteGranted = false;
        for (final MediaStreamTrack t
            in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
          t.enabled = false;
        }
        _audioMuted = true;
        notifyListeners();
      },
    );
    ch.onBroadcast(
      event: 'hand_raise',
      callback: (Map<String, dynamic> raw) {
        if (!isHost) return;
        final String uid = (raw['userId'] as String?) ?? '';
        final String name = (raw['displayName'] as String?) ?? '';
        if (uid.isEmpty || uid == userId) return;
        if ((raw['lower'] as bool?) ?? false) {
          _raisedHands.remove(uid);
        } else {
          _raisedHands[uid] = RaisedHand(
            userId: uid,
            displayName: name.isEmpty ? 'طالب' : name,
            raisedAt: DateTime.tryParse(raw['at'] as String? ?? '') ??
                DateTime.now(),
          );
        }
        notifyListeners();
      },
    );
    ch.onBroadcast(
      event: 'unmute_grant',
      callback: (Map<String, dynamic> raw) {
        // Only the targeted user reacts; everyone else ignores.
        final String target = (raw['target'] as String?) ?? '';
        if (target != userId) return;
        _unmuteGranted = true;
        _myHandRaised = false;
        notifyListeners();
      },
    );
    ch.onBroadcast(
      event: 'unmute_revoke',
      callback: (Map<String, dynamic> raw) {
        final String target = (raw['target'] as String?) ?? '';
        if (target != userId) return;
        _unmuteGranted = false;
        // Force-mute on revoke.
        for (final MediaStreamTrack t
            in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
          t.enabled = false;
        }
        _audioMuted = true;
        _videoMuted = true;
        notifyListeners();
      },
    );

    ch.subscribe((RealtimeSubscribeStatus status, Object? error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _broadcastPresence();
      }
    });
  }

  void _broadcastPresence() {
    final RealtimeChannel? ch = _channel;
    if (ch == null || _cfSessionId == null) return;
    final RoomPresencePayload payload = RoomPresencePayload(
      userId: userId,
      displayName: displayName,
      cfSessionId: _cfSessionId!,
      isHost: isHost,
      audioTrackName: _myAudioTrackName,
      videoTrackName: _myVideoTrackName,
    );
    unawaited(ch.sendBroadcastMessage(
      event: 'presence',
      payload: payload.toJson(),
    ));
  }

  Future<void> _onPeerPresence(RoomPresencePayload p) async {
    final StudyRoomParticipant? existing = _participants[p.userId];
    if (existing != null && existing.cfSessionId == p.cfSessionId) {
      // Already pulled this peer.
      return;
    }
    final StudyRoomParticipant participant = StudyRoomParticipant(
      userId: p.userId,
      displayName: p.displayName,
      cfSessionId: p.cfSessionId,
      isHost: p.isHost,
      audioTrackName: p.audioTrackName,
      videoTrackName: p.videoTrackName,
    );
    _participants[p.userId] = participant;
    notifyListeners();

    try {
      await _pullPeerTracks(participant);
      // Re-broadcast our own presence so they pull us back if they
      // joined after we did.
      _broadcastPresence();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _pullPeerTracks(StudyRoomParticipant peer) async {
    final RTCPeerConnection? pc = _pc;
    final String? sid = _cfSessionId;
    if (pc == null || sid == null) return;

    final TracksResponse pulled = await _client.pullTracks(
      sessionId: sid,
      remoteTracks: <RemoteTrackRef>[
        if (peer.audioTrackName != null)
          RemoteTrackRef(
            sessionId: peer.cfSessionId,
            trackName: peer.audioTrackName!,
          ),
        if (peer.videoTrackName != null)
          RemoteTrackRef(
            sessionId: peer.cfSessionId,
            trackName: peer.videoTrackName!,
          ),
      ],
    );

    if (pulled.requiresImmediateRenegotiation && pulled.sdpAnswer != null) {
      await pc.setRemoteDescription(
        RTCSessionDescription(pulled.sdpAnswer, 'offer'),
      );
      final RTCSessionDescription answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      await _client.renegotiate(
        sessionId: sid,
        sdpAnswer: answer.sdp ?? '',
      );
    }

    final RTCVideoRenderer renderer = RTCVideoRenderer();
    await renderer.initialize();

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        renderer.srcObject = event.streams.first;
      }
    };

    final StudyRoomParticipant updated = StudyRoomParticipant(
      userId: peer.userId,
      displayName: peer.displayName,
      cfSessionId: peer.cfSessionId,
      isHost: peer.isHost,
      audioMuted: peer.audioMuted,
      videoMuted: peer.videoMuted,
      remoteRenderer: renderer,
      audioTrackName: peer.audioTrackName,
      videoTrackName: peer.videoTrackName,
    );
    _participants[peer.userId] = updated;
    notifyListeners();
  }

  // ───────────────────────── controls ───────────────────────────────

  Future<void> setLocalAudioMuted(bool muted) async {
    // Allow muting at any time; only block *unmuting* when locked.
    if (!muted && _audioLocked) return;
    _audioMuted = muted;
    for (final MediaStreamTrack t
        in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
    notifyListeners();
  }

  Future<void> setLocalVideoMuted(bool muted) async {
    if (!_videoSupported) return;
    if (!muted && _videoLocked) return;
    _videoMuted = muted;
    for (final MediaStreamTrack t
        in _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
      t.enabled = !muted;
    }
    notifyListeners();
  }

  /// Lecture-only: a non-host student requests permission to speak.
  /// Idempotent — calling twice toggles the raised state.
  Future<void> toggleHandRaised() async {
    if (mode != RoomMode.lecture || isHost) return;
    final RealtimeChannel? ch = _channel;
    if (ch == null) return;
    _myHandRaised = !_myHandRaised;
    notifyListeners();
    await ch.sendBroadcastMessage(
      event: 'hand_raise',
      payload: <String, dynamic>{
        'userId': userId,
        'displayName': displayName,
        'at': DateTime.now().toIso8601String(),
        'lower': !_myHandRaised,
      },
    );
  }

  /// Host-only: grant a specific student temporary unmute permission.
  Future<void> grantUnmute(String targetUserId) async {
    if (!isHost) return;
    final RealtimeChannel? ch = _channel;
    if (ch == null) return;
    _raisedHands.remove(targetUserId);
    notifyListeners();
    await ch.sendBroadcastMessage(
      event: 'unmute_grant',
      payload: <String, dynamic>{
        'target': targetUserId,
        'fromUserId': userId,
        'at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Host-only: revoke an earlier grant and force-mute the student.
  Future<void> revokeUnmute(String targetUserId) async {
    if (!isHost) return;
    final RealtimeChannel? ch = _channel;
    if (ch == null) return;
    await ch.sendBroadcastMessage(
      event: 'unmute_revoke',
      payload: <String, dynamic>{
        'target': targetUserId,
        'fromUserId': userId,
        'at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Host-only: dismiss a raised hand without granting unmute.
  void dismissHand(String targetUserId) {
    if (!isHost) return;
    if (_raisedHands.remove(targetUserId) != null) {
      notifyListeners();
    }
  }

  /// Host-only: tell every participant to locally mute their mic.
  Future<void> hostMuteEveryone() async {
    if (!isHost) return;
    final RealtimeChannel? ch = _channel;
    if (ch == null) return;
    await ch.sendBroadcastMessage(
      event: 'host_mute_all',
      payload: <String, dynamic>{
        'fromUserId': userId,
        'at': DateTime.now().toIso8601String(),
      },
    );
    // In a lecture, the host stays unmuted (they're the speaker).
    // In a discussion / voice room, the host should silence themselves
    // too as a courtesy.
    if (mode != RoomMode.lecture) {
      await setLocalAudioMuted(true);
    }
  }

  Future<void> sendChatMessage(String body) async {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final RealtimeChannel? ch = _channel;
    if (ch == null) return;
    final RoomChatMessage local = RoomChatMessage(
      id: '${userId}_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      displayName: displayName,
      body: trimmed,
      sentAt: DateTime.now(),
      isHost: isHost,
    );
    _chat.add(local);
    notifyListeners();
    await ch.sendBroadcastMessage(
      event: 'chat',
      payload: <String, dynamic>{
        'id': local.id,
        'userId': local.userId,
        'displayName': local.displayName,
        'body': local.body,
        'sentAt': local.sentAt.toIso8601String(),
        'isHost': local.isHost,
      },
    );
  }

  // ─────────────────────────── teardown ─────────────────────────────

  void _setStatus(String s) {
    _connectionStatus = s;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _started = false;
    try {
      await _channel?.unsubscribe();
    } catch (_) {}
    try {
      for (final StudyRoomParticipant p in _participants.values) {
        await p.remoteRenderer?.dispose();
      }
    } catch (_) {}
    try {
      for (final MediaStreamTrack t
          in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
        await t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _pc?.close();
    } catch (_) {}
    try {
      await localRenderer.dispose();
    } catch (_) {}
    _client.close();
    super.dispose();
  }
}
