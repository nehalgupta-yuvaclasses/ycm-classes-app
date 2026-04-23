import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/widgets/settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal'),
            _buildSettingsGroup([
              SettingsTile(
                icon: Icons.person_2_outlined,
                title: 'Account Settings',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                onTap: () {},
              ),
            ]),
            SizedBox(height: 24.h),
            _buildSectionHeader('Preferences'),
            _buildSettingsGroup([
              SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                onTap: () {},
              ),
              SettingsTile(
                icon: Icons.language_rounded,
                title: 'App Language',
                trailing: 'English',
                onTap: () {},
              ),
            ]),

            SizedBox(height: 24.h),
            Center(
              child: Column(
                children: [
                  Text(
                    'Yuva Classes',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'v2.4.1 Build 2026',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 56.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 14.w),
        child: Center(
          child: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20.sp),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
      title: Text(
        'Settings',
        style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelBold.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        separatorBuilder: (context, index) => Divider(
          height: 0,
          indent: 58.w,
          endIndent: 16.w,
          color: AppColors.divider.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) => tiles[index],
      ),
    );
  }
}
