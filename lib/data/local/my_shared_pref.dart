import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class MySharedPref {
  MySharedPref._();

  static late SharedPreferences _sharedPreferences;

  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _authTokenKey = 'auth_token';
  static const String _authUserKey = 'auth_user';
  static const String _guestSessionIdKey = 'guest_session_id';
  static const String _callerNameKey = 'caller_name';

  static Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> setOnboardingComplete() =>
      _sharedPreferences.setBool(_onboardingCompleteKey, true);

  static bool isOnboardingComplete() =>
      _sharedPreferences.getBool(_onboardingCompleteKey) ?? false;

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

  /// The caller's first name as they told Atty. Luna; null until they do.
  static String? getCallerName() =>
      _sharedPreferences.getString(_callerNameKey);

  static Future<void> setCallerName(String name) =>
      _sharedPreferences.setString(_callerNameKey, name);
}
