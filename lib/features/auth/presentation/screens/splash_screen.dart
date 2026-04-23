import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _stage = 1; // 1: Simple Logo, 2: Main Brand

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.forward();

    // Stage 1: Simple Logo (2.5 seconds total)
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _stage = 2);
        _controller.reset();
        _controller.forward();
        
        // Stage 2: Main Brand (3 seconds from transition start)
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) {
            ref.read(splashFinishedProvider.notifier).state = true;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: _stage == 1 ? _buildStage1() : _buildStage2(),
      ),
    );
  }

  Widget _buildStage1() {
    return Container(
      key: const ValueKey('stage1'),
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logos/logo_simple.png',
              width: 240.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage2() {
    return Container(
      key: const ValueKey('stage2'),
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logos/logo_with_name.png',
                  width: 280.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
          // Loading indicator
          FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeIn)),
            child: SizedBox(
              width: 28.w,
              height: 28.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          SizedBox(height: 48.h),
        ],
      ),
    );
  }
}
