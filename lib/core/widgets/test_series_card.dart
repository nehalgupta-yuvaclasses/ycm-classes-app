import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_radius.dart';

class TestSeriesCard extends StatelessWidget {
  final String title;
  final String description;
  final String type; // 'Paid' or 'Free'
  final String? stats;
  final String? bestScore;
  final double? completion;
  final String? validTill;
  final String primaryAction;
  final String secondaryAction;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const TestSeriesCard({
    super.key,
    required this.title,
    required this.description,
    required this.type,
    this.stats,
    this.bestScore,
    this.completion,
    this.validTill,
    required this.primaryAction,
    required this.secondaryAction,
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPaid = type == 'Paid';
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading4, maxLines: 2, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4.h),
                    Text(description, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.successLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  type,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Stats row
          Row(
            children: [
              if (stats != null) ...[
                Icon(Icons.assignment_outlined, size: 16.sp, color: AppColors.textTertiary),
                SizedBox(width: 4.w),
                Text(stats!, style: AppTextStyles.caption),
              ],
              if (bestScore != null) ...[
                SizedBox(width: 16.w),
                Icon(Icons.emoji_events_outlined, size: 16.sp, color: AppColors.textTertiary),
                SizedBox(width: 4.w),
                Text('Best $bestScore', style: AppTextStyles.caption),
              ],
              if (validTill != null) ...[
                SizedBox(width: 16.w),
                Icon(Icons.calendar_today_outlined, size: 16.sp, color: AppColors.textTertiary),
                SizedBox(width: 4.w),
                Text('Valid till $validTill', style: AppTextStyles.caption),
              ],
            ],
          ),
          if (completion != null) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completion', style: AppTextStyles.caption),
                Text('${(completion! * 100).toInt()}%', style: AppTextStyles.captionMedium),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: completion!,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                minHeight: 5.h,
              ),
            ),
          ],
          SizedBox(height: 16.h),
          // Actions
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 42.h,
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    child: Text(secondaryAction, style: AppTextStyles.buttonSm),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 42.h,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    child: Text(primaryAction, style: AppTextStyles.button.copyWith(fontSize: 14.sp)),
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
