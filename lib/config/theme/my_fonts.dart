import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyFonts {
  static const _base = TextStyle(fontFamily: 'Poppins');

  static TextStyle get displayTextStyle => _base;
  static TextStyle get bodyTextStyle => _base;
  static TextStyle get buttonTextStyle => _base;
  static TextStyle get appBarTextStyle => _base;
  static TextStyle get chipTextStyle => _base;

  static double get appBarTittleSize => 20.sp;
  static double get bodySmallTextSize => 13.sp;
  static double get bodyMediumSize => 15.sp;
  static double get bodyLargeSize => 17.sp;
  static double get displayLargeSize => 24.sp;
  static double get displayMediumSize => 20.sp;
  static double get displaySmallSize => 16.sp;
  static double get buttonTextSize => 16.sp;
  static double get chipTextSize => 12.sp;
  static double get listTileTitleSize => 15.sp;
  static double get listTileSubtitleSize => 13.sp;
}
