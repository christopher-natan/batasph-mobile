import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/forgot_password/forgot_password_controller.dart';

class ForgotPasswordPage extends GetView<ForgotPasswordController> {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintStyle = TextStyle(
      fontSize: 14.sp,
      color: theme.hintColor,
      height: 1.5,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Obx(
            () => ListView(
              padding: EdgeInsets.fromLTRB(
                24.w,
                12.h,
                24.w,
                MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              children: controller.codeSent.value
                  ? _codeStep(hintStyle)
                  : _emailStep(hintStyle),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _emailStep(TextStyle hintStyle) {
    return [
      Text(
        'Forgot your password?',
        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700),
      ),
      SizedBox(height: 8.h),
      Text(
        'Enter your account email and we will send you a 6-digit code to set a new password.',
        style: hintStyle,
      ),
      SizedBox(height: 24.h),
      TextField(
        controller: controller.emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => controller.sendCode(),
        decoration: const InputDecoration(
          labelText: 'Email',
          prefixIcon: Icon(Icons.email_outlined),
        ),
      ),
      SizedBox(height: 24.h),
      _PrimaryButton(
        label: 'Send reset code',
        isLoading: controller.isSending.value,
        onPressed: controller.isBusy ? null : controller.sendCode,
      ),
    ];
  }

  List<Widget> _codeStep(TextStyle hintStyle) {
    return [
      Text(
        'Set a new password',
        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700),
      ),
      SizedBox(height: 8.h),
      Text.rich(
        TextSpan(
          text: 'If an account exists for ',
          children: [
            TextSpan(
              text: controller.sentToEmail.value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(
              text: ', we sent it a 6-digit code. It expires in 10 minutes.',
            ),
          ],
        ),
        style: hintStyle,
      ),
      SizedBox(height: 24.h),
      TextField(
        controller: controller.codeController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: TextStyle(fontSize: 22.sp, letterSpacing: 8.w),
        decoration: const InputDecoration(
          labelText: 'Reset code',
          prefixIcon: Icon(Icons.pin_outlined),
        ),
      ),
      SizedBox(height: 16.h),
      TextField(
        controller: controller.passwordController,
        obscureText: controller.obscurePassword.value,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: 'New password',
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
      SizedBox(height: 16.h),
      TextField(
        controller: controller.confirmPasswordController,
        obscureText: controller.obscureConfirmPassword.value,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => controller.resetPassword(),
        decoration: InputDecoration(
          labelText: 'Confirm new password',
          prefixIcon: const Icon(Icons.lock_reset_outlined),
          suffixIcon: IconButton(
            onPressed: controller.toggleConfirmPasswordVisibility,
            icon: Icon(
              controller.obscureConfirmPassword.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
      SizedBox(height: 24.h),
      _PrimaryButton(
        label: 'Reset password',
        isLoading: controller.isResetting.value,
        onPressed: controller.isBusy ? null : controller.resetPassword,
      ),
      SizedBox(height: 14.h),
      TextButton(
        onPressed: controller.canResend ? controller.resendCode : null,
        child: Text(
          controller.resendSecondsLeft.value > 0
              ? 'Resend code in ${controller.resendSecondsLeft.value}s'
              : controller.isSending.value
              ? 'Sending…'
              : 'Resend code',
        ),
      ),
      TextButton(
        onPressed: controller.isBusy ? null : controller.changeEmail,
        child: const Text('Use a different email'),
      ),
    ];
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        onPressed: onPressed,
        child: isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(label),
      ),
    );
  }
}
