import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';

class BatchDashboardScreen extends StatefulWidget {
  final String batchId;
  const BatchDashboardScreen({super.key, required this.batchId});

  @override
  State<BatchDashboardScreen> createState() => _BatchDashboardScreenState();
}

class _BatchDashboardScreenState extends State<BatchDashboardScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _subjects = [
    {'name': 'History of India', 'icon': Icons.account_balance_rounded, 'color': const Color(0xFF2563EB), 'bg': const Color(0xFFDBEAFE), 'lessons': 42, 'pdfs': 12},
    {'name': 'Polity & Constitution', 'icon': Icons.gavel_rounded, 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7), 'lessons': 38, 'pdfs': 10},
    {'name': 'Geography of India', 'icon': Icons.public_rounded, 'color': const Color(0xFF22C55E), 'bg': const Color(0xFFDCFCE7), 'lessons': 30, 'pdfs': 8},
    {'name': 'General Science', 'icon': Icons.science_rounded, 'color': const Color(0xFF8B5CF6), 'bg': const Color(0xFFEDE9FE), 'lessons': 25, 'pdfs': 5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        title: Text('Batch Dashboard', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch info card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          color: AppColors.primaryLight,
                        ),
                        child: Icon(Icons.person, size: 36.sp, color: AppColors.primary),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BPSC 2026 Complete Batch', style: AppTextStyles.heading3),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded, size: 14.sp, color: AppColors.textTertiary),
                                SizedBox(width: 4.w),
                                Text('Ankit Sir', style: AppTextStyles.caption),
                                SizedBox(width: 12.w),
                                Icon(Icons.menu_book_rounded, size: 14.sp, color: AppColors.textTertiary),
                                SizedBox(width: 4.w),
                                Text('148 lessons', style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  const Divider(),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overall Progress', style: AppTextStyles.bodyMedium),
                      Text('72%', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: 0.72,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                      minHeight: 8.h,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Tab selector
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  _DashboardTab(label: 'Subjects', isSelected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                  _DashboardTab(label: 'Live', isSelected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                  _DashboardTab(label: 'Notes', isSelected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Continue Learning
            Text('Continue Learning', style: AppTextStyles.heading3),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 28.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Indus Valley Civilizatio...', style: AppTextStyles.heading4.copyWith(fontSize: 15.sp), overflow: TextOverflow.ellipsis),
                        SizedBox(height: 2.h),
                        Text('History • 45m left', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward_rounded, color: AppColors.onPrimary, size: 20.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Course Subjects
            Text('Course Subjects', style: AppTextStyles.heading3),
            SizedBox(height: 12.h),
            ..._subjects.map((subject) => _SubjectTile(
                  name: subject['name'],
                  icon: subject['icon'],
                  color: subject['color'],
                  bgColor: subject['bg'],
                  lessons: subject['lessons'],
                  pdfs: subject['pdfs'],
                )),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DashboardTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int lessons;
  final int pdfs;

  const _SubjectTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.lessons,
    required this.pdfs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.heading4.copyWith(fontSize: 15.sp)),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded, size: 14.sp, color: AppColors.textTertiary),
                    SizedBox(width: 4.w),
                    Text('$lessons Lessons', style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
                    SizedBox(width: 10.w),
                    Icon(Icons.description_outlined, size: 14.sp, color: AppColors.textTertiary),
                    SizedBox(width: 4.w),
                    Text('$pdfs PDFs', style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 24.sp),
        ],
      ),
    );
  }
}
