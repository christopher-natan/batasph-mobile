import 'package:flutter/material.dart';

import 'package:batasph_mobile/data/local/my_shared_pref.dart';

enum AppThemeId {
  midnightInk,
  tealHaven,
  sepiaArchive,
  plumInk,
  indigoDust,
  sageMoss,
}

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

class AppThemeEntry {
  final AppThemeId id;
  final String name;
  final Color previewLight;
  final Color previewDark;
  final AppThemeColors light;
  final AppThemeColors dark;

  const AppThemeEntry({
    required this.id,
    required this.name,
    required this.previewLight,
    required this.previewDark,
    required this.light,
    required this.dark,
  });
}

class AppThemes {
  static const themes = <AppThemeEntry>[
    // 1. Midnight Ink & Amber
    AppThemeEntry(
      id: AppThemeId.midnightInk,
      name: 'Midnight Ink',
      previewLight: Color(0xFF2C3550),
      previewDark: Color(0xFF90A7D8),
      light: AppThemeColors(
        primaryColor: Color(0xFF2C3550),
        accentColor: Color(0xFFB9864A),
        scaffoldBackgroundColor: Color(0xFFF5F1EA),
        cardColor: Color(0xFFFFFFFF),
        dividerColor: Color(0xFFE6DDD1),
        hintTextColor: Color(0xFF6A7280),
        bodyTextColor: Color(0xFF1E2430),
        displayTextColor: Color(0xFF1E2430),
        bodySmallTextColor: Color(0xFF6A7280),
        iconColor: Colors.black,
        appBarColor: Color(0xFF2C3550),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF2C3550),
        buttonTextColor: Colors.white,
        buttonDisabledColor: Colors.grey,
        buttonDisabledTextColor: Colors.black,
        chipBackground: Color(0xFF2C3550),
        chipTextColor: Colors.white,
        listTileTitleColor: Color(0xFF575757),
        listTileSubtitleColor: Color(0xFF575757),
        listTileBackgroundColor: Color(0xFFF8F5EF),
        listTileIconColor: Color(0xFF575757),
      ),
      dark: AppThemeColors(
        primaryColor: Color(0xFF90A7D8),
        accentColor: Color(0xFFD7A96A),
        scaffoldBackgroundColor: Color(0xFF0E1320),
        cardColor: Color(0xFF171D2C),
        dividerColor: Color(0xFF283245),
        hintTextColor: Color(0xFF9DABC0),
        bodyTextColor: Color(0xFFEEF2FA),
        displayTextColor: Color(0xFFEEF2FA),
        bodySmallTextColor: Color(0xFF9DABC0),
        iconColor: Color(0xFF90A7D8),
        appBarColor: Color(0xFF171D2C),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF90A7D8),
        buttonTextColor: Color(0xFF0E1320),
        buttonDisabledColor: Color(0xFF283245),
        buttonDisabledTextColor: Colors.white54,
        chipBackground: Color(0xFF90A7D8),
        chipTextColor: Color(0xFF0E1320),
        listTileTitleColor: Colors.white,
        listTileSubtitleColor: Color(0xFF9DABC0),
        listTileBackgroundColor: Color(0xFF171D2C),
        listTileIconColor: Color(0xFF9DABC0),
      ),
    ),

    // 2. Teal Haven
    AppThemeEntry(
      id: AppThemeId.tealHaven,
      name: 'Teal Haven',
      previewLight: Color(0xFF1B7A68),
      previewDark: Color(0xFF5CC4AD),
      light: AppThemeColors(
        primaryColor: Color(0xFF1B7A68),
        accentColor: Color(0xFFE8A84C),
        scaffoldBackgroundColor: Color(0xFFF2F8F6),
        cardColor: Color(0xFFFFFFFF),
        dividerColor: Color(0xFFD8EAE5),
        hintTextColor: Color(0xFF6B8580),
        bodyTextColor: Color(0xFF1A2B26),
        displayTextColor: Color(0xFF1A2B26),
        bodySmallTextColor: Color(0xFF6B8580),
        iconColor: Colors.black,
        appBarColor: Color(0xFF1B7A68),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF1B7A68),
        buttonTextColor: Colors.white,
        buttonDisabledColor: Colors.grey,
        buttonDisabledTextColor: Colors.black,
        chipBackground: Color(0xFF1B7A68),
        chipTextColor: Colors.white,
        listTileTitleColor: Color(0xFF575757),
        listTileSubtitleColor: Color(0xFF575757),
        listTileBackgroundColor: Color(0xFFF0F8F6),
        listTileIconColor: Color(0xFF575757),
      ),
      dark: AppThemeColors(
        primaryColor: Color(0xFF5CC4AD),
        accentColor: Color(0xFFE8A84C),
        scaffoldBackgroundColor: Color(0xFF0C1F1A),
        cardColor: Color(0xFF14302A),
        dividerColor: Color(0xFF1E4A40),
        hintTextColor: Color(0xFF6B9E97),
        bodyTextColor: Color(0xFFE8F4F0),
        displayTextColor: Color(0xFFE8F4F0),
        bodySmallTextColor: Color(0xFF6B9E97),
        iconColor: Color(0xFF5CC4AD),
        appBarColor: Color(0xFF14302A),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF5CC4AD),
        buttonTextColor: Color(0xFF0C1F1A),
        buttonDisabledColor: Color(0xFF1E4A40),
        buttonDisabledTextColor: Colors.white54,
        chipBackground: Color(0xFF5CC4AD),
        chipTextColor: Color(0xFF0C1F1A),
        listTileTitleColor: Colors.white,
        listTileSubtitleColor: Color(0xFF6B9E97),
        listTileBackgroundColor: Color(0xFF14302A),
        listTileIconColor: Color(0xFF6B9E97),
      ),
    ),

    // 3. Sepia Archive
    AppThemeEntry(
      id: AppThemeId.sepiaArchive,
      name: 'Sepia Archive',
      previewLight: Color(0xFF6A3A32),
      previewDark: Color(0xFFD0A89B),
      light: AppThemeColors(
        primaryColor: Color(0xFF6A3A32),
        accentColor: Color(0xFFB88A56),
        scaffoldBackgroundColor: Color(0xFFF7EFE7),
        cardColor: Color(0xFFFFF9F4),
        dividerColor: Color(0xFFE7D8CC),
        hintTextColor: Color(0xFF7C6D66),
        bodyTextColor: Color(0xFF231C1A),
        displayTextColor: Color(0xFF231C1A),
        bodySmallTextColor: Color(0xFF7C6D66),
        iconColor: Colors.black,
        appBarColor: Color(0xFF6A3A32),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF6A3A32),
        buttonTextColor: Colors.white,
        buttonDisabledColor: Colors.grey,
        buttonDisabledTextColor: Colors.black,
        chipBackground: Color(0xFF6A3A32),
        chipTextColor: Colors.white,
        listTileTitleColor: Color(0xFF575757),
        listTileSubtitleColor: Color(0xFF575757),
        listTileBackgroundColor: Color(0xFFF8F2EC),
        listTileIconColor: Color(0xFF575757),
      ),
      dark: AppThemeColors(
        primaryColor: Color(0xFFD0A89B),
        accentColor: Color(0xFFD8B277),
        scaffoldBackgroundColor: Color(0xFF171110),
        cardColor: Color(0xFF241A18),
        dividerColor: Color(0xFF372A26),
        hintTextColor: Color(0xFFB6A39A),
        bodyTextColor: Color(0xFFF6EFEB),
        displayTextColor: Color(0xFFF6EFEB),
        bodySmallTextColor: Color(0xFFB6A39A),
        iconColor: Color(0xFFD0A89B),
        appBarColor: Color(0xFF241A18),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFFD0A89B),
        buttonTextColor: Color(0xFF171110),
        buttonDisabledColor: Color(0xFF372A26),
        buttonDisabledTextColor: Colors.white54,
        chipBackground: Color(0xFFD0A89B),
        chipTextColor: Color(0xFF171110),
        listTileTitleColor: Colors.white,
        listTileSubtitleColor: Color(0xFFB6A39A),
        listTileBackgroundColor: Color(0xFF241A18),
        listTileIconColor: Color(0xFFB6A39A),
      ),
    ),

    // 4. Plum Ink & Champagne
    AppThemeEntry(
      id: AppThemeId.plumInk,
      name: 'Plum Ink',
      previewLight: Color(0xFF5B3B53),
      previewDark: Color(0xFFD2B5CB),
      light: AppThemeColors(
        primaryColor: Color(0xFF5B3B53),
        accentColor: Color(0xFFC19A6B),
        scaffoldBackgroundColor: Color(0xFFF6F0F1),
        cardColor: Color(0xFFFFFDFD),
        dividerColor: Color(0xFFE7DCE2),
        hintTextColor: Color(0xFF7C6F79),
        bodyTextColor: Color(0xFF251E24),
        displayTextColor: Color(0xFF251E24),
        bodySmallTextColor: Color(0xFF7C6F79),
        iconColor: Colors.black,
        appBarColor: Color(0xFF5B3B53),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF5B3B53),
        buttonTextColor: Colors.white,
        buttonDisabledColor: Colors.grey,
        buttonDisabledTextColor: Colors.black,
        chipBackground: Color(0xFF5B3B53),
        chipTextColor: Colors.white,
        listTileTitleColor: Color(0xFF575757),
        listTileSubtitleColor: Color(0xFF575757),
        listTileBackgroundColor: Color(0xFFF7F1F3),
        listTileIconColor: Color(0xFF575757),
      ),
      dark: AppThemeColors(
        primaryColor: Color(0xFFD2B5CB),
        accentColor: Color(0xFFE0BC86),
        scaffoldBackgroundColor: Color(0xFF171218),
        cardColor: Color(0xFF231A24),
        dividerColor: Color(0xFF362A37),
        hintTextColor: Color(0xFFB59FB1),
        bodyTextColor: Color(0xFFF7F0F5),
        displayTextColor: Color(0xFFF7F0F5),
        bodySmallTextColor: Color(0xFFB59FB1),
        iconColor: Color(0xFFD2B5CB),
        appBarColor: Color(0xFF231A24),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFFD2B5CB),
        buttonTextColor: Color(0xFF171218),
        buttonDisabledColor: Color(0xFF362A37),
        buttonDisabledTextColor: Colors.white54,
        chipBackground: Color(0xFFD2B5CB),
        chipTextColor: Color(0xFF171218),
        listTileTitleColor: Colors.white,
        listTileSubtitleColor: Color(0xFFB59FB1),
        listTileBackgroundColor: Color(0xFF231A24),
        listTileIconColor: Color(0xFFB59FB1),
      ),
    ),

    // 5. Indigo Dust & Copper
    AppThemeEntry(
      id: AppThemeId.indigoDust,
      name: 'Indigo Dust',
      previewLight: Color(0xFF3E4C6D),
      previewDark: Color(0xFF9BAED4),
      light: AppThemeColors(
        primaryColor: Color(0xFF3E4C6D),
        accentColor: Color(0xFFB8744F),
        scaffoldBackgroundColor: Color(0xFFF4F1EE),
        cardColor: Color(0xFFFFFFFF),
        dividerColor: Color(0xFFE3DDD8),
        hintTextColor: Color(0xFF6B7380),
        bodyTextColor: Color(0xFF202631),
        displayTextColor: Color(0xFF202631),
        bodySmallTextColor: Color(0xFF6B7380),
        iconColor: Colors.black,
        appBarColor: Color(0xFF3E4C6D),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF3E4C6D),
        buttonTextColor: Colors.white,
        buttonDisabledColor: Colors.grey,
        buttonDisabledTextColor: Colors.black,
        chipBackground: Color(0xFF3E4C6D),
        chipTextColor: Colors.white,
        listTileTitleColor: Color(0xFF575757),
        listTileSubtitleColor: Color(0xFF575757),
        listTileBackgroundColor: Color(0xFFF5F2EF),
        listTileIconColor: Color(0xFF575757),
      ),
      dark: AppThemeColors(
        primaryColor: Color(0xFF9BAED4),
        accentColor: Color(0xFFD3926C),
        scaffoldBackgroundColor: Color(0xFF10141B),
        cardColor: Color(0xFF1A2130),
        dividerColor: Color(0xFF2A3344),
        hintTextColor: Color(0xFFA0AEC0),
        bodyTextColor: Color(0xFFEEF2F8),
        displayTextColor: Color(0xFFEEF2F8),
        bodySmallTextColor: Color(0xFFA0AEC0),
        iconColor: Color(0xFF9BAED4),
        appBarColor: Color(0xFF1A2130),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF9BAED4),
        buttonTextColor: Color(0xFF10141B),
        buttonDisabledColor: Color(0xFF2A3344),
        buttonDisabledTextColor: Colors.white54,
        chipBackground: Color(0xFF9BAED4),
        chipTextColor: Color(0xFF10141B),
        listTileTitleColor: Colors.white,
        listTileSubtitleColor: Color(0xFFA0AEC0),
        listTileBackgroundColor: Color(0xFF1A2130),
        listTileIconColor: Color(0xFFA0AEC0),
      ),
    ),
    // 6. Sage Moss & Honey
    AppThemeEntry(
      id: AppThemeId.sageMoss,
      name: 'Sage Moss',
      previewLight: Color(0xFF4B6858),
      previewDark: Color(0xFF8FBB9E),
      light: AppThemeColors(
        primaryColor: Color(0xFF4B6858),
        accentColor: Color(0xFFC49A5C),
        scaffoldBackgroundColor: Color(0xFFF2F4F0),
        cardColor: Color(0xFFFFFFFF),
        dividerColor: Color(0xFFDDE5D9),
        hintTextColor: Color(0xFF6E7D73),
        bodyTextColor: Color(0xFF1C261F),
        displayTextColor: Color(0xFF1C261F),
        bodySmallTextColor: Color(0xFF6E7D73),
        iconColor: Colors.black,
        appBarColor: Color(0xFF4B6858),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF4B6858),
        buttonTextColor: Colors.white,
        buttonDisabledColor: Colors.grey,
        buttonDisabledTextColor: Colors.black,
        chipBackground: Color(0xFF4B6858),
        chipTextColor: Colors.white,
        listTileTitleColor: Color(0xFF575757),
        listTileSubtitleColor: Color(0xFF575757),
        listTileBackgroundColor: Color(0xFFF4F6F2),
        listTileIconColor: Color(0xFF575757),
      ),
      dark: AppThemeColors(
        primaryColor: Color(0xFF8FBB9E),
        accentColor: Color(0xFFD4AA6A),
        scaffoldBackgroundColor: Color(0xFF0E1612),
        cardColor: Color(0xFF172420),
        dividerColor: Color(0xFF243830),
        hintTextColor: Color(0xFF7EA38D),
        bodyTextColor: Color(0xFFE8F0EB),
        displayTextColor: Color(0xFFE8F0EB),
        bodySmallTextColor: Color(0xFF7EA38D),
        iconColor: Color(0xFF8FBB9E),
        appBarColor: Color(0xFF172420),
        appBarIconsColor: Colors.white,
        buttonColor: Color(0xFF8FBB9E),
        buttonTextColor: Color(0xFF0E1612),
        buttonDisabledColor: Color(0xFF243830),
        buttonDisabledTextColor: Colors.white54,
        chipBackground: Color(0xFF8FBB9E),
        chipTextColor: Color(0xFF0E1612),
        listTileTitleColor: Colors.white,
        listTileSubtitleColor: Color(0xFF7EA38D),
        listTileBackgroundColor: Color(0xFF172420),
        listTileIconColor: Color(0xFF7EA38D),
      ),
    ),
  ];

  static AppThemeEntry get current {
    final id = MySharedPref.getAppTheme();
    return themes.firstWhere(
      (t) => t.id.name == id,
      orElse: () => themes.first,
    );
  }

  static AppThemeColors getColors({required bool isLight}) {
    final entry = current;
    return isLight ? entry.light : entry.dark;
  }
}
