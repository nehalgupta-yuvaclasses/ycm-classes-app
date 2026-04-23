import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingPhoneOtp {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const PendingPhoneOtp({
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });
}

class StorageService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _lastAuthMethodKey = 'last_auth_method';
  static const String _pendingOtpPhoneKey = 'pending_phone_number';
  static const String _pendingOtpVerificationIdKey = 'pending_phone_verification_id';
  static const String _pendingOtpResendTokenKey = 'pending_phone_resend_token';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  bool get isOnboardingCompleted => _prefs.getBool(_onboardingCompletedKey) ?? false;

  String? get lastAuthMethod => _prefs.getString(_lastAuthMethodKey);

  PendingPhoneOtp? get pendingPhoneOtp {
    final phoneNumber = _prefs.getString(_pendingOtpPhoneKey);
    final verificationId = _prefs.getString(_pendingOtpVerificationIdKey);
    if (phoneNumber == null || verificationId == null) {
      return null;
    }

    return PendingPhoneOtp(
      phoneNumber: phoneNumber,
      verificationId: verificationId,
      resendToken: _prefs.getInt(_pendingOtpResendTokenKey),
    );
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_onboardingCompletedKey, value);
  }

  Future<void> setLastAuthMethod(String value) async {
    await _prefs.setString(_lastAuthMethodKey, value);
  }

  Future<void> setPendingPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    int? resendToken,
  }) async {
    await _prefs.setString(_pendingOtpPhoneKey, phoneNumber);
    await _prefs.setString(_pendingOtpVerificationIdKey, verificationId);
    if (resendToken != null) {
      await _prefs.setInt(_pendingOtpResendTokenKey, resendToken);
    } else {
      await _prefs.remove(_pendingOtpResendTokenKey);
    }
  }

  Future<void> clearPendingPhoneOtp() async {
    await _prefs.remove(_pendingOtpPhoneKey);
    await _prefs.remove(_pendingOtpVerificationIdKey);
    await _prefs.remove(_pendingOtpResendTokenKey);
  }

  Future<void> clearAuthSession() async {
    await _prefs.remove(_lastAuthMethodKey);
    await clearPendingPhoneOtp();
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in ProviderScope');
});
