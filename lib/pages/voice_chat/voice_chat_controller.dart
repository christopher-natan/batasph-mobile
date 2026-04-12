import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/pages/chat/chat_controller.dart';
import 'package:batasph_mobile/pages/voice_chat/services/cloud_tts_service.dart';
import 'package:batasph_mobile/pages/voice_chat/services/listening_retry_guard.dart';
import 'package:batasph_mobile/pages/voice_chat/services/voice_audio_chunk_buffer.dart';
import 'package:batasph_mobile/pages/voice_chat/services/whisper_stt_service.dart';
import 'package:batasph_mobile/services/chat_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

enum VoiceChatState { idle, listening, processing, speaking, error }

class VoiceChatController extends GetxController {
  static const int _maxConsecutiveEmptyListeningRetries = 1;
  static const int _maxTranscriptionErrorRetries = 1;

  final _chatService = Get.find<ChatService>();
  final _listeningRetryGuard = ListeningRetryGuard(
    maxConsecutiveAutoRetries: _maxConsecutiveEmptyListeningRetries,
  );

  late final WhisperSttService _sttService;
  late final CloudTtsService _ttsService;

  final state = VoiceChatState.idle.obs;
  final userText = ''.obs;
  final agentText = ''.obs;
  final errorMessage = ''.obs;

  StreamSubscription<ChatStreamEvent>? _sseSubscription;
  final VoiceAudioChunkBuffer _audioBuffer = VoiceAudioChunkBuffer();

  bool _isPlayingTts = false;
  bool _sseDone = false;
  bool _autoContinue = true;
  int _turnId = 0;
  int _consecutiveTranscriptionErrors = 0;

  @override
  void onInit() {
    super.onInit();
    _sttService = Get.find<WhisperSttService>();
    _ttsService = Get.find<CloudTtsService>();
    unawaited(_sttService.warmUp());
  }

  Future<void> startListening() async {
    _autoContinue = true;
    _consecutiveTranscriptionErrors = 0;
    _listeningRetryGuard.reset();
    await _beginListening(clearAgentText: true, resetRecoveryBudget: false);
  }

  Future<void> resumeListening({bool clearAgentText = false}) async {
    _autoContinue = true;
    _consecutiveTranscriptionErrors = 0;
    _listeningRetryGuard.reset();
    await _beginListening(
      clearAgentText: clearAgentText,
      resetRecoveryBudget: true,
    );
  }

  Future<void> pauseConversation({bool clearTexts = false}) async {
    _listeningRetryGuard.reset();

    if (state.value == VoiceChatState.listening) {
      await _sttService.cancelSession();
    }

    if (state.value == VoiceChatState.listening ||
        state.value == VoiceChatState.processing ||
        state.value == VoiceChatState.speaking) {
      await _cancelActiveTurn(clearTexts: clearTexts);
    } else if (clearTexts) {
      _resetTexts(clearAgentText: true);
    } else {
      errorMessage.value = '';
    }

    state.value = VoiceChatState.idle;
  }

  Future<void> submitPrompt(String prompt) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _autoContinue = true;
    _listeningRetryGuard.reset();

    if (state.value == VoiceChatState.listening) {
      await _sttService.cancelSession();
    }

    if (state.value == VoiceChatState.listening ||
        state.value == VoiceChatState.processing ||
        state.value == VoiceChatState.speaking) {
      await _cancelActiveTurn(clearTexts: false);
    }

    _resetTexts(clearAgentText: true);
    userText.value = trimmed;
    _sendToBackend(trimmed);
  }

  Future<void> interrupt() async {
    switch (state.value) {
      case VoiceChatState.speaking:
      case VoiceChatState.processing:
        await _cancelActiveTurn(clearTexts: true);
        _listeningRetryGuard.reset();
        _consecutiveTranscriptionErrors = 0;
        await _beginListening(clearAgentText: true, resetRecoveryBudget: false);
      case VoiceChatState.listening:
        await _sttService.cancelSession();
        _listeningRetryGuard.reset();
        _consecutiveTranscriptionErrors = 0;
        state.value = VoiceChatState.idle;
      case VoiceChatState.idle:
        await startListening();
      case VoiceChatState.error:
        await startListening();
    }
  }

  Future<void> endConversation() async {
    _autoContinue = false;
    _listeningRetryGuard.reset();
    await _cancelActiveTurn(clearTexts: true);
    await _sttService.cancelSession();
    await _ttsService.stop();
    state.value = VoiceChatState.idle;
    if (Get.isRegistered<ChatController>()) {
      unawaited(Get.find<ChatController>().reloadHistory());
    }
  }

  void _onSttTranscribing() {
    if (state.value == VoiceChatState.listening) {
      state.value = VoiceChatState.processing;
    }
  }

  void _onSttResult(String transcript, bool isFinal) {
    _listeningRetryGuard.onSpeechCaptured(transcript);
    _consecutiveTranscriptionErrors = 0;
    userText.value = transcript;

    if (isFinal && transcript.trim().isNotEmpty) {
      _sendToBackend(transcript.trim());
    } else if (isFinal && transcript.trim().isEmpty) {
      final action = _listeningRetryGuard.onEmptyFinal(
        autoContinue: _autoContinue,
      );
      if (action == ListeningEmptyResultAction.retry) {
        _beginListeningSafe(clearAgentText: false, resetRecoveryBudget: false);
      } else {
        state.value = VoiceChatState.idle;
      }
    }
  }

  void _onSttError(String error) {
    BatasphLogger.error('Voice transcription error: $error');

    if (_autoContinue &&
        _consecutiveTranscriptionErrors < _maxTranscriptionErrorRetries) {
      _consecutiveTranscriptionErrors++;
      _beginListeningSafe(clearAgentText: false, resetRecoveryBudget: false);
      return;
    }

    _listeningRetryGuard.reset();
    _consecutiveTranscriptionErrors = 0;
    errorMessage.value = error;
    state.value = VoiceChatState.error;
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

    _sseSubscription = _chatService
        .streamMessage(
          text,
          mode: 'voice',
          language: MySharedPref.getAnswerLanguage().name,
          voice: MySharedPref.getSelectedVoice(),
        )
        .listen(
          (event) => _onSseEvent(turnId, event),
          onError: (Object error) {
            if (turnId != _turnId) {
              return;
            }
            BatasphLogger.error('Voice stream failed: $error');
            errorMessage.value = 'Failed to get response';
            state.value = VoiceChatState.error;
          },
          onDone: () {
            if (turnId != _turnId) {
              return;
            }
            _sseSubscription = null;
            _sseDone = true;
            if (!_isPlayingTts && _audioBuffer.isEmpty) {
              unawaited(_onSpeakingDone(turnId));
            }
          },
        );
  }

  void _onSseEvent(int turnId, ChatStreamEvent event) {
    if (turnId != _turnId) {
      return;
    }

    switch (event) {
      case TokenEvent():
        agentText.value += event.text;
      case AudioEvent():
        _enqueueAudio(turnId, event.index, event.audio);
      case DoneEvent():
        if (event.disclaimer.trim().isNotEmpty) {
          agentText.value =
              '${agentText.value.trim()}\n\n${event.disclaimer.trim()}';
        }
      case StreamWarningEvent():
        BatasphLogger.warning(
          'Voice stream warning: ${event.code} ${event.message}',
        );
        if (event.code == 'voice_synthesis_failed') {
          errorMessage.value = event.message;
        }
      case StreamErrorEvent():
        errorMessage.value = event.message;
        state.value = VoiceChatState.error;
      case UserMessageEvent():
        break;
    }
  }

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

      if (state.value == VoiceChatState.processing) {
        state.value = VoiceChatState.speaking;
      }

      try {
        await _ttsService.playAudio(audioBytes);
      } catch (error) {
        if (turnId != _turnId) {
          _isPlayingTts = false;
          return;
        }
        BatasphLogger.error('Voice audio playback failed: $error');
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
      await _onSpeakingDone(turnId);
    }
  }

  Future<void> _beginListening({
    required bool clearAgentText,
    required bool resetRecoveryBudget,
  }) async {
    if (resetRecoveryBudget) {
      _listeningRetryGuard.reset();
    }

    await _sttService.cancelSession();
    _resetTexts(clearAgentText: clearAgentText);
    errorMessage.value = '';
    state.value = VoiceChatState.listening;

    _sttService
      ..onResult = _onSttResult
      ..onError = _onSttError
      ..onTranscribing = _onSttTranscribing;

    await _sttService.startSession();
  }

  void _beginListeningSafe({
    required bool clearAgentText,
    required bool resetRecoveryBudget,
  }) {
    _beginListening(
      clearAgentText: clearAgentText,
      resetRecoveryBudget: resetRecoveryBudget,
    ).catchError((Object error) {
      BatasphLogger.error('Failed to restart listening: $error');
      errorMessage.value = 'Failed to start listening';
      state.value = VoiceChatState.error;
    });
  }

  Future<void> _onSpeakingDone(int turnId) async {
    if (turnId != _turnId) {
      return;
    }

    if (_autoContinue) {
      await _beginListening(clearAgentText: false, resetRecoveryBudget: true);
    } else {
      _listeningRetryGuard.reset();
      state.value = VoiceChatState.idle;
    }
  }

  Future<void> _cancelActiveTurn({required bool clearTexts}) async {
    _turnId++;
    _cancelSse();
    _audioBuffer.clear();
    _sseDone = false;
    _isPlayingTts = false;
    await _ttsService.stop();

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
    _autoContinue = false;
    _audioBuffer.clear();
    _chatService.cancelStream();
    _sseSubscription?.cancel();
    _sttService.dispose();
    _ttsService.dispose();
    super.onClose();
  }
}
