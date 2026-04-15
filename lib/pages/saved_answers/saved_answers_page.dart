import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/saved_answer_model.dart';
import 'package:batasph_mobile/pages/saved_answers/saved_answers_controller.dart';

class SavedAnswersPage extends GetView<SavedAnswersController> {
  const SavedAnswersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Answers',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        actions: [
          Obx(() {
            if (!controller.hasSavedAnswers) {
              return const SizedBox.shrink();
            }

            return IconButton(
              tooltip: 'Clear saved answers',
              onPressed: () => _confirmClearAll(context),
              icon: const Icon(Icons.delete_sweep_outlined),
            );
          }),
        ],
      ),
      body: Obx(() {
        final items = controller.filteredAnswers;
        final hasSavedAnswers = controller.hasSavedAnswers;

        if (!hasSavedAnswers) {
          return _EmptyState(
            title: 'No saved answers yet',
            description:
                'Tap the star on a BatasPH answer to keep the full question and answer together.',
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            TextField(
              controller: controller.searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search saved questions or answers',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.searchQuery.value.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: controller.searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            SizedBox(height: 16.h),
            if (items.isEmpty)
              const _EmptyState(
                title: 'No matching saved answers',
                description:
                    'Try a different keyword from the question, answer, or legal reference.',
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _SavedAnswerCard(
                    item: item,
                    onDelete: () => controller.removeSavedAnswer(item),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Clear saved answers?'),
        content: const Text(
          'This removes all locally saved question and answer pairs from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Clear all'),
          ),
        ],
      ),
      barrierDismissible: true,
    );

    if (confirmed == true) {
      await controller.clearAll();
      if (context.mounted) {
        Get.snackbar(
          'Saved answers cleared',
          'All locally saved items were removed.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}

class _SavedAnswerCard extends StatelessWidget {
  final SavedAnswerModel item;
  final VoidCallback onDelete;

  const _SavedAnswerCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        item.question,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Remove saved answer'),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: theme.hintColor,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _StatusChip(status: item.answerMessage.status),
            SizedBox(height: 12.h),
            Text(
              item.answerMessage.text,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.55,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (item.answerMessage.referenceLine != null) ...[
              SizedBox(height: 10.h),
              Text(
                item.answerMessage.referenceLine!,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.45,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: 10.h),
            Text(
              'Saved ${_formatSavedAt(item.savedAt)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.hintColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSavedAt(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.month}/${value.day}/${value.year} at $hour:$minute $period';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLowConfidence = status == 'low_confidence';
    final isGeneralGuidance = status == 'general_guidance';

    final label = switch (status) {
      'general_guidance' => 'General guidance',
      'low_confidence' => 'Low confidence',
      _ => 'Verified answer',
    };

    final backgroundColor = isLowConfidence
        ? scheme.errorContainer
        : isGeneralGuidance
        ? scheme.secondaryContainer
        : scheme.primaryContainer;

    final foregroundColor = isLowConfidence
        ? scheme.onErrorContainer
        : isGeneralGuidance
        ? scheme.onSecondaryContainer
        : scheme.onPrimaryContainer;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String description;

  const _EmptyState({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline_rounded,
              size: 44.sp,
              color: theme.hintColor,
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.6,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
