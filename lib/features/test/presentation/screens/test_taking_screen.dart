import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../providers/test_providers.dart';
import '../../domain/models/test_series_model.dart';

class TestTakingScreen extends ConsumerStatefulWidget {
  final String testId;
  const TestTakingScreen({super.key, required this.testId});

  @override
  ConsumerState<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends ConsumerState<TestTakingScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _answers = {};
  int? _selectedOption;
  
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerInitialized = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    if (_timerInitialized) return;
    _remainingSeconds = minutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _submitTest();
      }
    });
    _timerInitialized = true;
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _submitTest() {
    context.pushReplacement('/test/${widget.testId}/results');
  }

  @override
  Widget build(BuildContext context) {
    final testAsync = ref.watch(testDetailProvider(widget.testId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: testAsync.when(
        data: (test) {
          _startTimer(test.durationMinutes);
          return _buildTestContent(test);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildTestContent(TestModel test) {
    final questions = test.questions ?? [];
    if (questions.isEmpty) return const Center(child: Text('No questions found for this test.'));

    final currentQuestion = questions[_currentQuestionIndex];
    final totalQuestions = questions.length;

    return SafeArea(
      child: Column(
        children: [
          // Header bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 12.h),
            color: AppColors.surface,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _showExitDialog(context),
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.close_rounded),
                      ),
                    ),
                    Expanded(child: Center(child: Text(test.title, style: AppTextStyles.heading4, overflow: TextOverflow.ellipsis))),
                    // Timer
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: _remainingSeconds < 300 ? AppColors.errorLight : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, color: _remainingSeconds < 300 ? AppColors.error : AppColors.primary, size: 18.sp),
                          SizedBox(width: 6.w),
                          Text(_formatTime(_remainingSeconds), style: AppTextStyles.bodyMedium.copyWith(color: _remainingSeconds < 300 ? AppColors.error : AppColors.primary, fontSize: 14.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${_currentQuestionIndex + 1} of $totalQuestions', style: AppTextStyles.caption),
                    Text('${_answers.length} answered', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / totalQuestions,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6.h,
                  ),
                ),
              ],
            ),
          ),
          // Question & Options
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  // Question
                  Text(
                    currentQuestion.question,
                    style: AppTextStyles.heading3.copyWith(fontSize: 18.sp, height: 1.4),
                  ),
                  SizedBox(height: 28.h),
                  // Options
                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedOption == index;
                    final optionLabel = String.fromCharCode(65 + index);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedOption = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.5) : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  optionLabel,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Text(
                                option,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 24.h),
                  // Question Navigator
                  Text('Question Navigator', style: AppTextStyles.heading4.copyWith(fontSize: 14.sp)),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: List.generate(totalQuestions, (index) {
                      final isAnswered = _answers.containsKey(index);
                      final isCurrent = index == _currentQuestionIndex;
                      return GestureDetector(
                        onTap: () {
                          if (_selectedOption != null) {
                            _answers[_currentQuestionIndex] = _selectedOption!;
                          }
                          setState(() {
                            _currentQuestionIndex = index;
                            _selectedOption = _answers[index];
                          });
                        },
                        child: Container(
                          width: 38.w,
                          height: 38.w,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary
                                : isAnswered
                                    ? AppColors.successLight
                                    : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: isCurrent ? null : Border.all(color: isAnswered ? AppColors.success : AppColors.border),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isCurrent ? Colors.white : isAnswered ? AppColors.success : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
          // Bottom navigation
          Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.screenPadding, 12.h, AppSpacing.screenPadding, 12.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: OutlinedButton(
                        onPressed: _currentQuestionIndex > 0
                            ? () {
                                if (_selectedOption != null) {
                                  _answers[_currentQuestionIndex] = _selectedOption!;
                                }
                                setState(() {
                                  _currentQuestionIndex--;
                                  _selectedOption = _answers[_currentQuestionIndex];
                                });
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(color: _currentQuestionIndex > 0 ? AppColors.border : AppColors.divider),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        child: Text('Previous', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_selectedOption != null) {
                            _answers[_currentQuestionIndex] = _selectedOption!;
                          }
                          if (_currentQuestionIndex < totalQuestions - 1) {
                            setState(() {
                              _currentQuestionIndex++;
                              _selectedOption = _answers[_currentQuestionIndex];
                            });
                          } else {
                            _submitTest();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentQuestionIndex == totalQuestions - 1 ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        child: Text(
                          _currentQuestionIndex == totalQuestions - 1 ? 'Submit' : 'Next',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Exit Test?'),
        content: const Text('Your progress will be saved. You can resume later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continue')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Exit', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
