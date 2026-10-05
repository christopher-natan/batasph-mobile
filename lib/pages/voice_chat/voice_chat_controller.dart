import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/pages/chat/chat_controller.dart';
import 'package:batasph_mobile/pages/voice_chat/services/cloud_tts_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/output_volume_check.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_stt_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/stt_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/thinking_sound_player.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_audio_chunk_buffer.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_call_audio_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_filler_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_farewell_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_fillers.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_greeting_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/whisper_stt_service.dart';
import 'package:batasph_mobile/services/chat_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';
import 'package:batasph_mobile/utils/voice_avatar_util.dart';

enum VoiceChatState { idle, connecting, listening, processing, speaking, error }

enum _GreetingOutcome { played, cutShort }

/// A phone call with Batas.
///
/// The call shell (ringing → greeting → silence check-in → end tone, timer) is
/// BatasPH's; the conversation engine underneath is ported from Memori:
///
/// * One continuous [RealtimeSttService] session spans the whole call. It is
///   opened, muted, behind the ringing so the mic is live the instant the
///   greeting ends; between turns it is unmuted rather than restarted.
///   If realtime fails the call falls back to [WhisperSttService] (one
///   recording per turn) while the call continues.
/// * The greeting varies between calls and is cached on device after the
///   first synthesis in each selected voice.
/// * The wait for a reply is never silent: a short spoken filler the instant
///   the transcript is final, then a soft thinking loop until the first reply
///   audio chunk.
///
/// Two counters guard against races: `_turnId` invalidates a superseded
/// SSE/audio turn, `_callFlowId` invalidates a superseded call/listen flow.
/// Every async continuation re-checks its captured id before touching state.
class VoiceChatController extends GetxController {
  static const int _maxTranscriptionErrorRetries = 1;
  static const Duration _connectRingingDuration = Duration(seconds: 1);
  static const Duration _firstSilenceCheckIn = Duration(seconds: 10);
  static const Duration _secondSilenceFarewell = Duration(seconds: 8);

  static const _voiceLabels = <String, String>{
    'luna': 'Luna',
    'aria': 'Aria',
    'atlas': 'Atlas',
    'orion': 'Orion',
  };

  final _chatService = Get.find<ChatService>();
  final _callAudioService = Get.find<VoiceCallAudioService>();
  final _ttsService = Get.find<CloudTtsService>();
  late final VoiceGreetingService _greetingService;
  final VoiceFillerService _fillerService = VoiceFillerService();
  final ThinkingSoundPlayer _thinking = ThinkingSoundPlayer();

  SttService? _sttService;
  bool _usingWhisperFallback = false;

  /// Prepared ahead (onInit, then again after each play) so the clip is
  /// normally in hand before the user taps Call.
  Future<PreparedGreeting?>? _pendingGreeting;

  /// The continuous STT session being opened behind the ringing/greeting.
  /// [_beginListening] awaits it rather than opening a second one on top.
  Future<void>? _sessionOpening;

  /// True from the start of a call until the first listen after the greeting.
  /// An STT failure in this window only swaps the service; the listen that
  /// follows the greeting starts it.
  bool _greetingPhase = false;

  final state = VoiceChatState.idle.obs;
  final userText = ''.obs;
  final agentText = ''.obs;
  final errorMessage = ''.obs;
  final callElapsedSeconds = 0.obs;

  StreamSubscription<ChatStreamEvent>? _sseSubscription;
  final VoiceAudioChunkBuffer _audioBuffer = VoiceAudioChunkBuffer();
  Timer? _callTimer;
  Timer? _inactivityTimer;

  bool _isPlayingTts = false;
  bool _sseDone = false;

  /// Continuous listening: set when the user's speech ended while we were
  /// listening, cleared when its final transcript arrives. A transcript that
  /// arrives without it belongs to sound the mic picked up during OUR turn
  /// (the thinking loop is the only unmuted window) and is dropped.
  bool _awaitingTurnTranscript = false;
  bool _autoContinue = true;
  bool _endingCall = false;
  bool _hasMicPermission = false;
  int _turnId = 0;
  int _consecutiveTranscriptionErrors = 0;
  int _callFlowId = 0;
  int _silenceCheckIns = 0;

  Future<void> Function()? onFarewellComplete;

  // Per-turn diagnostics only; never read for control flow.
  Stopwatch? _turnStopwatch;
  int _turnTokenCount = 0;
  int _turnAudioChunkCount = 0;
  Duration? _turnFirstTokenAt;
  Duration? _turnFirstAudioAt;

  @override
  void onInit() {
    super.onInit();
    _greetingService = VoiceGreetingService();
    // One observer covers every transition, so no assignment site needs its
    // own log line and none can be forgotten.
    ever<VoiceChatState>(state, (next) {
      BatasphLogger.log(
        '[Voice] State -> ${next.name} | turn=$_turnId | flow=$_callFlowId',
      );
    });
    BatasphLogger.log('[Voice] Controller init | voice=$selectedVoiceId');
    _sttService = _createSttService();
    unawaited(_sttService!.warmUp());
    _pendingGreeting = _prepareGreeting();
    unawaited(_warmUpFillers());
    unawaited(_thinking.warmUp());
  }

  // ─── Service selection ─────────────────────────────────────

  SttService _createSttService({bool forceWhisper = false}) {
    if (forceWhisper) {
      BatasphLogger.log('[Voice] Using Whisper STT (fallback)');
      _usingWhisperFallback = true;
      return WhisperSttService();
    }
    BatasphLogger.log('[Voice] Using Realtime STT (continuous)');
    _usingWhisperFallback = false;
    return RealtimeSttService();
  }

  Future<PreparedGreeting?> _prepareGreeting() async {
    try {
      return await _greetingService.prepare(
        language: MySharedPref.getAnswerLanguage().name,
        voice: selectedVoiceId,
        voiceName: selectedVoiceLabel,
        tts: _ttsService,
      );
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] Unable to prepare greeting',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _warmUpFillers() async {
    // After the greeting so the two do not compete for the first TTS call.
    await _pendingGreeting;
    await _fillerService.warmUp(voice: selectedVoiceId, tts: _ttsService);
  }

  // ─── Presentation ──────────────────────────────────────────

  String get selectedVoiceId => MySharedPref.getSelectedVoice();

  String get selectedVoiceLabel =>
      _voiceLabels[selectedVoiceId] ?? _toSentenceCase(selectedVoiceId);

  String? get selectedVoiceAvatarAsset =>
      VoiceAvatarUtil.assetFor(selectedVoiceId);

  String get callDurationLabel {
    final totalSeconds = callElapsedSeconds.value;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _continuousSessionOpen =>
      _sttService?.supportsContinuousListening == true &&
      _sttService?.isActive == true;

  /// Batas is answering (stream open or audio playing). Listening must not
  /// start underneath it; [_onSpeakingDone] starts the next listen.
  bool get _isOurTurn =>
      state.value == VoiceChatState.speaking ||
      _sseSubscription != null ||
      _isPlayingTts;

  // ─── Public actions ────────────────────────────────────────

  Future<void> startCall() async {
    final flowId = ++_callFlowId;
    BatasphLogger.log(
      '[Voice] Start call | flow=$flowId | voice=$selectedVoiceId'
      ' | silence=${MySharedPref.getVoiceSilenceSeconds()}s'
      ' | speechLanguages=${MySharedPref.getSpeechLanguages()}'
      ' | stt=${_usingWhisperFallback ? 'whisper' : 'realtime'}',
    );
    _startCallTimer();
    _autoContinue = true;
    _endingCall = false;
    _greetingPhase = true;
    _consecutiveTranscriptionErrors = 0;
    _silenceCheckIns = 0;
    _cancelInactivityTimer();
    _resetTexts(clearAgentText: true);
    await _callAudioService.stop();
    state.value = VoiceChatState.connecting;

    try {
      // Ask before the phone rings: a permission dialog over a ringing,
      // greeting call is confusing, and a denial should end the call here.
      if (!await _ensureMicrophonePermission()) {
        if (flowId != _callFlowId) return;
        BatasphLogger.error('[Voice] Microphone permission denied');
        errorMessage.value = 'Microphone permission is needed for voice calls';
        state.value = VoiceChatState.error;
        return;
      }
      if (flowId != _callFlowId) return;

      await _warnIfVolumeOff();
      final greetingFuture = _pendingGreeting ?? _prepareGreeting();
      _pendingGreeting = null;
      final greeting = await greetingFuture;
      if (flowId != _callFlowId) return;
      if (greeting == null) {
        errorMessage.value = 'Unable to prepare the voice greeting. Try again.';
        state.value = VoiceChatState.error;
        _stopCallTimer();
        return;
      }

      await _callAudioService.playRingingLoop();
      // Open the mic session behind the ringing, not after the greeting, so
      // the mic is live the instant the greeting ends.
      _sessionOpening = _openSessionBehindGreeting(flowId);
      await Future<void>.delayed(_connectRingingDuration);
      if (flowId != _callFlowId || state.value != VoiceChatState.connecting) {
        BatasphLogger.log(
          '[Voice] Start call superseded during ringing | flow=$flowId',
        );
        return;
      }

      await _callAudioService.stop();
      if (flowId != _callFlowId) {
        return;
      }

      final outcome = await _playGreeting(flowId, greeting);
      if (outcome == _GreetingOutcome.cutShort) {
        BatasphLogger.log(
          '[Voice] Start call superseded during greeting | flow=$flowId',
        );
        return;
      }
      if (!_autoContinue) {
        return;
      }

      await _beginListening(clearAgentText: false);
    } catch (error, stackTrace) {
      if (flowId != _callFlowId) {
        return;
      }
      BatasphLogger.error(
        '[Voice] Failed to start call | flow=$flowId',
        error: error,
        stackTrace: stackTrace,
      );
      await _callAudioService.stop();
      errorMessage.value = 'Failed to start voice call';
      state.value = VoiceChatState.error;
      _stopCallTimer();
    } finally {
      if (flowId == _callFlowId) {
        _greetingPhase = false;
      }
    }
  }

  Future<void> submitPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return;
    }

    BatasphLogger.log(
      '[Voice] Typed prompt | chars=${trimmed.length} | from=${state.value.name}',
    );
    _autoContinue = true;
    await _callAudioService.stop();

    if (state.value == VoiceChatState.listening ||
        state.value == VoiceChatState.processing) {
      await _sttService?.cancelSession();
    }

    if (state.value == VoiceChatState.listening ||
        state.value == VoiceChatState.processing ||
        state.value == VoiceChatState.speaking) {
      await _cancelActiveTurn(clearTexts: false);
    }

    _resetTexts(clearAgentText: true);
    userText.value = trimmed;
    _respondToUser(trimmed);
  }

  Future<void> handlePrimaryControlTap() async {
    switch (state.value) {
      case VoiceChatState.connecting:
        return;
      case VoiceChatState.speaking:
      case VoiceChatState.processing:
      case VoiceChatState.listening:
        return;
      case VoiceChatState.idle:
        await startCall();
        return;
      case VoiceChatState.error:
        await startCall();
        return;
    }
  }

  Future<void> endConversation() async {
    if (_endingCall) return;
    _endingCall = true;
    BatasphLogger.log(
      '[Voice] End call | from=${state.value.name}'
      ' | duration=${callElapsedSeconds.value}s',
    );
    _autoContinue = false;
    _cancelInactivityTimer();
    _greetingPhase = false;
    _callFlowId++;
    await _cancelActiveTurn(clearTexts: true);
    await _callAudioService.stop();
    // Drop this call's STT session entirely; the next call starts on
    // realtime again even if this one fell back to Whisper.
    await _sttService?.dispose();
    _sttService = _createSttService();
    _sessionOpening = null;
    await _ttsService.stop();
    try {
      await _callAudioService.playEndCallTone();
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] End-call tone failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _stopCallTimer();
    state.value = VoiceChatState.idle;
    if (Get.isRegistered<ChatController>()) {
      unawaited(Get.find<ChatController>().reloadHistory());
    }
  }

  // ─── Call setup ────────────────────────────────────────────

  /// A muted phone makes the call look broken — the user talks and nothing
  /// comes back. Say so before the greeting; the call goes ahead either way,
  /// since the mic works regardless and they may unmute while reading.
  Future<void> _warnIfVolumeOff() async {
    if (!await OutputVolumeCheck.isSilent()) return;
    BatasphLogger.log('[Voice] Media volume is off, asking the user to unmute');
    Get.snackbar(
      'Volume is off',
      'Turn up your media volume to hear Batas.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Opens the continuous STT session, muted, while the phone rings and the
  /// greeting plays. Nothing is surfaced from here: [_beginListening] runs
  /// right after and owns the permission and error paths.
  Future<void> _openSessionBehindGreeting(int flowId) async {
    final stt = _sttService;
    if (stt == null || !stt.supportsContinuousListening) return;
    if (_continuousSessionOpen) return;
    try {
      if (!await _ensureMicrophonePermission()) return;
      if (flowId != _callFlowId || _continuousSessionOpen) return;
      _wireSttCallbacks();
      // Muted from the first chunk: the ringing and greeting are playing.
      stt.setMuted(true);
      await stt.startSession();
      if (!stt.isActive) {
        // Failed while opening; onError already swapped in the fallback.
        return;
      }
      BatasphLogger.log(
        '[Voice] STT session opened behind greeting | flow=$flowId',
      );
    } catch (error, stackTrace) {
      // _beginListening will try again on the normal path and report it.
      BatasphLogger.warning(
        '[Voice] STT open behind greeting failed, deferring | flow=$flowId',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Speaks the opener prepared before ringing. Never runs on the
  /// auto-continue loop.
  ///
  /// [_GreetingOutcome.cutShort] means ending the call stopped it by bumping the
  /// flow id and decide the next state themselves, so the caller must not
  /// start listening on top of that.
  Future<_GreetingOutcome> _playGreeting(
    int flowId,
    PreparedGreeting greeting,
  ) async {
    final turnId = ++_turnId;
    if (turnId != _turnId || flowId != _callFlowId) {
      return _GreetingOutcome.cutShort;
    }

    BatasphLogger.log('[Voice] Greeting | turn=$turnId | "${greeting.text}"');
    agentText.value = greeting.text;
    state.value = VoiceChatState.speaking;
    _sttService?.setMuted(true);
    _isPlayingTts = true;
    try {
      await _ttsService.playAudio(greeting.audio);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] Greeting playback failed',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      if (turnId == _turnId) _isPlayingTts = false;
    }
    if (turnId != _turnId || flowId != _callFlowId) {
      return _GreetingOutcome.cutShort;
    }
    return _GreetingOutcome.played;
  }

  Future<bool> _ensureMicrophonePermission() async {
    if (_hasMicPermission) {
      return true;
    }
    final recorder = AudioRecorder();
    final bool granted;
    try {
      granted = await recorder.hasPermission();
    } finally {
      recorder.dispose();
    }
    _hasMicPermission = granted;
    BatasphLogger.log('[Voice] Mic permission: $granted');
    return granted;
  }

  void _wireSttCallbacks() {
    _sttService!
      ..onResult = _onSttResult
      ..onError = _onSttError
      ..onTranscribing = _onSttTranscribing
      ..onSpeechStarted = _onSttSpeechStarted
      ..onIdle = _onSttIdle;
  }

  // ─── STT callbacks ─────────────────────────────────────────

  void _onSttSpeechStarted() {
    if (state.value == VoiceChatState.listening) {
      _cancelInactivityTimer();
    } else {
      // Sound during our own turn read as speech (the thinking loop is the
      // only unmuted window). Logged, not acted on.
      BatasphLogger.log(
        '[Voice] Speech detected during our turn | state=${state.value.name}'
        ' | playing=$_isPlayingTts | thinking=${_thinking.isPlaying}',
      );
    }
  }

  void _onSttTranscribing() {
    if (state.value == VoiceChatState.listening) {
      _cancelInactivityTimer();
      _awaitingTurnTranscript = true;
      state.value = VoiceChatState.processing;
    } else {
      BatasphLogger.log(
        '[Voice] Speech stopped during our turn | state=${state.value.name}',
      );
    }
  }

  void _onSttResult(String transcript, bool isFinal) {
    if (!_autoContinue) return;
    final isUsersTurn =
        state.value == VoiceChatState.listening || _awaitingTurnTranscript;
    if (!isUsersTurn) {
      if (isFinal) {
        BatasphLogger.log(
          '[Voice] Transcript during our turn dropped'
          ' | state=${state.value.name} | "$transcript"',
        );
      }
      return;
    }
    if (isFinal) _awaitingTurnTranscript = false;

    _consecutiveTranscriptionErrors = 0;
    userText.value = transcript;

    if (!isFinal) {
      return;
    }

    final trimmed = transcript.trim();
    if (trimmed.isNotEmpty) {
      _silenceCheckIns = 0;
      _cancelInactivityTimer();
      BatasphLogger.log(
        '[Voice] Transcript | chars=${trimmed.length} | "$trimmed"',
      );
      _respondToUser(trimmed);
      return;
    }

    if (_continuousSessionOpen) {
      // The server VAD segmented noise into an empty turn; the session is
      // still up, so just keep listening. Real silence ends via onIdle.
      BatasphLogger.log('[Voice] Empty transcript on open session, listening');
      if (state.value == VoiceChatState.processing) {
        state.value = VoiceChatState.listening;
      }
      _armInactivityTimer();
      return;
    }

    BatasphLogger.log('[Voice] Empty transcript, continuing to listen');
    if (_autoContinue) _beginListeningSafe(clearAgentText: false);
  }

  /// The continuous session closed after a long silence. Reopen it so the
  /// call remains ready until the user says goodbye or ends it manually.
  void _onSttIdle() {
    BatasphLogger.log('[Voice] STT idle, reconnecting listening');
    _awaitingTurnTranscript = false;
    if (_autoContinue && state.value == VoiceChatState.listening) {
      _beginListeningSafe(clearAgentText: false);
    }
  }

  void _onSttError(String error) {
    if (_endingCall) return;
    BatasphLogger.error(
      '[Voice] Transcription error: $error'
      ' | retries=$_consecutiveTranscriptionErrors/$_maxTranscriptionErrorRetries'
      ' | whisper=$_usingWhisperFallback | greetingPhase=$_greetingPhase',
    );
    _awaitingTurnTranscript = false;

    // Realtime failed and Whisper has not been tried yet: swap services. If
    // it is not the user's turn right now (greeting, or Batas answering),
    // the listen that follows starts it; otherwise start listening now.
    if (!_usingWhisperFallback && _autoContinue) {
      BatasphLogger.warning(
        '[Voice] Realtime STT failed, falling back to Whisper',
      );
      unawaited(_swapToWhisper());
      return;
    }

    if (_greetingPhase || _isOurTurn) {
      return;
    }

    if (_autoContinue &&
        _consecutiveTranscriptionErrors < _maxTranscriptionErrorRetries) {
      _consecutiveTranscriptionErrors++;
      BatasphLogger.log('[Voice] Retrying listen after transcription error');
      _beginListeningSafe(clearAgentText: false);
      return;
    }

    _consecutiveTranscriptionErrors = 0;
    errorMessage.value = error;
    state.value = VoiceChatState.error;
  }

  /// Replaces the realtime service with Whisper. The old service is fully
  /// torn down before Whisper opens its own recorder — two recorders
  /// overlapping on Android fails with a busy recorder. Listening starts
  /// here only when it is the user's turn; otherwise the listen that
  /// follows the greeting or the reply starts it.
  Future<void> _swapToWhisper() async {
    final flowId = _callFlowId;
    final old = _sttService;
    _sttService = _createSttService(forceWhisper: true);
    _consecutiveTranscriptionErrors = 0;
    await old?.dispose();
    if (flowId != _callFlowId || !_autoContinue) {
      return;
    }
    if (_greetingPhase || _isOurTurn) {
      return;
    }
    _beginListeningSafe(clearAgentText: false);
  }

  // ─── Backend SSE ───────────────────────────────────────────

  void _respondToUser(String text) {
    _silenceCheckIns = 0;
    _cancelInactivityTimer();
    final farewell = VoiceFarewellService.replyFor(
      text,
      language: MySharedPref.getAnswerLanguage().name,
    );
    if (farewell != null) {
      unawaited(_speakFarewell(farewell));
    } else {
      _sendToBackend(text);
    }
  }

  Future<void> _speakFarewell(String reply) async {
    final turnId = ++_turnId;
    _autoContinue = false;
    _cancelInactivityTimer();
    _callFlowId++;
    _awaitingTurnTranscript = false;
    _sttService?.setMuted(true);
    state.value = VoiceChatState.speaking;
    agentText.value = reply;
    errorMessage.value = '';
    _isPlayingTts = true;
    BatasphLogger.log('[Voice] Farewell | turn=$turnId | "$reply"');
    try {
      if (!_continuousSessionOpen) await _sttService?.cancelSession();
      if (turnId != _turnId) return;
      await _ttsService.speak(reply);
      if (turnId == _turnId) await onFarewellComplete?.call();
    } catch (error, stackTrace) {
      if (turnId != _turnId) return;
      BatasphLogger.error(
        '[Voice] Farewell playback failed',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to play farewell';
      state.value = VoiceChatState.error;
    } finally {
      if (turnId == _turnId) _isPlayingTts = false;
    }
  }

  void _sendToBackend(String text) {
    final turnId = ++_turnId;
    _cancelSse();
    state.value = VoiceChatState.processing;
    agentText.value = '';
    errorMessage.value = '';
    _audioBuffer.clear();
    _sseDone = false;
    _isPlayingTts = false;
    _turnStopwatch = Stopwatch()..start();
    _turnTokenCount = 0;
    _turnAudioChunkCount = 0;
    _turnFirstTokenAt = null;
    _turnFirstAudioAt = null;

    _sttService?.setMuted(true);

    final language = MySharedPref.getAnswerLanguage().name;
    final voice = MySharedPref.getSelectedVoice();
    BatasphLogger.log(
      '[Voice] Send | turn=$turnId | chars=${text.length}'
      ' | language=$language | voice=$voice',
    );

    _sseSubscription = _chatService
        .streamMessage(text, mode: 'voice', language: language, voice: voice)
        .listen(
          (event) => _onSseEvent(turnId, event),
          onError: (Object error, StackTrace stackTrace) {
            if (turnId != _turnId) {
              return;
            }
            BatasphLogger.error(
              '[Voice] Stream failed | turn=$turnId'
              ' | ${_turnStopwatch?.elapsedMilliseconds}ms',
              error: error,
              stackTrace: stackTrace,
            );
            unawaited(_thinking.stop());
            errorMessage.value = 'Failed to get response';
            state.value = VoiceChatState.error;
          },
          onDone: () {
            if (turnId != _turnId) {
              return;
            }
            BatasphLogger.log(
              '[Voice] Stream closed | turn=$turnId'
              ' | ${_turnStopwatch?.elapsedMilliseconds}ms'
              ' | tokens=$_turnTokenCount | audioChunks=$_turnAudioChunkCount'
              ' | playing=$_isPlayingTts | queued=${!_audioBuffer.isEmpty}',
            );
            _sseSubscription = null;
            _sseDone = true;
            if (!_isPlayingTts && _audioBuffer.isEmpty) {
              unawaited(_thinking.stop());
              unawaited(_onSpeakingDone(turnId));
            }
          },
        );

    unawaited(_playFillerThenThinking(turnId, text));
  }

  /// Covers the wait: a short spoken filler right away — "Checking." for a
  /// real question, a brief "Okay." for a one- or two-word turn — then the
  /// thinking loop until the first reply chunk. Reply audio that arrives
  /// during the filler queues behind it ([_isPlayingTts] keeps
  /// [_processAudioQueue] from starting underneath) and is drained as soon
  /// as the filler ends.
  Future<void> _playFillerThenThinking(int turnId, String text) async {
    final kind = VoiceFillers.isShortTurn(text)
        ? FillerKind.acknowledging
        : FillerKind.checking;
    final clip = _fillerService.next(kind);
    if (clip != null &&
        turnId == _turnId &&
        !_isPlayingTts &&
        _audioBuffer.isEmpty &&
        !_sseDone) {
      _isPlayingTts = true;
      _sttService?.setMuted(true);
      BatasphLogger.log(
        '[Voice] Filler | turn=$turnId | kind=${kind.name} | bytes=${clip.length}',
      );
      try {
        await _ttsService.playAudio(clip);
      } catch (error) {
        BatasphLogger.debug('[Voice] Filler playback error ignored: $error');
      }
      if (turnId != _turnId) {
        return; // cancelled; _cancelActiveTurn reset the flags
      }
      _isPlayingTts = false;
    } else {
      BatasphLogger.debug(
        '[Voice] No ${kind.name} filler | turn=$turnId'
        ' | ready=${_fillerService.readyCount} | playing=$_isPlayingTts'
        ' | buffered=${!_audioBuffer.isEmpty} | done=$_sseDone',
      );
    }

    if (turnId != _turnId) return;
    // An SSE error leaves _sseDone false (nothing more is coming, but it is
    // not "done" either), so check the error state explicitly or the loop
    // would start with nothing to stop it.
    if (_audioBuffer.isEmpty &&
        !_sseDone &&
        state.value != VoiceChatState.error) {
      await _thinking.start();
      // The loop is the one window where the mic streams during our turn;
      // anything it hears is logged in _onSttSpeechStarted, not acted on.
      _sttService?.setMuted(false);
    }
    if (turnId != _turnId) return;
    await _processAudioQueue(turnId);
  }

  void _onSseEvent(int turnId, ChatStreamEvent event) {
    if (turnId != _turnId) {
      return;
    }

    switch (event) {
      case TokenEvent():
        if (_turnTokenCount == 0) {
          _turnFirstTokenAt = _turnStopwatch?.elapsed;
          BatasphLogger.log(
            '[Voice] First token | turn=$turnId'
            ' | ${_turnFirstTokenAt?.inMilliseconds}ms',
          );
        }
        _turnTokenCount++;
        agentText.value += event.text;
      case AudioEvent():
        if (_turnAudioChunkCount == 0) {
          _turnFirstAudioAt = _turnStopwatch?.elapsed;
          BatasphLogger.log(
            '[Voice] First audio | turn=$turnId'
            ' | ${_turnFirstAudioAt?.inMilliseconds}ms',
          );
        }
        _turnAudioChunkCount++;
        BatasphLogger.debug(
          '[Voice] Audio chunk | turn=$turnId | index=${event.index}'
          ' | bytes=${event.audio.length}',
        );
        _enqueueAudio(turnId, event.index, event.audio);
      case DoneEvent():
        BatasphLogger.log(
          '[Voice] Done | turn=$turnId'
          ' | ${_turnStopwatch?.elapsedMilliseconds}ms'
          ' | firstToken=${_turnFirstTokenAt?.inMilliseconds}ms'
          ' | firstAudio=${_turnFirstAudioAt?.inMilliseconds}ms'
          ' | tokens=$_turnTokenCount | audioChunks=$_turnAudioChunkCount'
          ' | chars=${agentText.value.length}'
          ' | sources=${event.sources.length}'
          ' | status=${event.status} | lang=${event.responseLanguage}'
          ' | cached=${event.cached} | noResults=${event.noResults}',
        );
        if (event.disclaimer.trim().isNotEmpty) {
          agentText.value =
              '${agentText.value.trim()}\n\n${event.disclaimer.trim()}';
        }
      case StreamWarningEvent():
        BatasphLogger.warning(
          '[Voice] Stream warning | turn=$turnId | ${event.code} ${event.message}',
        );
        if (event.code == 'voice_synthesis_failed') {
          errorMessage.value = event.message;
        }
      case StreamErrorEvent():
        BatasphLogger.error(
          '[Voice] Stream error | turn=$turnId | ${event.message}',
        );
        unawaited(_thinking.stop());
        errorMessage.value = event.message;
        state.value = VoiceChatState.error;
      case UserMessageEvent():
        break;
    }
  }

  // ─── Audio playback (inline TTS from SSE) ──────────────────

  void _enqueueAudio(int turnId, int index, Uint8List audioBytes) {
    if (turnId != _turnId) {
      return;
    }
    _audioBuffer.add(index, audioBytes);
    unawaited(_processAudioQueue(turnId));
  }

  Future<void> _processAudioQueue(int turnId) async {
    if (_isPlayingTts || turnId != _turnId) {
      return;
    }

    while (turnId == _turnId) {
      final audioBytes = _audioBuffer.popNext();
      if (audioBytes == null) {
        break;
      }
      _isPlayingTts = true;
      _sttService?.setMuted(true);
      await _thinking.stop();
      if (turnId != _turnId) {
        _isPlayingTts = false;
        return;
      }

      if (state.value == VoiceChatState.processing) {
        state.value = VoiceChatState.speaking;
      }

      try {
        await _ttsService.playAudio(audioBytes);
      } catch (error, stackTrace) {
        if (turnId != _turnId) {
          _isPlayingTts = false;
          return;
        }
        BatasphLogger.error(
          '[Voice] Audio playback failed | turn=$turnId',
          error: error,
          stackTrace: stackTrace,
        );
        errorMessage.value = 'Failed to play voice response';
        state.value = VoiceChatState.error;
        _isPlayingTts = false;
        return;
      }

      _isPlayingTts = false;
    }

    if (turnId != _turnId) {
      return;
    }
    if (_sseDone && !_isPlayingTts && _audioBuffer.isEmpty) {
      BatasphLogger.log(
        '[Voice] Speaking done | turn=$turnId'
        ' | ${_turnStopwatch?.elapsedMilliseconds}ms',
      );
      await _onSpeakingDone(turnId);
    }
  }

  // ─── Listening ─────────────────────────────────────────────

  Future<void> _beginListening({required bool clearAgentText}) async {
    final flowId = ++_callFlowId;
    _greetingPhase = false;

    await _callAudioService.stop();
    if (flowId != _callFlowId || !_autoContinue) return;
    if (!await _ensureMicrophonePermission()) {
      if (flowId != _callFlowId || !_autoContinue) return;
      BatasphLogger.error('[Voice] Microphone permission denied');
      errorMessage.value = 'Microphone permission is needed for voice calls';
      state.value = VoiceChatState.error;
      return;
    }

    // If the session is still being opened behind the greeting, let it
    // finish rather than starting a second one on top of it.
    final opening = _sessionOpening;
    if (opening != null) {
      await opening;
      if (flowId != _callFlowId || !_autoContinue) return;
      _sessionOpening = null;
    }

    _awaitingTurnTranscript = false;
    if (_continuousSessionOpen) {
      // The session outlives the turn: nothing to mint or connect, the mic
      // is already running. Unmute and we are listening this instant.
      _resetTexts(clearAgentText: clearAgentText);
      _sttService!.setMuted(false);
      state.value = VoiceChatState.listening;
      _armInactivityTimer();
      return;
    }

    await _sttService!.cancelSession();
    if (flowId != _callFlowId || !_autoContinue) return;
    _resetTexts(clearAgentText: clearAgentText);
    // Not "listening" yet: the mic is live only once startSession() has
    // minted the secret, opened the socket and started the recorder. Saying
    // "Listening" before that invites the user to talk into a closed mic.
    state.value = VoiceChatState.processing;
    _wireSttCallbacks();
    await _sttService!.startSession();
    if (flowId != _callFlowId || !_autoContinue) return;
    if (!_sttService!.isActive) {
      // Cancelled or failed while connecting: the end-call or error path
      // already set the state.
      return;
    }
    if (state.value == VoiceChatState.processing) {
      state.value = VoiceChatState.listening;
      _armInactivityTimer();
    }
  }

  void _beginListeningSafe({required bool clearAgentText}) {
    _beginListening(clearAgentText: clearAgentText).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      BatasphLogger.error(
        '[Voice] Failed to restart listening',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to start listening';
      state.value = VoiceChatState.error;
    });
  }

  void _armInactivityTimer() {
    if (!_autoContinue || state.value != VoiceChatState.listening) return;
    if (_inactivityTimer?.isActive == true) return;

    final duration = _silenceCheckIns == 0
        ? _firstSilenceCheckIn
        : _secondSilenceFarewell;
    BatasphLogger.log(
      '[Voice] Silence timer armed | stage=$_silenceCheckIns'
      ' | ${duration.inSeconds}s',
    );
    _inactivityTimer = Timer(duration, () {
      _inactivityTimer = null;
      if (!_autoContinue || state.value != VoiceChatState.listening) return;
      if (_silenceCheckIns == 0) {
        unawaited(_speakSilenceCheckIn());
      } else {
        final language = MySharedPref.getAnswerLanguage().name;
        unawaited(
          _speakFarewell(
            VoiceFarewellService.silenceFarewell(language: language),
          ),
        );
      }
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  Future<void> _speakSilenceCheckIn() async {
    if (!_autoContinue || state.value != VoiceChatState.listening) return;

    final turnId = ++_turnId;
    final language = MySharedPref.getAnswerLanguage().name;
    final reply = VoiceFarewellService.silenceCheckIn(language: language);
    _cancelInactivityTimer();
    _callFlowId++;
    _awaitingTurnTranscript = false;
    _sttService?.setMuted(true);
    state.value = VoiceChatState.speaking;
    agentText.value = reply;
    errorMessage.value = '';
    _isPlayingTts = true;
    BatasphLogger.log('[Voice] Silence check-in | turn=$turnId | "$reply"');

    try {
      if (!_continuousSessionOpen) await _sttService?.cancelSession();
      if (turnId != _turnId || !_autoContinue) return;
      await _ttsService.speak(reply);
      if (turnId != _turnId || !_autoContinue) return;
      _isPlayingTts = false;
      _silenceCheckIns = 1;
      await _beginListening(clearAgentText: false);
    } catch (error, stackTrace) {
      if (turnId != _turnId) return;
      BatasphLogger.error(
        '[Voice] Silence check-in playback failed',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to continue the call';
      state.value = VoiceChatState.error;
    } finally {
      if (turnId == _turnId) _isPlayingTts = false;
    }
  }

  Future<void> _onSpeakingDone(int turnId) async {
    if (turnId != _turnId) {
      return;
    }

    BatasphLogger.log(
      '[Voice] Turn complete | turn=$turnId | autoContinue=$_autoContinue',
    );
    await _thinking.stop();
    if (_autoContinue) {
      await _beginListening(clearAgentText: false);
    }
  }

  Future<void> _cancelActiveTurn({required bool clearTexts}) async {
    BatasphLogger.log(
      '[Voice] Cancel turn | turn=$_turnId | sseDone=$_sseDone'
      ' | playing=$_isPlayingTts | queued=${!_audioBuffer.isEmpty}',
    );
    _turnId++;
    _cancelSse();
    _audioBuffer.clear();
    _sseDone = false;
    _isPlayingTts = false;
    _awaitingTurnTranscript = false;
    await Future.wait<void>([_thinking.stop(), _ttsService.stop()]);

    if (clearTexts) {
      _resetTexts(clearAgentText: true);
    } else {
      errorMessage.value = '';
    }
  }

  void _cancelSse() {
    _chatService.cancelStream();
    _sseSubscription?.cancel();
    _sseSubscription = null;
  }

  void _resetTexts({required bool clearAgentText}) {
    userText.value = '';
    if (clearAgentText) {
      agentText.value = '';
    }
    errorMessage.value = '';
  }

  @override
  void onClose() {
    BatasphLogger.log('[Voice] Controller close | state=${state.value.name}');
    _autoContinue = false;
    _cancelInactivityTimer();
    onFarewellComplete = null;
    _greetingPhase = false;
    _callFlowId++;
    _stopCallTimer();
    _audioBuffer.clear();
    unawaited(_callAudioService.dispose());
    _chatService.cancelStream();
    _sseSubscription?.cancel();
    unawaited(_sttService?.dispose());
    _sttService = null;
    unawaited(_ttsService.dispose());
    unawaited(_thinking.dispose());
    super.onClose();
  }

  // ─── Call shell ────────────────────────────────────────────

  void _startCallTimer() {
    _stopCallTimer();
    callElapsedSeconds.value = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callElapsedSeconds.value++;
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    callElapsedSeconds.value = 0;
  }

  String _toSentenceCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}
