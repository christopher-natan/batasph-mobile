import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:batasph_mobile/pages/verify_email/verify_email_arguments.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/api_error_util.dart';
import 'package:batasph_mobile/utils/google_sign_in_error_util.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class RegisterController extends GetxController {
  final _authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

  bool get isBusy => isLoading.value || isGoogleLoading.value;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
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

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Fill in all account fields.');
      return;
    }

    if (!GetUtils.isEmail(email)) {
      _showError('Enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }

    isLoading.value = true;
    try {
      await _authService.register(name: name, email: email, password: password);
      Get.snackbar(
        'Check your email',
        'We sent a 6-digit code to $email.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offNamed(
        Routes.VERIFY_EMAIL,
        arguments: VerifyEmailArguments(email: email, sendCodeOnOpen: false),
      );
    } on DioException catch (error) {
      final message = _extractError(error);
      BatasphLogger.error('[Auth] Register failed: $message', error: error);
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Register failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to create your account right now.');
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
        '[Auth] Google sign-up failed: $message',
        error: error,
      );
      _showError(message);
    } catch (error, stackTrace) {
      BatasphLogger.error(
        '[Auth] Google sign-up failed',
        error: error,
        stackTrace: stackTrace,
      );
      _showError('Unable to continue with Google right now.');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  void goToLogin() {
    Get.offNamed(Routes.LOGIN);
  }

  void _showError(String message) {
    Get.snackbar(
      'Sign up failed',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _extractError(DioException error) {
    return ApiErrorUtil.message(
      error,
      fallback: 'Unable to create your account right now.',
    );
  }
}
