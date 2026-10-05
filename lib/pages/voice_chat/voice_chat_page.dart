import 'package:flutter/material.dart';
import 'package:batasph_mobile/components/call_screen_frame_component.dart';
import 'package:batasph_mobile/components/circular_call_button_component.dart';
import 'package:batasph_mobile/pages/voice_chat/components/voice_activity_component.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/components/persona_avatar_component.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/pages/voice_chat/voice_chat_controller.dart';

/// The call screen, laid out like the phone's own in-call screen: who you are
/// talking to and the timer on top, the avatar in the middle, then Mute and
/// the red End button. A failed call shows its error with a retry. Ending the call (button,
/// back gesture, or saying goodbye) turns the same screen into the call
/// summary; Done goes back to Home.
class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage>
    with SingleTickerProviderStateMixin {
  late final VoiceChatController _controller;
  late final AnimationController _pulseController;
  Future<void>? _endingFuture;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<VoiceChatController>();
    _controller.onFarewellComplete = _endCall;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.startCall();
    });
  }

  @override
  void dispose() {
    _controller.onFarewellComplete = null;
    _pulseController.dispose();
    super.dispose();
  }

  /// One end per call even if End, back and the farewell race each other.
  Future<void> _endCall() {
    return _endingFuture ??= _controller.endConversation().whenComplete(() {
      _endingFuture = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ended = _controller.callEnded.value;
      return PopScope(
        canPop: ended,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _endCall();
        },
        child: Scaffold(
          body: CallScreenFrameComponent(
            footer: ended
                ? null
                : _CallControls(controller: _controller, onEnd: _endCall),
            child: ended
                ? _EndedView(controller: _controller)
                : _InCallView(controller: _controller, pulse: _pulseController),
          ),
        ),
      );
    });
  }
}

// ─── In call ─────────────────────────────────────────────────

class _InCallView extends StatelessWidget {
  final VoiceChatController controller;
  final Animation<double> pulse;

  const _InCallView({required this.controller, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.state.value;
      final connecting =
          state == VoiceChatState.connecting || state == VoiceChatState.idle;

      return Column(
        children: [
          _CallHeader(
            status: connecting ? 'Ringing…' : controller.callDurationLabel,
          ),
          const Spacer(),
          const SizedBox(height: 12),
          _AnimatedAvatar(state: state, pulse: pulse),
          const SizedBox(height: 10),
          _StatusChip(
            state: state,
            muted: controller.isUserMuted.value,
            pulse: pulse,
          ),
          const SizedBox(height: 10),
          const Spacer(),
          _ErrorArea(controller: controller),
        ],
      );
    });
  }
}

class _CallHeader extends StatelessWidget {
  final String status;
  final bool ended;

  const _CallHeader({required this.status, this.ended = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          AppConfig.personaName,
          style: TextStyle(
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: AppThemes.forest,
          ),
        ),
        if (!ended) ...[
          const SizedBox(height: 5),
          const Text(
            AppConfig.personaTagline,
            style: TextStyle(fontSize: 13, color: AppThemes.forest),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          status,
          style: TextStyle(
            fontSize: ended ? 14 : 17,
            fontWeight: ended ? FontWeight.w400 : FontWeight.w500,
            letterSpacing: ended ? 0 : 1.2,
            color: ended ? AppThemes.muted : AppThemes.callForest,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A subtle halo follows the call state without changing the portrait's size.
class _AnimatedAvatar extends StatelessWidget {
  final VoiceChatState state;
  final Animation<double> pulse;

  const _AnimatedAvatar({required this.state, required this.pulse});

  @override
  Widget build(BuildContext context) {
    // Preparing an answer is still Luna's turn on the line (filler, thinking
    // sound), so it pulses like speaking.
    final active =
        state == VoiceChatState.connecting ||
        state == VoiceChatState.processing ||
        state == VoiceChatState.speaking;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: 204,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final t = active && !reduceMotion ? pulse.value : 0.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 192 + 12 * t,
                height: 192 + 12 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppThemes.callRing.withValues(alpha: 0.45 - 0.2 * t),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: const PersonaAvatarComponent(size: 190),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final VoiceChatState state;
  final bool muted;
  final Animation<double> pulse;

  const _StatusChip({
    required this.state,
    required this.muted,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (state) {
      VoiceChatState.idle ||
      VoiceChatState.connecting => ('Ringing…', Icons.ring_volume_outlined),
      VoiceChatState.listening when muted => (
        "You're muted",
        Icons.mic_off_rounded,
      ),
      VoiceChatState.listening => ('Listening to you…', Icons.mic_none_rounded),
      VoiceChatState.processing ||
      VoiceChatState.speaking => ('Luna is speaking', Icons.volume_up_outlined),
      VoiceChatState.error => ('Call needs a retry', Icons.error_outline),
    };
    final speakingOrListening =
        state == VoiceChatState.speaking ||
        state == VoiceChatState.processing ||
        (state == VoiceChatState.listening && !muted);
    final color = state == VoiceChatState.error
        ? AppThemes.callRed
        : AppThemes.forest;

    return Semantics(
      liveRegion: true,
      child: Column(
        children: [
          if (speakingOrListening)
            VoiceActivityComponent(animation: pulse, animated: true)
          else
            SizedBox(height: 28, child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

/// The failed call's error with a retry, in the space above the controls.
class _ErrorArea extends StatelessWidget {
  final VoiceChatController controller;

  const _ErrorArea({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final error = controller.errorMessage.value;
      if (controller.state.value != VoiceChatState.error || error.isEmpty) {
        return const SizedBox.shrink();
      }
      return _ErrorCard(
        message: error,
        onRetry: controller.handlePrimaryControlTap,
      );
    });
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 136,
      child: Material(
        color: AppThemes.callRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppThemes.callRed,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Tap to try again',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppThemes.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          toggled: active,
          label: label,
          child: Material(
            color: active
                ? AppThemes.forest
                : Colors.white.withValues(alpha: 0.65),
            elevation: 2,
            shadowColor: AppThemes.forest.withValues(alpha: 0.12),
            shape: CircleBorder(
              side: BorderSide(
                color: active ? AppThemes.forest : AppThemes.line,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Icon(
                  active ? activeIcon : icon,
                  size: 26,
                  color: active ? Colors.white : AppThemes.ink,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: AppThemes.forest)),
      ],
    );
  }
}

// ─── Call ended ──────────────────────────────────────────────

class _EndedView extends StatelessWidget {
  final VoiceChatController controller;

  const _EndedView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          const SizedBox(height: 24),
          _CallHeader(
            status: 'Call ended · ${controller.endedCallDurationLabel}',
            ended: true,
          ),
          const Spacer(),
          const SizedBox(height: 32),
          const PersonaAvatarComponent(size: 180, dimmed: true),
          const SizedBox(height: 32),
          const Text(
            'Until next time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
              color: AppThemes.forest,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A little more clarity, one conversation at a time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.6, color: AppThemes.muted),
          ),
          const SizedBox(height: 28),
          const Spacer(),
          const Text(
            'General legal information, not legal advice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, height: 1.5, color: AppThemes.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: 'Done',
                  background: Colors.transparent,
                  foreground: AppThemes.forest,
                  onTap: controller.leaveCall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PillButton(
                  label: 'Call again',
                  icon: Icons.call_rounded,
                  background: AppThemes.forest,
                  foreground: Colors.white,
                  onTap: controller.startCall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    });
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: background == Colors.transparent
                  ? AppThemes.line
                  : background,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final VoiceChatController controller;
  final Future<void> Function() onEnd;

  const _CallControls({required this.controller, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleButton(
            label: 'Mute',
            icon: Icons.mic_none_rounded,
            activeIcon: Icons.mic_off_rounded,
            active: controller.isUserMuted.value,
            onTap: controller.toggleMute,
          ),
          const SizedBox(width: 48),
          CircularCallButtonComponent(
            endCall: true,
            label: 'End call',
            onTap: onEnd,
          ),
        ],
      ),
    );
  }
}
