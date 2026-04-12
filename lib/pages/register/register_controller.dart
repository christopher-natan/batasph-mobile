import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/routes/app_pages.dart';
import 'package:batasph_mobile/services/auth_service.dart';
import 'package:batasph_mobile/utils/logger_util.dart';

class RegisterController extends GetxController {
  final _authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmPassword = true.obs;

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
        'Account created',
        'Sign in to continue with your BatasPH account.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offNamed(Routes.LOGIN);
    } on DioException catch (error) {
      final message = _extractError(error);
      BatasphLogger.error('Register failed: $message');
      _showError(message);
    } catch (error) {
      BatasphLogger.error('Register failed: $error');
      _showError('Unable to create your account right now.');
    } finally {
      isLoading.value = false;
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
    if (error.response?.statusCode == 404) {
      return 'BatasPH API auth endpoints are not available yet.';
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Unable to create your account right now.';
  }
}
