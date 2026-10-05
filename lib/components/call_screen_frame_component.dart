import 'package:flutter/material.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';

/// Shared call canvas. Content can scroll while optional call controls stay put.
class CallScreenFrameComponent extends StatelessWidget {
  final Widget child;
  final Widget? footer;

  const CallScreenFrameComponent({super.key, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: IntrinsicHeight(child: child),
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppThemes.ivory,
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 0.8,
          colors: [AppThemes.callCanvasGlow, AppThemes.ivory],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: footer == null
                ? content
                : Column(
                    children: [
                      Expanded(child: content),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                        child: footer!,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
