import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/outline_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class LoginScreen extends AuthScreen {
  const LoginScreen({super.key});
}

enum _AuthMode { phone, email }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  _AuthMode _mode = _AuthMode.phone;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_refresh);
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_refresh);
    _emailController.removeListener(_refresh);
    _passwordController.removeListener(_refresh);
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetEmailMode() {
    setState(() {
      _mode = _AuthMode.email;
      _obscurePassword = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emailFocusNode.requestFocus();
    });
  }

  void _resetPhoneMode() {
    setState(() {
      _mode = _AuthMode.phone;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _phoneFocusNode.requestFocus();
    });
  }

  Future<void> _continueWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Enter your mobile number.');
      return;
    }

    await ref.read(authControllerProvider.notifier).requestPhoneOtp(phone);
  }

  Future<void> _continueWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Enter a valid email address.');
      return;
    }

    if (password.trim().isEmpty) {
      _showMessage('Enter your password.');
      return;
    }

    await ref.read(authControllerProvider.notifier).signInWithEmail(email, password);
  }

  Future<void> _continueWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        _showMessage(next.errorMessage!);
        return;
      }

      if (next.status == AuthStatus.otpSent) {
        context.push('/otp');
      }
    });

    final isPhoneMode = _mode == _AuthMode.phone;
    final canContinue = isPhoneMode
        ? _phoneController.text.trim().length == 10
        : _emailController.text.trim().isNotEmpty && _emailController.text.contains('@') && _passwordController.text.trim().isNotEmpty;

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
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: Icon(Icons.school_rounded, color: AppColors.primary, size: 28.sp),
                ),
                SizedBox(height: 32.h),

                // HEADER: Title and Subtitle
                Text(
                  'Welcome to Yuva Classes',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Crack Govt Exams with Confidence',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 48.h),

                // LOGIN FORM SECTION
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isPhoneMode
                      ? Column(
                          key: const ValueKey('phone-mode'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _phoneController,
                              label: 'Phone number',
                              hintText: 'Enter your mobile number',
                              prefixWidget: Container(
                                padding: EdgeInsets.only(left: 16.w, right: 8.w),
                                child: Text(
                                  '+91',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              focusNode: _phoneFocusNode,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'We’ll send a secure 6-digit OTP to verify your number',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          key: const ValueKey('email-mode'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email address',
                              hintText: 'name@example.com',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              focusNode: _emailFocusNode,
                            ),
                            SizedBox(height: 20.h),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hintText: 'Enter your password',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              focusNode: _passwordFocusNode,
                            ),
                          ],
                        ),
                ),
                SizedBox(height: 32.h),

                PrimaryButton(
                  text: isPhoneMode ? 'Send OTP' : 'Login',
                  isLoading: authState.isLoading,
                  onPressed: canContinue && !authState.isLoading
                      ? () async {
                          if (isPhoneMode) {
                            await _continueWithPhone();
                          } else {
                            await _continueWithEmail();
                          }
                        }
                      : null,
                ),
                SizedBox(height: 40.h),

                // SECONDARY LOGIN OPTIONS
                if (isPhoneMode) ...[
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'Alternative login',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  AppOutlineButton(
                    text: 'Continue with Google',
                    iconWidget: SvgPicture.asset(
                      'assets/images/google_logo.svg',
                      width: 20.w,
                      height: 20.w,
                    ),
                    onPressed: authState.isLoading ? null : _continueWithGoogle,
                  ),
                  SizedBox(height: 16.h),
                  Center(
                    child: TextButton(
                      onPressed: authState.isLoading ? null : _resetEmailMode,
                      child: RichText(
                        text: TextSpan(
                          text: 'Prefer email? ',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                          children: [
                            TextSpan(
                              text: 'Use email instead',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: TextButton(
                      onPressed: authState.isLoading ? null : _resetPhoneMode,
                      child: Text(
                        'Back to phone login',
                        style: AppTextStyles.buttonSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 60.h),

                // BOTTOM: Terms & Privacy
                Center(
                  child: Column(
                    children: [
                      Text(
                        'By continuing, you agree to our',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 11.sp),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Terms of Service',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'and',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 11.sp),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Privacy Policy',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
