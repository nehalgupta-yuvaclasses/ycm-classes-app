import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/models/auth_models.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/screens/auth/complete_profile_screen.dart';
import '../../features/auth/screens/auth/forgot_password_screen.dart';
import '../../features/auth/screens/auth/login_screen.dart';
import '../../features/auth/screens/auth/otp_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/explore/presentation/screens/search_results_screen.dart';
import '../../features/batch/presentation/screens/batch_screen.dart';
import '../../features/batch/presentation/screens/batch_dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/certificates_screen.dart';
import '../../features/profile/presentation/screens/downloads_screen.dart';
import '../../features/course/presentation/screens/course_detail_screen.dart';
import '../../features/course/presentation/screens/course_player_screen.dart';
import '../../features/course/presentation/screens/live_class_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/payment/presentation/screens/checkout_screen.dart';
import '../../features/payment/presentation/screens/transaction_history_screen.dart';
import '../../features/test/presentation/screens/test_taking_screen.dart';
import '../../features/test/presentation/screens/test_results_screen.dart';
import '../../features/settings/presentation/screens/legal_content_screen.dart';
import '../widgets/main_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final storageService = ref.watch(storageServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
        final isBooting = authState.status == AuthStatus.initial || authState.restoringSession;
      final isSplashFinished = ref.watch(splashFinishedProvider);

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/complete-profile' ||
          state.matchedLocation == '/forgot-password';

      final isSplash = state.matchedLocation == '/splash';

      if (isBooting || !isSplashFinished) {
        return isSplash ? null : '/splash';
      }

      if (authState.status == AuthStatus.otpSent) {
        return state.matchedLocation == '/otp' ? null : '/otp';
      }

      if (authState.status == AuthStatus.needsOnboarding) {
        return state.matchedLocation == '/complete-profile' ? null : '/complete-profile';
      }

      if (!authState.isAuthenticated) {
        // Not logged in
        if (isSplash) {
          return storageService.isOnboardingCompleted ? '/login' : '/onboarding';
        }
        if (!isAuthRoute) return '/login';
      } else {
        // Logged in
        final targetHome = '/home'; // Simplified for now since role logic is in profiles table

        if (isSplash || isAuthRoute) return targetHome;
      }

      return null;
    },
    routes: [
      // Auth flow
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('This app is currently available only for student accounts.'),
          ),
        ),
      ),
      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/batch',
                builder: (context, state) => const BatchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Detail routes outside shell
      GoRoute(
        path: '/course/:id',
        builder: (context, state) => CourseDetailScreen(courseId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/course/:id/player',
        builder: (context, state) => CoursePlayerScreen(courseId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/live-class',
        builder: (context, state) {
          final args = state.extra;
          if (args is LiveClassArgs) {
            return LiveClassScreen(args: args);
          }

          return const Scaffold(
            body: Center(
              child: Text('Missing live class details.'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/batch/:id/dashboard',
        builder: (context, state) => BatchDashboardScreen(batchId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/checkout/:courseId',
        builder: (context, state) => CheckoutScreen(courseId: state.pathParameters['courseId'] ?? ''),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/certificates',
        builder: (context, state) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/downloads',
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchResultsScreen(query: state.uri.queryParameters['q']),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionHistoryScreen(),
      ),
      GoRoute(
        path: '/test/:id',
        builder: (context, state) => TestTakingScreen(testId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/test/:id/results',
        builder: (context, state) => TestResultsScreen(testId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const LegalContentScreen(type: LegalContentType.privacyPolicy),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const LegalContentScreen(type: LegalContentType.termsOfService),
      ),
    ],
  );
});
