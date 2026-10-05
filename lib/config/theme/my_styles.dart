import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:batasph_mobile/config/theme/light_theme_colors.dart';
import 'package:batasph_mobile/config/theme/my_fonts.dart';

class MyStyles {
  static IconThemeData getIconTheme() =>
      IconThemeData(color: LightThemeColors.iconColor);

  static AppBarTheme getAppBarTheme() => AppBarTheme(
    elevation: 0,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    titleTextStyle: getTextTheme().bodyMedium!.copyWith(
      color: LightThemeColors.bodyTextColor,
      fontSize: MyFonts.appBarTittleSize,
    ),
    iconTheme: IconThemeData(color: LightThemeColors.appBarIconsColor),
    backgroundColor: LightThemeColors.appBarColor,
  );

  static TextTheme getTextTheme() => TextTheme(
    labelLarge: MyFonts.buttonTextStyle.copyWith(
      fontSize: MyFonts.buttonTextSize,
    ),
    bodyLarge: MyFonts.bodyTextStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: MyFonts.bodyLargeSize,
      color: LightThemeColors.bodyTextColor,
    ),
    bodyMedium: MyFonts.bodyTextStyle.copyWith(
      fontSize: MyFonts.bodyMediumSize,
      color: LightThemeColors.bodyTextColor,
    ),
    displayLarge: MyFonts.displayTextStyle.copyWith(
      fontSize: MyFonts.displayLargeSize,
      fontWeight: FontWeight.bold,
      color: LightThemeColors.displayTextColor,
    ),
    bodySmall: TextStyle(
      color: LightThemeColors.bodySmallTextColor,
      fontSize: MyFonts.bodySmallTextSize,
    ),
    displayMedium: MyFonts.displayTextStyle.copyWith(
      fontSize: MyFonts.displayMediumSize,
      fontWeight: FontWeight.bold,
      color: LightThemeColors.displayTextColor,
    ),
    displaySmall: MyFonts.displayTextStyle.copyWith(
      fontSize: MyFonts.displaySmallSize,
      fontWeight: FontWeight.bold,
      color: LightThemeColors.displayTextColor,
    ),
  );

  static ChipThemeData getChipTheme() {
    return ChipThemeData(
      backgroundColor: LightThemeColors.chipBackground,
      brightness: Brightness.light,
      labelStyle: getChipTextStyle(),
      secondaryLabelStyle: getChipTextStyle(),
      selectedColor: Colors.black,
      disabledColor: Colors.green,
      padding: const EdgeInsets.all(5),
      secondarySelectedColor: Colors.purple,
    );
  }

  static TextStyle getChipTextStyle() {
    return MyFonts.chipTextStyle.copyWith(
      fontSize: MyFonts.chipTextSize,
      color: LightThemeColors.chipTextColor,
    );
  }

  static WidgetStateProperty<TextStyle?>? getElevatedButtonTextStyle({
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
          color: LightThemeColors.buttonTextColor,
        );
      } else if (states.contains(WidgetState.disabled)) {
        return MyFonts.buttonTextStyle.copyWith(
          fontSize: fontSize ?? MyFonts.buttonTextSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: LightThemeColors.buttonDisabledTextColor,
        );
      }
      return MyFonts.buttonTextStyle.copyWith(
        fontSize: fontSize ?? MyFonts.buttonTextSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: LightThemeColors.buttonTextColor,
      );
    });
  }

  static ElevatedButtonThemeData getElevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
          ),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(vertical: 8.h),
          ),
          textStyle: getElevatedButtonTextStyle(),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.disabled)) {
              return LightThemeColors.buttonDisabledTextColor;
            }
            return LightThemeColors.buttonTextColor;
          }),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return LightThemeColors.buttonColor.withValues(alpha: 0.5);
            } else if (states.contains(WidgetState.disabled)) {
              return LightThemeColors.buttonDisabledColor;
            }
            return LightThemeColors.buttonColor;
          }),
        ),
      );

  static InputDecorationTheme getInputDecorationTheme() {
    final primary = LightThemeColors.primaryColor;
    const radius = 12.0;
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final iconColor = LightThemeColors.iconColor;
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

  static ListTileThemeData getListTileThemeData() {
    return ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      iconColor: LightThemeColors.listTileIconColor,
      tileColor: LightThemeColors.listTileBackgroundColor,
      titleTextStyle: TextStyle(
        fontSize: MyFonts.listTileTitleSize,
        color: LightThemeColors.listTileTitleColor,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: MyFonts.listTileSubtitleSize,
        color: LightThemeColors.listTileSubtitleColor,
      ),
    );
  }
}
