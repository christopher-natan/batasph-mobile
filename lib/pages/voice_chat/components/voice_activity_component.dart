import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';

/// A decorative speaking/listening indicator, not a microphone level meter.
class VoiceActivityComponent extends StatelessWidget {
  final Animation<double> animation;
  final bool animated;

  const VoiceActivityComponent({
    super.key,
    required this.animation,
    required this.animated,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: 28,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(23, (index) {
              final envelope = math.sin((index + 1) / 24 * math.pi);
              final phase = animated && !reduceMotion ? animation.value : 0.4;
              final wave = math.sin(index * 1.8 + phase * math.pi * 2).abs();
              return Container(
                width: 2.5,
                height: 4 + envelope * (6 + wave * 17),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppThemes.callForest.withValues(
                    alpha: 0.55 + wave * 0.3,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
