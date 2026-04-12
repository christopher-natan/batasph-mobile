import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:batasph_mobile/data/models/chat_message_model.dart';
import 'package:batasph_mobile/data/models/chat_source_model.dart';

class ChatBubbleComponent extends StatelessWidget {
  final ChatMessageModel message;
  final VoidCallback? onDelete;
  final ValueChanged<ChatSourceModel>? onOpenSource;

  const ChatBubbleComponent({
    super.key,
    required this.message,
    this.onDelete,
    this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: isUser ? 300.w : 340.w),
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
            Row(
              children: [
                if (!isUser)
                  Text(
                    'Grounded in legal text',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                const Spacer(),
                if (onDelete != null)
                  PopupMenuButton<String>(
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
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 18.sp,
                      color: isUser
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.hintColor,
                    ),
                  ),
              ],
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
            if (!isUser && message.legalBasis.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                'Legal Basis',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 8.h),
              ...message.legalBasis.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 6.h, right: 8.w),
                        child: Container(
                          width: 5.w,
                          height: 5.w,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12.sp,
                            height: 1.45,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!isUser && message.hasSources) ...[
              SizedBox(height: 10.h),
              Text(
                'Source Links',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 6.h),
              ...message.sources
                  .where((source) => source.sourceUrl.trim().isNotEmpty)
                  .map(
                    (source) => Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onOpenSource == null
                            ? null
                            : () => onOpenSource!(source),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          source.label,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
