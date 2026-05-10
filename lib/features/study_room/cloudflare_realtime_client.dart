import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Thin Dart wrapper around Cloudflare Realtime's SFU "Connection
/// API" — the HTTPS endpoints that create sessions, push tracks,
/// renegotiate, and close tracks.
///
///  https://developers.cloudflare.com/realtime/sfu/https-api/
///
/// We deliberately don't try to be a fully fledged WebRTC stack —
/// signalling lives here, the actual ICE / DTLS / media plumbing is
/// done by `flutter_webrtc` in [StudyRoomService].
///
/// Configuration is read from `.env`:
///
///   CLOUDFLARE_REALTIME_APP_ID=<app id>
///   CLOUDFLARE_REALTIME_APP_TOKEN=<app secret token>
///
/// In production both values would be held by a small backend that
/// signs short-lived per-room tokens for the client. For the dev
/// scaffold we read them straight out of `dotenv`; if either is
/// missing the client reports `isConfigured = false` and the UI
/// falls back to a "needs setup" empty-state.
class CloudflareRealtimeClient {
  CloudflareRealtimeClient({
    String? appId,
    String? appToken,
    String? baseUrl,
    http.Client? httpClient,
  })  : _appId = appId ?? _envOrNull('CLOUDFLARE_REALTIME_APP_ID'),
        _appToken = appToken ?? _envOrNull('CLOUDFLARE_REALTIME_APP_TOKEN'),
        _baseUrl = baseUrl ?? 'https://rtc.live.cloudflare.com/v1',
        _http = httpClient ?? http.Client();

  final String? _appId;
  final String? _appToken;
  final String _baseUrl;
  final http.Client _http;

  static String? _envOrNull(String key) {
    try {
      final String v = dotenv.env[key] ?? '';
      return v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  /// True if the App ID + App Token are present. The UI gates the
  /// study-room feature on this so an unconfigured app shows a
  /// "feature disabled" empty-state instead of crashing on the
  /// first network call.
  bool get isConfigured => _appId != null && _appToken != null;

  Map<String, String> get _authHeaders => <String, String>{
        'Authorization': 'Bearer ${_appToken ?? ''}',
        'Content-Type': 'application/json',
      };

  /// Creates a new SFU session, optionally seeded with an SDP offer
  /// and tracks. Returns the parsed session response (`sessionId` +
  /// `sessionDescription` answer + per-track entries).
  Future<NewSessionResponse> createSession({
    String? sdpOffer,
    List<NewTrackRequest> tracks = const <NewTrackRequest>[],
  }) async {
    _requireConfigured();
    final Uri uri = Uri.parse('$_baseUrl/apps/$_appId/sessions/new');
    final Map<String, dynamic> body = <String, dynamic>{
      if (sdpOffer != null)
        'sessionDescription': <String, String>{
          'type': 'offer',
          'sdp': sdpOffer,
        },
      if (tracks.isNotEmpty)
        'tracks': <Map<String, dynamic>>[
          for (final NewTrackRequest t in tracks) t.toJson(),
        ],
    };
    final http.Response res = await _http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _checkStatus(res, 'createSession');
    return NewSessionResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Adds tracks to an existing session. Returns the SFU's SDP
  /// answer along with the per-track ack payload.
  Future<TracksResponse> addTracks({
    required String sessionId,
    required String sdpOffer,
    required List<NewTrackRequest> tracks,
  }) async {
    _requireConfigured();
    final Uri uri =
        Uri.parse('$_baseUrl/apps/$_appId/sessions/$sessionId/tracks/new');
    final http.Response res = await _http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode(<String, dynamic>{
        'sessionDescription': <String, String>{
          'type': 'offer',
          'sdp': sdpOffer,
        },
        'tracks': <Map<String, dynamic>>[
          for (final NewTrackRequest t in tracks) t.toJson(),
        ],
      }),
    );
    _checkStatus(res, 'addTracks');
    return TracksResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Subscribes a session to remote tracks (audio + video) that were
  /// previously published by another session in the same app. The
  /// SFU returns an SDP offer that the local PeerConnection then
  /// answers via [renegotiate].
  Future<TracksResponse> pullTracks({
    required String sessionId,
    required List<RemoteTrackRef> remoteTracks,
  }) async {
    _requireConfigured();
    final Uri uri =
        Uri.parse('$_baseUrl/apps/$_appId/sessions/$sessionId/tracks/new');
    final http.Response res = await _http.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode(<String, dynamic>{
        'tracks': <Map<String, dynamic>>[
          for (final RemoteTrackRef r in remoteTracks)
            <String, dynamic>{
              'location': 'remote',
              'sessionId': r.sessionId,
              'trackName': r.trackName,
            },
        ],
      }),
    );
    _checkStatus(res, 'pullTracks');
    return TracksResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Sends an SDP answer back to the SFU after pulling remote tracks
  /// that triggered a server-initiated offer.
  Future<void> renegotiate({
    required String sessionId,
    required String sdpAnswer,
  }) async {
    _requireConfigured();
    final Uri uri =
        Uri.parse('$_baseUrl/apps/$_appId/sessions/$sessionId/renegotiate');
    final http.Response res = await _http.put(
      uri,
      headers: _authHeaders,
      body: jsonEncode(<String, dynamic>{
        'sessionDescription': <String, String>{
          'type': 'answer',
          'sdp': sdpAnswer,
        },
      }),
    );
    _checkStatus(res, 'renegotiate');
  }

  /// Closes one or more tracks on the SFU. Force-leaves the session
  /// if [force] is true.
  Future<void> closeTracks({
    required String sessionId,
    required List<String> mids,
    bool force = false,
  }) async {
    _requireConfigured();
    final Uri uri =
        Uri.parse('$_baseUrl/apps/$_appId/sessions/$sessionId/tracks/close');
    final http.Response res = await _http.put(
      uri,
      headers: _authHeaders,
      body: jsonEncode(<String, dynamic>{
        'tracks': <Map<String, dynamic>>[
          for (final String mid in mids) <String, dynamic>{'mid': mid},
        ],
        'force': force,
      }),
    );
    _checkStatus(res, 'closeTracks');
  }

  void _requireConfigured() {
    if (!isConfigured) {
      throw const RealtimeNotConfiguredException();
    }
  }

  void _checkStatus(http.Response res, String op) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw RealtimeApiException(
      'Cloudflare Realtime $op failed: ${res.statusCode} ${res.body}',
    );
  }

  void close() {
    _http.close();
  }
}

/// One pushed/pulled track request payload.
class NewTrackRequest {
  const NewTrackRequest({
    required this.location,
    required this.mid,
    required this.trackName,
  });

  /// `'local'` (we are publishing) or `'remote'` (we are subscribing
  /// to a track another session published).
  final String location;

  /// Local MID from the PeerConnection's transceiver.
  final String mid;

  /// Stable name we choose for the track within this session
  /// (e.g. `cam`, `mic`).
  final String trackName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'location': location,
        'mid': mid,
        'trackName': trackName,
      };
}

/// A remote track to subscribe to (other session's published track).
class RemoteTrackRef {
  const RemoteTrackRef({required this.sessionId, required this.trackName});
  final String sessionId;
  final String trackName;
}

class NewSessionResponse {
  const NewSessionResponse({
    required this.sessionId,
    required this.sdpAnswer,
    required this.tracks,
  });

  factory NewSessionResponse.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic>? sd =
        j['sessionDescription'] as Map<String, dynamic>?;
    final List<dynamic> rawTracks = (j['tracks'] as List<dynamic>?) ?? const <dynamic>[];
    return NewSessionResponse(
      sessionId: (j['sessionId'] as String?) ?? '',
      sdpAnswer: sd == null ? null : sd['sdp'] as String?,
      tracks: <TrackEntry>[
        for (final dynamic t in rawTracks)
          if (t is Map<String, dynamic>) TrackEntry.fromJson(t),
      ],
    );
  }

  final String sessionId;
  final String? sdpAnswer;
  final List<TrackEntry> tracks;
}

class TracksResponse {
  const TracksResponse({
    required this.sdpAnswer,
    required this.requiresImmediateRenegotiation,
    required this.tracks,
  });

  factory TracksResponse.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic>? sd =
        j['sessionDescription'] as Map<String, dynamic>?;
    final List<dynamic> rawTracks =
        (j['tracks'] as List<dynamic>?) ?? const <dynamic>[];
    return TracksResponse(
      sdpAnswer: sd == null ? null : sd['sdp'] as String?,
      requiresImmediateRenegotiation:
          (j['requiresImmediateRenegotiation'] as bool?) ?? false,
      tracks: <TrackEntry>[
        for (final dynamic t in rawTracks)
          if (t is Map<String, dynamic>) TrackEntry.fromJson(t),
      ],
    );
  }

  final String? sdpAnswer;
  final bool requiresImmediateRenegotiation;
  final List<TrackEntry> tracks;
}

class TrackEntry {
  const TrackEntry({
    required this.mid,
    required this.trackName,
    required this.sessionId,
    required this.errorCode,
  });

  factory TrackEntry.fromJson(Map<String, dynamic> j) {
    return TrackEntry(
      mid: (j['mid'] as String?) ?? '',
      trackName: (j['trackName'] as String?) ?? '',
      sessionId: (j['sessionId'] as String?) ?? '',
      errorCode: j['errorCode'] as String?,
    );
  }

  final String mid;
  final String trackName;

  /// For pulled (remote) tracks this is the *publisher*'s session id.
  /// For pushed tracks the field is empty.
  final String sessionId;
  final String? errorCode;
}

/// Thrown when the client is constructed without an App ID + token
/// pair available. The UI catches this to show its "feature disabled
/// — admin needs to configure CLOUDFLARE_REALTIME_*" empty-state.
class RealtimeNotConfiguredException implements Exception {
  const RealtimeNotConfiguredException();

  @override
  String toString() =>
      'RealtimeNotConfiguredException: '
      'CLOUDFLARE_REALTIME_APP_ID + CLOUDFLARE_REALTIME_APP_TOKEN are required.';
}

class RealtimeApiException implements Exception {
  const RealtimeApiException(this.message);
  final String message;

  @override
  String toString() => 'RealtimeApiException: $message';
}
