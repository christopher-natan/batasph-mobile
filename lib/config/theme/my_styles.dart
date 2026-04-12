import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:batasph_mobile/config/theme/dark_theme_colors.dart';
import 'package:batasph_mobile/config/theme/light_theme_colors.dart';
import 'package:batasph_mobile/config/theme/my_fonts.dart';

class MyStyles {
  static IconThemeData getIconTheme({required bool isLightTheme}) =>
      IconThemeData(
        color: isLightTheme
            ? LightThemeColors.iconColor
            : DarkThemeColors.iconColor,
      );

  static AppBarTheme getAppBarTheme({required bool isLightTheme}) =>
      AppBarTheme(
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: getTextTheme(isLightTheme: isLightTheme).bodyMedium!
            .copyWith(color: Colors.white, fontSize: MyFonts.appBarTittleSize),
        iconTheme: IconThemeData(
          color: isLightTheme
              ? LightThemeColors.appBarIconsColor
              : DarkThemeColors.appBarIconsColor,
        ),
        backgroundColor: isLightTheme
            ? LightThemeColors.appBarColor
            : DarkThemeColors.appbarColor,
      );

  static TextTheme getTextTheme({required bool isLightTheme}) => TextTheme(
    labelLarge: MyFonts.buttonTextStyle.copyWith(
      fontSize: MyFonts.buttonTextSize,
    ),
    bodyLarge: MyFonts.bodyTextStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: MyFonts.bodyLargeSize,
      color: isLightTheme
          ? LightThemeColors.bodyTextColor
          : DarkThemeColors.bodyTextColor,
    ),
    bodyMedium: MyFonts.bodyTextStyle.copyWith(
      fontSize: MyFonts.bodyMediumSize,
      color: isLightTheme
          ? LightThemeColors.bodyTextColor
          : DarkThemeColors.bodyTextColor,
    ),
    displayLarge: MyFonts.displayTextStyle.copyWith(
      fontSize: MyFonts.displayLargeSize,
      fontWeight: FontWeight.bold,
      color: isLightTheme
          ? LightThemeColors.displayTextColor
          : DarkThemeColors.displayTextColor,
    ),
    bodySmall: TextStyle(
      color: isLightTheme
          ? LightThemeColors.bodySmallTextColor
          : DarkThemeColors.bodySmallTextColor,
      fontSize: MyFonts.bodySmallTextSize,
    ),
    displayMedium: MyFonts.displayTextStyle.copyWith(
      fontSize: MyFonts.displayMediumSize,
      fontWeight: FontWeight.bold,
      color: isLightTheme
          ? LightThemeColors.displayTextColor
          : DarkThemeColors.displayTextColor,
    ),
    displaySmall: MyFonts.displayTextStyle.copyWith(
      fontSize: MyFonts.displaySmallSize,
      fontWeight: FontWeight.bold,
      color: isLightTheme
          ? LightThemeColors.displayTextColor
          : DarkThemeColors.displayTextColor,
    ),
  );

  static ChipThemeData getChipTheme({required bool isLightTheme}) {
    return ChipThemeData(
      backgroundColor: isLightTheme
          ? LightThemeColors.chipBackground
          : DarkThemeColors.chipBackground,
      brightness: Brightness.light,
      labelStyle: getChipTextStyle(isLightTheme: isLightTheme),
      secondaryLabelStyle: getChipTextStyle(isLightTheme: isLightTheme),
      selectedColor: Colors.black,
      disabledColor: Colors.green,
      padding: const EdgeInsets.all(5),
      secondarySelectedColor: Colors.purple,
    );
  }

  static TextStyle getChipTextStyle({required bool isLightTheme}) {
    return MyFonts.chipTextStyle.copyWith(
      fontSize: MyFonts.chipTextSize,
      color: isLightTheme
          ? LightThemeColors.chipTextColor
          : DarkThemeColors.chipTextColor,
    );
  }

  static WidgetStateProperty<TextStyle?>? getElevatedButtonTextStyle(
    bool isLightTheme, {
    bool isBold = true,
    double? fontSize,
  }) {
    return WidgetStateProperty.resolveWith<TextStyle>((
      Set<WidgetState> states,
    ) {
      if (states.contains(WidgetState.pressed)) {
        return MyFonts.buttonTextStyle.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize ?? MyFonts.buttonTextSize,
          color: isLightTheme
              ? LightThemeColors.buttonTextColor
              : DarkThemeColors.buttonTextColor,
        );
      } else if (states.contains(WidgetState.disabled)) {
        return MyFonts.buttonTextStyle.copyWith(
          fontSize: fontSize ?? MyFonts.buttonTextSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isLightTheme
              ? LightThemeColors.buttonDisabledTextColor
              : DarkThemeColors.buttonDisabledTextColor,
        );
      }
      return MyFonts.buttonTextStyle.copyWith(
        fontSize: fontSize ?? MyFonts.buttonTextSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: isLightTheme
            ? LightThemeColors.buttonTextColor
            : DarkThemeColors.buttonTextColor,
      );
    });
  }

  static ElevatedButtonThemeData getElevatedButtonTheme({
    required bool isLightTheme,
  }) => ElevatedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      ),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(vertical: 8.h),
      ),
      textStyle: getElevatedButtonTextStyle(isLightTheme),
      foregroundColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return isLightTheme
              ? LightThemeColors.buttonDisabledTextColor
              : DarkThemeColors.buttonDisabledTextColor;
        }
        return isLightTheme
            ? LightThemeColors.buttonTextColor
            : DarkThemeColors.buttonTextColor;
      }),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.pressed)) {
          return isLightTheme
              ? LightThemeColors.buttonColor.withValues(alpha: 0.5)
              : DarkThemeColors.buttonColor.withValues(alpha: 0.5);
        } else if (states.contains(WidgetState.disabled)) {
          return isLightTheme
              ? LightThemeColors.buttonDisabledColor
              : DarkThemeColors.buttonDisabledColor;
        }
        return isLightTheme
            ? LightThemeColors.buttonColor
            : DarkThemeColors.buttonColor;
      }),
    ),
  );

  static InputDecorationTheme getInputDecorationTheme({
    required bool isLightTheme,
  }) {
    final primary = isLightTheme
        ? LightThemeColors.primaryColor
        : DarkThemeColors.primaryColor;
    const radius = 12.0;
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final iconColor = isLightTheme
        ? LightThemeColors.iconColor
        : DarkThemeColors.iconColor;
    return InputDecorationTheme(
      prefixIconColor: iconColor,
      suffixIconColor: iconColor,
      border: defaultBorder,
      enabledBorder: defaultBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  static ListTileThemeData getListTileThemeData({required bool isLightTheme}) {
    return ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      iconColor: isLightTheme
          ? LightThemeColors.listTileIconColor
          : DarkThemeColors.listTileIconColor,
      tileColor: isLightTheme
          ? LightThemeColors.listTileBackgroundColor
          : DarkThemeColors.listTileBackgroundColor,
      titleTextStyle: TextStyle(
        fontSize: MyFonts.listTileTitleSize,
        color: isLightTheme
            ? LightThemeColors.listTileTitleColor
            : DarkThemeColors.listTileTitleColor,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: MyFonts.listTileSubtitleSize,
        color: isLightTheme
            ? LightThemeColors.listTileSubtitleColor
            : DarkThemeColors.listTileSubtitleColor,
      ),
    );
  }
}
