import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class ProfileController extends GetxController {
  final _authService = Get.find<AuthService>();

  final isLoading = false.obs;
  final syncMessage = RxnString();

  Rxn<UserModel> get currentUser => _authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    if (!_authService.isAuthenticated || currentUser.value == null) {
      Get.offAllNamed(Routes.LOGIN);
      return;
    }
    refreshProfile(showErrorSnackbar: false);
  }

  String get displayName {
    final name = currentUser.value?.name.trim() ?? '';
    return name.isEmpty ? 'BatasPH User' : name;
  }

  String get email {
    final value = currentUser.value?.email.trim() ?? '';
    return value.isEmpty ? 'No email available' : value;
  }

  String get authProviderLabel {
    final provider = currentUser.value?.authProvider.trim() ?? 'email';
    return provider.isEmpty ? 'email' : provider;
  }

  String get initials => currentUser.value?.initials ?? 'BT';

  String get userId {
    final id = currentUser.value?.id.trim() ?? '';
    return id.isEmpty ? 'Unavailable' : id;
  }

  Future<void> refreshProfile({bool showErrorSnackbar = true}) async {
    if (!_authService.isAuthenticated) {
      syncMessage.value = 'Sign in to view your BatasPH profile.';
      return;
    }

    isLoading.value = true;
    syncMessage.value = null;
    try {
      await _authService.refreshProfile();
    } on DioException catch (error) {
      final message = _extractError(error);
      BatasphLogger.error('Profile refresh failed: $message');
      syncMessage.value = message;
      if (showErrorSnackbar) {
        Get.snackbar(
          'Profile sync unavailable',
          message,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error) {
      BatasphLogger.error('Profile refresh failed: $error');
      syncMessage.value = 'Unable to refresh your BatasPH profile.';
      if (showErrorSnackbar) {
        Get.snackbar(
          'Profile sync unavailable',
          syncMessage.value!,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.offAllNamed(Routes.MAIN_SHELL);
    Get.snackbar(
      'Signed out',
      'Your BatasPH account session has been cleared.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _extractError(DioException error) {
    if (error.response?.statusCode == 404) {
      return 'Profile sync is not available yet on the BatasPH API.';
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Unable to refresh your BatasPH profile.';
  }
}
