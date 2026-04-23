import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../course/presentation/providers/course_providers.dart';
import '../../../course/domain/models/course_model.dart';
import '../../data/services/payment_remote_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CheckoutScreen({super.key, required this.courseId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _selectedPayment = 0;
  late final Razorpay _razorpay;
  late final PaymentRemoteService _paymentRemoteService;
  double _gstRate = 18;
  bool _isPaymentEnabled = true;
  bool _isLaunchingCheckout = false;
  bool _isVerifyingPayment = false;
  bool _isLoadingPaymentConfig = true;
  String? _paymentMessage;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'icon': Icons.phone_android_rounded, 'name': 'UPI', 'desc': 'Google Pay, PhonePe, Paytm'},
    {'icon': Icons.credit_card_rounded, 'name': 'Credit / Debit Card', 'desc': 'Visa, Mastercard, RuPay'},
    {'icon': Icons.account_balance_wallet_rounded, 'name': 'Wallets', 'desc': 'Amazon Pay, MobiKwik'},
    {'icon': Icons.account_balance_rounded, 'name': 'Net Banking', 'desc': 'All Indian Banks'},
  ];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _paymentRemoteService = PaymentRemoteService();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadPaymentConfiguration();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
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
      title: Text('Checkout', style: AppTextStyles.heading3.copyWith(fontSize: 18.sp)),
    );
  }

  Widget _buildBody() {
    // Guard: empty courseId should show error immediately
    if (widget.courseId.isEmpty) {
      return _buildErrorState('Invalid course. Please go back and try again.');
    }

    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));

    return courseAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16.h),
            Text('Loading checkout...', style: AppTextStyles.bodySm),
          ],
        ),
      ),
      error: (error, stackTrace) {
        debugPrint('CheckoutScreen error: $error\n$stackTrace');
        return _buildErrorState('Something went wrong. Please try again.');
      },
      data: (course) => _buildCheckoutContent(course),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48.sp),
            SizedBox(height: 16.h),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: () {
                if (widget.courseId.isNotEmpty) {
                  ref.invalidate(courseDetailProvider(widget.courseId));
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutContent(CourseModel course) {
    final price = course.price;
    final originalPriceValue = course.originalPrice ?? price;
    final hasDiscount = originalPriceValue > price;
    final gstAmount = (price * _gstRate / 100).round();
    final finalAmount = price.round() + gstAmount;
    final lessonCount = course.lessons?.length ?? 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              16.h,
              AppSpacing.screenPadding,
              24.h,
            ),
            children: [
              _buildCourseOverviewCard(course, lessonCount),
              SizedBox(height: 20.h),
              if (_paymentMessage != null) ...[
                _buildStatusBanner(_paymentMessage!),
                SizedBox(height: 16.h),
              ],
              _buildPriceSummaryCard(price, originalPriceValue, hasDiscount, gstAmount, finalAmount),
              SizedBox(height: 20.h),
              _buildPaymentMethodSection(),
              SizedBox(height: 20.h),
              _buildCheckoutInfoCard(),
            ],
          ),
        ),
        _buildBottomCTA(course, finalAmount),
      ],
    );
  }

  // ─── Course Summary Card ───────────────────────────────────────────

  Widget _buildCourseOverviewCard(CourseModel course, int lessonCount) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCourseThumbnail(course),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: AppTextStyles.heading4.copyWith(fontSize: 17.sp, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'By ${course.instructorName}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _buildMetaChip(course.categoryName),
                        _buildMetaChip('$lessonCount lessons'),
                        _buildMetaChip('${course.studentsCount} students'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  label: 'Course fee',
                  value: '₹${course.price.toStringAsFixed(0)}',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatTile(
                  label: 'Access',
                  value: 'After payment',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseThumbnail(CourseModel course) {
    final thumbnailUrl = course.thumbnailUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 84.w,
        height: 84.w,
        color: AppColors.primaryLight.withValues(alpha: 0.35),
        child: thumbnailUrl == null || thumbnailUrl.isEmpty
            ? Icon(Icons.school_rounded, color: AppColors.primary, size: 36.sp)
            : CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(Icons.school_rounded, color: AppColors.primary, size: 36.sp),
              ),
      ),
    );
  }

  Widget _buildMetaChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildStatTile({required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
          SizedBox(height: 4.h),
          Text(value, style: AppTextStyles.heading4.copyWith(fontSize: 15.sp)),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard(
    double price,
    double originalPriceValue,
    bool hasDiscount,
    int gstAmount,
    int finalAmount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price summary', style: AppTextStyles.heading3),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Course price', value: '₹${price.toStringAsFixed(0)}'),
              if (hasDiscount) ...[
                SizedBox(height: 12.h),
                _SummaryRow(
                  label: 'Discount',
                  value: '- ₹${(originalPriceValue - price).round()}',
                  valueColor: AppColors.success,
                ),
              ],
              SizedBox(height: 12.h),
              _SummaryRow(label: 'GST (${_gstRate.toStringAsFixed(0)}%)', value: '₹$gstAmount'),
              SizedBox(height: 16.h),
              Divider(color: AppColors.divider, thickness: 1),
              SizedBox(height: 16.h),
              _SummaryRow(
                label: 'Total amount',
                value: '₹$finalAmount',
                isBold: true,
                valueColor: AppColors.textPrimary,
              ),
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'Access is activated after successful payment verification.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Payment Method ────────────────────────────────────────────────

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose payment method', style: AppTextStyles.heading3),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: _paymentMethods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedPayment = index),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Row(
                        children: [
                          Container(
                            width: 48.w,
                            height: 48.w,
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Icon(method['icon'] as IconData, color: AppColors.primary, size: 22.sp),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(method['name'] as String, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                SizedBox(height: 2.h),
                                Text(method['desc'] as String, style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
                              ],
                            ),
                          ),
                          _buildRadioIndicator(index),
                        ],
                      ),
                    ),
                  ),
                  if (index < _paymentMethods.length - 1) Divider(indent: 72.w, height: 0),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioIndicator(int index) {
    final isSelected = _selectedPayment == index;
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusBanner(String message) {
    final isError = message.toLowerCase().contains('failed') || message.toLowerCase().contains('error');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        message,
        style: AppTextStyles.bodySm.copyWith(
          color: isError ? AppColors.error : AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCheckoutInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.divider),
            ),
            child: Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure checkout', style: AppTextStyles.heading4),
                SizedBox(height: 4.h),
                Text(
                  'Payments are processed by Razorpay. After verification, your course access opens automatically.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom CTA ────────────────────────────────────────────────────

  Widget _buildBottomCTA(CourseModel course, int finalAmount) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total payable', style: AppTextStyles.captionMedium.copyWith(fontSize: 12.sp)),
                Text('₹$finalAmount', style: AppTextStyles.price.copyWith(fontSize: 20.sp)),
              ],
              ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoadingPaymentConfig || !_isPaymentEnabled || _isLaunchingCheckout || _isVerifyingPayment
                    ? null
                    : () => _startCheckout(course, finalAmount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLaunchingCheckout || _isVerifyingPayment) ...[
                      SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        _isVerifyingPayment ? 'Verifying payment' : 'Opening Razorpay',
                        style: AppTextStyles.button.copyWith(fontSize: 15.sp),
                      ),
                    ] else ...[
                      Text(
                        _isPaymentEnabled ? 'Proceed to pay' : 'Payments disabled',
                        style: AppTextStyles.button.copyWith(fontSize: 15.sp),
                      ),
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_rounded, size: 20.sp, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPaymentConfiguration() async {
    try {
      final settings = await _paymentRemoteService.fetchPublicPaymentSettings();
      if (!mounted) {
        return;
      }

      setState(() {
        _gstRate = settings.gstRate;
        _isPaymentEnabled = settings.isEnabled;
        _paymentMessage = settings.isEnabled ? null : 'Payments are disabled by the admin team.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _paymentMessage = error.toString();
        _isPaymentEnabled = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPaymentConfig = false;
        });
      }
    }
  }

  Future<void> _startCheckout(CourseModel course, int finalAmount) async {
    if (!_isPaymentEnabled) {
      setState(() {
        _paymentMessage = 'Payments are disabled right now.';
      });
      return;
    }

    setState(() {
      _isLaunchingCheckout = true;
      _paymentMessage = null;
    });

    try {
      final order = await _paymentRemoteService.createRazorpayOrder(
        courseId: widget.courseId,
        amount: finalAmount.toDouble(),
      );

      final options = {
        'key': order.apiKey,
        'amount': (order.amount * 100).round(),
        'currency': order.currency,
        'name': 'Yuva Classes',
        'description': course.title,
        'order_id': order.orderId,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#111827',
        },
      };

      _razorpay.open(options);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _paymentMessage = error.toString();
        _isLaunchingCheckout = false;
      });
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifyingPayment = true;
      _paymentMessage = 'Verifying payment...';
    });

    try {
      await _paymentRemoteService.verifyRazorpayPayment(
        paymentId: response.paymentId!,
        orderId: response.orderId!,
        signature: response.signature!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _paymentMessage = 'Payment verified successfully.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified. Welcome to the course.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          context.pushReplacement('/course/${widget.courseId}/player');
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _paymentMessage = error.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLaunchingCheckout = false;
          _isVerifyingPayment = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLaunchingCheckout = false;
      _isVerifyingPayment = false;
      _paymentMessage = response.message ?? 'Payment failed. Please try again.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_paymentMessage ?? 'Payment failed. Please try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) {
      return;
    }

    setState(() {
      _paymentMessage = 'External wallet selected: ${response.walletName}';
    });
  }
}

// ─── Summary Row Widget ────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isBold ? AppTextStyles.bodyMedium : AppTextStyles.bodySm),
        Text(
          value,
          style: isBold
              ? AppTextStyles.bodyMedium.copyWith(fontSize: 16.sp)
              : AppTextStyles.bodyMedium.copyWith(color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}
