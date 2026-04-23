import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_radius.dart';

class AppOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? textColor;

  const AppOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.width,
    this.height,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.textPrimary,
          side: BorderSide(color: borderColor ?? AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null) ...[
              iconWidget!,
              SizedBox(width: 12.w),
            ] else if (icon != null) ...[
              Icon(icon, size: 20.sp),
              SizedBox(width: 12.w),
            ],
            Text(text, style: AppTextStyles.bodyMedium.copyWith(color: textColor ?? AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
