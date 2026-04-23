import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _didInit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required.')),
      );
      return;
    }

    await ref.read(profileControllerProvider.notifier).updateProfile(
          fullName: fullName,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );

    final nextState = ref.read(profileControllerProvider);
    if (!mounted) return;

    if (nextState.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nextState.error!),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    if (!_didInit && profile != null) {
      _didInit = true;
      _nameController.text = profile.fullName ?? '';
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phone ?? '';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Edit Profile', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            _buildAvatarSection(profile?.avatarUrl),
            SizedBox(height: 24.h),
            _buildFormSection(),
            SizedBox(height: 24.h),
            PrimaryButton(
              text: 'Save Changes',
              isLoading: state.updating,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(String? avatarUrl) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 96.w,
            height: 96.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
            child: (avatarUrl == null || avatarUrl.trim().isEmpty)
                ? Icon(Icons.person_rounded, size: 52.sp, color: AppColors.primary)
                : ClipOval(child: Image.network(avatarUrl, fit: BoxFit.cover)),
          ),
        ),
        SizedBox(height: 8.h),
        Text('Avatar updates are managed from backend settings.', style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          CustomTextField(
            label: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outline_rounded,
            controller: _nameController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Email Address',
            hintText: 'Email',
            prefixIcon: Icons.mail_outline_rounded,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            readOnly: true,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Phone Number',
            hintText: 'Enter phone number',
            prefixIcon: Icons.phone_outlined,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
