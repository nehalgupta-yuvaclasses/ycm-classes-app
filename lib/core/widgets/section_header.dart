import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: AppTextStyles.heading2),
            if (actionText != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  actionText!,
                  style: AppTextStyles.buttonSm.copyWith(fontSize: 15.sp),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 4.h),
          Text(subtitle!, style: AppTextStyles.bodySm),
        ],
      ],
    );
  }
}
