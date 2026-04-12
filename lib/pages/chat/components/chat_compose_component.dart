import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatComposeComponent extends StatelessWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool hasText;
  final bool isSending;
  final bool isStreaming;
  final VoidCallback onSubmit;
  final VoidCallback onCancelStream;
  final VoidCallback? onCollapse;
  final bool embedded;

  const ChatComposeComponent({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.hasText,
    required this.isSending,
    required this.isStreaming,
    required this.onSubmit,
    required this.onCancelStream,
    this.onCollapse,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF121A25).withValues(alpha: embedded ? 0.84 : 0.92)
            : const Color(0xFFFFFBF4).withValues(alpha: embedded ? 0.92 : 0.97),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFECE1D2),
        ),
        boxShadow: embedded
            ? null
            : [
                BoxShadow(
                  color: const Color(
                    0xFF202A3A,
                  ).withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TYPE INSTEAD',
                style: TextStyle(
                  color: const Color(0xFFA18867),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
              const Spacer(),
              if (onCollapse != null)
                IconButton(
                  onPressed: onCollapse,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close typing',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E2837),
                    fontSize: 14.sp,
                    height: 1.45,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    hintText: 'Ask a Philippine law question',
                    hintStyle: TextStyle(
                      color: theme.hintColor.withValues(alpha: 0.72),
                      fontSize: 14.sp,
                      height: 1.45,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF17202C) : Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              if (isStreaming)
                IconButton(
                  onPressed: onCancelStream,
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    color: Colors.red,
                  ),
                  tooltip: 'Stop stream',
                )
              else
                IconButton(
                  onPressed: hasText && !isSending ? onSubmit : null,
                  icon: const Icon(Icons.send_rounded),
                  tooltip: 'Send question',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
