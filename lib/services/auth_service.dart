import 'dart:convert';

import 'package:get/get.dart';
import 'package:batasph_mobile/data/local/my_shared_pref.dart';
import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/data/remote/auth_repository.dart';
import 'package:batasph_mobile/data/remote/user_repository.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class AuthService extends GetxService {
  static String? _token;
  static String? get token => _token;

  final currentUser = Rxn<UserModel>();

  final _authRepository = AuthRepository();
  final _userRepository = UserRepository();

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _hydrateSession();
  }

  void _hydrateSession() {
    _token = MySharedPref.getAuthToken();
    final userJson = MySharedPref.getAuthUserJson();
    if (userJson == null || userJson.isEmpty) {
      return;
    }

    try {
      currentUser.value = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
    } catch (error) {
      BatasphLogger.error('Failed to hydrate cached auth user: $error');
      currentUser.value = null;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authRepository.register(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _authRepository.login(
      email: email,
      password: password,
    );
    await _saveSession(response);
  }

  Future<UserModel?> refreshProfile() async {
    if (!isAuthenticated) {
      return currentUser.value;
    }

    final user = await _userRepository.getProfile();
    currentUser.value = user;
    await MySharedPref.setAuthUserJson(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> logout() async {
    _token = null;
    currentUser.value = null;
    await MySharedPref.clearAuthSession();
  }

  Future<void> handleUnauthorized() async {
    if (!isAuthenticated) {
      return;
    }

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
