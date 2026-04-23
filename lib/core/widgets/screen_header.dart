import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onIconTap;

  const ScreenHeader({
    super.key,
    required this.title,
    this.icon,
    this.onIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.heading2.copyWith(fontSize: 25.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (icon != null)
          GestureDetector(
            onTap: onIconTap,
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 22.sp),
            ),
          ),
      ],
    );
  }
}
