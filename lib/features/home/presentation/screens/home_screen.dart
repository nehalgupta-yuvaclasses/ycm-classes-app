import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../course/presentation/providers/course_providers.dart';
import '../../../course/domain/models/course_model.dart';
import '../../../course/domain/models/banner_model.dart';
import '../../../socials/presentation/widgets/social_modal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _sliderController = PageController();
  Timer? _sliderTimer;
  int _currentSliderPage = 0;

  @override
  void initState() {
    super.initState();
    _startSliderTimer();
  }

  void _startSliderTimer() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_sliderController.hasClients) {
        final totalPages = ref.read(bannersProvider).value?.length ?? 0;
        if (totalPages <= 1) return;

        if (_currentSliderPage < totalPages - 1) {
          _currentSliderPage++;
        } else {
          _currentSliderPage = 0;
        }

        _sliderController.animateToPage(
          _currentSliderPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);
    final featuredAsync = ref.watch(featuredCoursesProvider);
    final topPicksAsync = ref.watch(topPicksProvider);
    final recommendedAsync = ref.watch(recommendedCoursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(bannersProvider);
            ref.invalidate(featuredCoursesProvider);
            ref.invalidate(topPicksProvider);
            ref.invalidate(recommendedCoursesProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                // 1. THUMBNAIL SLIDER
                _buildThumbnailSlider(bannersAsync),
                SizedBox(height: 24.h),
                // 2. FEATURED BATCHES
                _buildFeaturedBatches(featuredAsync),
                SizedBox(height: 28.h),
                // 3. TOP PICKS
                _buildTopPicks(topPicksAsync),
                SizedBox(height: 28.h),
                // 4. RECOMMENDED FOR YOU
                _buildRecommendedForYou(recommendedAsync),
                
                SizedBox(height: 32.h),
                
                // 5. FOLLOW US BUTTON
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: _buildFollowUsButton(),
                ),
                
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowUsButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const SocialModal(),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_rounded, color: Colors.white, size: 20.sp),
              SizedBox(width: 12.w),
              Text(
                'Follow Us',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final student = ref.watch(authControllerProvider).user;
    final firstName = student?.fullName.isNotEmpty == true ? student!.fullName.split(' ')[0] : 'Student';

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16.h, AppSpacing.screenPadding, 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $firstName',
                  style: AppTextStyles.heading1.copyWith(fontSize: 25.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'What would you like to learn today?',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Icon(Icons.notifications_none_rounded, size: 22.sp, color: AppColors.textPrimary),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailSlider(AsyncValue<List<BannerModel>> bannersAsync) {
    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            SizedBox(
              height: 190.h,
              child: PageView.builder(
                controller: _sliderController,
                onPageChanged: (index) => setState(() => _currentSliderPage = index),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return GestureDetector(
                    onTap: () {
                      if (banner.targetId != null) {
                        context.push('/course/${banner.targetId}');
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildShimmerBox(height: 190.h, width: double.infinity),
                            errorWidget: (context, url, error) => Container(color: AppColors.primaryLight),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(banner.title, style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 22.sp)),
                                SizedBox(height: 4.h),
                                Text(banner.subtitle, style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.sp)),
                                SizedBox(height: 14.h),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(banner.cta, style: AppTextStyles.button.copyWith(color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12.h),
            SmoothPageIndicator(
              controller: _sliderController,
              count: banners.length,
              effect: ExpandingDotsEffect(
                dotWidth: 6.w,
                dotHeight: 6.w,
                spacing: 6.w,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.textTertiary.withValues(alpha: 0.3),
                expansionFactor: 4,
              ),
            ),
          ],
        );
      },
      loading: () => _buildShimmerBox(height: 190.h, width: double.infinity, margin: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding)),
      error: (err, _) => _buildErrorCard(() => ref.invalidate(bannersProvider)),
    );
  }

  Widget _buildFeaturedBatches(AsyncValue<List<CourseModel>> coursesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: SectionHeader(
            title: 'Featured Batches',
            actionText: 'See all',
            onAction: () => context.go('/explore'),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 250.h,
          child: coursesAsync.when(
            data: (courses) {
              if (courses.isEmpty) return _buildEmptyState('No featured batches found');
              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                separatorBuilder: (context, index) => SizedBox(width: 16.w),
                itemBuilder: (context, index) => _FeaturedCard(course: courses[index]),
              );
            },
            loading: () => _buildHorizontalSkeleton(),
            error: (err, _) => _buildErrorCard(() => ref.invalidate(featuredCoursesProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPicks(AsyncValue<List<CourseModel>> coursesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: SectionHeader(
            title: 'Top Picks',
            actionText: 'Browse',
            onAction: () => context.go('/explore'),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 180.h,
          child: coursesAsync.when(
            data: (courses) {
              if (courses.isEmpty) return _buildEmptyState('No top picks found');
              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                separatorBuilder: (context, index) => SizedBox(width: 14.w),
                itemBuilder: (context, index) => _TopPickCard(course: courses[index]),
              );
            },
            loading: () => _buildHorizontalSkeleton(height: 180.h),
            error: (err, _) => _buildErrorCard(() => ref.invalidate(topPicksProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedForYou(AsyncValue<List<CourseModel>> coursesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Text('Recommended for You', style: AppTextStyles.heading3),
        ),
        SizedBox(height: 16.h),
        coursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) return _buildEmptyState('No recommendations found');
            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              itemBuilder: (context, index) => _RecommendedCard(course: courses[index]),
            );
          },
          loading: () => _buildVerticalSkeleton(),
          error: (err, _) => _buildErrorCard(() => ref.invalidate(recommendedCoursesProvider)),
        ),
      ],
    );
  }

  // ─── UI Helper Widgets ──────────────────────────────────────────────

  Widget _buildShimmerBox({required double height, required double width, EdgeInsets? margin}) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: Colors.white.withValues(alpha: 0.5),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSkeleton({double height = 250}) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (context, index) => SizedBox(width: 16.w),
      itemBuilder: (context, index) => _buildShimmerBox(height: height, width: 220.w),
    );
  }

  Widget _buildVerticalSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => _buildShimmerBox(
          height: 100.h,
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 16.h, left: AppSpacing.screenPadding, right: AppSpacing.screenPadding),
        ),
      ),
    );
  }

  Widget _buildErrorCard(VoidCallback onRetry) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 32.sp),
          SizedBox(height: 12.h),
          Text('Something went wrong', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: AppColors.textTertiary, size: 40.sp),
            SizedBox(height: 12.h),
            Text(message, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final CourseModel course;
  const _FeaturedCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
        width: 220.w,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120.h,
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                  child: Center(child: Icon(Icons.school_rounded, size: 40.sp, color: Colors.white.withValues(alpha: 0.3))),
                ),
                if (course.discountPercentage != null)
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6.r)),
                      child: Text('${course.discountPercentage}% OFF', style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: AppTextStyles.heading4.copyWith(fontSize: 14.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.person_2_outlined, size: 14.sp, color: AppColors.textTertiary),
                      SizedBox(width: 4.w),
                      Expanded(child: Text(course.instructorName, style: AppTextStyles.bodySm.copyWith(fontSize: 12.sp), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹${course.price.toStringAsFixed(0)}', style: AppTextStyles.price.copyWith(fontSize: 16.sp, color: AppColors.primary)),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: AppColors.primary.withValues(alpha: 0.5)),
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

class _TopPickCard extends StatelessWidget {
  final CourseModel course;
  const _TopPickCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final badge = course.tags.firstWhere((t) => t == 'Top Rated' || t == 'Best Seller' || t == 'Bestseller', orElse: () => '');

    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
        width: 160.w,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90.h,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
              ),
              child: Center(child: Icon(Icons.star_rounded, color: AppColors.warning, size: 24.sp)),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge.isNotEmpty) ...[
                    Text(badge.toUpperCase(), style: TextStyle(color: AppColors.warning, fontSize: 9.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    SizedBox(height: 2.h),
                  ],
                  Text(course.title, style: AppTextStyles.heading4.copyWith(fontSize: 12.sp), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final CourseModel course;
  const _RecommendedCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.play_circle_fill_rounded, size: 30.sp, color: Colors.white.withValues(alpha: 0.5)),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4.r)),
                    child: Text('Based on your interest', style: TextStyle(color: AppColors.primary, fontSize: 9.sp, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(height: 6.h),
                  Text(course.title, style: AppTextStyles.heading4.copyWith(fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4.h),
                  Text('${course.instructorName} • ${course.categoryName}', style: AppTextStyles.caption.copyWith(fontSize: 11.sp)),
                  SizedBox(height: 6.h),
                  Text('₹${course.price.toStringAsFixed(0)}', style: AppTextStyles.price.copyWith(fontSize: 14.sp, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
