import 'dart:convert';

import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:batasph_mobile/config/config.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/data/remote/auth_repository.dart';
import 'package:batasph_mobile/data/remote/user_repository.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/google_sign_in_error_util.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class AuthService extends GetxService {
  static String? _token;
  static String? get token => _token;

  final currentUser = Rxn<UserModel>();

  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  bool _googleInitialized = false;
  Future<void>? _googleInitFuture;

  @override
  void onInit() {
    super.onInit();
    _hydrateSession();
    _googleInitFuture = _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleWebClientId,
      );
      _googleInitialized = true;
      BatasphLogger.log('[Auth] Google Sign-In initialized');
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Google Sign-In init failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    final initFuture = _googleInitFuture ??= _initGoogleSignIn();
    await initFuture;
    if (!_googleInitialized) {
      BatasphLogger.error(
        '[Auth] Google Sign-In did not initialize successfully',
      );
      throw Exception('Google Sign-In not initialized');
    }
  }

  void _hydrateSession() {
    _token = MySharedPref.getAuthToken();
    final userJson = MySharedPref.getAuthUserJson();
    if (userJson == null || userJson.isEmpty) {
      BatasphLogger.log(
        '[Auth] Session hydrated | authenticated=$isAuthenticated | user=none'
        ' | guest=${MySharedPref.getGuestSessionId()}',
      );
      return;
    }

    try {
      currentUser.value = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      BatasphLogger.log(
        '[Auth] Session hydrated | authenticated=$isAuthenticated'
        ' | user=${currentUser.value?.email}',
      );
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Failed to hydrate cached user',
        error: error,
        stackTrace: stackTrace,
      );
      currentUser.value = null;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    BatasphLogger.log('[Auth] Register | email=$email');
    await _authRepository.register(
      name: name,
      email: email,
      password: password,
    );
    BatasphLogger.log('[Auth] Register complete | email=$email');
  }

  Future<void> login({required String email, required String password}) async {
    BatasphLogger.log('[Auth] Login | email=$email');
    final response = await _authRepository.login(
      email: email,
      password: password,
    );
    await _saveSession(response);
    BatasphLogger.log('[Auth] Login complete | user=${response.user.email}');
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    BatasphLogger.log('[Auth] Verify email | email=$email');
    final response = await _authRepository.verifyEmail(
      email: email,
      code: code,
    );
    await _saveSession(response);
    BatasphLogger.log('[Auth] Email verified | user=${response.user.email}');
  }

  Future<void> resendVerificationCode(String email) async {
    BatasphLogger.log('[Auth] Resend verification code | email=$email');
    await _authRepository.resendVerificationCode(email);
  }

  Future<void> requestPasswordReset(String email) async {
    BatasphLogger.log('[Auth] Password reset requested | email=$email');
    await _authRepository.requestPasswordReset(email);
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    BatasphLogger.log('[Auth] Reset password | email=$email');
    await _authRepository.resetPassword(
      email: email,
      code: code,
      password: password,
    );
    BatasphLogger.log('[Auth] Password reset complete | email=$email');
  }

  Future<void> signInWithGoogle() async {
    BatasphLogger.log('[Auth] Google sign-in started');
    await _ensureGoogleInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        BatasphLogger.error(
          '[Auth] Google sign-in returned no ID token — serverClientId may be wrong',
        );
        throw Exception('Failed to get Google ID token');
      }

      final response = await _authRepository.googleAuth(idToken);
      await _saveSession(response);
      BatasphLogger.log(
        '[Auth] Google sign-in complete | ${response.user.email}',
      );
    } on GoogleSignInException catch (error) {
      final message = GoogleSignInErrorUtil.diagnosticMessage(
        error,
        packageName: 'com.vxtory.batasph',
        serverClientId: AppConfig.googleWebClientId,
      );
      if (GoogleSignInErrorUtil.isCanceled(error)) {
        BatasphLogger.warning('[Auth] $message');
      } else {
        BatasphLogger.error('[Auth] $message', error: error);
      }
      rethrow;
    }
  }

  Future<UserModel?> refreshProfile() async {
    if (!isAuthenticated) {
      return currentUser.value;
    }

    final user = await _userRepository.getProfile();
    currentUser.value = user;
    await MySharedPref.setAuthUserJson(jsonEncode(user.toJson()));
    BatasphLogger.log('[Auth] Profile refreshed | user=${user.email}');
    return user;
  }

  /// Deletes the account on the server, then clears the local session.
  Future<void> deleteAccount() async {
    final email = currentUser.value?.email;
    BatasphLogger.log('[Auth] Delete account | user=$email');
    await _userRepository.deleteAccount();
    await logout();
    BatasphLogger.log('[Auth] Account deleted | user=$email');
  }

  Future<void> logout() async {
    BatasphLogger.log('[Auth] Logout | user=${currentUser.value?.email}');
    _token = null;
    currentUser.value = null;
    await MySharedPref.clearAuthSession();
  }

  Future<void> handleUnauthorized() async {
    if (!isAuthenticated) {
      return;
    }

    BatasphLogger.warning(
      '[Auth] 401 with active session, clearing | route=${Get.currentRoute}',
    );
    await logout();
    if (Get.currentRoute == Routes.PROFILE) {
      Get.offAllNamed(Routes.LOGIN);
      return;
    }

    if (Get.currentRoute == Routes.LOGIN ||
        Get.currentRoute == Routes.REGISTER) {
      return;
    }

    Get.snackbar(
      'Session expired',
      'Please sign in again to access your BatasPH account.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _saveSession(AuthResponse response) async {
    _token = response.accessToken;
    currentUser.value = response.user;
    await MySharedPref.setAuthSession(
      token: response.accessToken,
      userJson: jsonEncode(response.user.toJson()),
    );
  }
}
