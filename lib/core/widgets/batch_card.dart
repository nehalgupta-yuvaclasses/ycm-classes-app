import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_radius.dart';

class BatchCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String? lessonCount;
  final double? progress;
  final String status;
  final String? validTill;
  final VoidCallback? onDetails;
  final VoidCallback? onContinue;

  const BatchCard({
    super.key,
    required this.title,
    required this.instructor,
    this.lessonCount,
    this.progress,
    this.status = 'Purchased',
    this.validTill,
    this.onDetails,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructor avatar
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: AppColors.primaryLight,
                ),
                child: Icon(Icons.person, size: 40.sp, color: AppColors.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: AppTextStyles.heading4, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            status,
                            style: AppTextStyles.label.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14.sp, color: AppColors.textTertiary),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            instructor,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lessonCount != null) ...[
                          SizedBox(width: 8.w),
                          Icon(Icons.menu_book_rounded, size: 14.sp, color: AppColors.textTertiary),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              '$lessonCount lessons',
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (validTill != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14.sp, color: AppColors.textTertiary),
                          SizedBox(width: 4.w),
                          Text('Valid till $validTill', style: AppTextStyles.caption),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (progress != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Course progress', style: AppTextStyles.caption),
                Text('${(progress! * 100).toInt()}%', style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary)),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                minHeight: 6.h,
              ),
            ),
            SizedBox(height: 16.h),
          ] else ...[
            Text(
              'Progress data unavailable',
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
            SizedBox(height: 16.h),
          ],
          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42.h,
                  child: OutlinedButton(
                    onPressed: onDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    child: Text('Details', style: AppTextStyles.buttonSm),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 42.h,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    child: Text('Continue', style: AppTextStyles.button.copyWith(fontSize: 14.sp)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
