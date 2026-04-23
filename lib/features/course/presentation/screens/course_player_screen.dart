import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../batch/presentation/providers/batch_providers.dart';

class CoursePlayerScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CoursePlayerScreen({super.key, required this.courseId});

  @override
  ConsumerState<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends ConsumerState<CoursePlayerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;


  final List<_PlayerLesson> _lessons = [
    _PlayerLesson('1. Introduction to Ancient History', 'Video • 45m', LessonStatus.completed),
    _PlayerLesson('2. Indus Valley Civilization', 'Playing • 1h 20m', LessonStatus.playing),
    _PlayerLesson('3. Vedic Period & Culture', 'Video • 1h 45m', LessonStatus.upcoming),
    _PlayerLesson('4. Buddhism & Jainism', 'Video • 2h 10m', LessonStatus.upcoming),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enrolledAsync = ref.watch(myBatchesProvider);
    final isEnrolled = enrolledAsync.maybeWhen(
      data: (batches) => batches.any((batch) => batch.id == widget.courseId),
      orElse: () => false,
    );

    if (!isEnrolled) {
      return _buildAccessDenied(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Video Player Section
          Stack(
            children: [
              Container(
                height: 260.h,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).padding.top),
                    // Controls row
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Row(
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
                              child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22.sp),
                            ),
                          ),
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.settings_rounded, color: Colors.white, size: 22.sp),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Play button
                    Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36.sp),
                    ),
                    const Spacer(),
                    // Progress bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3.h,
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(value: 0.3, onChanged: (_) {}),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('24:15  /  1:20:00', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                                GestureDetector(
                                  onTap: () {},
                                  child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24.sp),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Content
          Expanded(
            child: Container(
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 20.h, AppSpacing.screenPadding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('2. Indus Valley Civilization', style: AppTextStyles.heading2),
                        SizedBox(height: 4.h),
                        Text('Module 1: Ancient Indian History', style: AppTextStyles.bodySm),
                        SizedBox(height: 16.h),
                        // Course progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Course Progress', style: AppTextStyles.bodyMedium),
                            Text('15%', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: 0.15,
                            backgroundColor: AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                            minHeight: 6.h,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textTertiary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Lectures'),
                      Tab(text: 'Notes'),
                      Tab(text: 'Discussion'),
                    ],
                  ),
                  const Divider(height: 1),
                  // Lesson list
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLecturesList(),
                        _buildPlaceholderTab('Notes will appear here'),
                        _buildPlaceholderTab('Discussion forum coming soon'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, color: AppColors.textTertiary, size: 56.sp),
              SizedBox(height: 16.h),
              Text('Enrollment required', style: AppTextStyles.heading3, textAlign: TextAlign.center),
              SizedBox(height: 8.h),
              Text('Purchase the course to access the player and lesson list.', style: AppTextStyles.bodySm, textAlign: TextAlign.center),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => context.push('/checkout/${widget.courseId}'),
                child: const Text('Go to checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLecturesList() {
    return ListView(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Text('Module 1: Ancient Indian History', style: AppTextStyles.heading4),
        SizedBox(height: 14.h),
        ..._lessons.asMap().entries.map((entry) {
          final lesson = entry.value;
          final isPlaying = lesson.status == LessonStatus.playing;
          return Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isPlaying ? AppColors.primaryLight.withValues(alpha: 0.4) : AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isPlaying ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
            ),
            child: Row(
              children: [
                _getStatusIcon(lesson.status),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isPlaying ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        lesson.meta,
                        style: AppTextStyles.caption.copyWith(
                          color: isPlaying ? AppColors.primary : AppColors.textTertiary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPlaying)
                  Icon(Icons.equalizer_rounded, color: AppColors.primary, size: 22.sp),
              ],
            ),
          );
        }),
        SizedBox(height: 20.h),
        Text('Module 2: Medieval Indian History', style: AppTextStyles.heading4),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.textTertiary, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. Early Medieval India', style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp)),
                    SizedBox(height: 2.h),
                    Text('Video • 1h 30m', style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getStatusIcon(LessonStatus status) {
    switch (status) {
      case LessonStatus.completed:
        return Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: AppColors.success, size: 20.sp),
        );
      case LessonStatus.playing:
        return Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.sp),
        );
      case LessonStatus.upcoming:
        return Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.play_arrow_rounded, color: AppColors.textTertiary, size: 20.sp),
        );
    }
  }

  Widget _buildPlaceholderTab(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upcoming_outlined, size: 48.sp, color: AppColors.textTertiary),
          SizedBox(height: 12.h),
          Text(message, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

enum LessonStatus { completed, playing, upcoming }

class _PlayerLesson {
  final String title;
  final String meta;
  final LessonStatus status;
  _PlayerLesson(this.title, this.meta, this.status);
}
