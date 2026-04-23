import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/batch_card.dart';
import '../../../../core/widgets/screen_header.dart';
import '../providers/batch_providers.dart';
import '../../../test/presentation/providers/test_providers.dart';

class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController?.indexIsChanging ?? false) {
      setState(() {}); // Update tab selector UI
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabSelection);
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20.h),
            _buildTabSelector(),
            SizedBox(height: 16.h),
            Expanded(
              child: _tabController == null 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController!,
                    children: [
                      _buildMyBatches(),
                      _buildMyTests(),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16.h, AppSpacing.screenPadding, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _isSearching
            ? _buildSearchView()
            : ScreenHeader(
                title: 'Learning',
                icon: Icons.search_rounded,
                onIconTap: () => setState(() => _isSearching = true),
              ),
      ),
    );
  }

  Widget _buildSearchView() {
    return Container(
      key: const ValueKey('search_view'),
      height: 44.w,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () => setState(() {
              _isSearching = false;
              _searchController.clear();
            }),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18.sp),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.all(10.w),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'What are you looking for?',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.textTertiary, letterSpacing: 0.3),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
              ),
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () => setState(() => _searchController.clear()),
              icon: Icon(Icons.cancel_rounded, color: AppColors.textTertiary.withValues(alpha: 0.5), size: 20.sp),
              constraints: const BoxConstraints(),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Icon(Icons.search_rounded, color: AppColors.primary.withValues(alpha: 0.3), size: 22.sp),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    if (_tabController == null) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        height: 50.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Stack(
          children: [
            // Sliding background
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: _tabController!.index == 0 ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: (1.sw - (AppSpacing.screenPadding * 2) - 8.w) / 2,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
            Row(
              children: [
                _TabButton(
                  label: 'My Batches',
                  isSelected: _tabController!.index == 0,
                  onTap: () => _tabController!.animateTo(0),
                ),
                _TabButton(
                  label: 'My Tests',
                  isSelected: _tabController!.index == 1,
                  onTap: () => _tabController!.animateTo(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBatches() {
    final batchesAsync = ref.watch(myBatchesProvider);
    final activeCount = ref.watch(activeBatchesCountProvider);

    return batchesAsync.when(
      data: (batches) {
        final filteredBatches = batches.where((b) => 
          b.title.toLowerCase().contains(_searchController.text.toLowerCase())
        ).toList();

        if (filteredBatches.isEmpty) {
          return _buildEmptyState(
            _searchController.text.isEmpty 
              ? 'You haven\'t enrolled in any batches yet.'
              : 'No batches match your search.',
            cta: _searchController.text.isEmpty ? 'Explore Courses' : null,
            onCta: () => context.go('/explore'),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(myBatchesProvider),
          child: ListView.builder(
            key: const ValueKey('batches_list'),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: filteredBatches.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 20.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Purchased Batches', style: AppTextStyles.heading2),
                      if (activeCount > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '$activeCount Enrolled',
                            style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                );
              }
              final batch = filteredBatches[index - 1];
              return BatchCard(
                title: batch.title,
                instructor: batch.instructorName,
                lessonCount: batch.totalLessons.toString(),
                progress: null,
                onDetails: () => context.push('/batch/${batch.id}/dashboard'),
                onContinue: () => context.push('/course/${batch.id}/player'),
              );
            },
          ),
        );
      },
      loading: () => _buildShimmerList(),
      error: (error, _) => _buildErrorState(() => ref.invalidate(myBatchesProvider)),
    );
  }

  Widget _buildMyTests() {
    final enrollmentAsync = ref.watch(myEnrolledTestsProvider);

    return enrollmentAsync.when(
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return _buildEmptyState('No test series found matching your criteria.');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(myEnrolledTestsProvider),
          child: ListView.builder(
            key: const ValueKey('tests_list'),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: enrollments.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.only(top: 8.h, bottom: 20.h),
                  child: Text('My Test Series', style: AppTextStyles.heading2),
                );
              }
              final e = enrollments[index - 1];
              final s = e['test_series'];
              return _buildTestItem(e, s);
            },
          ),
        );
      },
      loading: () => _buildShimmerList(),
      error: (err, _) => _buildErrorState(() => ref.invalidate(myEnrolledTestsProvider)),
    );
  }

  Widget _buildTestItem(Map<String, dynamic> enrollment, Map<String, dynamic> series) {
    final isCompleted = enrollment['status'] == 'Completed';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.successLight : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  enrollment['status'].toUpperCase(),
                  style: TextStyle(
                    color: isCompleted ? AppColors.success : AppColors.warning,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isCompleted && enrollment['score'] != null)
                Text(
                  'Score: ${enrollment['score']}/${enrollment['total_marks']}',
                  style: AppTextStyles.heading4.copyWith(color: AppColors.primary, fontSize: 13.sp),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(series['title'], style: AppTextStyles.heading3.copyWith(fontSize: 16.sp)),
          SizedBox(height: 4.h),
          Text('${series['total_tests']} Tests • ${series['category']}', style: AppTextStyles.caption),
          SizedBox(height: 16.h),
          Divider(height: 1, color: AppColors.divider),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/test/${series['id']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(isCompleted ? 'Re-take Test' : 'Continue Test', style: AppTextStyles.buttonSm),
                ),
              ),
              SizedBox(width: 12.w),
              OutlinedButton(
                onPressed: () => context.push('/test/${series['id']}/results'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: Text('Analysis', style: AppTextStyles.buttonSm.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: 4,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: Colors.white.withValues(alpha: 0.5),
        child: Container(
          height: 160.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, {String? cta, VoidCallback? onCta}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined, size: 72.sp, color: AppColors.textTertiary.withValues(alpha: 0.3)),
            SizedBox(height: 24.h),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (cta != null) ...[
              SizedBox(height: 32.h),
              SizedBox(
                width: 200.w,
                child: ElevatedButton(
                  onPressed: onCta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Text(cta, style: AppTextStyles.button),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48.sp),
          SizedBox(height: 16.h),
          Text('Failed to load content', style: AppTextStyles.bodyMedium),
          TextButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
