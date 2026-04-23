import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_radius.dart';

class CourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String price;
  final String? originalPrice;
  final String? discount;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const CourseCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.price,
    this.originalPrice,
    this.discount,
    this.imageUrl,
    this.onTap,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            Stack(
              children: [
                Container(
                  height: 180.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Center(
                    child: Icon(Icons.school_rounded, size: 60.sp, color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ),
                if (discount != null)
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '$discount OFF',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading4, maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 16.sp, color: AppColors.textTertiary),
                      SizedBox(width: 4.w),
                      Text(instructor, style: AppTextStyles.caption),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (originalPrice != null) ...[
                            Text('₹$originalPrice', style: AppTextStyles.priceOld),
                            SizedBox(width: 8.w),
                          ],
                          Text('₹$price', style: AppTextStyles.price.copyWith(fontSize: 18.sp)),
                        ],
                      ),
                      if (onViewDetails != null)
                        SizedBox(
                          height: 36.h,
                          child: ElevatedButton(
                            onPressed: onViewDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              elevation: 0,
                              minimumSize: Size(0, 36.h),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                            child: Text('View Details', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
