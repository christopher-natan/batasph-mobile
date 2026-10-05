import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:batasph_mobile/data/models/answer_feedback_model.dart';
import 'package:batasph_mobile/pages/report_answer/report_answer_controller.dart';

class ReportAnswerPage extends GetView<ReportAnswerController> {
  const ReportAnswerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final question = controller.arguments.questionMessage;
    final answer = controller.arguments.answerMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report Answer',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Question',
              child: Text(
                question.text,
                style: TextStyle(fontSize: 15.sp, height: 1.55),
              ),
            ),
            SizedBox(height: 12.h),
            _SectionCard(
              title: 'Answer',
              child: Text(
                answer.text,
                style: TextStyle(fontSize: 14.sp, height: 1.55),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'What is wrong with this answer?',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10.h),
            Obx(
              () => Column(
                children: AnswerFeedbackIssueType.values
                    .map(
                      (issueType) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: InkWell(
                          onTap: () {
                            controller.selectedIssueType.value = issueType;
                          },
                          borderRadius: BorderRadius.circular(18.r),
                          child: Ink(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18.r),
                              border: Border.all(
                                color:
                                    controller.selectedIssueType.value ==
                                        issueType
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                              ),
                              color:
                                  controller.selectedIssueType.value ==
                                      issueType
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(context).cardColor,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  controller.selectedIssueType.value ==
                                          issueType
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        issueType.label,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        issueType.description,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Optional note',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: controller.commentController,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText:
                    'Add details if this answer missed a law, used the wrong rule, or needs clearer wording.',
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => FilledButton.icon(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : controller.submitReport,
                  icon: controller.isSubmitting.value
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.flag_outlined),
                  label: Text(
                    controller.isSubmitting.value
                        ? 'Sending report...'
                        : 'Send report',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8.h),
            child,
          ],
        ),
      ),
    );
  }
}
