import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/primary_button.dart';

class TestResultsScreen extends StatelessWidget {
  final String testId;
  const TestResultsScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Score Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16.h, AppSpacing.screenPadding, 40.h),
                child: Column(
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded, color: Colors.white, size: 22.sp),
                          ),
                        ),
                        Text('Test Results', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600)),
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.share_rounded, color: Colors.white, size: 20.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 32.h),
                    // Score circle
                    Container(
                      width: 140.w,
                      height: 140.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('86%', style: TextStyle(fontSize: 42.sp, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('Score', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text('Great Performance! 🎉', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 6.h),
                    Text(
                      'You scored better than 78% of students',
                      style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              // Stats cards
              Transform.translate(
                offset: Offset(0, -20.h),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _StatItem(icon: Icons.check_circle_rounded, color: AppColors.success, value: '8', label: 'Correct')),
                        _VerticalDivider(),
                        Expanded(child: _StatItem(icon: Icons.cancel_rounded, color: AppColors.error, value: '1', label: 'Wrong')),
                        _VerticalDivider(),
                        Expanded(child: _StatItem(icon: Icons.remove_circle_rounded, color: AppColors.warning, value: '1', label: 'Skipped')),
                        _VerticalDivider(),
                        Expanded(child: _StatItem(icon: Icons.timer_rounded, color: AppColors.primary, value: '18m', label: 'Time')),
                      ],
                    ),
                  ),
                ),
              ),
              // Performance breakdown
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Performance Breakdown', style: AppTextStyles.heading3),
                    SizedBox(height: 16.h),
                    _SubjectBar(subject: 'Indian Polity', score: 0.90, color: AppColors.success, label: '9/10'),
                    _SubjectBar(subject: 'History', score: 0.75, color: AppColors.primary, label: '6/8'),
                    _SubjectBar(subject: 'Geography', score: 0.85, color: AppColors.warning, label: '6/7'),
                    _SubjectBar(subject: 'Economy', score: 0.60, color: AppColors.error, label: '3/5'),
                    SizedBox(height: 28.h),
                    // Comparison card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Comparison', style: AppTextStyles.heading4),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(child: _CompareItem(label: 'Your Score', value: '86%', icon: Icons.person_rounded, color: AppColors.primary)),
                              SizedBox(width: 12.w),
                              Expanded(child: _CompareItem(label: 'Average', value: '62%', icon: Icons.people_rounded, color: AppColors.textTertiary)),
                              SizedBox(width: 12.w),
                              Expanded(child: _CompareItem(label: 'Topper', value: '98%', icon: Icons.emoji_events_rounded, color: AppColors.warning)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 28.h),
                    // Actions
                    PrimaryButton(
                      text: 'View Solutions',
                      onPressed: () {},
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                        child: Text('Back to Tests', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                      ),
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(height: 8.h),
        Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 20.sp)),
        SizedBox(height: 2.h),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 60.h,
      color: AppColors.divider,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final String subject;
  final double score;
  final Color color;
  final String label;
  const _SubjectBar({required this.subject, required this.score, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject, style: AppTextStyles.bodyMedium),
              Text(label, style: AppTextStyles.captionMedium),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10.h,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _CompareItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(value, style: AppTextStyles.heading3.copyWith(fontSize: 18.sp)),
          SizedBox(height: 2.h),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11.sp)),
        ],
      ),
    );
  }
}
