import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/models/user_model.dart';
import '../../domain/models/profile_models.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: state.loading && !state.hasData
              ? const _ProfileScreenSkeleton()
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        16.h,
                        AppSpacing.screenPadding,
                        0,
                      ),
                      child: ScreenHeader(
                        title: 'Profile',
                        icon: Icons.settings_rounded,
                        onIconTap: () => context.push('/settings'),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(profileControllerProvider.notifier)
                            .refresh(),
                        child: CustomScrollView(
                          key: const ValueKey('profile_content'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: _ProfileSummary(
                                authUser: authState.user,
                                profile: state.profile,
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  if (state.error != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 16.h),
                                      child: _ErrorBanner(
                                        message: state.error!,
                                        onRetry: () => ref
                                            .read(
                                              profileControllerProvider
                                                  .notifier,
                                            )
                                            .refresh(),
                                      ),
                                    )
                                  else
                                    SizedBox(height: 16.h),

                                  _SectionHeader(title: 'Learning Journey'),
                                  SizedBox(height: 12.h),
                                ]),
                              ),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                              ),
                              sliver: _VisualStatsGrid(stats: state.stats),
                            ),
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  SizedBox(height: 28.h),
                                  _SectionHeader(title: 'Account Settings'),
                                  SizedBox(height: 12.h),
                                  _GroupedCard(
                                    children: [
                                      SettingsTile(
                                        icon: Icons.workspace_premium_outlined,
                                        iconBgColor: const Color(0xFFF0FDF4),
                                        iconColor: const Color(0xFF16A34A),
                                        title: 'My Certificates',
                                        onTap: () =>
                                            context.push('/certificates'),
                                      ),
                                      const _MenuDivider(),
                                      SettingsTile(
                                        icon: Icons.download_done_rounded,
                                        iconBgColor: const Color(0xFFEFF6FF),
                                        iconColor: AppColors.info,
                                        title: 'Downloads',
                                        onTap: () => context.push('/downloads'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 28.h),
                                  _SectionHeader(title: 'Support & Legal'),
                                  SizedBox(height: 12.h),
                                  _GroupedCard(
                                    children: [
                                      SettingsTile(
                                        icon: Icons.policy_outlined,
                                        iconBgColor: const Color(0xFFFFF7ED),
                                        iconColor: const Color(0xFFEA580C),
                                        title: 'Privacy Policy',
                                        onTap: () =>
                                            context.push('/privacy-policy'),
                                      ),
                                      const _MenuDivider(),
                                      SettingsTile(
                                        icon: Icons.info_outline_rounded,
                                        iconBgColor: const Color(0xFFF5F3FF),
                                        iconColor: const Color(0xFF7C3AED),
                                        title: 'Terms of Service',
                                        onTap: () =>
                                            context.push('/terms-of-service'),
                                      ),
                                      const _MenuDivider(),
                                      SettingsTile(
                                        icon: Icons.help_outline_rounded,
                                        iconBgColor: const Color(0xFFF0F9FF),
                                        iconColor: const Color(0xFF0284C7),
                                        title: 'Help & Support',
                                        onTap: () => context.push('/settings'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 32.h),
                                  _buildLogoutButton(ref, authState),
                                  SizedBox(height: 48.h),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }


  Widget _buildLogoutButton(WidgetRef ref, AuthViewState authState) {
    return GestureDetector(
      onTap: () => ref.read(authControllerProvider.notifier).signOut(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authState.status == AuthStatus.loading)
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            else
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              'Sign Out',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({this.authUser, required this.profile});
  final UserModel? authUser;
  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        20.h,
        AppSpacing.screenPadding,
        12.h,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Avatar(avatarUrl: profile?.avatarUrl, size: 64.r),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile?.fullName ?? authUser?.fullName ?? 'Student',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (profile?.email != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      profile!.email!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else if (authUser?.email.isNotEmpty == true) ...[
                    SizedBox(height: 2.h),
                    Text(
                      authUser?.email ?? '',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => context.push('/edit-profile'),
              child: Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary,
                  size: 18.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualStatsGrid extends StatelessWidget {
  const _VisualStatsGrid({required this.stats});
  final UserStatsModel? stats;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.w,
        crossAxisSpacing: 12.w,
        childAspectRatio: 1.6,
      ),
      delegate: SliverChildListDelegate([
        _StatCard(
          label: 'Enrolled',
          value: stats?.enrolledCoursesCount.toString() ?? '0',
          icon: Icons.auto_stories_rounded,
          color: AppColors.primary,
        ),
        _StatCard(
          label: 'Attempts',
          value: stats?.attemptsCount.toString() ?? '0',
          icon: Icons.assignment_rounded,
          color: const Color(0xFFF59E0B),
        ),
        _StatCard(
          label: 'Completed',
          value: stats?.completedAttemptsCount.toString() ?? '0',
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF10B981),
        ),
        _StatCard(
          label: 'Avg Score',
          value: stats?.averageScorePercentage == null
              ? '—'
              : '${stats!.averageScorePercentage!.toStringAsFixed(0)}%',
          icon: Icons.show_chart_rounded,
          color: const Color(0xFF6366F1),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.heading4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, this.size = 48});

  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: (size / 2).r,
        backgroundColor: AppColors.primaryLight,
        child: (avatarUrl == null || avatarUrl!.trim().isEmpty)
            ? Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: (size * 0.5).sp,
              )
            : ClipOval(
                child: Image.network(
                  avatarUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: (size * 0.5).sp,
                  ),
                ),
              ),
      ),
    );
  }
}

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(indent: 52.w, height: 1, color: AppColors.divider);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _ProfileScreenSkeleton extends StatelessWidget {
  const _ProfileScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: Colors.white,
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
