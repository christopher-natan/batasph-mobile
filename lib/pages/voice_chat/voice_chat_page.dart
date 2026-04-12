import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/voice_chat/voice_chat_controller.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage>
    with TickerProviderStateMixin {
  late final VoiceChatController _controller;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<VoiceChatController>();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startListening();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.endConversation();
    if (mounted) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          await _close();
        },
        child: Stack(
          children: [
            const Positioned.fill(child: _VoiceOverlayBackground()),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(controller: _controller, onClose: _close),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 12.h),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final transcriptHeight = math.min(
                            138.h,
                            constraints.maxHeight * 0.24,
                          );
                          final spacing = math.min(
                            12.h,
                            constraints.maxHeight * 0.025,
                          );

                          return Obx(
                            () => Column(
                              children: [
                                Expanded(
                                  child: Center(
                                    child: _VoiceHero(
                                      controller: _controller,
                                      pulseAnimation: _pulseAnimation,
                                      waveController: _waveController,
                                    ),
                                  ),
                                ),
                                SizedBox(height: spacing),
                                SizedBox(
                                  height: transcriptHeight,
                                  child: _TranscriptRegion(
                                    state: _controller.state.value,
                                    userText: _controller.userText.value,
                                    agentText: _controller.agentText.value,
                                    errorMessage:
                                        _controller.errorMessage.value,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 24.h),
                    child: _EndButton(onClose: _close),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceOverlayBackground extends StatelessWidget {
  const _VoiceOverlayBackground();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D1118).withValues(alpha: 0.94),
              const Color(0xFF111823).withValues(alpha: 0.9),
              const Color(0xFF0D131C).withValues(alpha: 0.96),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -90,
              child: _GlowCircle(
                size: 280,
                color: const Color(0xFFB97537).withValues(alpha: 0.15),
              ),
            ),
            Positioned(
              top: 220,
              left: -90,
              child: _GlowCircle(
                size: 240,
                color: const Color(0xFFE2BF85).withValues(alpha: 0.1),
              ),
            ),
            Positioned(
              bottom: 120,
              right: -70,
              child: _GlowCircle(
                size: 210,
                color: const Color(0xFF8B5A2A).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoiceChatController controller;
  final Future<void> Function() onClose;

  const _TopBar({required this.controller, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 6.h),
      child: Row(
        children: [
          _CircleActionButton(icon: Icons.close_rounded, onTap: onClose),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Minimal hands-free legal asking',
                  style: TextStyle(
                    color: const Color(0xFFAEB9CB),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => _StatusChip(state: controller.state.value)),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Future<void> Function() onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Icon(icon, color: Colors.white, size: 20.sp),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final VoiceChatState state;

  const _StatusChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      VoiceChatState.idle => ('Ready', const Color(0xFFE2BF85)),
      VoiceChatState.listening => ('Listening', const Color(0xFFF4B257)),
      VoiceChatState.processing => ('Processing', const Color(0xFFD28A43)),
      VoiceChatState.speaking => ('Speaking', const Color(0xFFF2C57E)),
      VoiceChatState.error => ('Retry', Colors.redAccent),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          SizedBox(width: 7.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceHero extends StatelessWidget {
  final VoiceChatController controller;
  final Animation<double> pulseAnimation;
  final AnimationController waveController;

  const _VoiceHero({
    required this.controller,
    required this.pulseAnimation,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.state.value;
      final (title, subtitle) = _copyForState(state);

      return LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : 520.h;
          final scale = (availableHeight / 520.h).clamp(0.62, 1.0);
          final showSupportText = availableHeight > 340.h;
          final orbFrameSize = (220.w * scale).clamp(148.w, 220.w);

          return Container(
            padding: EdgeInsets.fromLTRB(
              22.w * scale,
              20.h * scale,
              22.w * scale,
              22.h * scale,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF202B3F),
                  Color(0xFF182233),
                  Color(0xFF121A27),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.24),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w * scale,
                    vertical: 7.h * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    'VOICE MODE',
                    style: TextStyle(
                      color: const Color(0xFFE2BF85),
                      fontSize: (11.sp * scale).clamp(10.sp, 11.sp),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.7 * scale,
                    ),
                  ),
                ),
                SizedBox(height: (18.h * scale).clamp(10.h, 18.h)),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (28.sp * scale).clamp(22.sp, 28.sp),
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: (10.h * scale).clamp(6.h, 10.h)),
                Text(
                  subtitle,
                  maxLines: scale < 0.8 ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFC3CDDC),
                    fontSize: (13.sp * scale).clamp(11.sp, 13.sp),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: (22.h * scale).clamp(12.h, 22.h)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.interrupt,
                  child: SizedBox(
                    width: orbFrameSize,
                    height: orbFrameSize,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _VoiceOrb(
                        controller: controller,
                        pulseAnimation: pulseAnimation,
                        waveController: waveController,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: (16.h * scale).clamp(10.h, 16.h)),
                _StatePill(state: state, scale: scale),
                if (showSupportText) ...[
                  SizedBox(height: (10.h * scale).clamp(6.h, 10.h)),
                  Text(
                    state == VoiceChatState.speaking
                        ? 'Tap the mic to interrupt.'
                        : 'Animation-ready mic orb for the next visual pass.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF9AA7BB),
                      fontSize: (12.sp * scale).clamp(10.sp, 12.sp),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  (String, String) _copyForState(VoiceChatState state) {
    return switch (state) {
      VoiceChatState.idle => (
        'Speak when ready.',
        'BatasPH is ready to listen, process, and answer aloud.',
      ),
      VoiceChatState.listening => (
        'Listening closely.',
        'Ask naturally. We will capture the transcript below.',
      ),
      VoiceChatState.processing => (
        'Checking the law.',
        'The system is grounding your answer before speaking.',
      ),
      VoiceChatState.speaking => (
        'Speaking now.',
        'The answer is being read aloud. Interrupt if needed.',
      ),
      VoiceChatState.error => (
        'Voice needs a retry.',
        'Use the mic again or close and reopen the voice session.',
      ),
    };
  }
}

class _StatePill extends StatelessWidget {
  final VoiceChatState state;
  final double scale;

  const _StatePill({required this.state, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (state) {
      VoiceChatState.idle => (
        'Ready',
        Icons.mic_none_rounded,
        const Color(0xFFE2BF85),
      ),
      VoiceChatState.listening => (
        'Listening',
        Icons.hearing_rounded,
        const Color(0xFFF4B257),
      ),
      VoiceChatState.processing => (
        'Processing',
        Icons.auto_awesome_rounded,
        const Color(0xFFD28A43),
      ),
      VoiceChatState.speaking => (
        'Speaking',
        Icons.volume_up_rounded,
        const Color(0xFFF2C57E),
      ),
      VoiceChatState.error => (
        'Try Again',
        Icons.error_outline_rounded,
        Colors.redAccent,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.w * scale,
        vertical: 10.h * scale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: (16.sp * scale).clamp(14.sp, 16.sp)),
          SizedBox(width: 8.w * scale),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: (12.sp * scale).clamp(10.sp, 12.sp),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;
  final Color accentColor;

  const _TranscriptCard({
    required this.title,
    required this.icon,
    required this.text,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxLines = math.max(
                  2,
                  (constraints.maxHeight / (13.sp * 1.55)).floor(),
                );

                return Text(
                  text,
                  maxLines: maxLines,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    height: 1.55,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptRegion extends StatelessWidget {
  final VoiceChatState state;
  final String userText;
  final String agentText;
  final String errorMessage;

  const _TranscriptRegion({
    required this.state,
    required this.userText,
    required this.agentText,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final showError = state == VoiceChatState.error && errorMessage.isNotEmpty;
    final shouldShowTranscript =
        !showError &&
        userText.isNotEmpty &&
        (state == VoiceChatState.listening ||
            state == VoiceChatState.processing ||
            agentText.isEmpty);

    if (showError) {
      return _ErrorCard(message: errorMessage);
    }

    if (shouldShowTranscript) {
      return _TranscriptCard(
        title: 'Live Transcript',
        icon: Icons.hearing_rounded,
        text: userText,
        accentColor: const Color(0xFFE2BF85),
      );
    }

    if (agentText.isNotEmpty) {
      return _TranscriptCard(
        title: 'BatasPH Reply',
        icon: Icons.record_voice_over_outlined,
        text: agentText,
        accentColor: const Color(0xFFF4C781),
      );
    }

    if (userText.isNotEmpty) {
      return _TranscriptCard(
        title: 'Live Transcript',
        icon: Icons.hearing_rounded,
        text: userText,
        accentColor: const Color(0xFFE2BF85),
      );
    }

    return const _TranscriptPlaceholder();
  }
}

class _TranscriptPlaceholder extends StatelessWidget {
  const _TranscriptPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Text(
          'Transcript and reply will stay visible here during voice chat.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFAAB6C9),
            fontSize: 12.sp,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13.sp,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndButton extends StatelessWidget {
  final Future<void> Function() onClose;

  const _EndButton({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onClose,
        icon: const Icon(Icons.call_end_outlined),
        label: const Text('End voice chat'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          backgroundColor: Colors.white.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _VoiceOrb extends StatelessWidget {
  final VoiceChatController controller;
  final Animation<double> pulseAnimation;
  final AnimationController waveController;

  const _VoiceOrb({
    required this.controller,
    required this.pulseAnimation,
    required this.waveController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.state.value;
      final isListening = state == VoiceChatState.listening;
      final isProcessing = state == VoiceChatState.processing;
      final isSpeaking = state == VoiceChatState.speaking;
      final isActive = isListening || isSpeaking;

      final orbColor = switch (state) {
        VoiceChatState.idle => const Color(0xFFC8843C),
        VoiceChatState.listening => const Color(0xFFD89445),
        VoiceChatState.processing => const Color(0xFFB97537),
        VoiceChatState.speaking => const Color(0xFFE2BF85),
        VoiceChatState.error => Colors.redAccent,
      };

      return SizedBox(
        width: 220.w,
        height: 220.w,
        child: AnimatedBuilder(
          animation: Listenable.merge([pulseAnimation, waveController]),
          builder: (context, child) {
            final scale = isActive ? pulseAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                painter: _WaveformRingPainter(
                  color: orbColor,
                  progress: waveController.value,
                  isActive: isActive,
                  isProcessing: isProcessing,
                  barCount: 52,
                ),
                child: Center(
                  child: Container(
                    width: 122.w,
                    height: 122.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [orbColor, orbColor.withValues(alpha: 0.82)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: orbColor.withValues(alpha: 0.34),
                          blurRadius: 34,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: isProcessing
                        ? Center(
                            child: SizedBox(
                              width: 34.w,
                              height: 34.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          )
                        : Icon(
                            isSpeaking
                                ? Icons.volume_up_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 52.sp,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}

class _WaveformRingPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isActive;
  final bool isProcessing;
  final int barCount;

  _WaveformRingPainter({
    required this.color,
    required this.progress,
    required this.isActive,
    required this.isProcessing,
    required this.barCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = size.width * 0.32;
    final maxBarHeight = size.width * 0.12;
    final barWidth = size.width * 0.02;

    final paint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.6 : 0.22)
      ..strokeWidth = barWidth
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < barCount; index++) {
      final angle = (2 * math.pi / barCount) * index - math.pi / 2;

      double heightFraction;
      if (isActive) {
        final wave1 = math.sin((progress * 2 * math.pi) + (index * 0.4));
        final wave2 = math.sin((progress * 2 * math.pi * 1.7) + (index * 0.25));
        final wave3 = math.cos((progress * 2 * math.pi * 0.8) + (index * 0.6));
        heightFraction = 0.3 + 0.7 * ((wave1 + wave2 + wave3 + 3) / 6);
      } else if (isProcessing) {
        final distance = ((index / barCount) - progress).abs();
        final wrapped = distance > 0.5 ? 1.0 - distance : distance;
        heightFraction = 0.2 + 0.48 * math.max(0, 1.0 - wrapped * 5);
      } else {
        heightFraction = 0.16;
      }

      final barHeight = maxBarHeight * heightFraction;
      final startRadius = innerRadius + 2;
      final endRadius = startRadius + barHeight;

      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isProcessing != isProcessing ||
        oldDelegate.color != color;
  }
}
