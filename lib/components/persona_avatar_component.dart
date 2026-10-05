import 'package:flutter/material.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';

/// Luna's portrait in a fine double ring. The ended call uses a neutral ring.
class PersonaAvatarComponent extends StatelessWidget {
  final double size;
  final bool dimmed;

  const PersonaAvatarComponent({
    super.key,
    required this.size,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppThemes.ivory,
        border: Border.all(
          color: dimmed ? AppThemes.line : AppThemes.callRing,
          width: 1.5,
        ),
        boxShadow: [
          if (!dimmed)
            BoxShadow(
              color: AppThemes.callSage.withValues(alpha: 0.5),
              blurRadius: 32,
              spreadRadius: 8,
            ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.035),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppThemes.callSage,
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.025),
          child: ClipOval(
            child: Image.asset(
              AppConfig.personaAvatarAsset,
              fit: BoxFit.cover,
              cacheWidth: 768,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
