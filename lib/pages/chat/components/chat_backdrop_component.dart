import 'package:flutter/material.dart';

class ChatBackdropComponent extends StatelessWidget {
  const ChatBackdropComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0F141D), Color(0xFF121A25), Color(0xFF10141B)]
              : const [Color(0xFFF7F2E8), Color(0xFFF1E9DC), Color(0xFFE8DED0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -76,
            child: _GlowCircle(
              size: 250,
              color: isDark
                  ? const Color(0xFF31425B).withValues(alpha: 0.4)
                  : const Color(0xFFE7D7BE).withValues(alpha: 0.68),
            ),
          ),
          Positioned(
            top: 160,
            left: -84,
            child: _GlowCircle(
              size: 220,
              color: isDark
                  ? const Color(0xFF24334D).withValues(alpha: 0.24)
                  : const Color(0xFFD8C4A6).withValues(alpha: 0.26),
            ),
          ),
          Positioned(
            bottom: 180,
            right: -70,
            child: _GlowCircle(
              size: 210,
              color: isDark
                  ? const Color(0xFF24334D).withValues(alpha: 0.18)
                  : const Color(0xFFF3E3C8).withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFFFF8EE).withValues(alpha: 0.78),
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
