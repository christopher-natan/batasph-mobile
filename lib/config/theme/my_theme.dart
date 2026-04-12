import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:batasph_mobile/config/theme/app_themes.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/config/theme/dark_theme_colors.dart';
import 'package:batasph_mobile/config/theme/light_theme_colors.dart';
import 'package:batasph_mobile/config/theme/my_styles.dart';

class MyTheme {
  static ThemeData getThemeData({required bool isLight}) {
    return ThemeData(
      primaryColor: isLight
          ? LightThemeColors.primaryColor
          : DarkThemeColors.primaryColor,
      colorScheme:
          ColorScheme.fromSwatch(
            accentColor: isLight
                ? LightThemeColors.accentColor
                : DarkThemeColors.accentColor,
            backgroundColor: isLight
                ? LightThemeColors.backgroundColor
                : DarkThemeColors.backgroundColor,
            brightness: isLight ? Brightness.light : Brightness.dark,
          ).copyWith(
            primary: isLight
                ? LightThemeColors.primaryColor
                : DarkThemeColors.primaryColor,
            secondary: isLight
                ? LightThemeColors.accentColor
                : DarkThemeColors.accentColor,
          ),
      brightness: isLight ? Brightness.light : Brightness.dark,
      cardColor: isLight
          ? LightThemeColors.cardColor
          : DarkThemeColors.cardColor,
      hintColor: isLight
          ? LightThemeColors.hintTextColor
          : DarkThemeColors.hintTextColor,
      dividerColor: isLight
          ? LightThemeColors.dividerColor
          : DarkThemeColors.dividerColor,
      scaffoldBackgroundColor: isLight
          ? LightThemeColors.scaffoldBackgroundColor
          : DarkThemeColors.scaffoldBackgroundColor,
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isLight
            ? LightThemeColors.primaryColor
            : DarkThemeColors.primaryColor,
      ),
      appBarTheme: MyStyles.getAppBarTheme(isLightTheme: isLight),
      elevatedButtonTheme: MyStyles.getElevatedButtonTheme(
        isLightTheme: isLight,
      ),
      textTheme: MyStyles.getTextTheme(isLightTheme: isLight),
      chipTheme: MyStyles.getChipTheme(isLightTheme: isLight),
      iconTheme: MyStyles.getIconTheme(isLightTheme: isLight),
      listTileTheme: MyStyles.getListTileThemeData(isLightTheme: isLight),
      inputDecorationTheme: MyStyles.getInputDecorationTheme(
        isLightTheme: isLight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isLight
                ? LightThemeColors.primaryColor
                : DarkThemeColors.primaryColor;
          }
          return isLight ? Colors.grey.shade400 : Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isLight
                    ? LightThemeColors.primaryColor
                    : DarkThemeColors.primaryColor)
                .withValues(alpha: 0.4);
          }
          return isLight ? Colors.grey.shade300 : Colors.grey.shade800;
        }),
      ),
    );
  }

  static void changeTheme() {
    bool isLightTheme = MySharedPref.getThemeIsLight();
    MySharedPref.setThemeIsLight(!isLightTheme);
    Get.changeThemeMode(!isLightTheme ? ThemeMode.light : ThemeMode.dark);
  }

  static void changeAppTheme(AppThemeId themeId) {
    MySharedPref.setAppTheme(themeId.name);
    Get.changeTheme(getThemeData(isLight: MySharedPref.getThemeIsLight()));
    Get.changeThemeMode(
      MySharedPref.getThemeIsLight() ? ThemeMode.light : ThemeMode.dark,
    );
    Get.forceAppUpdate();
  }

  bool get getThemeIsLight => MySharedPref.getThemeIsLight();
}
