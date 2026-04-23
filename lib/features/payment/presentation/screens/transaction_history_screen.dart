import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  final List<_TransactionData> _transactions = const [
    _TransactionData(
      title: 'BPSC 2026 Complete Foundation Batch',
      date: '28 Mar 2026',
      time: '10:45 AM',
      amount: '₹2,999',
      status: 'Success',
      method: 'UPI • Google Pay',
      transactionId: 'TXN20260328104523',
    ),
    _TransactionData(
      title: 'SSC Mega Test Series 2025',
      date: '15 Mar 2026',
      time: '02:30 PM',
      amount: '₹499',
      status: 'Success',
      method: 'Card • ****4521',
      transactionId: 'TXN20260315143012',
    ),
    _TransactionData(
      title: 'Railway ALP & Tech Guaranteed Batch',
      date: '01 Mar 2026',
      time: '06:15 PM',
      amount: '₹999',
      status: 'Failed',
      method: 'UPI • PhonePe',
      transactionId: 'TXN20260301181502',
    ),
    _TransactionData(
      title: 'Banking IBPS PO Crash Course',
      date: '20 Feb 2026',
      time: '11:00 AM',
      amount: '₹1,299',
      status: 'Success',
      method: 'Net Banking • SBI',
      transactionId: 'TXN20260220110034',
    ),
    _TransactionData(
      title: 'Current Affairs Monthly Pack',
      date: '05 Feb 2026',
      time: '04:20 PM',
      amount: '₹199',
      status: 'Refunded',
      method: 'Wallet • Amazon Pay',
      transactionId: 'TXN20260205162089',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        title: Text('Transaction History', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary strip
          Container(
            margin: EdgeInsets.all(AppSpacing.screenPadding),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(value: '₹5,995', label: 'Total Spent'),
                Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
                _SummaryItem(value: '4', label: 'Courses'),
                Container(width: 1, height: 40.h, color: Colors.white.withValues(alpha: 0.3)),
                _SummaryItem(value: '1', label: 'Test Series'),
              ],
            ),
          ),
          // Transaction list
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final txn = _transactions[index];
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              color: txn.status == 'Success'
                                  ? AppColors.successLight
                                  : txn.status == 'Refunded'
                                      ? AppColors.warningLight
                                      : AppColors.errorLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              txn.status == 'Success'
                                  ? Icons.check_circle_rounded
                                  : txn.status == 'Refunded'
                                      ? Icons.replay_rounded
                                      : Icons.error_rounded,
                              color: txn.status == 'Success'
                                  ? AppColors.success
                                  : txn.status == 'Refunded'
                                      ? AppColors.warning
                                      : AppColors.error,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(txn.title, style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
                                SizedBox(height: 4.h),
                                Text('${txn.date} • ${txn.time}', style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(txn.amount, style: AppTextStyles.bodyMedium.copyWith(fontSize: 16.sp)),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: txn.status == 'Success'
                                      ? AppColors.successLight
                                      : txn.status == 'Refunded'
                                          ? AppColors.warningLight
                                          : AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  txn.status,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: txn.status == 'Success'
                                        ? AppColors.success
                                        : txn.status == 'Refunded'
                                            ? AppColors.warning
                                            : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(txn.method, style: AppTextStyles.caption.copyWith(fontSize: 12.sp)),
                            Row(
                              children: [
                                Text('ID: ${txn.transactionId.substring(0, 12)}...', style: AppTextStyles.captionMedium.copyWith(fontSize: 11.sp)),
                                SizedBox(width: 4.w),
                                Icon(Icons.copy_rounded, size: 14.sp, color: AppColors.textTertiary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white)),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _TransactionData {
  final String title;
  final String date;
  final String time;
  final String amount;
  final String status;
  final String method;
  final String transactionId;

  const _TransactionData({
    required this.title,
    required this.date,
    required this.time,
    required this.amount,
    required this.status,
    required this.method,
    required this.transactionId,
  });
}
