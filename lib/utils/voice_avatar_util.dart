import 'package:flutter/material.dart';

class VoiceAvatarUtil {
  VoiceAvatarUtil._();

  static const _assets = <String, String>{
    'luna': 'assets/images/avatars/luna.png',
    'aria': 'assets/images/avatars/aria.png',
  };

  static String? assetFor(String voiceId) =>
      _assets[voiceId.trim().toLowerCase()];

  static Color fallbackColorFor(String voiceId) {
    return switch (voiceId.trim().toLowerCase()) {
      'luna' => const Color(0xFF2E415E),
      'aria' => const Color(0xFF6D4951),
      'atlas' => const Color(0xFF345D65),
      'orion' => const Color(0xFF675A78),
      _ => const Color(0xFF42506B),
    };
  }
}
