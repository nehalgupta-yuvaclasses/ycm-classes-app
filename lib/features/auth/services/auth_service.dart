import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/supabase/supabase_client.dart';
import '../../../core/utils/app_error.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({firebase.FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? firebase.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  supabase.SupabaseClient get _supabaseClient => SupabaseClientManager.client;

  firebase.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  supabase.User? get currentSupabaseUser => _supabaseClient.auth.currentUser;

  Stream<firebase.User?> firebaseAuthStateChanges() => _firebaseAuth.authStateChanges();

  Stream<supabase.AuthState> supabaseAuthStateChanges() => _supabaseClient.auth.onAuthStateChange;

  String normalizeIndianPhone(String rawPhone) {
    final trimmed = rawPhone.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return '+91$digits';
    }

    if (digits.length == 12 && digits.startsWith('91') && RegExp(r'^91[6-9]\d{9}$').hasMatch(digits)) {
      return '+$digits';
    }

    if (trimmed.startsWith('+91') && RegExp(r'^\+91[6-9]\d{9}$').hasMatch(trimmed.replaceAll(' ', ''))) {
      return trimmed.replaceAll(' ', '');
    }

    throw const AppError('Enter a valid Indian mobile number in +91XXXXXXXXXX format.');
  }

  bool isValidIndianPhone(String rawPhone) {
    try {
      normalizeIndianPhone(rawPhone);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(firebase.FirebaseAuthException error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    final normalizedPhone = normalizeIndianPhone(phoneNumber);

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (firebase.PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: onAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<firebase.User?> confirmPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on firebase.FirebaseAuthException catch (error) {
      throw AppError(error.message ?? 'OTP verification failed.');
    } catch (error) {
      throw AppError(error.toString());
    }
  }

  Future<firebase.User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw const AppError('Google authentication could not be completed.');
      }

      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on firebase.FirebaseAuthException catch (error) {
      throw AppError(error.message ?? 'Google sign-in failed.');
    } catch (error) {
      throw AppError(error.toString());
    }
  }

  Future<supabase.User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response.user;
    } on supabase.AuthException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError(error.toString());
    }
  }

  Future<supabase.User?> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
      );
      return response.user;
    } on supabase.AuthException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError(error.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email.trim());
    } on supabase.AuthException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError(error.toString());
    }
  }

  Future<UserModel?> findStudentProfile({
    String? firebaseUid,
    String? email,
    String? phone,
    String? userId,
  }) async {
    final identifiers = <MapEntry<String, String>>[
      if ((firebaseUid ?? '').trim().isNotEmpty) MapEntry('firebase_uid', firebaseUid!.trim()),
      if ((userId ?? '').trim().isNotEmpty) MapEntry('user_id', userId!.trim()),
      if ((phone ?? '').trim().isNotEmpty) MapEntry('phone', phone!.trim()),
      if ((email ?? '').trim().isNotEmpty) MapEntry('email', email!.trim()),
    ];

    for (final identifier in identifiers) {
      final response = await _supabaseClient
          .from('students')
          .select()
          .eq(identifier.key, identifier.value)
          .limit(1);

      if (response.isNotEmpty) {
        return UserModel.fromJson(Map<String, dynamic>.from(response.first as Map));
      }
    }

    return null;
  }

  Future<UserModel> upsertStudentProfile(UserModel profile) async {
    try {
      final existing = await findStudentProfile(
        firebaseUid: profile.firebaseUid,
        email: profile.email,
        phone: profile.phone,
        userId: profile.userId,
      );

      final merged = existing == null ? profile : existing.mergeWith(profile);
      final payload = merged.toJson();

      final response = existing == null
          ? await _supabaseClient.from('students').insert(payload).select().single()
          : await _supabaseClient.from('students').update(payload).eq('id', existing.id).select().single();

      return UserModel.fromJson(Map<String, dynamic>.from(response as Map));
    } on supabase.PostgrestException catch (error) {
      throw AppError(error.message);
    } catch (error) {
      throw AppError('Failed to save student profile: ${error.toString()}');
    }
  }

  Future<void> signOutFirebase() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<void> signOutSupabase() async {
    await _supabaseClient.auth.signOut();
  }

  Future<void> signOutAll() async {
    await signOutFirebase();
    await signOutSupabase();
  }
}
