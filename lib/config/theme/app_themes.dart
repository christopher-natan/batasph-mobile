import 'package:flutter/material.dart';

class AppThemeColors {
  final Color primaryColor;
  final Color accentColor;
  final Color scaffoldBackgroundColor;
  final Color cardColor;
  final Color dividerColor;
  final Color hintTextColor;
  final Color bodyTextColor;
  final Color displayTextColor;
  final Color bodySmallTextColor;
  final Color iconColor;
  final Color appBarColor;
  final Color appBarIconsColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color buttonDisabledColor;
  final Color buttonDisabledTextColor;
  final Color chipBackground;
  final Color chipTextColor;
  final Color listTileTitleColor;
  final Color listTileSubtitleColor;
  final Color listTileBackgroundColor;
  final Color listTileIconColor;

  const AppThemeColors({
    required this.primaryColor,
    required this.accentColor,
    required this.scaffoldBackgroundColor,
    required this.cardColor,
    required this.dividerColor,
    required this.hintTextColor,
    required this.bodyTextColor,
    required this.displayTextColor,
    required this.bodySmallTextColor,
    required this.iconColor,
    required this.appBarColor,
    required this.appBarIconsColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.buttonDisabledColor,
    required this.buttonDisabledTextColor,
    required this.chipBackground,
    required this.chipTextColor,
    required this.listTileTitleColor,
    required this.listTileSubtitleColor,
    required this.listTileBackgroundColor,
    required this.listTileIconColor,
  });
}

/// The BatasPH brand palette: warm ivory ground, forest green for actions,
/// amber from the logo for accents. Light only — there is no dark mode.
class AppThemes {
  AppThemes._();

  static const ivory = Color(0xFFF5F1EA);
  static const forest = Color(0xFF1F4D3F);
  static const amber = Color(0xFFC8964F);
  static const ink = Color(0xFF1B2420);
  static const muted = Color(0xFF5F6B66);
  static const line = Color(0xFFE6DDD1);
  static const surfaceSoft = Color(0xFFE9E2D6);

  // Dialer and call surfaces: warm paper with restrained sage accents.
  static const callCanvasGlow = Color(0xFFF2F3E9);
  static const callSage = Color(0xFFE3E9D9);
  static const callRing = Color(0xFFC9D6BE);
  static const callForest = Color(0xFF246454);
  static const callCoral = Color(0xFFE75343);

  /// The red End button, kept apart from the brand so it reads like the
  /// phone's own dialer.
  static const callRed = Color(0xFFD64545);

  static const colors = AppThemeColors(
    primaryColor: forest,
    accentColor: amber,
    scaffoldBackgroundColor: ivory,
    cardColor: Colors.white,
    dividerColor: line,
    hintTextColor: muted,
    bodyTextColor: ink,
    displayTextColor: ink,
    bodySmallTextColor: muted,
    iconColor: ink,
    appBarColor: ivory,
    appBarIconsColor: ink,
    buttonColor: forest,
    buttonTextColor: Colors.white,
    buttonDisabledColor: surfaceSoft,
    buttonDisabledTextColor: muted,
    chipBackground: surfaceSoft,
    chipTextColor: ink,
    listTileTitleColor: ink,
    listTileSubtitleColor: muted,
    listTileBackgroundColor: Colors.white,
    listTileIconColor: forest,
  );
}
