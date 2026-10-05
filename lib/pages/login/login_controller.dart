import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:batasph_mobile/pages/forgot_password/forgot_password_arguments.dart';
import 'package:batasph_mobile/pages/verify_email/verify_email_arguments.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/api_error_util.dart';
import 'package:batasph_mobile/utils/google_sign_in_error_util.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class LoginController extends GetxController {
  final _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final obscurePassword = true.obs;

  bool get isBusy => isLoading.value || isGoogleLoading.value;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Enter both your email and password.');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      _showError('Enter a valid email address.');
      return;
    }

    isLoading.value = true;
    try {
      await _authService.login(email: email, password: password);
      Get.snackbar(
        'Signed in',
        'Your BatasPH account is now active on this device.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(Routes.MAIN_SHELL);
    } on DioException catch (error) {
      if (ApiErrorUtil.isEmailNotVerified(error)) {
        // Right password, unverified inbox: finish verification instead.
        BatasphLogger.log(
          '[Auth] Login needs email verification | email=$email',
        );
        Get.toNamed(
          Routes.VERIFY_EMAIL,
          arguments: VerifyEmailArguments(email: email, sendCodeOnOpen: true),
        );
        return;
      }
      final message = _extractError(error);
      BatasphLogger.error('[Auth] Login failed: $message', error: error);
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Login failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to sign in right now.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    if (isBusy) {
      return;
    }

    isGoogleLoading.value = true;
    try {
      await _authService.signInWithGoogle();
      Get.snackbar(
        'Signed in',
        'Your BatasPH account is now active on this device.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAllNamed(Routes.MAIN_SHELL);
    } on GoogleSignInException catch (error) {
      // A user backing out of the account picker is not an error worth showing.
      if (!GoogleSignInErrorUtil.isCanceled(error)) {
        _showError('Google sign-in failed. Please try again.');
      }
    } on DioException catch (error) {
      final message = _extractError(error);
      BatasphLogger.error(
        '[Auth] Google sign-in failed: $message',
        error: error,
      );
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Google sign-in failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to sign in with Google right now.');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  void goToRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  Future<void> goToForgotPassword() async {
    final result = await Get.toNamed(
      Routes.FORGOT_PASSWORD,
      arguments: ForgotPasswordArguments(
        initialEmail: emailController.text.trim(),
      ),
    );
    // A completed reset hands back the email so the user can sign straight in.
    if (result is String) {
      emailController.text = result;
      passwordController.clear();
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Sign in failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _extractError(DioException error) {
    return ApiErrorUtil.message(
      error,
      fallback: 'Unable to sign in right now.',
    );
  }
}
