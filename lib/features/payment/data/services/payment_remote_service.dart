import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/utils/app_error.dart';

class PublicPaymentSettings {
  final String provider;
  final String apiKey;
  final String currency;
  final double gstRate;
  final bool isEnabled;

  const PublicPaymentSettings({
    required this.provider,
    required this.apiKey,
    required this.currency,
    required this.gstRate,
    required this.isEnabled,
  });
}

class RazorpayOrderResponse {
  final String orderId;
  final double amount;
  final String currency;
  final String apiKey;
  final double gstRate;
  final String provider;
  final String courseTitle;

  const RazorpayOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.apiKey,
    required this.gstRate,
    required this.provider,
    required this.courseTitle,
  });
}

class PaymentRemoteService {
  PaymentRemoteService({SupabaseClient? client})
    : _client = client ?? SupabaseClientManager.client;

  final SupabaseClient _client;

  Future<PublicPaymentSettings> fetchPublicPaymentSettings() async {
    final response = await _invoke('get_public_payment_settings');

    return PublicPaymentSettings(
      provider: response['provider']?.toString() ?? 'razorpay',
      apiKey: response['apiKey']?.toString() ?? '',
      currency: response['currency']?.toString() ?? 'INR',
      gstRate: double.tryParse(response['gstRate']?.toString() ?? '18') ?? 18,
      isEnabled: response['isEnabled'] == true,
    );
  }

  Future<RazorpayOrderResponse> createRazorpayOrder({
    required String courseId,
    required double amount,
  }) async {
    final response = await _invoke(
      'create_razorpay_order',
      payload: {'courseId': courseId, 'amount': amount, 'source': 'mobile'},
    );

    return RazorpayOrderResponse(
      orderId: response['orderId']?.toString() ?? '',
      amount: double.tryParse(response['amount']?.toString() ?? '0') ?? 0,
      currency: response['currency']?.toString() ?? 'INR',
      apiKey: response['apiKey']?.toString() ?? '',
      gstRate: double.tryParse(response['gstRate']?.toString() ?? '18') ?? 18,
      provider: response['provider']?.toString() ?? 'razorpay',
      courseTitle: response['courseTitle']?.toString() ?? '',
    );
  }

  Future<void> verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    await _invoke(
      'verify_payment',
      payload: {
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
        'source': 'mobile',
      },
    );
  }

  Future<Map<String, dynamic>> _invoke(
    String action, {
    Map<String, dynamic> payload = const {},
  }) async {
    final supabaseToken = _client.auth.currentSession?.accessToken;
    final firebaseToken = await firebase.FirebaseAuth.instance.currentUser
        ?.getIdToken(true);
    final bearerToken = supabaseToken ?? firebaseToken;
    final response = await _client.functions.invoke(
      'razorpay-payments',
      body: {'action': action, ...payload},
      headers: bearerToken == null
          ? null
          : {'Authorization': 'Bearer $bearerToken'},
    );

    final data = response.data;
    if (response.status >= 400) {
      throw AppError(_friendlyPaymentError(data));
    }

    if (data is Map<String, dynamic>) {
      if (data['error'] != null) {
        throw AppError(_friendlyPaymentError(data));
      }
      return data;
    }

    return <String, dynamic>{};
  }

  String _friendlyPaymentError(dynamic data) {
    final rawMessage = data is Map && data['error'] != null
        ? data['error'].toString()
        : 'Payment request failed';

    if (rawMessage.contains('UNAUTHORIZED_UNSUPPORTED_TOKEN_ALGORITHM') ||
        rawMessage.contains('Unsupported JWT algorithm') ||
        rawMessage.contains('Unauthorized')) {
      return 'Payment authentication failed. Please try again or contact support.';
    }

    return rawMessage;
  }
}
