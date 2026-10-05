import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:batasph_mobile/data/models/user_model.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class SettingsController extends GetxController {
  final _authService = Get.find<AuthService>();

  Rxn<UserModel> get currentUser => _authService.currentUser;

  bool get hasAccountSession =>
      _authService.isAuthenticated && currentUser.value != null;

  String get accountName {
    final name = currentUser.value?.name.trim() ?? '';
    return name.isEmpty ? 'BatasPH Account' : name;
  }

  String get accountSubtitle {
    final email = currentUser.value?.email.trim() ?? '';
    if (email.isNotEmpty) {
      return email;
    }
    return 'Sign in to prepare your BatasPH account profile.';
  }

  String get accountInitials => currentUser.value?.initials ?? 'BT';

  void openLogin() {
    Get.toNamed(Routes.LOGIN);
  }

  void openRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  void openProfile() {
    if (!hasAccountSession) {
      openLogin();
      return;
    }
    Get.toNamed(Routes.PROFILE);
  }

  void openVoiceSettings() {
    Get.toNamed(Routes.VOICE_SETTINGS);
  }

  Future<void> logout() async {
    await _authService.logout();
    Get.snackbar(
      'Signed out',
      'Your BatasPH account session has been cleared.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ─── Diagnostics ───────────────────────────────────────────

  final isSharingLogs = false.obs;

  /// Hands the newest log file to the OS share sheet. The newest file is
  /// what's wanted nearly every time — the problem just happened — and one
  /// attachment keeps every share target (mail, Drive, chat) happy.
  Future<void> shareLogs() async {
    if (isSharingLogs.value) return;
    isSharingLogs.value = true;
    try {
      // Buffered lines must hit disk before we hand the file over.
      await BatasphLogger.flush();
      final files = await BatasphLogger.logFiles();
      if (files.isEmpty) {
        BatasphLogger.warning('[Logs] Share requested but no log files exist');
        Get.snackbar(
          'No logs yet',
          'There is no diagnostic log to share on this device.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final newest = files.first;
      final name = newest.uri.pathSegments.last;
      BatasphLogger.log(
        '[Logs] Sharing $name (${await newest.length()} bytes)',
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(newest.path)],
          subject: 'BatasPH logs — $name',
          text: 'BatasPH diagnostic log: $name',
        ),
      );
      BatasphLogger.log('[Logs] Share result: ${result.status.name}');
    } catch (e, st) {
      BatasphLogger.error('[Logs] Share failed', error: e, stackTrace: st);
      Get.snackbar(
        'Unable to share logs',
        'Try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSharingLogs.value = false;
    }
  }
}
