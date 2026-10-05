import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/pages/voice_chat/services/output_volume_check.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_call_events.dart';
import 'package:batasph_mobile/pages/voice_chat/services/realtime_call_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_call_api_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_call_audio_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

enum VoiceChatState { idle, connecting, listening, processing, speaking, error }

/// A phone call with Atty. Luna on OpenAI Realtime speech-to-speech.
///
/// The model hears the caller and answers in her own voice over WebRTC
/// ([RealtimeCallService]); turn-taking and interruptions happen in the
/// model. This controller owns the call around it:
///
/// * The phone rings (and Luna picks up) while the session is minted and
///   WebRTC connects; the mic is off until the pick-up, then Luna speaks
///   first, asking a new caller's name or confirming a returning one's.
/// * Luna's tools: `lookup_philippine_law` is relayed to the API's grounded
///   law search, `save_caller_name` saves the name on the phone, and
///   `end_call` hangs up once her goodbye has finished playing.
/// * A call lasts at most 3:30: Luna warns thirty seconds before and says
///   goodbye when time is up, after any answer she is giving.
/// * Silence: a check-in after 10 s, then a goodbye after 8 s more.
///
/// `_callFlowId` invalidates a superseded call: every async continuation
/// re-checks its captured id before touching state.
class VoiceChatController extends GetxController {
  static const int _callLimitSeconds = 3 * 60 + 30;
  static const int _timeWarningSeconds = _callLimitSeconds - 30;

  /// Past the limit Luna is still mid-answer or the caller mid-sentence;
  /// the call ends here regardless, without a goodbye.
  static const int _hardStopSeconds = _callLimitSeconds + 30;
  static const Duration _firstSilenceCheckIn = Duration(seconds: 10);
  static const Duration _secondSilenceFarewell = Duration(seconds: 8);

  /// A goodbye whose audio never starts must not leave the call hanging.
  static const Duration _hangUpWithoutAudio = Duration(seconds: 2);

  static const String _lookupTool = 'lookup_philippine_law';
  static const String _saveNameTool = 'save_caller_name';
  static const String _endCallTool = 'end_call';

  final _callAudioService = Get.find<VoiceCallAudioService>();
  final VoiceCallApiService _api = VoiceCallApiService();

  RealtimeCallService? _call;
  StreamSubscription<RealtimeCallEvent>? _callEvents;

  final state = VoiceChatState.idle.obs;
  final errorMessage = ''.obs;
  final callElapsedSeconds = 0.obs;

  /// The caller's own mute: their microphone track is off.
  final isUserMuted = false.obs;

  /// The call is over and the page shows its summary. Set by
  /// [endConversation], cleared when a new call starts.
  final callEnded = false.obs;
  final endedCallSeconds = 0.obs;
  final lastQuestion = ''.obs;
  final lastLegalBasis = <String>[].obs;

  Future<void> Function()? onFarewellComplete;

  Timer? _callTimer;
  Timer? _silenceTimer;
  Timer? _hangUpTimer;
  int _callFlowId = 0;
  bool _endingCall = false;
  bool _hasMicPermission = false;

  // Live call state, from the data channel.
  bool _connected = false;
  bool _responseActive = false;
  bool _lunaSpeaking = false;
  bool _callerSpeaking = false;
  int _lookupsInFlight = 0;

  /// Tool outputs were sent while another response was running; ask for
  /// Luna's follow-up once it finishes.
  bool _responsePending = false;

  /// Luna said goodbye: hang up once her audio has finished playing.
  bool _hangUpAfterSpeech = false;
  int _silenceCheckIns = 0;
  bool _timeWarningDue = false;
  bool _timeUp = false;

  // Diagnostics only.
  Stopwatch? _replyStopwatch;

  // ─── Presentation ──────────────────────────────────────────

  String get callDurationLabel => _formatDuration(callElapsedSeconds.value);

  String get endedCallDurationLabel => _formatDuration(endedCallSeconds.value);

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ─── Public actions ────────────────────────────────────────

  Future<void> startCall() async {
    final flowId = ++_callFlowId;
    final savedName = MySharedPref.getCallerName();
    BatasphLogger.log(
      '[Voice] Start call | flow=$flowId'
      ' | returningCaller=${savedName != null}',
    );
    _resetCallState();
    callEnded.value = false;
    lastQuestion.value = '';
    lastLegalBasis.clear();
    errorMessage.value = '';
    _startCallTimer();
    state.value = VoiceChatState.connecting;

    try {
      // Ask before the phone rings: a permission dialog over a ringing call
      // is confusing, and a denial should end the call here.
      if (!await _ensureMicrophonePermission()) {
        if (flowId != _callFlowId) return;
        _fail('Microphone permission is needed for voice calls');
        return;
      }
      if (flowId != _callFlowId) return;
      await _warnIfVolumeOff();

      // The phone rings while the call is set up behind it.
      final ringing = _callAudioService.playRingback();
      final connecting = _connect(flowId, savedName);
      await ringing;
      final call = await connecting;
      if (flowId != _callFlowId) {
        await call?.close();
        return;
      }
      if (call == null) {
        _fail('Could not reach Atty. Luna. Tap to try again.');
        return;
      }

      // Picked up: open the mic and let Luna speak first.
      _connected = true;
      call.setMicEnabled(!isUserMuted.value);
      state.value = VoiceChatState.listening;
      BatasphLogger.log('[Voice] Picked up | flow=$flowId');
      _requestResponse();
    } catch (error, stackTrace) {
      if (flowId != _callFlowId) return;
      BatasphLogger.error(
        '[Voice] Failed to start call | flow=$flowId',
        error: error,
        stackTrace: stackTrace,
      );
      _fail('Failed to start the call. Tap to try again.');
    }
  }

  /// Mints the session and connects WebRTC. Null when it cannot connect;
  /// the reason is logged here.
  Future<RealtimeCallService?> _connect(int flowId, String? savedName) async {
    final call = RealtimeCallService();
    try {
      final secret = await _api.createSession(savedName: savedName);
      if (flowId != _callFlowId) {
        await call.close();
        return null;
      }
      _call = call;
      _callEvents = call.events.listen((event) => _onCallEvent(flowId, event));
      await call.connect(clientSecret: secret);
      return call;
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] Call connect failed | flow=$flowId',
        error: error,
        stackTrace: stackTrace,
      );
      await call.close();
      return null;
    }
  }

  Future<void> handlePrimaryControlTap() async {
    switch (state.value) {
      case VoiceChatState.idle:
      case VoiceChatState.error:
        await startCall();
      case VoiceChatState.connecting:
      case VoiceChatState.listening:
      case VoiceChatState.processing:
      case VoiceChatState.speaking:
        return;
    }
  }

  Future<void> endConversation() async {
    if (_endingCall) return;
    _endingCall = true;
    _callFlowId++;
    BatasphLogger.log(
      '[Voice] End call | from=${state.value.name}'
      ' | duration=${callElapsedSeconds.value}s',
    );
    endedCallSeconds.value = callElapsedSeconds.value;
    _stopCallTimer();
    _cancelSilenceTimer();
    _hangUpTimer?.cancel();
    await _closeCall();
    await _callAudioService.stop();
    try {
      await _callAudioService.playCallDroppedTone();
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] Call-dropped tone failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    isUserMuted.value = false;
    state.value = VoiceChatState.idle;
    callEnded.value = true;
  }

  /// Leaves the ended-call summary for Home.
  void leaveCall() {
    BatasphLogger.log('[Voice] Leave call screen');
    Get.back();
  }

  /// Mutes the caller like a phone's mute key; the silence check-in does
  /// not fire while muted, since a muted caller is not gone.
  void toggleMute() {
    final muted = !isUserMuted.value;
    isUserMuted.value = muted;
    BatasphLogger.log('[Voice] User mute -> $muted');
    if (_connected) _call?.setMicEnabled(!muted);
    if (muted) {
      _cancelSilenceTimer();
    } else {
      _onMaybeIdle();
    }
  }

  // ─── Call events ───────────────────────────────────────────

  void _onCallEvent(int flowId, RealtimeCallEvent event) {
    if (flowId != _callFlowId) return;
    switch (event) {
      case CallerSpeechStarted():
        _callerSpeaking = true;
        _silenceCheckIns = 0;
        _cancelSilenceTimer();
      case CallerSpeechStopped():
        _callerSpeaking = false;
        _replyStopwatch = Stopwatch()..start();
      case ResponseStarted():
        _responseActive = true;
        _cancelSilenceTimer();
      case ResponseFinished():
        _responseActive = false;
        _onResponseFinished(flowId, event);
      case LunaAudioStarted():
        _lunaSpeaking = true;
        _hangUpTimer?.cancel();
        final waited = _replyStopwatch?.elapsedMilliseconds;
        if (waited != null) {
          BatasphLogger.log('[Voice] Luna replying | after=${waited}ms');
          _replyStopwatch = null;
        }
      case LunaAudioStopped():
        _lunaSpeaking = false;
        if (_hangUpAfterSpeech && !_responseActive) {
          _hangUp();
          return;
        }
      case CallerTranscript(:final text):
        BatasphLogger.log('[Voice] Caller: "$text"');
      case LunaTranscript(:final text):
        BatasphLogger.log('[Voice] Luna: "$text"');
      case RealtimeError(:final code, :final message):
        BatasphLogger.warning('[Voice] Realtime error | $code | $message');
      case CallConnectionLost(:final reason):
        BatasphLogger.error('[Voice] Call dropped | $reason');
        unawaited(_closeCall());
        _fail('The call dropped. Tap to call again.');
        return;
    }
    _refreshState();
    _onMaybeIdle();
  }

  void _onResponseFinished(int flowId, ResponseFinished event) {
    if (event.functionCalls.isNotEmpty) {
      unawaited(
        _handleFunctionCalls(flowId, event.functionCalls, spoke: event.spoke),
      );
    }
    if (_responsePending && !_hangUpAfterSpeech) {
      _responsePending = false;
      _requestResponse();
    }
    if (_hangUpAfterSpeech && !_lunaSpeaking && event.spoke) {
      // Normally her goodbye is still playing and LunaAudioStopped hangs up;
      // if its audio never starts, do not leave the call open. (A response
      // with no words is not a goodbye: she is asked for one instead.)
      _hangUpTimer?.cancel();
      _hangUpTimer = Timer(_hangUpWithoutAudio, _hangUp);
    }
  }

  // ─── Luna's tools ──────────────────────────────────────────

  /// [spoke]: Luna said something in the response that made these calls.
  Future<void> _handleFunctionCalls(
    int flowId,
    List<FunctionCall> calls, {
    required bool spoke,
  }) async {
    var needsFollowUp = false;
    for (final call in calls) {
      BatasphLogger.log('[Voice] Tool | ${call.name} | ${call.arguments}');
      switch (call.name) {
        case _lookupTool:
          _sendToolOutput(call, await _lookup(flowId, call));
          needsFollowUp = true;
        case _saveNameTool:
          final name = (call.arguments['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) {
            _sendToolOutput(call, {'saved': false, 'reason': 'no name given'});
          } else {
            await MySharedPref.setCallerName(name);
            BatasphLogger.log('[Voice] Caller name saved | "$name"');
            _sendToolOutput(call, {'saved': true});
          }
          // She greets by name in the same turn; asking her to speak again
          // would repeat it. Only a silent save needs a follow-up.
          if (!spoke) needsFollowUp = true;
        case _endCallTool:
          _hangUpAfterSpeech = true;
          if (!spoke) {
            // She hung up without a word, which sounds like the line went
            // dead: have her say goodbye first, then hang up after it.
            BatasphLogger.log('[Voice] end_call without a goodbye, asking');
            _sendToolOutput(call, {'ok': true});
            _requestResponse(
              instructions:
                  'Say a short warm goodbye in Taglish now, like: "Sige, salamat sa pagtawag! Ingat ka, bye!" Do not call any tool.',
            );
            return;
          }
        default:
          BatasphLogger.error('[Voice] Unknown tool | ${call.name}');
          _sendToolOutput(call, {'error': 'unknown tool'});
          needsFollowUp = true;
      }
      if (flowId != _callFlowId) return;
    }
    if (_hangUpAfterSpeech) {
      if (!_lunaSpeaking && !_responseActive) _hangUp();
      return;
    }
    if (needsFollowUp) _requestResponse();
  }

  Future<Map<String, dynamic>> _lookup(int flowId, FunctionCall call) async {
    final question = (call.arguments['question'] as String?)?.trim() ?? '';
    if (question.isEmpty) {
      BatasphLogger.error('[Voice] Lookup without a question');
      return {'status': 'error', 'answer': ''};
    }
    _lookupsInFlight++;
    _refreshState();
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _api.lookup(question);
      if (flowId == _callFlowId) {
        lastQuestion.value = question;
        lastLegalBasis.assignAll(
          (result['legalBasis'] as List<dynamic>? ?? const []).cast<String>(),
        );
      }
      BatasphLogger.log(
        '[Voice] Lookup | ${stopwatch.elapsedMilliseconds}ms'
        ' | status=${result['status']}',
      );
      return result;
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Voice] Lookup failed | ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
      return {'status': 'error', 'answer': ''};
    } finally {
      _lookupsInFlight--;
      if (flowId == _callFlowId) _refreshState();
    }
  }

  void _sendToolOutput(FunctionCall call, Map<String, dynamic> output) {
    _call?.send({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': call.callId,
        // Tool outputs are JSON strings on the wire.
        'output': jsonEncode(output),
      },
    });
  }

  /// Asks Luna to speak: her follow-up after a tool, or a line given by
  /// [instructions] (time notices, silence check-ins). Deferred while a
  /// response is running, since only one may run at a time.
  void _requestResponse({String? instructions}) {
    if (_responseActive) {
      if (instructions == null) _responsePending = true;
      return;
    }
    _call?.send({
      'type': 'response.create',
      if (instructions != null) 'response': {'instructions': instructions},
    });
  }

  // ─── Turn state, silence and time ──────────────────────────

  void _refreshState() {
    if (!_connected || _endingCall) return;
    if (state.value == VoiceChatState.error) return;
    state.value = _lunaSpeaking
        ? VoiceChatState.speaking
        : _lookupsInFlight > 0 || _responseActive
        ? VoiceChatState.processing
        : VoiceChatState.listening;
  }

  bool get _isIdle =>
      _connected &&
      !_endingCall &&
      !_responseActive &&
      !_lunaSpeaking &&
      !_callerSpeaking &&
      _lookupsInFlight == 0 &&
      !_hangUpAfterSpeech;

  /// The floor is the caller's: speak a due time notice, or start the
  /// silence clock.
  void _onMaybeIdle() {
    if (!_isIdle) return;
    if (_speakDueTimeNotice()) return;
    _armSilenceTimer();
  }

  void _onCallTick(int seconds) {
    if (!_connected || _endingCall) return;
    if (seconds == _timeWarningSeconds) {
      _timeWarningDue = true;
      _onMaybeIdle();
    } else if (seconds == _callLimitSeconds) {
      _timeUp = true;
      _onMaybeIdle();
    } else if (seconds == _hardStopSeconds) {
      BatasphLogger.warning('[Voice] Hard stop at ${seconds}s');
      unawaited(onFarewellComplete?.call() ?? endConversation());
    }
  }

  /// True when a time notice was spoken.
  bool _speakDueTimeNotice() {
    if (_timeUp) {
      BatasphLogger.log('[Voice] Call time limit reached');
      _hangUpAfterSpeech = true;
      _requestResponse(
        instructions:
            'The call time is up. In warm Taglish, tell the caller the time for this call is over, thank them, invite them to call again, and say goodbye, like: "Ay, ubos na pala ang oras natin for this call. Salamat sa pagtawag ha! Tawag ka lang ulit anytime. Ingat, bye!" Then call end_call.',
      );
      return true;
    }
    if (!_timeWarningDue) return false;
    _timeWarningDue = false;
    BatasphLogger.log('[Voice] Time warning');
    _requestResponse(
      instructions:
          'In warm Taglish, politely tell the caller there are thirty seconds left in this call, ask if there is anything else they want to clarify, and mention they can always call again. For example: "Pasensya na, may thirty seconds na lang tayo bago matapos ang call. May gusto ka pa bang linawin? Pero pwede ka namang tumawag ulit anytime."',
    );
    return true;
  }

  void _armSilenceTimer() {
    if (isUserMuted.value || _silenceTimer?.isActive == true) return;
    final duration = _silenceCheckIns == 0
        ? _firstSilenceCheckIn
        : _secondSilenceFarewell;
    _silenceTimer = Timer(duration, () {
      _silenceTimer = null;
      if (!_isIdle) return;
      if (_silenceCheckIns == 0) {
        _silenceCheckIns = 1;
        BatasphLogger.log('[Voice] Silence check-in');
        _requestResponse(
          instructions:
              'The caller has been quiet. In warm Taglish, ask if they are still there and if they have another question, like: "Hello, nandiyan ka pa ba? May iba ka pa bang tanong?"',
        );
      } else {
        BatasphLogger.log('[Voice] Silence farewell');
        _hangUpAfterSpeech = true;
        _requestResponse(
          instructions:
              'The caller is still quiet. In warm Taglish, say it seems they are no longer on the line, thank them and say goodbye, like: "Mukhang wala ka na sa linya. Salamat sa pagtawag, tawag ka lang ulit anytime. Ingat, bye!" Then call end_call.',
        );
      }
    });
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _hangUp() {
    _hangUpTimer?.cancel();
    if (_endingCall) return;
    BatasphLogger.log('[Voice] Luna hung up');
    unawaited(onFarewellComplete?.call() ?? endConversation());
  }

  // ─── Call setup and teardown ───────────────────────────────

  /// A muted phone makes the call look broken — the user talks and nothing
  /// comes back. Say so before the call; it goes ahead either way.
  Future<void> _warnIfVolumeOff() async {
    if (!await OutputVolumeCheck.isSilent()) return;
    BatasphLogger.log('[Voice] Media volume is off, asking the user to unmute');
    Get.snackbar(
      'Volume is off',
      'Turn up your volume to hear ${AppConfig.personaName}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<bool> _ensureMicrophonePermission() async {
    if (_hasMicPermission) return true;
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

  void _resetCallState() {
    _endingCall = false;
    _connected = false;
    _responseActive = false;
    _lunaSpeaking = false;
    _callerSpeaking = false;
    _lookupsInFlight = 0;
    _responsePending = false;
    _hangUpAfterSpeech = false;
    _silenceCheckIns = 0;
    _timeWarningDue = false;
    _timeUp = false;
    _replyStopwatch = null;
    _cancelSilenceTimer();
    _hangUpTimer?.cancel();
  }

  void _fail(String message) {
    errorMessage.value = message;
    state.value = VoiceChatState.error;
    _connected = false;
    _cancelSilenceTimer();
    _stopCallTimer();
    unawaited(_callAudioService.stop());
  }

  Future<void> _closeCall() async {
    _connected = false;
    final events = _callEvents;
    final call = _call;
    _callEvents = null;
    _call = null;
    await events?.cancel();
    await call?.close();
  }

  @override
  void onClose() {
    BatasphLogger.log('[Voice] Controller close | state=${state.value.name}');
    _callFlowId++;
    onFarewellComplete = null;
    _stopCallTimer();
    _cancelSilenceTimer();
    _hangUpTimer?.cancel();
    unawaited(_closeCall());
    unawaited(_callAudioService.dispose());
    super.onClose();
  }

  // ─── Call timer ────────────────────────────────────────────

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
