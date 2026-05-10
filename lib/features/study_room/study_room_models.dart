// Domain types for the study-rooms feature.
//
// Three room modes are supported:
//
//  • [RoomMode.discussion] — default. Camera + mic on by default,
//    everyone is symmetric, anyone can mute themselves.
//  • [RoomMode.voice] — voice-only room. Camera capture is never
//    requested; the UI shows avatar tiles instead of video views.
//  • [RoomMode.lecture] — teacher livestream. Non-hosts join muted
//    (mic + cam) and cannot unmute themselves until the host sends
//    an `unmute_grant` event. Hosts get a single-speaker layout
//    with a thumbnail strip below for raised hands.
//
// A "study room" is a lightweight concept on top of Cloudflare's
// SFU + Supabase Realtime broadcast channels:
//
//  • Each participant gets a Cloudflare Realtime *session* (one
//    PeerConnection per device).
//  • Sessions discover each other by broadcasting their `sessionId`
//    to a Supabase channel keyed on the room id. There's no DB
//    table — broadcast events disappear with the page.
//  • Chat messages travel through the same Supabase channel under a
//    different event name so they can survive A/V mute/unmute
//    without re-creating subscriptions.

import 'package:flutter_webrtc/flutter_webrtc.dart';

/// How a study room is structured. Affects default mute state, the
/// UI layout, and whether non-hosts can manipulate their own A/V.
enum RoomMode {
  /// Camera + mic on by default. Everyone is peer-to-peer-ish.
  discussion,

  /// No camera capture. Audio-only avatar grid.
  voice,

  /// Teacher livestream. Non-hosts auto-mute + locked controls.
  lecture,
}

extension RoomModeX on RoomMode {
  /// Wire-format string used in route extras + presence payloads.
  String get wire {
    switch (this) {
      case RoomMode.discussion:
        return 'discussion';
      case RoomMode.voice:
        return 'voice';
      case RoomMode.lecture:
        return 'lecture';
    }
  }

  static RoomMode parse(String? raw) {
    switch (raw) {
      case 'voice':
        return RoomMode.voice;
      case 'lecture':
        return RoomMode.lecture;
      case 'discussion':
      default:
        return RoomMode.discussion;
    }
  }
}

/// Identifier of one peer in a study room.
class StudyRoomParticipant {
  StudyRoomParticipant({
    required this.userId,
    required this.displayName,
    required this.cfSessionId,
    this.isHost = false,
    this.audioMuted = false,
    this.videoMuted = false,
    this.remoteRenderer,
    this.audioTrackName,
    this.videoTrackName,
  });

  /// Stable user id (Supabase auth user id, or a generated guest id).
  final String userId;

  final String displayName;

  /// Cloudflare Realtime session id this participant is publishing
  /// from. Other peers subscribe to this id to pull tracks.
  final String cfSessionId;

  /// Whether this participant is the room host (admin powers like
  /// "mute everyone").
  bool isHost;

  bool audioMuted;
  bool videoMuted;

  /// The published track names this participant exposes. We default
  /// to `mic` + `cam`; voice-only fallback drops `cam`.
  String? audioTrackName;
  String? videoTrackName;

  /// Hooked up by [StudyRoomService] when we successfully pull this
  /// peer's tracks. Bound to a [RTCVideoView] in the UI.
  RTCVideoRenderer? remoteRenderer;

  StudyRoomParticipant copyWithMuteState({
    bool? audioMuted,
    bool? videoMuted,
  }) {
    return StudyRoomParticipant(
      userId: userId,
      displayName: displayName,
      cfSessionId: cfSessionId,
      isHost: isHost,
      audioMuted: audioMuted ?? this.audioMuted,
      videoMuted: videoMuted ?? this.videoMuted,
      remoteRenderer: remoteRenderer,
      audioTrackName: audioTrackName,
      videoTrackName: videoTrackName,
    );
  }
}

/// One chat message in a room. Survives mute/unmute by living on the
/// dedicated chat broadcast event.
class RoomChatMessage {
  const RoomChatMessage({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.body,
    required this.sentAt,
    this.isHost = false,
  });

  final String id;
  final String userId;
  final String displayName;
  final String body;
  final DateTime sentAt;
  final bool isHost;
}

/// Discovery payload broadcast on the room channel so other peers
/// know this user just published their tracks.
class RoomPresencePayload {
  const RoomPresencePayload({
    required this.userId,
    required this.displayName,
    required this.cfSessionId,
    required this.isHost,
    required this.audioTrackName,
    required this.videoTrackName,
  });

  factory RoomPresencePayload.fromJson(Map<String, dynamic> j) {
    return RoomPresencePayload(
      userId: (j['userId'] as String?) ?? '',
      displayName: (j['displayName'] as String?) ?? '',
      cfSessionId: (j['cfSessionId'] as String?) ?? '',
      isHost: (j['isHost'] as bool?) ?? false,
      audioTrackName: (j['audioTrackName'] as String?) ?? 'mic',
      videoTrackName: (j['videoTrackName'] as String?) ?? 'cam',
    );
  }

  final String userId;
  final String displayName;
  final String cfSessionId;
  final bool isHost;
  final String audioTrackName;
  final String videoTrackName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'displayName': displayName,
        'cfSessionId': cfSessionId,
        'isHost': isHost,
        'audioTrackName': audioTrackName,
        'videoTrackName': videoTrackName,
      };
}

/// One pending raised hand in a [RoomMode.lecture] room.
///
/// Students broadcast a `hand_raise` event when they want to speak;
/// the host sees them in a list and can grant temporary unmute.
class RaisedHand {
  const RaisedHand({
    required this.userId,
    required this.displayName,
    required this.raisedAt,
  });

  final String userId;
  final String displayName;
  final DateTime raisedAt;
}
