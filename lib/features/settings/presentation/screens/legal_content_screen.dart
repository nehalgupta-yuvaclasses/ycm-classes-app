import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';

enum LegalContentType { privacyPolicy, termsOfService }

class LegalContentScreen extends StatelessWidget {
  final LegalContentType type;

  const LegalContentScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final String title = type == LegalContentType.privacyPolicy 
        ? 'Privacy Policy' 
        : 'Terms of Service';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, title),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last Updated: April 2026',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
              SizedBox(height: 24.h),
              if (type == LegalContentType.privacyPolicy)
                ..._buildPrivacyPolicyContent()
              else
                ..._buildTermsOfServiceContent(),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 24.sp),
      ),
      title: Text(
        title,
        style: AppTextStyles.heading3.copyWith(fontSize: 18.sp),
      ),
    );
  }

  List<Widget> _buildPrivacyPolicyContent() {
    return [
      _buildSection('1. Introduction', 'Welcome to Yuva Classes. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you visit our application.'),
      _buildSection('2. Data Collection', 'We collect several different types of information for various purposes to provide and improve our service to you. This includes: Email address, First name and last name, Phone number, and Usage data.'),
      _buildSection('3. Use of Data', 'Yuva Classes uses the collected data for various purposes: To provide and maintain the service, to notify you about changes to our service, to provide customer care and support, and to monitor the usage of the service.'),
      _buildSection('4. Data Protection', 'The security of your data is important to us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your personal data, we cannot guarantee its absolute security.'),
      _buildSection('5. Your Rights', 'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to request access, correction, erasure, or restriction of your personal data.'),
    ];
  }

  List<Widget> _buildTermsOfServiceContent() {
    return [
      _buildSection('1. Acceptance of Terms', 'By accessing and using the Yuva Classes application, you accept and agree to be bound by the terms and provision of this agreement.'),
      _buildSection('2. User Accounts', 'When you create an account with us, you must provide information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the terms, which may result in immediate termination of your account.'),
      _buildSection('3. Content and Courses', 'All course materials, including videos, PDFs, and assessments, are the intellectual property of Yuva Classes or its content providers. You are granted a limited, non-exclusive license to use the content for personal, non-commercial purposes.'),
      _buildSection('4. Payment and Refunds', 'Payments for courses are processed through secure payment gateways. Refund policies for each course are mentioned at the time of enrollment. Generally, digital content access is non-refundable once started.'),
      _buildSection('5. Termination', 'We may terminate or suspend access to our service immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.'),
    ];
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading4.copyWith(color: AppColors.textPrimary)),
          SizedBox(height: 8.h),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
