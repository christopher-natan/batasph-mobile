import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';
import 'package:batasph_mobile/data/models/chat_source_model.dart';
import 'package:batasph_mobile/data/models/chat_stream_event.dart';
import 'package:batasph_mobile/pages/report_answer/report_answer_arguments.dart';
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
  final isLoadingMore = false.obs;
  final hasMoreMessages = true.obs;
  bool _followScrollScheduled = false;

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
    scrollController.addListener(_onScroll);
    _syncLocalDisplayState();
    _loadHistory();
  }

  @override
  void onClose() {
    _chatService.cancelStream();
    scrollController.removeListener(_onScroll);
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
      BatasphLogger.warning(
        '[Chat] Message rejected: ${normalizedText.length} chars > '
        '${AppConfig.chatMaxMessageLength} limit',
      );
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

    final stopwatch = Stopwatch()..start();
    var tokenCount = 0;
    Duration? firstTokenAt;

    try {
      final answerLanguage = MySharedPref.getAnswerLanguage().name;
      BatasphLogger.log(
        '[Chat] Send | chars=${normalizedText.length} | language=$answerLanguage',
      );
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
            if (tokenCount == 0) {
              firstTokenAt = stopwatch.elapsed;
            }
            tokenCount++;
            streamingText.value += event.text;
            _followStreamIfNearBottom();
          case DoneEvent():
            BatasphLogger.log(
              '[Chat] Done | ${stopwatch.elapsedMilliseconds}ms'
              ' | firstToken=${firstTokenAt?.inMilliseconds}ms'
              ' | tokens=$tokenCount'
              ' | chars=${streamingText.value.length}'
              ' | sources=${event.sources.length}'
              ' | legalBasis=${event.legalBasis.length}'
              ' | status=${event.status}'
              ' | lang=${event.responseLanguage}'
              ' | cached=${event.cached}'
              ' | noResults=${event.noResults}',
            );
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
            BatasphLogger.error(
              '[Chat] Stream error after ${stopwatch.elapsedMilliseconds}ms: '
              '${event.message}',
            );
            _handleSendFailure(
              optimisticId: optimisticId,
              failedText: normalizedText,
            );
          case StreamWarningEvent():
            BatasphLogger.warning(
              '[Chat] Stream warning: ${event.code} ${event.message}',
            );
          case AudioEvent():
            break;
        }
      }
    } on DioException catch (error) {
      if (error.type == DioExceptionType.cancel) {
        BatasphLogger.log(
          '[Chat] Stream cancelled after ${stopwatch.elapsedMilliseconds}ms'
          ' | tokens=$tokenCount',
        );
        _finalizeCancelledStream();
      } else {
        BatasphLogger.error(
          '[Chat] Stream failed after ${stopwatch.elapsedMilliseconds}ms: '
          '${error.type.name} ${error.message}',
          error: error,
        );
        _handleSendFailure(
          optimisticId: optimisticId,
          failedText: normalizedText,
        );
      }
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Chat] Stream failed after ${stopwatch.elapsedMilliseconds}ms',
        error: error,
        stackTrace: stackTrace,
      );
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
    BatasphLogger.log('[Chat] Cancel requested by user');
    _chatService.cancelStream();
  }

  void retryFailedMessage() {
    final text = failedMessageText.value;
    if (text.isEmpty) {
      return;
    }
    BatasphLogger.log('[Chat] Retrying failed message');
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
    BatasphLogger.log('[Chat] Clearing history | messages=${messages.length}');
    try {
      await _chatService.clearHistory();
      messages.clear();
      failedMessageText.value = '';
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Chat] Failed to clear history',
        error: error,
        stackTrace: stackTrace,
      );
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

    BatasphLogger.log('[Chat] Deleting messages | ids=$idsToDelete');
    try {
      await _chatService.deleteMessages(idsToDelete);
      messages.removeWhere((item) => idsToDelete.contains(item.id));
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Chat] Failed to delete messages',
        error: error,
        stackTrace: stackTrace,
      );
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
      BatasphLogger.log(
        '[Chat] Saved answer ${isSaved ? 'added' : 'removed'} | id=${answerMessage.id}',
      );

      Get.snackbar(
        isSaved ? 'Saved answer' : 'Removed saved answer',
        isSaved
            ? 'This question and answer pair is now saved on this device.'
            : 'This question and answer pair was removed from saved answers.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Chat] Failed to toggle saved answer',
        error: error,
        stackTrace: stackTrace,
      );
      Get.snackbar(
        'Unable to update saved answers',
        'Try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> reportAnswer(ChatMessageModel answerMessage) async {
    final questionMessage = _findPairedQuestion(answerMessage);
    if (answerMessage.isUser || questionMessage == null) {
      return;
    }

    focusNode.unfocus();
    await Get.toNamed(
      Routes.REPORT_ANSWER,
      arguments: ReportAnswerArguments(
        questionMessage: questionMessage,
        answerMessage: answerMessage,
      ),
    );
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
      // Paged requests come back newest-first; the list is oldest-first.
      final page = await _chatService.getHistory(limit: AppConfig.chatPageSize);
      final history = page.reversed.toList();
      hasMoreMessages.value = history.length >= AppConfig.chatPageSize;
      BatasphLogger.log(
        '[Chat] History loaded | messages=${history.length}'
        ' | hasMore=${hasMoreMessages.value}',
      );
      messages.assignAll(history);
      await _scrollToBottom();
    } catch (error, stackTrace) {
      BatasphLogger.warning(
        '[Chat] Failed to load history',
        error: error,
        stackTrace: stackTrace,
      );
      messages.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Older messages load when the user drags up to the top of the list.
  /// The direction check keeps programmatic scrolls (the initial jump to
  /// the bottom) and a short, non-scrolling list from paging by themselves.
  void _onScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.userScrollDirection != ScrollDirection.forward) return;
    if (position.pixels <= position.minScrollExtent + 100) {
      loadMoreMessages();
    }
  }

  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMoreMessages.value || messages.isEmpty) {
      return;
    }

    isLoadingMore.value = true;
    // Prepending grows the list above the viewport; remember how far the
    // reader was from the top so the view can be put back on the same
    // message once the new extent is known.
    final position = scrollController.hasClients
        ? scrollController.position
        : null;
    final extentBefore = position?.maxScrollExtent ?? 0;
    final pixelsBefore = position?.pixels ?? 0;
    try {
      final oldest = messages.first;
      final page = await _chatService.getHistory(
        limit: AppConfig.chatPageSize,
        before: oldest.timestamp,
      );
      final older = page.reversed.toList();
      BatasphLogger.log(
        '[Chat] Older history loaded | messages=${older.length}'
        ' | before=${oldest.timestamp.toIso8601String()}',
      );

      if (older.isEmpty) {
        hasMoreMessages.value = false;
        return;
      }

      messages.insertAll(0, older);
      hasMoreMessages.value = older.length >= AppConfig.chatPageSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final delta = scrollController.position.maxScrollExtent - extentBefore;
        scrollController.jumpTo(pixelsBefore + delta);
      });
    } catch (error, stackTrace) {
      BatasphLogger.warning(
        '[Chat] Failed to load older history',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Keeps a streaming reply in view, but only when the reader is already at
  /// the bottom — someone scrolled up reading an earlier answer is not
  /// yanked back down by every token.
  void _followStreamIfNearBottom() {
    if (_followScrollScheduled || !scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.maxScrollExtent - position.pixels > 120) return;
    // Tokens arrive faster than frames; one jump per frame is enough.
    _followScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followScrollScheduled = false;
      if (!scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
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
