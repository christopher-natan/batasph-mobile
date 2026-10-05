import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';

class ChatBubbleComponent extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onReport;
  final bool isSaved;

  const ChatBubbleComponent({
    super.key,
    required this.message,
    this.onDelete,
    this.onToggleSaved,
    this.onReport,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isUser ? 280.w : 340.w),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
            bottomRight: Radius.circular(isUser ? 4.r : 16.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser || onDelete != null)
              _BubbleHeader(
                isUser: isUser,
                theme: theme,
                onDelete: onDelete,
                onToggleSaved: onToggleSaved,
                onReport: onReport,
                isSaved: isSaved,
                message: message,
              ),
            if (!isUser) SizedBox(height: 6.h),
            if (isUser)
              SelectableText(
                message.text,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                  height: 1.5,
                ),
              )
            else
              MarkdownBody(
                data: message.text,
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
            if (!isUser && message.referenceLine != null) ...[
              SizedBox(height: 10.h),
              Text(
                message.referenceLine!,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.45,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (!isUser && message.disclaimer.trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                message.disclaimer.trim(),
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.45,
                  color: theme.hintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BubbleHeader extends StatelessWidget {
  final bool isUser;
  final ThemeData theme;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSaved;
  final VoidCallback? onReport;
  final bool isSaved;
  final ChatMessageModel message;

  const _BubbleHeader({
    required this.isUser,
    required this.theme,
    required this.onDelete,
    required this.onToggleSaved,
    required this.onReport,
    required this.isSaved,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: _DeleteMenu(
          iconColor: Colors.white.withValues(alpha: 0.8),
          onDelete: onDelete,
        ),
      );
    }

    return Row(
      children: [
        Text(
          _label,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const Spacer(),
        if (onToggleSaved != null)
          IconButton(
            onPressed: onToggleSaved,
            tooltip: isSaved ? 'Remove saved answer' : 'Save answer',
            visualDensity: VisualDensity.compact,
            splashRadius: 18.r,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: 28.w, height: 28.w),
            icon: Icon(
              isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18.sp,
              color: isSaved ? const Color(0xFFA77B43) : theme.hintColor,
            ),
          ),
        if (onReport != null)
          IconButton(
            onPressed: onReport,
            tooltip: 'Report answer',
            visualDensity: VisualDensity.compact,
            splashRadius: 18.r,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(width: 28.w, height: 28.w),
            icon: Icon(
              Icons.flag_outlined,
              size: 17.sp,
              color: theme.hintColor,
            ),
          ),
        _DeleteMenu(iconColor: theme.hintColor, onDelete: onDelete),
      ],
    );
  }

  String get _label {
    switch (message.status) {
      case 'ok':
        return 'Grounded in legal text';
      case 'general_guidance':
        return 'General legal guidance';
      case 'low_confidence':
        return 'Low-confidence reply';
      case 'error':
        return 'Service issue';
      default:
        return 'Assistant reply';
    }
  }
}

class _DeleteMenu extends StatelessWidget {
  final Color iconColor;
  final VoidCallback? onDelete;

  const _DeleteMenu({required this.iconColor, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (onDelete == null) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          onDelete?.call();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete message pair'),
        ),
      ],
      icon: Icon(Icons.more_horiz_rounded, size: 18.sp, color: iconColor),
    );
  }
}
