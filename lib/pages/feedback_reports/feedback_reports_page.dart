import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/answer_feedback_model.dart';
import 'package:batasph_mobile/pages/feedback_reports/feedback_reports_controller.dart';

class FeedbackReportsPage extends GetView<FeedbackReportsController> {
  const FeedbackReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reported Answers',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(() {
        final reports = controller.filteredReports;
        final hasReports = controller.feedbackReports.isNotEmpty;

        if (!controller.isLoaded && !hasReports) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!hasReports) {
          return const _EmptyState(
            title: 'No reports yet',
            description:
                'Use Report answer from a BatasPH reply when something looks wrong or unclear.',
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            TextField(
              controller: controller.searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search reported questions or issues',
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
            if (reports.isEmpty)
              const _EmptyState(
                title: 'No matching reports',
                description:
                    'Try a different keyword from the question, answer, or issue type.',
              )
            else
              ...reports.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _ReportCard(item: item),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AnswerFeedbackModel item;

  const _ReportCard({required this.item});

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
                  child: Text(
                    item.question,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                _IssueChip(issueType: item.issueType),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              item.answer,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.55,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (item.comment.trim().isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                'Your note',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                item.comment.trim(),
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: theme.hintColor,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Text(
              'Reported ${_formatDate(item.createdAt)}',
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

  String _formatDate(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.month}/${value.day}/${value.year} at $hour:$minute $period';
  }
}

class _IssueChip extends StatelessWidget {
  final AnswerFeedbackIssueType issueType;

  const _IssueChip({required this.issueType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        issueType.label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
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
            Icon(Icons.flag_outlined, size: 44.sp, color: theme.hintColor),
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
