import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/course_card.dart';
import '../../../../core/widgets/screen_header.dart';
import '../providers/explore_providers.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(exploreCoursesProvider);

    // Sync controller with provider state (for external resets)
    final currentSearch = ref.watch(exploreSearchQueryProvider);
    if (_searchController.text != currentSearch) {
      _searchController.text = currentSearch;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16.h, AppSpacing.screenPadding, 0),
              child: ScreenHeader(
                title: 'Explore',
              ),
            ),
            SizedBox(height: 16.h),
            
            // Modern Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Container(
                height: 52.h,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(exploreSearchQueryProvider.notifier).state = value;
                  },
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search courses, exams...',
                    hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textTertiary),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 24.sp),
                    suffixIcon: _searchController.text.isNotEmpty 
                      ? IconButton(
                          icon: Icon(Icons.cancel_rounded, size: 20.sp, color: AppColors.textTertiary.withValues(alpha: 0.6)),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(exploreSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Real-time Course Discovery
            Expanded(
              child: coursesAsync.when(
                data: (courses) {
                  if (courses.isEmpty) {
                    return _buildEmptyState(ref);
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(exploreCoursesProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 24.h),
                      itemCount: courses.length,
                      separatorBuilder: (context, index) => SizedBox(height: 16.h),
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        return CourseCard(
                          title: course.title,
                          instructor: course.instructorName,
                          price: '₹${course.price.toStringAsFixed(0)}',
                          originalPrice: course.discountPrice != null ? '₹${(course.price + (course.discountPrice ?? 0)).toStringAsFixed(0)}' : null,
                          discount: course.discountPercentage != null ? '${course.discountPercentage}% off' : null,
                          onTap: () => context.push('/course/${course.id}'),
                          onViewDetails: () => context.push('/course/${course.id}'),
                        );
                      },
                    ),
                  );
                },
                loading: () => ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  itemCount: 5,
                  separatorBuilder: (context, index) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) => _buildShimmerCard(),
                ),
                error: (error, _) => _buildErrorCard(error.toString(), () => ref.invalidate(exploreCoursesProvider)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: Colors.white.withValues(alpha: 0.5),
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48.sp),
            SizedBox(height: 16.h),
            Text('Failed to fetch courses', style: AppTextStyles.bodyMedium),
            SizedBox(height: 8.h),
            Text(
              error,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    final query = ref.read(exploreSearchQueryProvider);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 72.sp, color: AppColors.textTertiary.withValues(alpha: 0.3)),
            SizedBox(height: 24.h),
            Text(
              'No courses found',
              style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
            ),
            SizedBox(height: 12.h),
            Text(
              query.isNotEmpty 
                ? 'We couldn\'t find any courses matching "$query".'
                : 'There are no active courses at the moment.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                ref.read(exploreSearchQueryProvider.notifier).state = '';
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('Clear Search', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
