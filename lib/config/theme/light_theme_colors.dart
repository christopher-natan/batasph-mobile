import 'package:flutter/material.dart';

import 'package:batasph_mobile/config/theme/app_themes.dart';

class LightThemeColors {
  static AppThemeColors get _c => AppThemes.getColors(isLight: true);

  static Color get primaryColor => _c.primaryColor;
  static Color get accentColor => _c.accentColor;
  static Color get appBarColor => _c.appBarColor;
  static Color get scaffoldBackgroundColor => _c.scaffoldBackgroundColor;
  static Color get backgroundColor => _c.scaffoldBackgroundColor;
  static Color get dividerColor => _c.dividerColor;
  static Color get cardColor => _c.cardColor;
  static Color get appBarIconsColor => _c.appBarIconsColor;
  static Color get iconColor => _c.iconColor;
  static Color get buttonColor => _c.buttonColor;
  static Color get buttonTextColor => _c.buttonTextColor;
  static Color get buttonDisabledColor => _c.buttonDisabledColor;
  static Color get buttonDisabledTextColor => _c.buttonDisabledTextColor;
  static Color get bodyTextColor => _c.bodyTextColor;
  static Color get displayTextColor => _c.displayTextColor;
  static Color get bodySmallTextColor => _c.bodySmallTextColor;
  static Color get hintTextColor => _c.hintTextColor;
  static Color get chipBackground => _c.chipBackground;
  static Color get chipTextColor => _c.chipTextColor;
  static Color get listTileTitleColor => _c.listTileTitleColor;
  static Color get listTileSubtitleColor => _c.listTileSubtitleColor;
  static Color get listTileBackgroundColor => _c.listTileBackgroundColor;
  static Color get listTileIconColor => _c.listTileIconColor;
}
