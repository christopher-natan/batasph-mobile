import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';
import 'package:batasph_mobile/data/models/chat_source_model.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/chat_service.dart';
import 'package:batasph_mobile/services/saved_answers_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class ChatController extends GetxController {
  final _chatService = Get.find<ChatService>();
  final _savedAnswersService = Get.find<SavedAnswersService>();

  final messages = <ChatMessageModel>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;
  final isStreaming = false.obs;
  final streamingText = ''.obs;
  final failedMessageText = ''.obs;
  final hasText = false.obs;
  final answerLanguage = MySharedPref.getAnswerLanguage().obs;
  final recentSearches = <String>[].obs;
  final isTextChatMode = false.obs;

  final textController = TextEditingController();
  final scrollController = ScrollController();
  final focusNode = FocusNode();

  List<String> get savedAnswerIds => _savedAnswersService.savedAnswers
      .map((item) => item.id)
      .toList(growable: false);

  @override
  void onInit() {
    super.onInit();
    textController.addListener(() {
      hasText.value = textController.text.trim().isNotEmpty;
    });
    _syncLocalDisplayState();
    _loadHistory();
  }

  @override
  void onClose() {
    _chatService.cancelStream();
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> askStarterQuestion(String question) async {
    isTextChatMode.value = true;
    await sendMessage(question);
  }

  Future<void> reloadHistory() async {
    await _loadHistory();
  }

  Future<void> sendMessage(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty || isSending.value) {
      return;
    }

    if (normalizedText.length > AppConfig.chatMaxMessageLength) {
      Get.snackbar(
        'Message too long',
        'Keep your question within ${AppConfig.chatMaxMessageLength} characters.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    failedMessageText.value = '';
    isSending.value = true;
    isStreaming.value = false;
    streamingText.value = '';

    final optimisticId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessageModel(
      id: optimisticId,
      text: normalizedText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(optimisticMessage);
    await MySharedPref.addRecentSearch(normalizedText);
    _syncRecentSearches();
    await _scrollToBottom();

    try {
      final answerLanguage = MySharedPref.getAnswerLanguage().name;
      await for (final event in _chatService.streamMessage(
        normalizedText,
        language: answerLanguage,
      )) {
        switch (event) {
          case UserMessageEvent():
            replaceMessageById(
              messages,
              messageId: optimisticId,
              replacement: event.message,
            );
          case TokenEvent():
            if (!isStreaming.value) {
              isStreaming.value = true;
            }
            streamingText.value += event.text;
          case DoneEvent():
            messages.add(
              ChatMessageModel(
                id:
                    event.aiMessageId ??
                    'msg_${DateTime.now().millisecondsSinceEpoch}',
                text: streamingText.value.trim(),
                isUser: false,
                timestamp: DateTime.now(),
                sources: event.sources,
                legalBasis: event.legalBasis,
                status: event.status ?? '',
                responseLanguage: event.responseLanguage ?? '',
                disclaimer: event.disclaimer,
              ),
            );
            isStreaming.value = false;
            streamingText.value = '';
            await _scrollToBottom();
          case StreamErrorEvent():
            BatasphLogger.error('Chat stream error: ${event.message}');
            _handleSendFailure(
              optimisticId: optimisticId,
              failedText: normalizedText,
            );
          case StreamWarningEvent():
            BatasphLogger.warning(
              'Chat stream warning: ${event.code} ${event.message}',
            );
          case AudioEvent():
            break;
        }
      }
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        _finalizeCancelledStream();
      } else {
        BatasphLogger.error('Chat stream failed: ${error.message}');
        _handleSendFailure(
          optimisticId: optimisticId,
          failedText: normalizedText,
        );
      }
    } catch (error) {
      BatasphLogger.error('Chat stream failed: $error');
      _handleSendFailure(
        optimisticId: optimisticId,
        failedText: normalizedText,
      );
    } finally {
      isSending.value = false;
      isStreaming.value = false;
    }
  }

  Future<void> submitMessage() async {
    final text = textController.text;
    if (text.trim().isEmpty) {
      return;
    }
    textController.clear();
    focusNode.requestFocus();
    await sendMessage(text);
  }

  void openTextComposer() {
    if (isTextChatMode.value) {
      focusNode.requestFocus();
      return;
    }

    isTextChatMode.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  void showVoiceFirstLanding() {
    focusNode.unfocus();
    isTextChatMode.value = false;
  }

  void cancelStream() {
    _chatService.cancelStream();
  }

  void retryFailedMessage() {
    final text = failedMessageText.value;
    if (text.isEmpty) {
      return;
    }
    failedMessageText.value = '';
    sendMessage(text);
  }

  void openVoiceChat() {
    focusNode.unfocus();
    Get.toNamed(Routes.VOICE_CHAT);
  }

  void openSavedAnswers() {
    focusNode.unfocus();
    Get.toNamed(Routes.SAVED_ANSWERS);
  }

  Future<void> useRecentPrompt(String prompt) async {
    isTextChatMode.value = true;
    await sendMessage(prompt);
  }

  void updateAnswerLanguage(AnswerLanguage language) {
    answerLanguage.value = language;
  }

  Future<void> clearChat() async {
    try {
      await _chatService.clearHistory();
      messages.clear();
      failedMessageText.value = '';
    } catch (error) {
      BatasphLogger.error('Failed to clear chat history: $error');
      Get.snackbar(
        'Unable to clear chat',
        'Try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteMessagePair(ChatMessageModel message) async {
    final index = messages.indexWhere((item) => item.id == message.id);
    if (index == -1) {
      return;
    }

    String? pairedId;
    if (message.isUser &&
        index + 1 < messages.length &&
        !messages[index + 1].isUser) {
      pairedId = messages[index + 1].id;
    } else if (!message.isUser &&
        index - 1 >= 0 &&
        messages[index - 1].isUser) {
      pairedId = messages[index - 1].id;
    }

    final idsToDelete = <String>[message.id];
    if (pairedId != null) {
      idsToDelete.add(pairedId);
    }

    try {
      await _chatService.deleteMessages(idsToDelete);
      messages.removeWhere((item) => idsToDelete.contains(item.id));
    } catch (error) {
      BatasphLogger.error('Failed to delete chat messages: $error');
      Get.snackbar(
        'Unable to delete messages',
        'Try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void openSource(ChatSourceModel source) {
    if (source.sourceUrl.trim().isEmpty) {
      return;
    }

    Get.toNamed(
      Routes.LEGAL_WEBVIEW,
      arguments: {'title': source.label, 'url': source.sourceUrl},
    );
  }

  bool isSavedAnswer(String answerMessageId) {
    return _savedAnswersService.isSaved(answerMessageId);
  }

  Future<void> toggleSavedAnswer(ChatMessageModel answerMessage) async {
    final questionMessage = _findPairedQuestion(answerMessage);
    if (answerMessage.isUser || questionMessage == null) {
      return;
    }

    try {
      final isSaved = await _savedAnswersService.toggleSavedAnswer(
        questionMessage: questionMessage,
        answerMessage: answerMessage,
      );

      Get.snackbar(
        isSaved ? 'Saved answer' : 'Removed saved answer',
        isSaved
            ? 'This question and answer pair is now saved on this device.'
            : 'This question and answer pair was removed from saved answers.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      BatasphLogger.error('Failed to toggle saved answer: $error');
      Get.snackbar(
        'Unable to update saved answers',
        'Try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  static int replaceMessageById(
    List<ChatMessageModel> messages, {
    required String messageId,
    required ChatMessageModel replacement,
  }) {
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index != -1) {
      messages[index] = replacement;
    }
    return index;
  }

  static bool removeMessageById(
    List<ChatMessageModel> messages, {
    required String messageId,
  }) {
    final index = messages.indexWhere((message) => message.id == messageId);
    if (index == -1) {
      return false;
    }
    messages.removeAt(index);
    return true;
  }

  Future<void> _loadHistory() async {
    isLoading.value = true;
    try {
      _syncLocalDisplayState();
      final history = await _chatService.getHistory();
      messages.assignAll(history);
      await _scrollToBottom();
    } catch (error) {
      BatasphLogger.warning('Failed to load chat history: $error');
      messages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _syncLocalDisplayState() {
    answerLanguage.value = MySharedPref.getAnswerLanguage();
    _syncRecentSearches();
  }

  void _syncRecentSearches() {
    recentSearches.assignAll(MySharedPref.getRecentSearches());
  }

  void _handleSendFailure({
    required String optimisticId,
    required String failedText,
  }) {
    removeMessageById(messages, messageId: optimisticId);
    failedMessageText.value = failedText;
    isStreaming.value = false;
    streamingText.value = '';
  }

  void _finalizeCancelledStream() {
    if (streamingText.value.trim().isNotEmpty) {
      messages.add(
        ChatMessageModel(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: streamingText.value.trim(),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
    isStreaming.value = false;
    streamingText.value = '';
  }

  Future<void> _scrollToBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!scrollController.hasClients) {
      return;
    }

    await scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  ChatMessageModel? _findPairedQuestion(ChatMessageModel answerMessage) {
    final index = messages.indexWhere((item) => item.id == answerMessage.id);
    if (index <= 0) {
      return null;
    }

    final previousMessage = messages[index - 1];
    if (!previousMessage.isUser) {
      return null;
    }

    return previousMessage;
  }
}
