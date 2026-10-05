import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/pages/voice_chat/services/barge_in_detector.dart';
import 'package:batasph_mobile/pages/voice_chat/services/caller_identity_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/cloud_tts_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/echo_text_guard.dart';
import 'package:batasph_mobile/pages/voice_chat/services/output_volume_check.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_stt_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/stt_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/thinking_sound_player.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_audio_chunk_buffer.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_barge_in_mode.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_call_audio_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_echo_probe.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_filler_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_farewell_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_greeting_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/whisper_stt_service.dart';
import 'package:batasph_mobile/services/chat_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

enum VoiceChatState { idle, connecting, listening, processing, speaking, error }

enum _GreetingOutcome { played, cutShort }

/// Where the call is in finding out who is calling.
enum _IdentityStep { none, askingName, confirmingName }

/// A phone call with Atty. Luna.
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
///   first synthesis. A first-time caller is asked their name, which is
///   saved on the phone; a returning caller is asked to confirm it, and a
///   different name replaces it ([CallerIdentityService]).
/// * A call lasts at most five minutes: Luna warns thirty seconds before
///   and says goodbye when time is up, after any answer she is giving.
/// * The wait for a reply is never silent: a short spoken filler the instant
///   the transcript is final, then a soft thinking loop until the first reply
///   audio chunk.
/// * Barge-in (also from Memori, configured in [VoiceBargeIn]): while Luna
///   speaks the mic stays open behind an uplink gate; speech ducks her,
///   confirmed words stop her and hand the floor over, a false alarm lets
///   her carry on. The user's Mute always wins over it.
///
/// Two counters guard against races: `_turnId` invalidates a superseded
/// SSE/audio turn, `_callFlowId` invalidates a superseded call/listen flow.
/// Every async continuation re-checks its captured id before touching state.
class VoiceChatController extends GetxController {
  static const int _maxTranscriptionErrorRetries = 1;
  static const Duration _firstSilenceCheckIn = Duration(seconds: 10);
  static const Duration _secondSilenceFarewell = Duration(seconds: 8);
  static const int _callLimitSeconds = 5 * 60;
  static const int _timeWarningSeconds = _callLimitSeconds - 30;

  final _chatService = Get.find<ChatService>();
  final _callAudioService = Get.find<VoiceCallAudioService>();
  final _ttsService = Get.find<CloudTtsService>();
  late final VoiceGreetingService _greetingService;
  final VoiceFillerService _fillerService = VoiceFillerService();
  final ThinkingSoundPlayer _thinking = ThinkingSoundPlayer();
  final CallerIdentityService _identity = CallerIdentityService();
  final Random _random = Random();

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

  /// The sentences of this reply Luna has spoken so far, so echo heard
  /// mid-reply is recognised as hers.
  String _spokenText = '';
  final errorMessage = ''.obs;
  final callElapsedSeconds = 0.obs;

  /// The user's own mute. Independent of the turn-taking mute: while it is
  /// on, nothing the user says is sent, whoever's turn it is.
  final isUserMuted = false.obs;

  /// The call is over and the page shows its summary. Set by
  /// [endConversation], cleared when a new call starts.
  final callEnded = false.obs;
  final endedCallSeconds = 0.obs;
  final lastQuestion = ''.obs;
  final lastLegalBasis = <String>[].obs;

  StreamSubscription<ChatStreamEvent>? _sseSubscription;
  final VoiceAudioChunkBuffer _audioBuffer = VoiceAudioChunkBuffer();
  Timer? _callTimer;
  Timer? _inactivityTimer;

  bool _isPlayingTts = false;
  bool _sseDone = false;

  /// Continuous listening: set when the user's speech ended while we were
  /// listening, cleared when its final transcript arrives. A transcript that
  /// arrives without it belongs to sound the mic picked up during OUR turn;
  /// it is only ever used as barge-in evidence, never sent.
  bool _awaitingTurnTranscript = false;

  /// True from the moment we take the microphone for our own audio until it
  /// is handed back to the user. Scopes barge-in and the echo measurement.
  bool _holdingMic = false;

  /// Between the VAD's speech_started and the final transcript, so the room
  /// floor is never measured through the user's own voice.
  bool _userIsSpeaking = false;

  /// Whether any of our own audio played this turn, so the mic-reopen guard
  /// is only paid when there is something to drain.
  bool _spokeAloudThisTurn = false;

  /// Measures whether the microphone hears Luna (logged as `[BARGE] echo`).
  final _echoProbe = VoiceEchoProbe();

  /// Catches our own voice coming back as a "user" transcript.
  final _echoGuard = EchoTextGuard();

  /// Decides whether speech over the reply is a real interruption.
  late final _bargeIn = BargeInDetector(
    onDuck: _onBargeInDuck,
    onConfirm: _onBargeInConfirmed,
    onRelease: _onBargeInReleased,
  );

  bool _autoContinue = true;
  bool _endingCall = false;
  bool _hasMicPermission = false;
  int _turnId = 0;
  int _consecutiveTranscriptionErrors = 0;
  int _callFlowId = 0;
  int _silenceCheckIns = 0;

  /// A realtime failure gets one fresh session before the call drops to
  /// Whisper. A single network reset used to send the whole call to the
  /// fallback, whose transcriber invents sentences out of room noise
  /// (device run 2026-10-05: "If you have any questions, please post a
  /// comment." was sent as the user's question).
  bool _realtimeRetried = false;

  _IdentityStep _identityStep = _IdentityStep.none;

  /// The saved name this call's greeting asked about; null when the
  /// greeting asked for a name.
  String? _greetedName;

  /// One "sorry, what was your name?" per call before moving on.
  bool _identityRetried = false;

  /// Thirty seconds left: the warning is spoken the next time the floor
  /// would go back to the caller.
  bool _timeWarningDue = false;

  /// Five minutes are up: the goodbye is spoken as soon as Luna is not
  /// mid-answer, and the call ends.
  bool _timeUp = false;

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
    BatasphLogger.log(
      '[Voice] Controller init | voice=${AppConfig.personaVoice}',
    );
    _sttService = _createSttService();
    unawaited(_sttService!.warmUp());
    _pendingGreeting = _prepareGreeting();
    unawaited(_fillerService.load());
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
    return RealtimeSttService(continuous: true);
  }

  Future<PreparedGreeting?> _prepareGreeting() async {
    try {
      return await _greetingService.prepare(
        voice: AppConfig.personaVoice,
        voiceName: AppConfig.personaName,
        tts: _ttsService,
        callerName: MySharedPref.getCallerName(),
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

  // ─── Presentation ──────────────────────────────────────────

  String get callDurationLabel => _formatDuration(callElapsedSeconds.value);

  String get endedCallDurationLabel => _formatDuration(endedCallSeconds.value);

  String _formatDuration(int totalSeconds) {
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
      '[Voice] Start call | flow=$flowId | voice=${AppConfig.personaVoice}'
      ' | speechLanguages=${MySharedPref.getSpeechLanguages()}'
      ' | stt=${_usingWhisperFallback ? 'whisper' : 'realtime'}',
    );
    _startCallTimer();
    callEnded.value = false;
    lastQuestion.value = '';
    lastLegalBasis.clear();
    _echoProbe.reset();
    _echoGuard.clear();
    _autoContinue = true;
    _endingCall = false;
    _greetingPhase = true;
    _consecutiveTranscriptionErrors = 0;
    _silenceCheckIns = 0;
    _realtimeRetried = false;
    _identityStep = _IdentityStep.none;
    _greetedName = null;
    _identityRetried = false;
    _timeWarningDue = false;
    _timeUp = false;
    _cancelInactivityTimer();
    _resetTexts();
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

      // The phone rings while the greeting is prepared and the mic session
      // opens behind it, so the mic is live the instant the greeting ends.
      final ringing = _callAudioService.playRingback();
      _sessionOpening = _openSessionBehindGreeting(flowId);
      final greeting = await greetingFuture;
      await ringing;
      if (flowId != _callFlowId || state.value != VoiceChatState.connecting) {
        BatasphLogger.log(
          '[Voice] Start call superseded during ringing | flow=$flowId',
        );
        return;
      }
      if (greeting == null) {
        errorMessage.value = 'Unable to prepare the voice greeting. Try again.';
        state.value = VoiceChatState.error;
        _stopCallTimer();
        return;
      }

      // Set before the greeting plays: a caller may answer over it.
      _greetedName = greeting.callerName;
      _identityStep = greeting.callerName == null
          ? _IdentityStep.askingName
          : _IdentityStep.confirmingName;
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

      await _beginListening();
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
    endedCallSeconds.value = callElapsedSeconds.value;
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
      await _callAudioService.playCallDroppedTone();
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] End-call tone failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _stopCallTimer();
    _bargeIn.reset();
    _holdingMic = false;
    _echoProbe.logSession('mode=${VoiceBargeIn.mode.name} call ended');
    isUserMuted.value = false;
    state.value = VoiceChatState.idle;
    callEnded.value = true;
  }

  // ─── User controls ─────────────────────────────────────────

  /// Leaves the ended-call summary for Home.
  void leaveCall() {
    BatasphLogger.log('[Voice] Leave call screen');
    Get.back();
  }

  /// Mutes the user like a phone's mute key: nothing they say is sent, and
  /// the silence check-in does not fire, since a muted caller is not gone.
  void toggleMute() {
    final muted = !isUserMuted.value;
    isUserMuted.value = muted;
    BatasphLogger.log(
      '[Voice] User mute -> $muted | state=${state.value.name}'
      ' | continuous=${_sttService?.supportsContinuousListening}',
    );
    final listening = state.value == VoiceChatState.listening;
    if (muted) {
      _cancelInactivityTimer();
      _sttService?.setMuted(true);
      // Whisper has no mute: stop the turn's recording instead.
      if (listening && _sttService?.supportsContinuousListening == false) {
        unawaited(_sttService?.cancelSession());
      }
      return;
    }
    if (!listening) {
      // Our turn: with barge-in the held mic goes back to open-but-gated;
      // otherwise the next listen picks it back up.
      if (_holdingMic) _holdMicForOurTurn();
      return;
    }
    if (_continuousSessionOpen) {
      _sttService!.setMuted(false);
      _armInactivityTimer();
    } else {
      _beginListeningSafe();
    }
  }

  /// Every turn-taking mute goes through here so the user's own mute always
  /// wins: the assistant's turn can mute the mic, but only the user can
  /// unmute it.
  void _setSttMuted(bool muted) {
    _sttService?.setMuted(muted || isUserMuted.value);
  }

  // ─── Our turn: the microphone ──────────────────────────────

  /// Called whenever our own audio (greeting, filler, reply, check-in) takes
  /// the floor. Half-duplex mutes the mic; barge-in keeps it open behind the
  /// uplink gate and keeps the input buffer, since words spoken over us are
  /// the next turn.
  void _holdMicForOurTurn() {
    _holdingMic = true;
    if (_isPlayingTts) _spokeAloudThisTurn = true;
    if (!VoiceBargeIn.keepsMicOpen || isUserMuted.value) {
      _sttService?.setMuted(true);
      return;
    }
    _sttService?.setMuted(false, preserveBuffer: true);
    _sttService?.setUplinkGate(true);
  }

  /// The user's turn: the mic streams ungated (their speech is never gated).
  void _releaseMicToUser() {
    _holdingMic = false;
    _sttService?.setUplinkGate(false);
    _setSttMuted(false);
  }

  /// True when speech heard right now may interrupt: Luna's own voice is
  /// playing, the mic is ours, and the user has not muted themselves.
  bool get _bargeInArmed =>
      VoiceBargeIn.interrupts &&
      _holdingMic &&
      _isPlayingTts &&
      !isUserMuted.value;

  void _onBargeInDuck() {
    BatasphLogger.log('[BARGE] ducking — speech heard over the reply');
    unawaited(_ttsService.setDucked(true));
  }

  void _onBargeInReleased() {
    BatasphLogger.log('[BARGE] false alarm — no words, resuming the reply');
    unawaited(_ttsService.setDucked(false));
  }

  /// A real interruption. The reply is abandoned and the floor handed over;
  /// the confirming words are still mid-utterance, so the turn is not sent
  /// from here — the mic stays open and the final transcript arrives through
  /// the normal listening path.
  void _onBargeInConfirmed(String transcript) {
    BatasphLogger.log('[BARGE] INTERRUPTED by the user | heard="$transcript"');
    unawaited(_interruptForUser());
  }

  Future<void> _interruptForUser() async {
    _greetingPhase = false;
    _cancelInactivityTimer();
    await _cancelActiveTurn(clearTexts: true);
    await _ttsService.setDucked(false);
    _bargeIn.reset();
    _echoGuard.clear();
    _spokeAloudThisTurn = false;
    _consecutiveTranscriptionErrors = 0;
    _holdingMic = false;
    // The session never closed, so the user is already being heard; the
    // gate comes off because they are mid-sentence.
    _sttService?.setUplinkGate(false);
    _sttService?.setMuted(isUserMuted.value, preserveBuffer: true);
    state.value = VoiceChatState.listening;
  }

  /// One captured frame's level, bucketed by what was happening: our voice
  /// playing, or the user's turn with nobody talking (the room). Anything
  /// else would pollute the comparison.
  void _onSttAudioLevel(double dbfs) {
    if (_holdingMic) {
      if (_isPlayingTts) _echoProbe.addLevel(dbfs, assistantSpeaking: true);
      return;
    }
    if (_userIsSpeaking || state.value != VoiceChatState.listening) return;
    _echoProbe.addLevel(dbfs, assistantSpeaking: false);
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
      'Turn up your media volume to hear ${AppConfig.personaName}.',
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
      // Held from the first chunk: the ringing and greeting are playing.
      _holdMicForOurTurn();
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
    // Remembered before playing: echo arrives while we are still speaking.
    _echoGuard.remember(greeting.text);
    state.value = VoiceChatState.speaking;
    _isPlayingTts = true;
    _holdMicForOurTurn();
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
      ..onIdle = _onSttIdle
      ..onAudioLevel = _onSttAudioLevel;
  }

  // ─── STT callbacks ─────────────────────────────────────────

  void _onSttSpeechStarted() {
    _userIsSpeaking = true;
    if (_bargeInArmed) _bargeIn.onSpeechStarted();
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
    _userIsSpeaking = false;
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
      if (_bargeInArmed) {
        _bargeIn.onTranscript(
          transcript,
          isEcho: _echoGuard.looksLikeEcho(transcript),
        );
      }
      if (isFinal) {
        _userIsSpeaking = false;
        BatasphLogger.log(
          '[BARGE] transcript during our turn dropped'
          ' | state=${state.value.name} | holdingMic=$_holdingMic'
          ' | playing=$_isPlayingTts | "$transcript"',
        );
      }
      return;
    }
    if (isFinal) {
      _awaitingTurnTranscript = false;
      _userIsSpeaking = false;
    }

    _consecutiveTranscriptionErrors = 0;

    if (!isFinal) {
      return;
    }

    final trimmed = transcript.trim();
    if (trimmed.isNotEmpty && _echoGuard.looksLikeEcho(trimmed)) {
      BatasphLogger.log(
        '[BARGE] rejected our own voice, not sending | "$trimmed"',
      );
      if (_continuousSessionOpen) {
        if (state.value == VoiceChatState.processing) {
          state.value = VoiceChatState.listening;
        }
        _armInactivityTimer();
      } else {
        _beginListeningSafe();
      }
      return;
    }
    if (trimmed.isNotEmpty) {
      _echoGuard.clear();
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
    if (_autoContinue) _beginListeningSafe();
  }

  /// The continuous session closed after a long silence. Reopen it so the
  /// call remains ready until the user says goodbye or ends it manually.
  void _onSttIdle() {
    BatasphLogger.log('[Voice] STT idle, reconnecting listening');
    _awaitingTurnTranscript = false;
    if (_autoContinue && state.value == VoiceChatState.listening) {
      _beginListeningSafe();
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

    // Realtime failed for the first time this call: the session is gone, so
    // the next listen opens a fresh one. Not the user's turn right now
    // (greeting, or Luna answering) — the listen that follows does it.
    if (!_usingWhisperFallback && _autoContinue && !_realtimeRetried) {
      _realtimeRetried = true;
      BatasphLogger.warning(
        '[Voice] Realtime STT failed, retrying once before Whisper',
      );
      if (!(_greetingPhase || _isOurTurn)) {
        _beginListeningSafe();
      }
      return;
    }

    // Realtime failed again and Whisper has not been tried yet: swap
    // services. Same turn rule as above.
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
      _beginListeningSafe();
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
    _beginListeningSafe();
  }

  // ─── Backend SSE ───────────────────────────────────────────

  void _respondToUser(String text) {
    _silenceCheckIns = 0;
    _cancelInactivityTimer();
    final farewell = VoiceFarewellService.replyFor(text);
    if (farewell != null) {
      unawaited(_speakFarewell(farewell));
    } else if (_identityStep != _IdentityStep.none) {
      unawaited(_answerIdentity(text));
    } else {
      _sendToBackend(text);
    }
  }

  /// The caller's answer to the greeting's "May I ask your name?" or "Am I
  /// speaking with Chris again?". A filler plays while the API reads the
  /// reply. A new name is saved on the phone; a question said with the name,
  /// or instead of it, is answered straight away.
  Future<void> _answerIdentity(String text) async {
    final turnId = ++_turnId;
    final step = _identityStep;
    final greetedName = _greetedName;
    _identityStep = _IdentityStep.none;
    state.value = VoiceChatState.processing;
    _holdMicForOurTurn();

    final filler = _fillerService.next();
    final results = await Future.wait<Object?>([
      _identity.identify(
        text,
        savedName: step == _IdentityStep.confirmingName ? greetedName : null,
      ),
      if (filler != null) _playFiller(turnId, filler),
    ]);
    if (turnId != _turnId || !_autoContinue) return;
    final reply = results.first! as CallerReply;
    BatasphLogger.log(
      '[Voice] Caller identity | step=${step.name}'
      ' | reply=${reply.kind.name} | name=${reply.name}'
      ' | question=${reply.question}',
    );

    switch (reply.kind) {
      case CallerReplyKind.confirmed:
        final question = reply.question;
        if (question != null) {
          _sendToBackend(question, withFiller: false);
          return;
        }
        unawaited(
          _speakThenListen(
            _identity.welcomeBack(greetedName!),
            label: 'Welcome back',
          ),
        );
      case CallerReplyKind.name:
        final name = reply.name!;
        BatasphLogger.log('[Voice] Caller name saved | "$name"');
        unawaited(MySharedPref.setCallerName(name));
        final question = reply.question;
        if (question != null) {
          _sendToBackend(question, withFiller: false);
          return;
        }
        final String line;
        if (greetedName == null) {
          line = _identity.welcomeNew(name);
        } else if (CallerIdentityService.isSameName(name, greetedName)) {
          line = _identity.welcomeBack(name);
        } else {
          line = _identity.nameUpdated(name);
        }
        unawaited(_speakThenListen(line, label: 'Welcome'));
      case CallerReplyKind.denied:
        _identityStep = _IdentityStep.askingName;
        unawaited(
          _speakThenListen(_identity.askNameAfterDenial(), label: 'Ask name'),
        );
      case CallerReplyKind.question:
        _sendToBackend(reply.question ?? text, withFiller: false);
      case CallerReplyKind.unclear:
        if (_identityRetried) {
          unawaited(_speakThenListen(_identity.skipName(), label: 'Skip name'));
          return;
        }
        _identityRetried = true;
        _identityStep = _IdentityStep.askingName;
        unawaited(
          _speakThenListen(_identity.askNameAgain(), label: 'Ask name again'),
        );
    }
  }

  /// Speaks one of Luna's own lines (not a backend answer), then hands the
  /// floor back. Barge-in works as during any reply.
  Future<void> _speakThenListen(String line, {required String label}) async {
    final turnId = ++_turnId;
    _cancelInactivityTimer();
    _callFlowId++;
    _awaitingTurnTranscript = false;
    state.value = VoiceChatState.speaking;
    errorMessage.value = '';
    _isPlayingTts = true;
    _echoGuard.remember(line);
    _holdMicForOurTurn();
    BatasphLogger.log('[Voice] $label | turn=$turnId | "$line"');

    try {
      if (!_continuousSessionOpen) await _sttService?.cancelSession();
      if (turnId != _turnId || !_autoContinue) return;
      await _ttsService.speak(line);
      if (turnId != _turnId || !_autoContinue) return;
      _isPlayingTts = false;
      _spokeAloudThisTurn = true;
      await _handFloorToUser(turnId);
    } catch (error, stackTrace) {
      if (turnId != _turnId) return;
      BatasphLogger.error(
        '[Voice] $label playback failed',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to continue the call';
      state.value = VoiceChatState.error;
    } finally {
      if (turnId == _turnId) _isPlayingTts = false;
    }
  }

  /// Plays one filler clip on our turn. A cancelled turn leaves the flags
  /// to [_cancelActiveTurn].
  Future<void> _playFiller(int turnId, FillerClip filler) async {
    _isPlayingTts = true;
    _holdMicForOurTurn();
    BatasphLogger.log('[Voice] Filler | turn=$turnId | "${filler.text}"');
    try {
      await _ttsService.playAudio(filler.audio);
    } catch (error) {
      BatasphLogger.debug('[Voice] Filler playback error ignored: $error');
    }
    if (turnId == _turnId) _isPlayingTts = false;
  }

  Future<void> _speakFarewell(String reply) async {
    final turnId = ++_turnId;
    _autoContinue = false;
    _cancelInactivityTimer();
    _callFlowId++;
    _awaitingTurnTranscript = false;
    _setSttMuted(true);
    state.value = VoiceChatState.speaking;
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

  void _sendToBackend(String text, {bool withFiller = true}) {
    final turnId = ++_turnId;
    _cancelSse();
    _bargeIn.reset();
    state.value = VoiceChatState.processing;
    _spokenText = '';
    errorMessage.value = '';
    _audioBuffer.clear();
    _sseDone = false;
    _isPlayingTts = false;
    _turnStopwatch = Stopwatch()..start();
    _turnTokenCount = 0;
    _turnAudioChunkCount = 0;
    _turnFirstTokenAt = null;
    _turnFirstAudioAt = null;
    lastQuestion.value = text;
    lastLegalBasis.clear();

    _holdMicForOurTurn();

    const voice = AppConfig.personaVoice;
    BatasphLogger.log(
      '[Voice] Send | turn=$turnId | chars=${text.length} | voice=$voice',
    );

    _sseSubscription = _chatService
        .streamMessage(text, mode: 'voice', voice: voice)
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

    unawaited(_playFillerThenThinking(turnId, withFiller: withFiller));
  }

  /// Covers the wait while the answer is already being prepared: a short
  /// filler right away ("Hmm, okay."), then the thinking loop until the
  /// first reply chunk. Reply audio that arrives during the filler queues
  /// behind it ([_isPlayingTts] keeps [_processAudioQueue] from starting
  /// underneath) and is drained as soon as the filler ends.
  Future<void> _playFillerThenThinking(
    int turnId, {
    required bool withFiller,
  }) async {
    final filler = withFiller ? _fillerService.next() : null;
    if (filler != null &&
        turnId == _turnId &&
        !_isPlayingTts &&
        _audioBuffer.isEmpty &&
        !_sseDone) {
      await _playFiller(turnId, filler);
    } else if (withFiller) {
      BatasphLogger.debug(
        '[Voice] No filler | turn=$turnId'
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
      _setSttMuted(false);
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
        _enqueueAudio(turnId, event.index, (
          audio: event.audio,
          text: event.text,
        ));
      case DoneEvent():
        BatasphLogger.log(
          '[Voice] Done | turn=$turnId'
          ' | ${_turnStopwatch?.elapsedMilliseconds}ms'
          ' | firstToken=${_turnFirstTokenAt?.inMilliseconds}ms'
          ' | firstAudio=${_turnFirstAudioAt?.inMilliseconds}ms'
          ' | tokens=$_turnTokenCount | audioChunks=$_turnAudioChunkCount'
          ' | sources=${event.sources.length}'
          ' | status=${event.status} | lang=${event.responseLanguage}'
          ' | cached=${event.cached} | noResults=${event.noResults}',
        );
        lastLegalBasis.assignAll(event.legalBasis);
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
    }
  }

  // ─── Audio playback (inline TTS from SSE) ──────────────────

  void _enqueueAudio(int turnId, int index, VoiceAudioChunk chunk) {
    if (turnId != _turnId) {
      return;
    }
    _audioBuffer.add(index, chunk);
    unawaited(_processAudioQueue(turnId));
  }

  Future<void> _processAudioQueue(int turnId) async {
    if (_isPlayingTts || turnId != _turnId) {
      return;
    }

    while (turnId == _turnId) {
      final chunk = _audioBuffer.popNext();
      if (chunk == null) {
        break;
      }
      _isPlayingTts = true;
      _holdMicForOurTurn();
      // Never inherit a duck from an earlier chunk or turn.
      await _ttsService.setDucked(false);
      // Everything said so far, so echo heard mid-reply is recognised as
      // ours rather than treated as an interruption.
      _spokenText = '$_spokenText ${chunk.text.trim()}'.trim();
      _echoGuard.remember(_spokenText);
      await _thinking.stop();
      if (turnId != _turnId) {
        _isPlayingTts = false;
        return;
      }

      if (state.value == VoiceChatState.processing) {
        state.value = VoiceChatState.speaking;
      }

      try {
        await _ttsService.playAudio(chunk.audio);
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

  Future<void> _beginListening() async {
    final flowId = ++_callFlowId;
    _greetingPhase = false;
    // Whatever happened in our turn, the floor is the user's now: release
    // any outstanding duck (the greeting never reaches _onSpeakingDone).
    _bargeIn.reset();

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
      _resetTexts();
      _releaseMicToUser();
      state.value = VoiceChatState.listening;
      _armInactivityTimer();
      return;
    }

    await _sttService!.cancelSession();
    if (flowId != _callFlowId || !_autoContinue) return;
    _resetTexts();
    if (isUserMuted.value && !_sttService!.supportsContinuousListening) {
      // Whisper cannot mute a recording, so a muted user gets no recording;
      // toggleMute starts one on unmute.
      state.value = VoiceChatState.listening;
      return;
    }
    // A fresh realtime session starts unmuted; apply the user's mute before
    // its first chunk.
    _holdingMic = false;
    _sttService!.setUplinkGate(false);
    _setSttMuted(false);
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

  void _beginListeningSafe() {
    _beginListening().catchError((Object error, StackTrace stackTrace) {
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
    if (isUserMuted.value) return;
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
        unawaited(_speakFarewell(VoiceFarewellService.silenceFarewell));
      }
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  Future<void> _speakSilenceCheckIn() async {
    if (!_autoContinue || state.value != VoiceChatState.listening) return;
    // The next silence ends the call.
    _silenceCheckIns = 1;
    await _speakThenListen(
      VoiceFarewellService.silenceCheckIn,
      label: 'Silence check-in',
    );
  }

  Future<void> _onSpeakingDone(int turnId) async {
    if (turnId != _turnId) {
      return;
    }

    BatasphLogger.log(
      '[Voice] Turn complete | turn=$turnId | autoContinue=$_autoContinue',
    );
    _echoProbe.logTurn('$turnId finished');
    await _thinking.stop();
    _bargeIn.reset();
    if (_spokeAloudThisTurn) _echoGuard.remember(_spokenText);
    if (_autoContinue) await _handFloorToUser(turnId);
  }

  /// The end of any of Luna's turns. A due time notice is spoken first;
  /// otherwise the caller has the floor.
  Future<void> _handFloorToUser(int turnId) async {
    if (_spokeAloudThisTurn) {
      // Let the speaker finish before the microphone listens to it.
      await Future<void>.delayed(VoiceBargeIn.micReopenGuard);
      if (turnId != _turnId) return;
    }
    _spokeAloudThisTurn = false;
    if (_speakDueTimeNotice()) return;
    await _beginListening();
  }

  // ─── Call time limit ───────────────────────────────────────

  void _onCallTick(int seconds) {
    if (!_autoContinue) return;
    if (seconds == _timeWarningSeconds) {
      _timeWarningDue = true;
      // Said now only if nobody is talking; else when the floor next
      // returns to the caller.
      if (state.value == VoiceChatState.listening && !_userIsSpeaking) {
        _speakDueTimeNotice();
      }
    } else if (seconds == _callLimitSeconds) {
      _timeUp = true;
      // Luna finishes the answer she is giving; anything else is cut here.
      if (!_isOurTurn) _speakDueTimeNotice();
    }
  }

  /// Speaks the goodbye once time is up, or the thirty-second warning when
  /// due. False when there is nothing to say.
  bool _speakDueTimeNotice() {
    if (_timeUp) {
      BatasphLogger.log('[Voice] Call time limit reached');
      unawaited(_speakFarewell(_pick(VoiceFarewellService.timeUpFarewells)));
      return true;
    }
    if (!_timeWarningDue) return false;
    _timeWarningDue = false;
    unawaited(
      _speakThenListen(
        _pick(VoiceFarewellService.timeWarnings),
        label: 'Time warning',
      ),
    );
    return true;
  }

  String _pick(List<String> lines) => lines[_random.nextInt(lines.length)];

  Future<void> _cancelActiveTurn({required bool clearTexts}) async {
    BatasphLogger.log(
      '[Voice] Cancel turn | turn=$_turnId | sseDone=$_sseDone'
      ' | playing=$_isPlayingTts | queued=${!_audioBuffer.isEmpty}',
    );
    _echoProbe.logTurn('$_turnId cancelled');
    _turnId++;
    _cancelSse();
    _audioBuffer.clear();
    _sseDone = false;
    _isPlayingTts = false;
    _spokeAloudThisTurn = false;
    _awaitingTurnTranscript = false;
    await Future.wait<void>([_thinking.stop(), _ttsService.stop()]);

    if (clearTexts) {
      _resetTexts();
    } else {
      errorMessage.value = '';
    }
  }

  void _cancelSse() {
    _chatService.cancelStream();
    _sseSubscription?.cancel();
    _sseSubscription = null;
  }

  void _resetTexts() {
    _spokenText = '';
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
    _bargeIn.dispose();
    super.onClose();
  }

  // ─── Call shell ────────────────────────────────────────────

  void _startCallTimer() {
    _stopCallTimer();
    callElapsedSeconds.value = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callElapsedSeconds.value++;
      _onCallTick(callElapsedSeconds.value);
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    callElapsedSeconds.value = 0;
  }
}
