import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/category_chip.dart';
import '../../../../core/widgets/course_card.dart';
import '../../../course/presentation/providers/course_providers.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String? query;
  const SearchResultsScreen({super.key, this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late TextEditingController _searchController;
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Courses', 'Test Series', 'Batches', 'Educators'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For now, we reuse the coursesProvider but could have a specific searchQueryProvider
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search header
            Container(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12.h, AppSpacing.screenPadding, 12.h),
              color: AppColors.surface,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 22),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      height: 44.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.primary, size: 20.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: false,
                              style: TextStyle(fontSize: 15.sp),
                              onSubmitted: (value) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search courses...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 20.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            // Filter chips
            SizedBox(
              height: 40.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  return CategoryChip(
                    label: _filters[index],
                    isSelected: _selectedFilter == index,
                    onTap: () => setState(() => _selectedFilter = index),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            // Results List
            Expanded(
              child: coursesAsync.when(
                data: (courses) {
                  // Filter courses based on search text locally for this demo, 
                  // normally this would be a server-side search.
                  final filteredCourses = courses.where((c) => 
                    c.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                    c.instructorName.toLowerCase().contains(_searchController.text.toLowerCase())
                  ).toList();

                  if (filteredCourses.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
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
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: AppColors.divider,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 48.sp, color: AppColors.textTertiary),
          ),
          SizedBox(height: 20.h),
          Text('No results found', style: AppTextStyles.heading3),
          SizedBox(height: 8.h),
          Text(
            'Try a different search term or\nbrowse our categories',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(height: 1.5),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 44.h,
            child: ElevatedButton(
              onPressed: () => context.go('/explore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                padding: EdgeInsets.symmetric(horizontal: 32.w),
              ),
              child: Text('Browse Courses', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
