import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../providers/course_providers.dart';
import '../../../batch/presentation/providers/batch_providers.dart';
import '../../domain/models/course_model.dart';
import 'live_class_screen.dart';

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));
    final enrolledAsync = ref.watch(myBatchesProvider);
    final isEnrolled = enrolledAsync.maybeWhen(
      data: (batches) => batches.any((batch) => batch.id == courseId),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: courseAsync.when(
        data: (course) => _buildContent(context, course, isEnrolled),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CourseModel course, bool isEnrolled) {
    final lessonCount = course.lessons?.length ?? 0;
    final liveLessonCount = _liveLessonCount(course);
    final recordedLessonCount = _recordedLessonCount(course);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // 1. VIDEO / HEADER IMAGE
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 250.h,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: course.thumbnailUrl?.isNotEmpty == true
                          ? CachedNetworkImage(
                              imageUrl: course.thumbnailUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250.h,
                              placeholder: (context, url) => _buildVideoPlaceholder(),
                              errorWidget: (context, url, error) => _buildVideoPlaceholder(),
                            )
                          : _buildVideoPlaceholder(),
                    ),
                    // Glassy Overlay for Category
                    if (course.categoryName.isNotEmpty)
                      Positioned(
                        bottom: 16.h,
                        left: 16.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            course.categoryName.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    // Actions
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8.h,
                      left: 16.w,
                      child: _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8.h,
                      right: 16.w,
                      child: _CircleIconButton(
                        icon: Icons.share_outlined,
                        onTap: () => _shareCourse(course),
                      ),
                    ),
                  ],
                ),
              ),
              // 2. MAIN CONTENT
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                  ),
                  transform: Matrix4.translationValues(0, -24.h, 0),
                  padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 32.h, AppSpacing.screenPadding, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags
                      if (course.tags.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: course.tags.map((tag) => _Tag(label: tag)).toList(),
                          ),
                        ),
                        
                      // Title & Subtitle
                      Text(course.title, style: AppTextStyles.heading1.copyWith(fontSize: 26.sp, letterSpacing: -0.5)),
                      if (course.subtitle?.isNotEmpty == true) ...[
                        SizedBox(height: 8.h),
                        Text(
                          course.subtitle!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 24.h),
                      
                      // Essential Info Bar
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoItem(icon: Icons.menu_book_rounded, label: 'Lessons', value: '$lessonCount'),
                            _buildVerticalDivider(),
                            _InfoItem(icon: Icons.videocam_outlined, label: 'Live', value: '$liveLessonCount'),
                            _buildVerticalDivider(),
                            _InfoItem(icon: Icons.timer_outlined, label: 'Recorded', value: '$recordedLessonCount'),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),
                      
                      // Instructor Section
                      Text('Your Instructor', style: AppTextStyles.heading3),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _InstructorAvatar(imageUrl: course.instructorAvatar),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course.instructorName, style: AppTextStyles.heading4),
                                  SizedBox(height: 2.h),
                                  Text('Lead Faculty • Yuva Classes', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                            _CircleIconButton(
                              icon: Icons.chevron_right_rounded,
                              size: 32.w,
                              iconSize: 18.sp,
                              color: AppColors.divider,
                              iconColor: AppColors.textTertiary,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32.h),
                      
                      // About Section
                      Text('About Course', style: AppTextStyles.heading3),
                      SizedBox(height: 12.h),
                      Text(
                        course.description,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      
                      SizedBox(height: 32.h),

                      // Curriculum Section
                      if (course.lessons != null && course.lessons!.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Course Content', style: AppTextStyles.heading3),
                            Text('$lessonCount Lessons', style: AppTextStyles.captionMedium.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: course.lessons!.length,
                          separatorBuilder: (context, index) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) => _LessonTile(
                            courseTitle: course.title,
                            lesson: course.lessons![index],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 120.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 3. PURCHASE BAR
        _buildPurchaseBar(context, course, isEnrolled),
      ],
    );
  }

  Widget _buildVideoPlaceholder() {
    return Center(
      child: Container(
        width: 64.w,
        height: 64.w,
        decoration: BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36.sp),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24.h,
      color: AppColors.divider,
    );
  }

  Widget _buildPurchaseBar(BuildContext context, CourseModel course, bool isEnrolled) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16.h, AppSpacing.screenPadding, 16.h + ScreenUtil().bottomBarHeight),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('₹${course.price.toStringAsFixed(0)}', style: AppTextStyles.price.copyWith(fontSize: 24.sp)),
              if (course.originalPrice != null && course.originalPrice! > course.price)
                Text('₹${course.originalPrice!.toStringAsFixed(0)}', style: AppTextStyles.priceOld),
            ],
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: SizedBox(
              height: 56.h,
              child: ElevatedButton(
                onPressed: () => context.push(isEnrolled ? '/course/${course.id}/player' : '/checkout/${course.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: Text(isEnrolled ? 'Open Course' : 'Get Full Access', style: AppTextStyles.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCourse(CourseModel course) async {
    final message = StringBuffer()
      ..writeln(course.title)
      ..writeln('by ${course.instructorName}')
      ..writeln('Price: ₹${course.price.toStringAsFixed(0)}')
      ..writeln('Open in Yuva Classes: /course/${course.id}');

    await Share.share(
      message.toString().trim(),
      subject: course.title,
    );
  }

  int _liveLessonCount(CourseModel course) {
    return course.lessons?.where((lesson) => lesson.isLiveSession).length ?? 0;
  }

  int _recordedLessonCount(CourseModel course) {
    return course.lessons?.where((lesson) => !lesson.isLiveSession).length ?? 0;
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double? size;
  final double? iconSize;
  final Color? color;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size,
    this.iconSize,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size ?? 44.w,
        height: size ?? 44.w,
        decoration: BoxDecoration(
          color: color ?? Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: color == null ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5) : null,
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: iconSize ?? 22.sp),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelBold.copyWith(color: AppColors.primary, fontSize: 10.sp),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 20.sp),
        SizedBox(height: 6.h),
        Text(value, style: AppTextStyles.labelBold.copyWith(fontSize: 14.sp)),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10.sp)),
      ],
    );
  }
}

class _InstructorAvatar extends StatelessWidget {
  final String? imageUrl;
  const _InstructorAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: CircleAvatar(
        radius: 28.r,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: imageUrl?.isNotEmpty == true ? NetworkImage(imageUrl!) : null,
        child: imageUrl?.isNotEmpty == true ? null : Icon(Icons.person, size: 30.sp, color: AppColors.primary),
      ),
    );
  }
}

class _IncludeItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _IncludeItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22.sp),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.bodyMedium),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
          ],
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  final String courseTitle;
  final LessonModel lesson;
  const _LessonTile({required this.courseTitle, required this.lesson});

  void _openLiveClass(BuildContext context) {
    context.push(
      '/live-class',
      extra: LiveClassArgs(courseTitle: courseTitle, lesson: lesson),
    );
  }

  String _formatScheduledAt() {
    final value = lesson.scheduledAt?.trim() ?? '';
    if (value.isEmpty) return '';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    return DateFormat('d MMM, h:mm a').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final isLiveLesson = lesson.isLiveSession;
    final isLiveNow = lesson.isLive;
    final isEnded = lesson.hasEnded;
    final scheduledLabel = _formatScheduledAt();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: isLiveNow
                  ? AppColors.errorLight
                  : isEnded
                      ? AppColors.divider
                      : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLiveLesson
                  ? (isLiveNow ? Icons.videocam_rounded : isEnded ? Icons.event_busy_rounded : Icons.schedule_rounded)
                  : Icons.play_circle_outline_rounded,
              color: isLiveNow
                  ? AppColors.error
                  : isEnded
                      ? AppColors.textTertiary
                      : AppColors.primary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
                      ),
                    ),
                    if (isLiveLesson)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isLiveNow ? AppColors.errorLight : AppColors.divider,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          isLiveNow ? 'LIVE' : isEnded ? 'ENDED' : 'SCHEDULED',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: isLiveNow ? AppColors.error : AppColors.textTertiary,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  isLiveLesson
                      ? (scheduledLabel.isNotEmpty ? 'Live class • $scheduledLabel' : 'Live class')
                      : 'Video • ${lesson.duration}',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.sp,
                    color: isLiveNow ? AppColors.error : AppColors.textTertiary,
                  ),
                ),
                if (isLiveLesson && lesson.liveStartedAt != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    isLiveNow
                        ? 'Started ${DateFormat('h:mm a').format(lesson.liveStartedAt!.toLocal())}'
                        : isEnded && lesson.liveEndedAt != null
                            ? 'Ended ${DateFormat('h:mm a').format(lesson.liveEndedAt!.toLocal())}'
                            : 'Waiting to go live',
                    style: AppTextStyles.caption.copyWith(fontSize: 11.sp, color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (lesson.hasPlayback)
            if (isLiveLesson && isLiveNow)
              SizedBox(
                width: 124.w,
                height: 36.h,
                child: ElevatedButton(
                  onPressed: () => _openLiveClass(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text('Join Class', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
                ),
              )
            else
              SizedBox(
                width: 124.w,
                height: 36.h,
                child: ElevatedButton(
                  onPressed: () => _openLiveClass(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text((lesson.lessonType == 'recorded' || lesson.isRecordedReady) ? 'Watch Recording' : 'Open Lesson', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700)),
                ),
              )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isEnded ? AppColors.divider : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
              ),
              child: Text(
                isEnded ? 'Class Ended' : 'Not Live Yet',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}
