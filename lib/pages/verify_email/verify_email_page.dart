import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/verify_email/verify_email_controller.dart';

class VerifyEmailPage extends GetView<VerifyEmailController> {
  const VerifyEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24.w,
              12.h,
              24.w,
              MediaQuery.of(context).viewInsets.bottom + 24.h,
            ),
            children: [
              Text(
                'Check your email',
                style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Text.rich(
                TextSpan(
                  text: 'Enter the 6-digit code we sent to ',
                  children: [
                    TextSpan(
                      text: controller.email,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '. It expires in 10 minutes.'),
                  ],
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              TextField(
                controller: controller.codeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => controller.verify(),
                style: TextStyle(fontSize: 22.sp, letterSpacing: 8.w),
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
              SizedBox(height: 24.h),
              Obx(
                () => SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed:
                        controller.isVerifying.value ||
                            controller.isResending.value
                        ? null
                        : controller.verify,
                    child: controller.isVerifying.value
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text('Verify and sign in'),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Obx(
                () => TextButton(
                  onPressed: controller.canResend
                      ? controller.resendCode
                      : null,
                  child: Text(
                    controller.resendSecondsLeft.value > 0
                        ? 'Resend code in ${controller.resendSecondsLeft.value}s'
                        : controller.isResending.value
                        ? 'Sending…'
                        : 'Resend code',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
