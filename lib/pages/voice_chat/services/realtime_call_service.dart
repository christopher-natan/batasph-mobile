import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_call_events.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// One speech-to-speech call with OpenAI Realtime over WebRTC.
///
/// WebRTC carries the audio both ways with the phone's echo cancellation,
/// so Luna does not hear herself on the loudspeaker; the "oai-events" data
/// channel carries everything else (turns, tool calls). The API mints the
/// short-lived [connect] secret; the SDP exchange goes straight to OpenAI,
/// so call audio never touches our server.
class RealtimeCallService {
  static const String _callsUrl = 'https://api.openai.com/v1/realtime/calls';
  static const Duration _connectTimeout = Duration(seconds: 15);

  final _events = StreamController<RealtimeCallEvent>.broadcast();
  RTCPeerConnection? _peer;
  RTCDataChannel? _channel;
  MediaStream? _microphone;
  bool _closed = false;

  Stream<RealtimeCallEvent> get events => _events.stream;

  bool get isOpen => _channel?.state == RTCDataChannelState.RTCDataChannelOpen;

  /// Opens the microphone (muted) and connects the call. Completes once the
  /// data channel is open; throws if the call cannot be set up.
  Future<void> connect({required String clientSecret}) async {
    final stopwatch = Stopwatch()..start();
    _microphone = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    // Nothing is sent until the call is picked up.
    setMicEnabled(false);

    final peer = await createPeerConnection({'sdpSemantics': 'unified-plan'});
    _peer = peer;
    for (final track in _microphone!.getAudioTracks()) {
      await peer.addTrack(track, _microphone!);
    }
    // Luna's voice is the remote audio track; on mobile it plays by itself.
    peer.onConnectionState = (state) {
      BatasphLogger.log('[RTC] Connection -> ${state.name}');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _emit(CallConnectionLost(state.name));
      }
    };

    final channel = await peer.createDataChannel(
      'oai-events',
      RTCDataChannelInit(),
    );
    _channel = channel;
    final opened = Completer<void>();
    channel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen &&
          !opened.isCompleted) {
        opened.complete();
      }
    };
    channel.onMessage = (message) {
      final event = RealtimeCallEvent.parse(message.text);
      if (event != null) _emit(event);
    };

    final offer = await peer.createOffer({'offerToReceiveAudio': true});
    await peer.setLocalDescription(offer);
    final answer = await _exchangeSdp(offer.sdp!, clientSecret);
    await peer.setRemoteDescription(RTCSessionDescription(answer, 'answer'));
    await opened.future.timeout(_connectTimeout);
    // A phone call on loudspeaker, like the rest of the app's audio.
    await Helper.setSpeakerphoneOn(true);
    BatasphLogger.log('[RTC] Connected | ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Sends our SDP offer to OpenAI for its answer. A dropped connection is
  /// retried once: the phone's mobile network resets connections to
  /// api.openai.com now and then (device run 2026-10-06: "Connection reset
  /// by peer" on the first call, the next call fine). An HTTP error, such as
  /// a rejected key, is not retried.
  Future<String> _exchangeSdp(String offerSdp, String clientSecret) async {
    try {
      return await _postSdp(offerSdp, clientSecret);
    } on DioException catch (error) {
      if (error.type != DioExceptionType.connectionError &&
          error.type != DioExceptionType.unknown) {
        rethrow;
      }
      BatasphLogger.warning(
        '[RTC] SDP exchange dropped, retrying once | ${error.message}',
      );
      return _postSdp(offerSdp, clientSecret);
    }
  }

  Future<String> _postSdp(String offerSdp, String clientSecret) async {
    final response = await Dio().post<String>(
      _callsUrl,
      data: offerSdp,
      options: Options(
        headers: {'Authorization': 'Bearer $clientSecret'},
        contentType: 'application/sdp',
        responseType: ResponseType.plain,
        sendTimeout: _connectTimeout,
        receiveTimeout: _connectTimeout,
      ),
    );
    final answer = response.data;
    if (answer == null || answer.isEmpty) {
      throw StateError('OpenAI returned no SDP answer');
    }
    return answer;
  }

  void setMicEnabled(bool enabled) {
    for (final track in _microphone?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  /// Sends one client event (`response.create`, `conversation.item.create`).
  void send(Map<String, dynamic> event) {
    final channel = _channel;
    if (channel == null || !isOpen) {
      BatasphLogger.warning(
        '[RTC] Not sent, channel closed | type=${event['type']}',
      );
      return;
    }
    channel.send(RTCDataChannelMessage(jsonEncode(event)));
  }

  void _emit(RealtimeCallEvent event) {
    if (!_closed) _events.add(event);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _channel?.close();
      await _peer?.close();
      for (final track in _microphone?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
      await _microphone?.dispose();
    } catch (error, stackTrace) {
      BatasphLogger.warning(
        '[RTC] Close failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _events.close();
  }
}
