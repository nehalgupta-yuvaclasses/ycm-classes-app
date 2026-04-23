import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_radius.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconBgColor;
  final Color? iconColor;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const SettingsTile({
    super.key,
    required this.icon,
    this.iconBgColor,
    this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isDestructive
        ? AppColors.errorLight
        : (iconBgColor ?? AppColors.primaryLight);
    final Color fgColor = isDestructive
        ? AppColors.error
        : (iconColor ?? AppColors.primary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: fgColor, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDestructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(trailing!, style: AppTextStyles.caption),
              SizedBox(width: 8.w),
            ],
            if (!isDestructive)
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 24.sp),
          ],
        ),
      ),
    );
  }
}
