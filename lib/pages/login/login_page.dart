import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/components/google_sign_in_button_component.dart';
import 'package:batasph_mobile/components/or_divider_component.dart';
import 'package:batasph_mobile/pages/login/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24.w,
              24.h,
              24.w,
              MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            children: [
              _HeroPanel(theme: theme),
              SizedBox(height: 28.h),
              Text(
                'Sign in',
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Text(
                'Access your BatasPH account and future synced profile data.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28.h),
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              SizedBox(height: 16.h),
              Obx(
                () => TextField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword.value,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: controller.togglePasswordVisibility,
                      icon: Icon(
                        controller.obscurePassword.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.goToForgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              SizedBox(height: 8.h),
              Obx(
                () => SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: controller.isBusy ? null : controller.login,
                    child: controller.isLoading.value
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text('Sign in'),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              const OrDividerComponent(),
              SizedBox(height: 20.h),
              Obx(
                () => GoogleSignInButtonComponent(
                  isLoading: controller.isGoogleLoading.value,
                  onPressed: controller.isBusy
                      ? null
                      : controller.signInWithGoogle,
                ),
              ),
              SizedBox(height: 14.h),
              TextButton(
                onPressed: controller.goToRegister,
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BatasPH Account',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Session and profile support copied from the reference app and adapted for BatasPH.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.hintColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
