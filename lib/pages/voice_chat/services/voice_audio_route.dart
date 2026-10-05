import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'package:batasph_mobile/pages/voice_chat/services/voice_barge_in_mode.dart';

/// The single place that decides the audio route for a voice-chat session.
/// Ported from Memori.
///
/// On Android `AudioManager.mode` and `isSpeakerphoneOn` are GLOBAL, not per
/// player: audioplayers writes both whenever a player's AudioContext is set
/// (`WrappedPlayer.updateAudioContext` — the source comments them
/// "AudioManager values are set globally") and `record` writes the same two
/// from the capture side. A build where the two disagreed lost the microphone
/// mid-session (2026-09-18, see [ThinkingSoundPlayer]). Deriving both from the
/// constants here is what stops them drifting apart again.
///
/// What actually matters for echo cancellation is the playback *usage*, and
/// that part is per player: the AEC engaged by a `VOICE_COMMUNICATION` capture
/// only references the voice-communication output path, so playback on the
/// media usage leaks into the microphone uncancelled.
class VoiceAudioRoute {
  const VoiceAudioRoute._();

  /// The two globals, defined once. Both sides below read them.
  static const _recorderMode = AudioManagerMode.modeInCommunication;
  static const _playerMode = AndroidAudioMode.inCommunication;
  static const _speakerphone = true;

  /// Which output path the reply is played on.
  ///
  /// `voiceCommunication` is the path the platform AEC is documented to
  /// reference — but Android puts it on the **voice-call stream**, which is
  /// band-limited and much quieter than media, and on the test device it was
  /// already pinned at maximum (9/9) so it cannot be turned up. Replies were
  /// audibly too quiet to use.
  ///
  /// `media` is normal loudness. Whether the AEC still cancels it is
  /// device-dependent: the capture side stays on `VOICE_COMMUNICATION` with
  /// `MODE_IN_COMMUNICATION`, and on devices whose canceller references the
  /// whole output mix rather than just the voice path, cancellation survives.
  /// [VoiceEchoProbe] is what decides — compare the leak figure against the
  /// ~36dB no-AEC baseline before trusting it.
  static const _playbackUsage = AndroidUsageType.media;

  /// The capture configuration for the conversation recorder.
  ///
  /// Plain defaults unless the microphone has to stay open while we speak:
  /// the voice-communication source narrows the band and moves the volume to
  /// the call stream, which is not worth paying for in half-duplex.
  static AndroidRecordConfig recordConfig() {
    if (!VoiceBargeIn.appliesVoiceRoute) {
      return const AndroidRecordConfig();
    }
    return const AndroidRecordConfig(
      audioSource: AndroidAudioSource.voiceCommunication,
      audioManagerMode: _recorderMode,
      speakerphone: _speakerphone,
    );
  }

  /// The context for the player that speaks the assistant's replies, or null
  /// to leave that player on the app default.
  ///
  /// Null unless [VoiceBargeIn.appliesVoiceRoute], and that matters: setting a
  /// context writes the two globals above, so a player with no need for the
  /// voice-communication route must never set one. It is also why the
  /// thinking loop and the done sound leave theirs alone.
  ///
  /// Android only. iOS gets its echo cancellation from `record`'s
  /// `setVoiceProcessingEnabled` on the input node, and changing the playback
  /// category there is a separate question this does not answer.
  static AudioContext? playerContext() {
    if (!VoiceBargeIn.appliesVoiceRoute) return null;
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: _speakerphone,
        audioMode: _playerMode,
        contentType: AndroidContentType.speech,
        usageType: _playbackUsage,
      ),
    );
  }

  /// One line describing the route actually in force, for the log.
  ///
  /// Without this the echo figure is unreadable: a leak measured while the
  /// route silently failed to apply says nothing about whether the route
  /// works. Logged once per session by the STT service.
  static String describe() {
    final recorder = recordConfig();
    final player = playerContext()?.android;
    return 'mode=${VoiceBargeIn.mode.name} '
        'platform=${defaultTargetPlatform.name} '
        'capture(source=${recorder.audioSource.name} '
        'managerMode=${recorder.audioManagerMode.name} '
        'speakerphone=${recorder.speakerphone}) '
        'playback(${player == null ? 'app default — no context set' : 'usage=${player.usageType.name} '
                  'content=${player.contentType.name} '
                  'mode=${player.audioMode.name} '
                  'speakerphone=${player.isSpeakerphoneOn}'})';
  }
}
