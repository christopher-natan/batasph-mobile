import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';
import 'package:batasph_mobile/pages/chat/chat_controller.dart';
import 'package:batasph_mobile/pages/chat/components/chat_backdrop_component.dart';
import 'package:batasph_mobile/pages/chat/components/chat_bubble_component.dart';
import 'package:batasph_mobile/pages/chat/components/chat_compose_component.dart';
import 'package:batasph_mobile/pages/chat/components/chat_recent_prompts_component.dart';
import 'package:batasph_mobile/pages/chat/components/chat_voice_hero_component.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF10141B)
          : const Color(0xFFF7F2E8),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(child: ChatBackdropComponent()),
            SafeArea(
              child: Obx(() {
                final answerLanguageLabel =
                    controller.answerLanguage.value.label;
                final recentPrompts = List<String>.from(
                  controller.recentSearches,
                );
                final isTextChatMode = controller.isTextChatMode.value;

                if (controller.isLoading.value && isTextChatMode) {
                  return _ChatLoadingState(
                    isDark: isDark,
                    onOpenVoiceChat: controller.openVoiceChat,
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: isTextChatMode
                      ? _ConversationLayout(
                          controller: controller,
                          answerLanguageLabel: answerLanguageLabel,
                        )
                      : _VoiceFirstLayout(
                          controller: controller,
                          answerLanguageLabel: answerLanguageLabel,
                          recentPrompts: recentPrompts,
                        ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceFirstLayout extends StatelessWidget {
  final ChatController controller;
  final String answerLanguageLabel;
  final List<String> recentPrompts;

  const _VoiceFirstLayout({
    required this.controller,
    required this.answerLanguageLabel,
    required this.recentPrompts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      key: const ValueKey('voice-first-layout'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
          sliver: SliverList.list(
            children: [
              _ChatHeader(subtitle: 'Voice-first legal asking'),
              SizedBox(height: 18.h),
              _IntroBlock(
                eyebrow: 'VOICE-FIRST ASK PAGE',
                title: 'Speak your question.',
                description:
                    'The primary action is voice. Use typing only when speaking is not ideal.',
                isDark: isDark,
              ),
              SizedBox(height: 22.h),
              ChatVoiceHeroComponent(
                answerLanguageLabel: answerLanguageLabel,
                onOpenVoiceChat: controller.openVoiceChat,
              ),
              SizedBox(height: 22.h),
              ChatRecentPromptsComponent(
                prompts: recentPrompts,
                onTypeInstead: controller.openTextComposer,
                onSelectPrompt: controller.useRecentPrompt,
              ),
              SizedBox(height: 16.h),
              _PageNote(
                isDark: isDark,
                text:
                    'Ask prioritizes the fastest action: voice in the center, typing as fallback, and recent prompts for low-friction repeats.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationLayout extends StatelessWidget {
  final ChatController controller;
  final String answerLanguageLabel;

  const _ConversationLayout({
    required this.controller,
    required this.answerLanguageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      key: const ValueKey('conversation-layout'),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
          child: _ChatHeader(
            subtitle: 'Text chat',
            onBack: controller.showVoiceFirstLanding,
            onClearChat: controller.clearChat,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
          child: ChatVoiceHeroComponent(
            answerLanguageLabel: answerLanguageLabel,
            onOpenVoiceChat: controller.openVoiceChat,
            compact: true,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF22324D),
            onRefresh: controller.reloadHistory,
            child:
                controller.messages.isEmpty &&
                    !controller.isSending.value &&
                    !controller.isStreaming.value &&
                    controller.failedMessageText.value.isEmpty
                ? ListView(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 12.h),
                    children: const [_EmptyTextChatState()],
                  )
                : ListView(
                    controller: controller.scrollController,
                    padding: EdgeInsets.only(bottom: 12.h),
                    children: [
                      ...controller.messages.map(
                        (message) => ChatBubbleComponent(
                          message: message,
                          onDelete: message.id.startsWith('temp_')
                              ? null
                              : () => controller.deleteMessagePair(message),
                          onOpenSource: controller.openSource,
                        ),
                      ),
                      if (controller.isStreaming.value)
                        _StreamingBubble(text: controller.streamingText.value),
                      if (controller.isSending.value &&
                          !controller.isStreaming.value)
                        _ThinkingBubble(theme: theme),
                      if (controller.failedMessageText.value.isNotEmpty)
                        _FailedBubble(
                          failedText: controller.failedMessageText.value,
                          onRetry: controller.retryFailedMessage,
                        ),
                    ],
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          child: SafeArea(
            top: false,
            child: ChatComposeComponent(
              textController: controller.textController,
              focusNode: controller.focusNode,
              hasText: controller.hasText.value,
              isSending: controller.isSending.value,
              isStreaming: controller.isStreaming.value,
              onSubmit: controller.submitMessage,
              onCancelStream: controller.cancelStream,
            ),
          ),
        ),
        SizedBox(height: isDark ? 4.h : 0),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onClearChat;

  const _ChatHeader({required this.subtitle, this.onBack, this.onClearChat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1C2533)
                    : const Color(0xFFFDF8EF),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE8DDCD),
                ),
              ),
              child: Icon(
                onBack == null
                    ? Icons.graphic_eq_rounded
                    : Icons.arrow_back_rounded,
                color: const Color(0xFFA77B43),
                size: 20.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask Batas',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF24324C),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFAAB5C7)
                      : const Color(0xFF8A7A67),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (onClearChat != null)
          IconButton(
            onPressed: onClearChat,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear chat',
          ),
      ],
    );
  }
}

class _IntroBlock extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final bool isDark;

  const _IntroBlock({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFFFF8ED).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999.r),
          ),
          child: Text(
            eyebrow,
            style: TextStyle(
              color: const Color(0xFFA18867),
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.9,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1C2533),
            fontSize: 30.sp,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          description,
          style: TextStyle(
            color: isDark ? const Color(0xFFB0BAC9) : const Color(0xFF6E746F),
            fontSize: 14.sp,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _PageNote extends StatelessWidget {
  final bool isDark;
  final String text;

  const _PageNote({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFECE1D2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? const Color(0xFFB0BAC9) : const Color(0xFF59606B),
          fontSize: 13.sp,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onOpenVoiceChat;

  const _ChatLoadingState({
    required this.isDark,
    required this.onOpenVoiceChat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: Column(
        children: [
          _ChatHeader(subtitle: 'Loading conversation'),
          const Spacer(),
          Container(
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF121A25).withValues(alpha: 0.88)
                  : const Color(0xFFFBF7F1).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE9DECF),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(
                  'Loading Ask Batas...',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E2837),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _EmptyTextChatState extends StatelessWidget {
  const _EmptyTextChatState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121A25).withValues(alpha: 0.88)
            : const Color(0xFFFBF7F1).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE9DECF),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.keyboard_alt_rounded,
            size: 40.sp,
            color: const Color(0xFFA77B43),
          ),
          SizedBox(height: 14.h),
          Text(
            'Text chat is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E2837),
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Type your Philippine law question below. Voice chat is still available from the header or hero card.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFFA9B4C7) : const Color(0xFF7B756E),
              fontSize: 13.sp,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  final ThemeData theme;

  const _ThinkingBubble({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(4.r),
            bottomRight: Radius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14.w,
              height: 14.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Preparing your legal answer...',
              style: TextStyle(fontSize: 13.sp, color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingBubble extends StatelessWidget {
  final String text;

  const _StreamingBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 340.w),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(4.r),
            bottomRight: Radius.circular(16.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grounded in legal text',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 6.h),
            MarkdownBody(
              data: text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontSize: 14.sp, height: 1.5),
                strong: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
                listBullet: TextStyle(fontSize: 14.sp, height: 1.5),
                blockSpacing: 2.h,
                listIndent: 12.w,
                listBulletPadding: EdgeInsets.only(right: 4.w),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailedBubble extends StatelessWidget {
  final String failedText;
  final VoidCallback onRetry;

  const _FailedBubble({required this.failedText, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 300.w),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(16.r),
            bottomRight: Radius.circular(4.r),
          ),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(failedText, style: TextStyle(fontSize: 14.sp, height: 1.5)),
            SizedBox(height: 8.h),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.red),
              label: const Text('Retry', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
