import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/notification_tile.dart';
import '../../domain/models/notification_models.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20.sp, color: AppColors.textPrimary),
        ),
        title: Text('Notifications',
            style: AppTextStyles.heading4.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(notificationControllerProvider.notifier).markAllAsRead(),
            icon: Icon(Icons.done_all_rounded,
                size: 22.sp, color: AppColors.primary),
            tooltip: 'Mark all as read',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          final grouped = _groupNotifications(notifications);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsStreamProvider),
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                if (grouped['today']!.isNotEmpty) ...[
                  Text('Today', style: AppTextStyles.heading4),
                  SizedBox(height: 12.h),
                  ...grouped['today']!.map((n) => _buildTile(n, ref)),
                  SizedBox(height: 8.h),
                ],
                if (grouped['yesterday']!.isNotEmpty) ...[
                  Text('Yesterday', style: AppTextStyles.heading4),
                  SizedBox(height: 12.h),
                  ...grouped['yesterday']!.map((n) => _buildTile(n, ref)),
                  SizedBox(height: 8.h),
                ],
                if (grouped['older']!.isNotEmpty) ...[
                  Text('Older', style: AppTextStyles.heading4),
                  SizedBox(height: 12.h),
                  ...grouped['older']!.map((n) => _buildTile(n, ref)),
                ],
              ],
            ),
          );
        },
        loading: () => _buildLoadingState(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTile(NotificationModel n, WidgetRef ref) {
    return NotificationTile(
      key: ValueKey(n.id),
      icon: _getIcon(n.channel),
      iconBgColor: _getBgColor(n.channel),
      iconColor: _getIconColor(n.channel),
      title: n.title,
      body: n.message,
      timestamp: _formatTimestamp(n.createdAt),
      isUnread: !n.isRead,
      onTap: () {
        if (!n.isRead) {
          ref.read(notificationControllerProvider.notifier).markAsRead(n.id);
        }
      },
    );
  }

  Map<String, List<NotificationModel>> _groupNotifications(
      List<NotificationModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = {
      'today': <NotificationModel>[],
      'yesterday': <NotificationModel>[],
      'older': <NotificationModel>[],
    };

    for (var n in list) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (date == today) {
        groups['today']!.add(n);
      } else if (date == yesterday) {
        groups['yesterday']!.add(n);
      } else {
        groups['older']!.add(n);
      }
    }

    return groups;
  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return DateFormat('MMM d, h:mm a').format(date);
  }

  IconData _getIcon(String channel) {
    switch (channel.toLowerCase()) {
      case 'live': return Icons.videocam_rounded;
      case 'update': return Icons.auto_awesome_rounded;
      case 'quiz': return Icons.quiz_rounded;
      case 'offer': return Icons.local_offer_outlined;
      default: return Icons.notifications_none_rounded;
    }
  }

  Color _getBgColor(String channel) {
    switch (channel.toLowerCase()) {
      case 'live': return AppColors.errorLight;
      case 'update': return AppColors.primaryLight;
      case 'quiz': return AppColors.successLight;
      default: return const Color(0xFFF3F4F6);
    }
  }

  Color _getIconColor(String channel) {
    switch (channel.toLowerCase()) {
      case 'live': return AppColors.error;
      case 'update': return AppColors.primary;
      case 'quiz': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64.sp, color: AppColors.textTertiary),
          SizedBox(height: 16.h),
          Text('No notifications yet',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: 5,
        itemBuilder: (_, _) => Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    );
  }
}
