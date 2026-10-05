import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/forgot_password/forgot_password_arguments.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/api_error_util.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// Matches the API's resend cooldown.
const _resendCooldownSeconds = 60;

class ForgotPasswordController extends GetxController {
  final _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  /// False: asking for the email. True: entering the code and new password.
  final codeSent = false.obs;
  final isSending = false.obs;
  final isResetting = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final resendSecondsLeft = 0.obs;

  /// The address the code went to, fixed once sent.
  final sentToEmail = ''.obs;

  Timer? _cooldownTimer;

  bool get isBusy => isSending.value || isResetting.value;
  bool get canResend => resendSecondsLeft.value == 0 && !isBusy;

  @override
  void onInit() {
    super.onInit();
    final routeArgs = Get.arguments;
    if (routeArgs is! ForgotPasswordArguments) {
      throw StateError('ForgotPasswordPage requires ForgotPasswordArguments');
    }
    emailController.text = routeArgs.initialEmail;
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  Future<void> sendCode() async {
    final email = emailController.text.trim();
    if (!GetUtils.isEmail(email)) {
      _showError('Enter a valid email address.');
      return;
    }
    await _requestCode(email);
  }

  Future<void> resendCode() async {
    if (!canResend) {
      return;
    }
    await _requestCode(sentToEmail.value);
  }

  /// Back to the email step, e.g. after a typo in the address.
  void changeEmail() {
    _cooldownTimer?.cancel();
    resendSecondsLeft.value = 0;
    codeController.clear();
    codeSent.value = false;
  }

  Future<void> resetPassword() async {
    final code = codeController.text.trim();
    final password = passwordController.text;

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('Enter the 6-digit code from your email.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    isResetting.value = true;
    try {
      await _authService.resetPassword(
        email: sentToEmail.value,
        code: code,
        password: password,
      );
      Get.snackbar(
        'Password updated',
        'Sign in with your new password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      // The sign-in screen pre-fills this address.
      Get.back(result: sentToEmail.value);
    } on DioException catch (error) {
      final message = ApiErrorUtil.message(
        error,
        fallback: 'Unable to reset your password right now.',
      );
      BatasphLogger.error(
        '[Auth] Reset password failed: $message',
        error: error,
      );
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Reset password failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to reset your password right now.');
    } finally {
      isResetting.value = false;
    }
  }

  Future<void> _requestCode(String email) async {
    isSending.value = true;
    try {
      await _authService.requestPasswordReset(email);
      sentToEmail.value = email;
      codeSent.value = true;
      _startCooldown();
    } on DioException catch (error) {
      final message = ApiErrorUtil.message(
        error,
        fallback: 'Unable to send a reset code right now.',
      );
      BatasphLogger.error(
        '[Auth] Password reset request failed: $message',
        error: error,
      );
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Password reset request failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to send a reset code right now.');
    } finally {
      isSending.value = false;
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    resendSecondsLeft.value = _resendCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft.value <= 1) {
        resendSecondsLeft.value = 0;
        timer.cancel();
        return;
      }
      resendSecondsLeft.value--;
    });
  }

  void _showError(String message) {
    Get.snackbar(
      'Password reset failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
