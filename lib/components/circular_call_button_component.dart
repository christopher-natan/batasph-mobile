import 'package:flutter/material.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';

/// The same familiar handset action on the dialer and in-call screen.
class CircularCallButtonComponent extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool endCall;

  const CircularCallButtonComponent({
    super.key,
    required this.label,
    required this.onTap,
    this.endCall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = endCall ? AppThemes.callCoral : AppThemes.callForest;
    final size = endCall ? 72.0 : 96.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(endCall ? 0 : 7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: endCall ? null : Border.all(color: Colors.white, width: 2),
            color: endCall ? null : AppThemes.callSage.withValues(alpha: 0.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: endCall ? 0.16 : 0.14),
                blurRadius: endCall ? 20 : 32,
                spreadRadius: endCall ? 0 : 6,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Semantics(
            button: true,
            label: label,
            child: Material(
              color: color,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: size,
                  child: Icon(
                    endCall ? Icons.call_end_rounded : Icons.call_rounded,
                    color: Colors.white,
                    size: endCall ? 30 : 38,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: endCall ? 12 : 16,
            fontWeight: endCall ? FontWeight.w400 : FontWeight.w600,
            color: AppThemes.forest,
          ),
        ),
      ],
    );
  }
}
