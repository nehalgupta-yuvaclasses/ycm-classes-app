import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/course_model.dart';

class LiveClassArgs {
  final String courseTitle;
  final LessonModel lesson;

  const LiveClassArgs({
    required this.courseTitle,
    required this.lesson,
  });
}

class LiveClassScreen extends StatelessWidget {
  const LiveClassScreen({super.key, required this.args});

  final LiveClassArgs args;

  Future<void> _launchMeeting() async {
    final url = args.lesson.liveUrl?.isNotEmpty == true
        ? args.lesson.liveUrl!
        : 'https://meet.jit.si/yuva-${args.lesson.moduleId.isNotEmpty ? args.lesson.moduleId : args.lesson.id}';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = args.lesson;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Live Class'),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      lesson.isLive ? 'LIVE NOW' : 'SCHEDULED',
                      style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(args.courseTitle, style: AppTextStyles.heading3.copyWith(color: Colors.white)),
                  SizedBox(height: 8.h),
                  Text(lesson.title, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  SizedBox(height: 14.h),
                  Text(
                    lesson.scheduledAt?.isNotEmpty == true
                        ? 'Scheduled: ${lesson.scheduledAt}'
                        : 'Ready to join from the configured meeting link.',
                    style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meeting', style: AppTextStyles.heading4),
                  SizedBox(height: 10.h),
                  Text(
                    lesson.liveUrl?.isNotEmpty == true ? lesson.liveUrl! : 'No live URL was provided. A fallback meeting room will be opened.',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: _launchMeeting,
                icon: const Icon(Icons.videocam_rounded),
                label: Text('Join Class', style: AppTextStyles.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}