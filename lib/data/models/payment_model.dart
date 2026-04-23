double _paymentDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  return double.tryParse(value.toString()) ?? fallback;
}

String _paymentString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? _paymentDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class PaymentModel {
  final String id;
  final String? studentId;
  final String? userId;
  final String? courseId;
  final double amount;
  final String status;
  final String provider;
  final String currency;
  final double gstAmount;
  final String? orderId;
  final String? paymentId;
  final DateTime? createdAt;
  final DateTime? verifiedAt;

  const PaymentModel({
    required this.id,
    this.studentId,
    this.userId,
    this.courseId,
    required this.amount,
    required this.status,
    required this.provider,
    required this.currency,
    required this.gstAmount,
    this.orderId,
    this.paymentId,
    this.createdAt,
    this.verifiedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: _paymentString(json['id']),
      studentId: _paymentString(json['student_id'], ''),
      userId: _paymentString(json['user_id'], ''),
      courseId: _paymentString(json['course_id'], ''),
      amount: _paymentDouble(json['amount']),
      status: _paymentString(json['status'], 'pending'),
      provider: _paymentString(json['provider'], 'razorpay'),
      currency: _paymentString(json['currency'], 'INR'),
      gstAmount: _paymentDouble(json['gst_amount']),
      orderId: _paymentString(json['order_id'], ''),
      paymentId: _paymentString(json['payment_id'], ''),
      createdAt: _paymentDateTime(json['created_at']),
      verifiedAt: _paymentDateTime(json['verified_at']),
    );
  }
}