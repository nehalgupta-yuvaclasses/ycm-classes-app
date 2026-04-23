import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/storage_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Welcome to\nYuva Classes',
      description: 'Your gateway to mastering government competitive exams with the right strategy and guidance.',
      image: 'assets/images/onboarding/onboarding_1.png',
    ),
    _OnboardingData(
      title: 'Learn Smart,\nNot Hard',
      description: 'Access structured lessons, practice tests, and study materials designed for real exam success.',
      image: 'assets/images/onboarding/onboarding_2.png',
    ),
    _OnboardingData(
      title: 'Stay Consistent\n& Improve',
      description: 'Track your progress, attend live classes, and move closer to your goal every day.',
      image: 'assets/images/onboarding/onboarding_3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(storageServiceProvider).setOnboardingCompleted(true);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FF),
              Color(0xFFE9ECFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skip Button
              _TopBar(onSkip: _completeOnboarding),
              
              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    return _OnboardingPage(data: _pages[index], index: index);
                  },
                ),
              ),
              
              // Bottom Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: 32.h,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Smooth Page Indicator
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 8.w,
                        dotHeight: 8.w,
                        activeDotColor: const Color(0xFF4A6CF7),
                        dotColor: Colors.black12,
                        spacing: 8.w,
                        expansionFactor: 3.5,
                      ),
                    ),
                    SizedBox(height: 40.h),
                    
                    // Premium CTA Button
                    _PremiumButton(
                      text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutQuart,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onSkip;
  const _TopBar({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: TextButton(
          onPressed: onSkip,
          child: Text(
            'Skip',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final int index;
  const _OnboardingPage({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          // Illustration - Center aligned for visual balance
          Center(
            child: Hero(
              tag: 'illustration_$index',
              child: Image.asset(
                data.image,
                width: 0.85.sw, // Take more screen width as requested
                height: 280.h,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 48.h),
          // Title
          Text(
            data.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
              height: 1.1,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: 16.h),
          // Description
          Text(
            data.description,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF555555),
              height: 1.5,
            ),
            textAlign: TextAlign.left,
            maxLines: 3,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PremiumButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6CF7), Color(0xFF6C63FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6CF7).withValues(alpha: 0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String image;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}
