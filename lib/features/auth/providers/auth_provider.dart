import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_error.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthViewState>((ref) {
      return AuthController(
        authService: ref.read(authServiceProvider),
        storageService: ref.read(storageServiceProvider),
      );
    });

final splashFinishedProvider = StateProvider<bool>((ref) => false);

class AuthController extends StateNotifier<AuthViewState> {
  AuthController({
    required AuthService authService,
    required StorageService storageService,
  }) : _authService = authService,
       _storageService = storageService,
       super(AuthViewState.initial) {
    _bootstrap();
  }

  final AuthService _authService;
  final StorageService _storageService;

  StreamSubscription<firebase.User?>? _firebaseSubscription;
  StreamSubscription<supabase.AuthState>? _supabaseSubscription;
  bool _bootstrapping = false;
  bool _syncingSession = false;

  Future<void> _bootstrap() async {
    if (_bootstrapping) {
      return;
    }

    _bootstrapping = true;
    state = state.copyWith(
      status: AuthStatus.loading,
      restoringSession: true,
      clearError: true,
    );

    try {
      await _restorePendingOtp();
      await _reconcileSession();

      _firebaseSubscription?.cancel();
      _firebaseSubscription = _authService.firebaseAuthStateChanges().listen((
        _,
      ) {
        _reconcileSession();
      });

      _supabaseSubscription?.cancel();
      _supabaseSubscription = _authService.supabaseAuthStateChanges().listen((
        _,
      ) {
        _reconcileSession();
      });
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
        restoringSession: false,
      );
    } finally {
      _bootstrapping = false;
      if (state.status == AuthStatus.loading) {
        state = state.copyWith(restoringSession: false, clearError: true);
      } else {
        state = state.copyWith(restoringSession: false);
      }
    }
  }

  Future<void> _restorePendingOtp() async {
    final pendingOtp = _storageService.pendingPhoneOtp;
    if (pendingOtp == null) {
      return;
    }

    final firebaseUser = _authService.currentFirebaseUser;
    if (firebaseUser != null) {
      return;
    }

    state = state.copyWith(
      status: AuthStatus.otpSent,
      verificationId: pendingOtp.verificationId,
      resendToken: pendingOtp.resendToken,
      pendingPhone: pendingOtp.phoneNumber,
      clearUser: true,
      clearError: true,
      authMethod: AuthMethod.firebasePhone,
      restoringSession: false,
    );
  }

  Future<void> _reconcileSession() async {
    if (_syncingSession) {
      return;
    }

    _syncingSession = true;
    try {
      final lastMethod = _storageService.lastAuthMethod;
      final firebaseUser = _authService.currentFirebaseUser;
      final supabaseUser = _authService.currentSupabaseUser;

      if (lastMethod == AuthMethod.supabaseEmail.name && supabaseUser != null) {
        await _syncSupabaseUser(supabaseUser);
        return;
      }

      if ((lastMethod == AuthMethod.firebasePhone.name ||
              lastMethod == AuthMethod.google.name) &&
          firebaseUser != null) {
        await _syncFirebaseUser(
          firebaseUser,
          preferredMethod: _parseMethod(lastMethod),
        );
        return;
      }

      if (firebaseUser != null) {
        await _syncFirebaseUser(
          firebaseUser,
          preferredMethod: AuthMethod.firebasePhone,
        );
        return;
      }

      if (supabaseUser != null) {
        await _syncSupabaseUser(supabaseUser);
        return;
      }

      final pendingOtp = _storageService.pendingPhoneOtp;
      if (pendingOtp != null) {
        state = state.copyWith(
          status: AuthStatus.otpSent,
          verificationId: pendingOtp.verificationId,
          resendToken: pendingOtp.resendToken,
          pendingPhone: pendingOtp.phoneNumber,
          clearUser: true,
          clearError: true,
          authMethod: AuthMethod.firebasePhone,
        );
        return;
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearVerificationId: true,
        clearResendToken: true,
        clearPendingPhone: true,
        clearError: true,
        authMethod: AuthMethod.unknown,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    } finally {
      _syncingSession = false;
    }
  }

  Future<void> requestPhoneOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    if (!_authService.isValidIndianPhone(phoneNumber)) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage:
            'Enter a valid Indian mobile number in +91XXXXXXXXXX format.',
      );
      return;
    }

    try {
      await _authService.requestPhoneOtp(
        phoneNumber: phoneNumber,
        forceResendingToken: state.resendToken,
        onCodeSent: (verificationId, resendToken) async {
          await _storageService.setPendingPhoneOtp(
            phoneNumber: _authService.normalizeIndianPhone(phoneNumber),
            verificationId: verificationId,
            resendToken: resendToken,
          );
          state = state.copyWith(
            status: AuthStatus.otpSent,
            verificationId: verificationId,
            resendToken: resendToken,
            pendingPhone: _authService.normalizeIndianPhone(phoneNumber),
            clearUser: true,
            clearError: true,
            authMethod: AuthMethod.firebasePhone,
          );
        },
        onVerificationFailed: (error) {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: _humanizeError(error),
          );
        },
        onAutoRetrievalTimeout: (verificationId) {
          state = state.copyWith(
            status: AuthStatus.otpSent,
            verificationId: verificationId,
            pendingPhone: _authService.normalizeIndianPhone(phoneNumber),
            clearError: true,
            authMethod: AuthMethod.firebasePhone,
          );
        },
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> resendOtp() async {
    final pendingPhone = state.pendingPhone;
    if (pendingPhone == null) {
      return;
    }

    await requestPhoneOtp(pendingPhone);
  }

  Future<void> verifyOtp(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null || smsCode.trim().length != 6) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Enter the 6-digit OTP sent to your phone.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final user = await _authService.confirmPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      if (user == null) {
        throw const AppError('OTP verification failed.');
      }

      await _storageService.setLastAuthMethod(AuthMethod.firebasePhone.name);
      await _authService.signOutSupabase();
      await _clearPendingOtp();
      await _syncFirebaseUser(user, preferredMethod: AuthMethod.firebasePhone);
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final firebaseUser = await _authService.signInWithGoogle();
      if (firebaseUser == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
        return;
      }

      await _storageService.setLastAuthMethod(AuthMethod.google.name);
      await _authService.signOutSupabase();
      await _clearPendingOtp();
      await _syncFirebaseUser(firebaseUser, preferredMethod: AuthMethod.google);
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final supabaseUser = await _authService.signInWithEmail(email, password);
      if (supabaseUser == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
        return;
      }

      await _storageService.setLastAuthMethod(AuthMethod.supabaseEmail.name);
      await _authService.signOutFirebase();
      await _clearPendingOtp();
      await _syncSupabaseUser(supabaseUser);
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> signUp(String fullName, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final supabaseUser = await _authService.signUpWithEmail(email, password);
      if (supabaseUser == null) {
        throw const AppError('Account creation failed.');
      }

      final activeSupabaseUser =
          _authService.currentSupabaseUser ??
          await _authService
              .signInWithEmail(email, password)
              .catchError((_) => null);
      if (activeSupabaseUser == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage:
              'Account created. Please verify your email and sign in again.',
        );
        return;
      }

      await _storageService.setLastAuthMethod(AuthMethod.supabaseEmail.name);
      await _authService.signOutFirebase();
      await _clearPendingOtp();

      final draft =
          UserModel.empty(
            userId: activeSupabaseUser.id,
            email: activeSupabaseUser.email ?? email,
          ).copyWith(
            fullName: fullName,
            email: activeSupabaseUser.email ?? email,
            userId: activeSupabaseUser.id,
          );

      final existing = await _authService.findStudentProfile(
        userId: activeSupabaseUser.id,
        email: draft.email,
      );

      if (existing != null && existing.hasRequiredProfile) {
        final saved = await _authService.upsertStudentProfile(
          existing.mergeWith(draft),
        );
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: saved,
          clearError: true,
          authMethod: AuthMethod.supabaseEmail,
        );
        return;
      }

      state = state.copyWith(
        status: AuthStatus.needsOnboarding,
        user: draft,
        clearError: true,
        authMethod: AuthMethod.supabaseEmail,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> completeOnboarding({
    required String fullName,
    required String aspirantType,
    String? email,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No authenticated user found. Please sign in again.',
      );
      return;
    }

    final resolvedEmail = (email ?? currentUser.email).trim();
    if (resolvedEmail.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Email is required to complete onboarding.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      final updatedProfile = currentUser.copyWith(
        fullName: fullName.trim(),
        email: resolvedEmail,
        aspirantType: aspirantType,
      );
      var saved = await _authService.upsertStudentProfile(updatedProfile);

      // If Firebase auth and not yet linked, ensure identity row exists in 'users' and link
      final firebaseUid = currentUser.firebaseUid;
      if (firebaseUid != null &&
          firebaseUid.isNotEmpty &&
          saved.userId == null) {
        try {
          await _authService.ensureFirebaseUserIdentityAndLink(
            studentId: saved.id,
            email: saved.email,
            fullName: saved.fullName,
            firebaseUid: firebaseUid,
          );
          saved = saved.copyWith(userId: saved.id);
        } catch (e) {
          // Log but don't fail onboarding
          print('Identity sync error during onboarding: $e');
        }
      }

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: saved,
        clearError: true,
      );
      await _storageService.setOnboardingCompleted(true);
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _authService.resetPassword(email);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      await _authService.signOutAll();
      await _storageService.clearAuthSession();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        clearVerificationId: true,
        clearPendingPhone: true,
        clearResendToken: true,
        authMethod: AuthMethod.unknown,
      );
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanizeError(error),
      );
    }
  }

  Future<void> _syncFirebaseUser(
    firebase.User firebaseUser, {
    required AuthMethod preferredMethod,
  }) async {
    final existing = await _authService.findStudentProfile(
      firebaseUid: firebaseUser.uid,
      phone: firebaseUser.phoneNumber,
      email: firebaseUser.email,
    );

    final authDraft = UserModel(
      id: existing?.id ?? '',
      userId: existing?.userId,
      fullName: existing?.fullName.trim().isNotEmpty == true
          ? existing!.fullName
          : (firebaseUser.displayName?.trim().isNotEmpty == true
                ? firebaseUser.displayName!.trim()
                : ''),
      email: existing?.email.trim().isNotEmpty == true
          ? existing!.email
          : (firebaseUser.email?.trim() ?? ''),
      phone: existing?.phone ?? firebaseUser.phoneNumber,
      firebaseUid: firebaseUser.uid,
      aspirantType: existing?.aspirantType,
      city: existing?.city,
      state: existing?.state,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );

    final shouldShowOnboarding =
        existing == null || !authDraft.hasRequiredProfile;
    if (shouldShowOnboarding) {
      state = state.copyWith(
        status: AuthStatus.needsOnboarding,
        user: authDraft,
        clearError: true,
        clearVerificationId: true,
        clearPendingPhone: true,
        clearResendToken: true,
        authMethod: preferredMethod,
      );
      return;
    }

    var saved = await _authService.upsertStudentProfile(authDraft);

    // If not yet linked to a public.users identity, create and link
    if (saved.userId == null) {
      try {
        await _authService.ensureFirebaseUserIdentityAndLink(
          studentId: saved.id,
          email: saved.email,
          fullName: saved.fullName,
          firebaseUid: firebaseUser.uid,
        );
        saved = saved.copyWith(userId: saved.id);
      } catch (e) {
        // Identity sync should not break login; log and continue
        print('Identity sync error: $e');
      }
    }

    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: saved,
      clearError: true,
      clearVerificationId: true,
      clearPendingPhone: true,
      clearResendToken: true,
      authMethod: preferredMethod,
    );
  }

  Future<void> _syncSupabaseUser(supabase.User supabaseUser) async {
    final fullName = _extractDisplayName(supabaseUser);
    final existing = await _authService.findStudentProfile(
      userId: supabaseUser.id,
      email: supabaseUser.email,
    );

    final authDraft = UserModel(
      id: existing?.id ?? '',
      userId: supabaseUser.id,
      fullName: existing?.fullName.trim().isNotEmpty == true
          ? existing!.fullName
          : fullName,
      email: existing?.email.trim().isNotEmpty == true
          ? existing!.email
          : (supabaseUser.email?.trim() ?? ''),
      phone: existing?.phone,
      firebaseUid: existing?.firebaseUid,
      aspirantType: existing?.aspirantType,
      city: existing?.city,
      state: existing?.state,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );

    final shouldShowOnboarding =
        existing == null || !authDraft.hasRequiredProfile;
    if (shouldShowOnboarding) {
      state = state.copyWith(
        status: AuthStatus.needsOnboarding,
        user: authDraft,
        clearError: true,
        clearVerificationId: true,
        clearPendingPhone: true,
        clearResendToken: true,
        authMethod: AuthMethod.supabaseEmail,
      );
      return;
    }

    final saved = await _authService.upsertStudentProfile(authDraft);
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: saved,
      clearError: true,
      clearVerificationId: true,
      clearPendingPhone: true,
      clearResendToken: true,
      authMethod: AuthMethod.supabaseEmail,
    );
  }

  Future<void> _clearPendingOtp() async {
    await _storageService.clearPendingPhoneOtp();
    state = state.copyWith(
      clearVerificationId: true,
      clearResendToken: true,
      clearPendingPhone: true,
    );
  }

  String _extractDisplayName(supabase.User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final candidates = <String?>[
      metadata['full_name'] as String?,
      metadata['name'] as String?,
      metadata['display_name'] as String?,
      user.email,
    ];

    for (final candidate in candidates) {
      final value = candidate?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return 'Student';
  }

  AuthMethod _parseMethod(String? method) {
    return switch (method) {
      'firebasePhone' => AuthMethod.firebasePhone,
      'google' => AuthMethod.google,
      'supabaseEmail' => AuthMethod.supabaseEmail,
      _ => AuthMethod.unknown,
    };
  }

  String _humanizeError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();

    if (lower.contains('socketexception') || lower.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (lower.contains('invalid-verification-code') || lower.contains('otp')) {
      return 'The OTP is invalid or expired. Request a new code and try again.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Too many attempts. Please wait before retrying.';
    }
    if (lower.contains('app-not-authorized') ||
        lower.contains('invalid app info in play_integrity_token')) {
      return 'Firebase phone auth is still blocked for this Android build. Recheck the Android app SHA-1 and SHA-256 in Firebase Console, then download the updated google-services.json.';
    }
    if (lower.contains('user-cancelled-authorize') ||
        lower.contains('sign in cancelled')) {
      return 'Google sign-in was cancelled.';
    }
    if (lower.contains('invalid-email')) {
      return 'Enter a valid email address.';
    }

    return text.replaceFirst('AppError: ', '').trim();
  }

  @override
  void dispose() {
    _firebaseSubscription?.cancel();
    _supabaseSubscription?.cancel();
    super.dispose();
  }
}
