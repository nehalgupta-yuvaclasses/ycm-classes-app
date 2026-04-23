import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _resendTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = 30;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        return;
      }

      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }

  void _verify() {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP.')),
      );
      return;
    }

    ref.read(authControllerProvider.notifier).verifyOtp(code);
  }

  String _maskPhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) {
      return phone ?? '';
    }
    return '+91 ***** ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final pendingPhone = authState.pendingPhone;
    final themePin = PinTheme(
      width: 54.w,
      height: 58.h,
      textStyle: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
    );

    ref.listen(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding * 1.2, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP: Back Button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.sp),
                  ),
                ),
                SizedBox(height: 48.h),

                // HEADER: Title and Subtitle
                Text(
                  'Verify OTP',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  pendingPhone == null
                      ? 'Enter the 6-digit code sent to your mobile number.'
                      : 'We sent a 6-digit code to ${_maskPhone(pendingPhone)}.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 48.h),

                // OTP INPUT SECTION
                Pinput(
                  length: 6,
                  controller: _otpController,
                  focusNode: _focusNode,
                  defaultPinTheme: themePin,
                  focusedPinTheme: themePin.copyWith(
                    decoration: themePin.decoration!.copyWith(
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  submittedPinTheme: themePin.copyWith(
                    decoration: themePin.decoration!.copyWith(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onCompleted: (_) => _verify(),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
                SizedBox(height: 40.h),

                PrimaryButton(
                  text: 'Verify and continue',
                  isLoading: authState.isLoading,
                  onPressed: _verify,
                ),
                SizedBox(height: 24.h),

                // RESEND SECTION
                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: authState.isLoading || _secondsRemaining > 0
                            ? null
                            : () {
                                ref.read(authControllerProvider.notifier).resendOtp();
                                _startResendTimer();
                              },
                        child: RichText(
                          text: TextSpan(
                            text: "Didn't receive code? ",
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                            children: [
                              TextSpan(
                                text: _secondsRemaining > 0 ? 'Resend in $_secondsRemaining s' : 'Resend OTP',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (pendingPhone != null) ...[
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Use another number',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
