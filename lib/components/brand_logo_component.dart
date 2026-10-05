import 'package:flutter/material.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/config/theme/app_themes.dart';

/// The approved balance-and-book emblem with a typeset, accessible wordmark.
class BrandLogoComponent extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool stacked;

  const BrandLogoComponent({
    super.key,
    this.markSize = 38,
    this.fontSize = 26,
    this.stacked = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      AppConfig.brandLogoAsset,
      width: markSize,
      height: markSize,
      excludeFromSemantics: true,
      filterQuality: FilterQuality.high,
    );
    final wordmark = Text.rich(
      const TextSpan(
        children: [
          TextSpan(
            text: 'Batas',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: 'PH',
            style: TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: fontSize,
        height: 1.2,
        letterSpacing: -0.8,
        color: AppThemes.forest,
      ),
    );
    return Semantics(
      label: AppConfig.appName,
      image: true,
      excludeSemantics: true,
      child: stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [mark, const SizedBox(height: 20), wordmark],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [mark, const SizedBox(width: 9), wordmark],
            ),
    );
  }
}
