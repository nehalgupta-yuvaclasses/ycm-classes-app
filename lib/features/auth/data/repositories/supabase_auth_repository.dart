import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  // Since we're mocking, we don't need a real SupabaseClient
  SupabaseAuthRepository(dynamic _);

  @override
  Stream<AuthState> get onAuthStateChange {
    // Return a stream that immediately emits a signed-in state for testing
    return Stream.value(
      AuthState(
        AuthChangeEvent.signedIn,
        Session(
          accessToken: 'mock_token',
          tokenType: 'bearer',
          user: _mockUser,
        ),
      ),
    );
  }

  @override
  User? get currentUser => _mockUser;

  User get _mockUser => User(
        id: 'mock_user_id',
        appMetadata: {},
        userMetadata: {'full_name': 'Shivam App'},
        aud: '',
        createdAt: DateTime.now().toIso8601String(),
      );

  @override
  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResponse(session: Session(accessToken: '', tokenType: '', user: _mockUser), user: _mockUser);
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AuthResponse(session: Session(accessToken: '', tokenType: '', user: _mockUser), user: _mockUser);
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<bool> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  @override
  Future<void> updateUserMetadata(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
