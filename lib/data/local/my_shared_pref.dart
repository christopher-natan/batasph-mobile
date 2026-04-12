import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:batasph_mobile/config/language/answer_language.dart';

class MySharedPref {
  MySharedPref._();

  static late SharedPreferences _sharedPreferences;

  static const String _lightThemeKey = 'is_theme_light';
  static const String _appThemeKey = 'app_theme';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _answerLanguageKey = 'answer_language';
  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';
  static const String _guestSessionIdKey = 'guest_session_id';
  static const String _voiceSilenceSecondsKey = 'voice_silence_seconds';
  static const String _selectedVoiceKey = 'selected_voice';
  static const String _speechLanguagesKey = 'speech_languages';

  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> setThemeIsLight(bool lightTheme) =>
      _sharedPreferences.setBool(_lightThemeKey, lightTheme);

  static bool getThemeIsLight() =>
      _sharedPreferences.getBool(_lightThemeKey) ?? true;

  static Future<void> setAppTheme(String themeId) =>
      _sharedPreferences.setString(_appThemeKey, themeId);

  static String getAppTheme() =>
      _sharedPreferences.getString(_appThemeKey) ?? 'midnightInk';

  static Future<void> setAnswerLanguage(AnswerLanguage language) =>
      _sharedPreferences.setString(_answerLanguageKey, language.name);

  static AnswerLanguage getAnswerLanguage() => answerLanguageFromStorage(
    _sharedPreferences.getString(_answerLanguageKey),
  );

  static Future<void> setOnboardingComplete() =>
      _sharedPreferences.setBool(_onboardingCompleteKey, true);

  static bool isOnboardingComplete() =>
      _sharedPreferences.getBool(_onboardingCompleteKey) ?? false;

  static List<String> getRecentSearches() =>
      _sharedPreferences.getStringList(_recentSearchesKey) ?? [];

  static Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final searches = getRecentSearches();
    searches.remove(trimmed);
    searches.insert(0, trimmed);
    if (searches.length > 5) {
      searches.removeLast();
    }
    await _sharedPreferences.setStringList(_recentSearchesKey, searches);
  }

  static Future<void> clearRecentSearches() =>
      _sharedPreferences.remove(_recentSearchesKey);

  static Future<void> setAuthSession({
    required String token,
    required String userJson,
  }) async {
    await _sharedPreferences.setString(_authTokenKey, token);
    await _sharedPreferences.setString(_authUserKey, userJson);
  }

  static String? getAuthToken() => _sharedPreferences.getString(_authTokenKey);

  static String? getAuthUserJson() =>
      _sharedPreferences.getString(_authUserKey);

  static Future<void> setAuthUserJson(String userJson) =>
      _sharedPreferences.setString(_authUserKey, userJson);

  static Future<void> clearAuthSession() async {
    await _sharedPreferences.remove(_authTokenKey);
    await _sharedPreferences.remove(_authUserKey);
  }

  static String getGuestSessionId() {
    String? sessionId = _sharedPreferences.getString(_guestSessionIdKey);
    if (sessionId == null || sessionId.isEmpty) {
      sessionId = const Uuid().v4();
      _sharedPreferences.setString(_guestSessionIdKey, sessionId);
    }
    return sessionId;
  }

  static Future<void> setVoiceSilenceSeconds(int seconds) =>
      _sharedPreferences.setInt(_voiceSilenceSecondsKey, seconds);

  static int getVoiceSilenceSeconds() =>
      _sharedPreferences.getInt(_voiceSilenceSecondsKey) ?? 1;

  static Future<void> setSelectedVoice(String? voice) async {
    if (voice == null || voice.trim().isEmpty) {
      await _sharedPreferences.remove(_selectedVoiceKey);
      return;
    }

    await _sharedPreferences.setString(_selectedVoiceKey, voice.trim());
  }

  static String getSelectedVoice() =>
      _sharedPreferences.getString(_selectedVoiceKey) ?? 'luna';

  static List<String> getSpeechLanguages() =>
      _sharedPreferences.getStringList(_speechLanguagesKey) ??
      const ['en', 'tl'];

  static Future<void> setSpeechLanguages(List<String> languages) async {
    final normalized = languages
        .map((language) => language.trim())
        .where((language) => language.isNotEmpty)
        .toSet()
        .toList();
    await _sharedPreferences.setStringList(_speechLanguagesKey, normalized);
  }
}
