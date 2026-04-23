import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/social_model.dart';
import '../../providers/socials_provider.dart';

class SocialModal extends ConsumerWidget {
  const SocialModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialsAsync = ref.watch(socialsProvider);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Follow Us',
            style: AppTextStyles.heading2,
          ),
          SizedBox(height: 8.h),
          Text(
            'Stay connected with us on social media for latest updates and news.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 32.h),
          socialsAsync.when(
            data: (socials) => _buildSocialGrid(context, socials),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Failed to load social links', style: AppTextStyles.bodySm.copyWith(color: AppColors.error))),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildSocialGrid(BuildContext context, SocialModel socials) {
    final List<_SocialItem> activeSocials = [
      if (socials.instagram.isNotEmpty)
        _SocialItem(
          name: 'Instagram',
          url: socials.instagramHref,
          icon: _SocialIcons.instagram,
          color: const Color(0xFFE4405F),
        ),
      if (socials.facebook.isNotEmpty)
        _SocialItem(
          name: 'Facebook',
          url: socials.facebookHref,
          icon: _SocialIcons.facebook,
          color: const Color(0xFF1877F2),
        ),
      if (socials.whatsapp.isNotEmpty || socials.phone.isNotEmpty)
        _SocialItem(
          name: 'WhatsApp',
          url: socials.whatsappHref,
          icon: _SocialIcons.whatsapp,
          color: const Color(0xFF25D366),
        ),
      if (socials.youtube.isNotEmpty)
        _SocialItem(
          name: 'YouTube',
          url: socials.youtubeHref,
          icon: _SocialIcons.youtube,
          color: const Color(0xFFFF0000),
        ),
      if (socials.telegram.isNotEmpty)
        _SocialItem(
          name: 'Telegram',
          url: socials.telegramHref,
          icon: _SocialIcons.telegram,
          color: const Color(0xFF26A5E4),
        ),
      if (socials.twitter.isNotEmpty)
        _SocialItem(
          name: 'X (Twitter)',
          url: socials.twitterHref,
          icon: _SocialIcons.twitter,
          color: const Color(0xFF000000),
        ),
      if (socials.linkedin.isNotEmpty)
        _SocialItem(
          name: 'LinkedIn',
          url: socials.linkedinHref,
          icon: _SocialIcons.linkedin,
          color: const Color(0xFF0077B5),
        ),
    ];

    if (activeSocials.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            Icon(Icons.link_off_rounded, size: 48.sp, color: AppColors.textTertiary),
            SizedBox(height: 12.h),
            Text('No social handles connected yet', style: AppTextStyles.bodySm),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 20.h,
        childAspectRatio: 0.9,
      ),
      itemCount: activeSocials.length,
      itemBuilder: (context, index) {
        final item = activeSocials[index];
        return InkWell(
          onTap: () => _launchURL(item.url),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.string(
                    item.icon,
                    width: 30.w,
                    height: 30.w,
                    colorFilter: ColorFilter.mode(item.color, BlendMode.srcIn),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelBold.copyWith(fontSize: 11.sp),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SocialItem {
  final String name;
  final String url;
  final String icon;
  final Color color;

  const _SocialItem({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });
}

class _SocialIcons {
  static const String instagram = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"></path><line x1="17.5" y1="6.5" x2="17.51" y2="6.5"></line></svg>''';
  static const String facebook = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"></path></svg>''';
  static const String whatsapp = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 1 1-7.6-11.7 8.38 8.38 0 0 1 3.8.9L21 3z"></path></svg>''';
  static const String youtube = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22.54 6.42a2.78 2.78 0 0 0-1.94-2C18.88 4 12 4 12 4s-6.88 0-8.6.46a2.78 2.78 0 0 0-1.94 2A29 29 0 0 0 1 11.75a29 29 0 0 0 .46 5.33A2.78 2.78 0 0 0 3.4 19c1.72.46 8.6.46 8.6.46s6.88 0 8.6-.46a2.78 2.78 0 0 0 1.94-2 29 29 0 0 0 .46-5.25 29 29 0 0 0-.46-5.33z"></path><polygon points="9.75 15.02 15.5 11.75 9.75 8.48 9.75 15.02"></polygon></svg>''';
  static const String telegram = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="22" y1="2" x2="11" y2="13"></line><polygon points="22 2 15 22 11 13 2 9 22 2"></polygon></svg>''';
  static const String twitter = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 3a10.9 10.9 0 0 1-3.14 1.53 4.48 4.48 0 0 0-7.86 3v1A10.66 10.66 0 0 1 3 4s-4 9 5 13a11.64 11.64 0 0 1-7 2c9 5 20 0 20-11.5a4.5 4.5 0 0 0-.08-.83A7.72 7.72 0 0 0 23 3z"></path></svg>''';
  static const String linkedin = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 8a6 6 0 0 1 6 6v7h-4v-7a2 2 0 0 0-2-2 2 2 0 0 0-2 2v7h-4v-7a6 6 0 0 1 6-6z"></path><rect x="2" y="9" width="4" height="12"></rect><circle cx="4" cy="4" r="2"></circle></svg>''';
}
