import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/verify_email/verify_email_arguments.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/api_error_util.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

/// Matches the API's resend cooldown, so the button never offers a resend the
/// server would refuse.
const _resendCooldownSeconds = 60;

class VerifyEmailController extends GetxController {
  final _authService = Get.find<AuthService>();

  late final VerifyEmailArguments arguments;
  final codeController = TextEditingController();
  final isVerifying = false.obs;
  final isResending = false.obs;
  final resendSecondsLeft = 0.obs;

  Timer? _cooldownTimer;

  String get email => arguments.email;
  bool get canResend =>
      resendSecondsLeft.value == 0 && !isResending.value && !isVerifying.value;

  @override
  void onInit() {
    super.onInit();
    final routeArgs = Get.arguments;
    if (routeArgs is! VerifyEmailArguments) {
      throw StateError('VerifyEmailPage requires VerifyEmailArguments');
    }
    arguments = routeArgs;
    BatasphLogger.log(
      '[Auth] Verify email opened | email=$email'
      ' | sendCodeOnOpen=${arguments.sendCodeOnOpen}',
    );

    if (arguments.sendCodeOnOpen) {
      resendCode();
    } else {
      // Registration just sent a code.
      _startCooldown();
    }
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    codeController.dispose();
    super.onClose();
  }

  Future<void> verify() async {
    final code = codeController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('Enter the 6-digit code from your email.');
      return;
    }

    isVerifying.value = true;
    try {
      await _authService.verifyEmail(email: email, code: code);
      Get.snackbar(
        'Email verified',
        'Your BatasPH account is now active on this device.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(Routes.HOME);
    } on DioException catch (error) {
      final message = ApiErrorUtil.message(
        error,
        fallback: 'Unable to verify your email right now.',
      );
      BatasphLogger.error('[Auth] Verify failed: $message', error: error);
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Verify failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to verify your email right now.');
    } finally {
      isVerifying.value = false;
    }
  }

  Future<void> resendCode() async {
    if (!canResend) {
      return;
    }

    isResending.value = true;
    try {
      await _authService.resendVerificationCode(email);
      codeController.clear();
      _startCooldown();
      Get.snackbar(
        'Code sent',
        'Check $email for a new 6-digit code.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException catch (error) {
      final message = ApiErrorUtil.message(
        error,
        fallback: 'Unable to send a new code right now.',
      );
      BatasphLogger.error('[Auth] Resend code failed: $message', error: error);
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Resend code failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to send a new code right now.');
    } finally {
      isResending.value = false;
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
      'Verification failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
