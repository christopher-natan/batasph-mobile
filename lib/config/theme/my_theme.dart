import 'package:flutter/material.dart';

import 'package:batasph_mobile/config/theme/light_theme_colors.dart';
import 'package:batasph_mobile/config/theme/my_styles.dart';

class MyTheme {
  static ThemeData getThemeData() {
    return ThemeData(
      primaryColor: LightThemeColors.primaryColor,
      colorScheme:
          ColorScheme.fromSwatch(
            accentColor: LightThemeColors.accentColor,
            backgroundColor: LightThemeColors.backgroundColor,
            brightness: Brightness.light,
          ).copyWith(
            primary: LightThemeColors.primaryColor,
            secondary: LightThemeColors.accentColor,
          ),
      brightness: Brightness.light,
      cardColor: LightThemeColors.cardColor,
      hintColor: LightThemeColors.hintTextColor,
      dividerColor: LightThemeColors.dividerColor,
      scaffoldBackgroundColor: LightThemeColors.scaffoldBackgroundColor,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: LightThemeColors.primaryColor,
      ),
      appBarTheme: MyStyles.getAppBarTheme(),
      elevatedButtonTheme: MyStyles.getElevatedButtonTheme(),
      textTheme: MyStyles.getTextTheme(),
      chipTheme: MyStyles.getChipTheme(),
      iconTheme: MyStyles.getIconTheme(),
      listTileTheme: MyStyles.getListTileThemeData(),
      inputDecorationTheme: MyStyles.getInputDecorationTheme(),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LightThemeColors.primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LightThemeColors.primaryColor.withValues(alpha: 0.4);
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }
}
