import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/pages/profile/profile_controller.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshProfile(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            Obx(
              () => Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30.r,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          child: Text(
                            controller.initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.displayName,
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                controller.email,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (controller.isLoading.value) ...[
                      SizedBox(height: 18.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999.r),
                        child: LinearProgressIndicator(
                          minHeight: 4.h,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Obx(() {
              final message = controller.syncMessage.value;
              if (message == null || message.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Card(
                  color: theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.5,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              );
            }),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _DetailRow(label: 'Name', value: controller.displayName),
                    SizedBox(height: 12.h),
                    _DetailRow(label: 'Email', value: controller.email),
                    SizedBox(height: 12.h),
                    _DetailRow(
                      label: 'Provider',
                      value: controller.authProviderLabel,
                    ),
                    SizedBox(height: 12.h),
                    _DetailRow(label: 'User ID', value: controller.userId),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Obx(
              () => SizedBox(
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.refreshProfile(),
                  icon: const Icon(Icons.sync_outlined),
                  label: const Text('Refresh profile'),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Obx(
              () => SizedBox(
                height: 52.h,
                child: OutlinedButton.icon(
                  onPressed:
                      controller.isLoading.value || controller.isDeleting.value
                      ? null
                      : controller.logout,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Sign out'),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Obx(
              () => TextButton.icon(
                onPressed:
                    controller.isLoading.value || controller.isDeleting.value
                    ? null
                    : () => _confirmDeleteAccount(),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                icon: controller.isDeleting.value
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your BatasPH account, your chat history '
          'and your answer reports. It cannot be undone. Answers saved on '
          'this device stay until you clear them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.error,
              foregroundColor: Get.theme.colorScheme.onError,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      await controller.deleteAccount();
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: theme.hintColor,
          ),
        ),
        SizedBox(height: 4.h),
        SelectableText(
          value,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
