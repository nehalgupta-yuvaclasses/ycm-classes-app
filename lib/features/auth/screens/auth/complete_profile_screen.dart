import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  String? _selectedAspirantType;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _phoneController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _emailController.removeListener(_refresh);
    _phoneController.removeListener(_refresh);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncInitialValues(UserModel? user) {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _nameController.text = user?.fullName.trim() ?? '';
    _emailController.text = user?.email.trim() ?? '';
    _phoneController.text = user?.phone?.trim() ?? '';
    _selectedAspirantType = user?.aspirantType;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  Future<void> _submit() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final isPhoneLogin = phone.isNotEmpty;

    if (fullName.isEmpty) {
      _showMessage('Enter your full name.');
      return;
    }

    if ((isPhoneLogin && email.isEmpty) || (!isPhoneLogin && email.isEmpty && (ref.read(authControllerProvider).user?.email.trim().isEmpty ?? true))) {
      _showMessage('Enter a valid email address.');
      return;
    }

    if (_selectedAspirantType == null || _selectedAspirantType!.isEmpty) {
      _showMessage('Select your aspirant type.');
      return;
    }

    await ref.read(authControllerProvider.notifier).completeOnboarding(
          fullName: fullName,
          email: email.isNotEmpty ? email : null,
          aspirantType: _selectedAspirantType!,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final phone = user?.phone?.trim() ?? '';
    final isPhoneLogin = phone.isNotEmpty;
    final emailIsLocked = user?.email.trim().isNotEmpty ?? false;

    _syncInitialValues(user);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        _showMessage(next.errorMessage!);
      }
    });

    final canSubmit = _nameController.text.trim().isNotEmpty &&
      _selectedAspirantType != null &&
      _selectedAspirantType!.isNotEmpty &&
      (emailIsLocked || _emailController.text.trim().isNotEmpty) &&
      !authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding * 1.2, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP: Logo
                Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Icon(Icons.school_rounded, color: AppColors.primary, size: 24.sp),
                    ),
                    const Spacer(),
                    Text(
                      'Yuva Classes',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),

                // HEADER: Title and Subtitle
                Text(
                  'Complete Profile',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'We need a few details before you continue.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 40.h),

                // FORM SECTION
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hintText: 'Your full name',
                  prefixIcon: Icons.person_outline_rounded,
                  focusNode: _nameFocusNode,
                ),
                SizedBox(height: 24.h),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'name@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocusNode,
                  readOnly: emailIsLocked,
                  enabled: !authState.isLoading,
                ),
                if (isPhoneLogin) ...[
                  SizedBox(height: 24.h),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    hintText: '+91 98765 43210',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    focusNode: _phoneFocusNode,
                    readOnly: true,
                  ),
                ],
                SizedBox(height: 24.h),
                Text(
                  'Aspirant Type',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAspirantType,
                  decoration: InputDecoration(
                    hintText: 'Choose your aspirant type',
                    prefixIcon: Icon(Icons.school_outlined, color: AppColors.textTertiary, size: 22.sp),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  ),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textTertiary, size: 24.sp),
                  items: aspirantTypeOptions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item, style: AppTextStyles.bodyMedium),
                        ),
                      )
                      .toList(),
                  onChanged: authState.isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedAspirantType = value;
                          });
                        },
                ),
                SizedBox(height: 48.h),

                PrimaryButton(
                  text: 'Complete Profile',
                  isLoading: authState.isLoading,
                  onPressed: canSubmit ? _submit : null,
                ),
                SizedBox(height: 24.h),
                Center(
                  child: Text(
                    isPhoneLogin
                        ? 'Your verified phone number is linked to your profile.'
                        : 'This profile will be used across all your login methods.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
