import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get onAuthStateChange;
  User? get currentUser;
  
  Future<AuthResponse> signInWithEmail({required String email, required String password});
  Future<AuthResponse> signUpWithEmail({required String email, required String password, required String fullName});
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<bool> signInWithGoogle();
  Future<void> updateUserMetadata(Map<String, dynamic> data);
}
