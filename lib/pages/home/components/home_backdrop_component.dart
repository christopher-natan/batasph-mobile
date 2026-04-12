import 'package:flutter/material.dart';

class HomeBackdropComponent extends StatelessWidget {
  const HomeBackdropComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0F141D), Color(0xFF131A25), Color(0xFF10141B)]
              : const [Color(0xFFF7F2E8), Color(0xFFF2ECE0), Color(0xFFE8DED0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -80,
            child: _GlowCircle(
              size: 260,
              color: isDark
                  ? const Color(0xFF35435F).withValues(alpha: 0.44)
                  : const Color(0xFFE7D7BE).withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            bottom: 180,
            left: -70,
            child: _GlowCircle(
              size: 210,
              color: isDark
                  ? const Color(0xFF253147).withValues(alpha: 0.3)
                  : const Color(0xFFD8C4A6).withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFFFF9F0).withValues(alpha: 0.78),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
