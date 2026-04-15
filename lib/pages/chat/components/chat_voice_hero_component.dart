import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatVoiceHeroComponent extends StatelessWidget {
  final String answerLanguageLabel;
  final VoidCallback onOpenVoiceChat;
  final bool compact;

  const ChatVoiceHeroComponent({
    super.key,
    required this.answerLanguageLabel,
    required this.onOpenVoiceChat,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactVoiceHero(
            answerLanguageLabel: answerLanguageLabel,
            onOpenVoiceChat: onOpenVoiceChat,
          )
        : _ProminentVoiceHero(
            answerLanguageLabel: answerLanguageLabel,
            onOpenVoiceChat: onOpenVoiceChat,
          );
  }
}

class _ProminentVoiceHero extends StatelessWidget {
  final String answerLanguageLabel;
  final VoidCallback onOpenVoiceChat;

  const _ProminentVoiceHero({
    required this.answerLanguageLabel,
    required this.onOpenVoiceChat,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenVoiceChat,
        borderRadius: BorderRadius.circular(36.r),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 24.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF24334D), Color(0xFF324665), Color(0xFF1D293D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E2837).withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _HeroChip(
                    label: 'Voice Ready',
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    textColor: const Color(0xFFF3D6A4),
                  ),
                  SizedBox(width: 10.w),
                  _HeroChip(
                    label: answerLanguageLabel,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    textColor: const Color(0xFFD8E2F2),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'Speak your question.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Voice is the fastest way to ask while driving or on the go.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFD6E0F0),
                  fontSize: 13.sp,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 24.h),
              _MicOrb(size: 220.w, micSize: 96.w, iconSize: 52.sp),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999.r),
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: Text(
                  'Tap once to open voice chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactVoiceHero extends StatelessWidget {
  final String answerLanguageLabel;
  final VoidCallback onOpenVoiceChat;

  const _CompactVoiceHero({
    required this.answerLanguageLabel,
    required this.onOpenVoiceChat,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenVoiceChat,
        borderRadius: BorderRadius.circular(28.r),
        child: Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF24334D), Color(0xFF324665)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E2837).withValues(alpha: 0.12),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              _MicOrb(size: 74.w, micSize: 44.w, iconSize: 24.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice-first asking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Open voice chat quickly. Answer language: $answerLanguageLabel.',
                      style: TextStyle(
                        color: const Color(0xFFD6E0F0),
                        fontSize: 12.sp,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicOrb extends StatelessWidget {
  final double size;
  final double micSize;
  final double iconSize;

  const _MicOrb({
    required this.size,
    required this.micSize,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8C38A).withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE8C38A).withValues(alpha: 0.22),
              ),
            ),
          ),
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC18B47), Color(0xFFE2BF85)],
              ),
            ),
          ),
          Container(
            width: micSize,
            height: micSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.mic_rounded, color: Colors.white, size: iconSize),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _HeroChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
