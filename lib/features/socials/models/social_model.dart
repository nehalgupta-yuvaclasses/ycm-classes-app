class SocialModel {
  final String phone;
  final String email;
  final String whatsapp;
  final String telegram;
  final String instagram;
  final String facebook;
  final String twitter;
  final String youtube;
  final String linkedin;
  final String address;
  final String supportHours;
  final String? id;
  final String? key;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SocialModel({
    required this.phone,
    required this.email,
    required this.whatsapp,
    required this.telegram,
    required this.instagram,
    required this.facebook,
    required this.twitter,
    required this.youtube,
    required this.linkedin,
    required this.address,
    required this.supportHours,
    this.id,
    this.key,
    this.createdAt,
    this.updatedAt,
  });

  factory SocialModel.empty() {
    return const SocialModel(
      phone: '',
      email: '',
      whatsapp: '',
      telegram: '',
      instagram: '',
      facebook: '',
      twitter: '',
      youtube: '',
      linkedin: '',
      address: '',
      supportHours: '',
    );
  }

  factory SocialModel.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    final data = value is Map ? Map<String, dynamic>.from(value) : json;

    return SocialModel(
      phone: _stringValue(data['phone']),
      email: _stringValue(data['email']),
      whatsapp: _stringValue(data['whatsapp']),
      telegram: _stringValue(data['telegram']),
      instagram: _stringValue(data['instagram']),
      facebook: _stringValue(data['facebook']),
      twitter: _stringValue(data['twitter']),
      youtube: _stringValue(data['youtube']),
      linkedin: _stringValue(data['linkedin']),
      address: _stringValue(data['address']),
      supportHours: _stringValue(data['support_hours']),
      id: json['id'] as String?,
      key: json['key'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  SocialModel copyWith({
    String? phone,
    String? email,
    String? whatsapp,
    String? telegram,
    String? instagram,
    String? facebook,
    String? twitter,
    String? youtube,
    String? linkedin,
    String? address,
    String? supportHours,
    String? id,
    String? key,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SocialModel(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      whatsapp: whatsapp ?? this.whatsapp,
      telegram: telegram ?? this.telegram,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      youtube: youtube ?? this.youtube,
      linkedin: linkedin ?? this.linkedin,
      address: address ?? this.address,
      supportHours: supportHours ?? this.supportHours,
      id: id ?? this.id,
      key: key ?? this.key,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone.trim(),
      'email': email.trim(),
      'whatsapp': whatsapp.trim(),
      'telegram': telegram.trim(),
      'instagram': instagram.trim(),
      'facebook': facebook.trim(),
      'twitter': twitter.trim(),
      'youtube': youtube.trim(),
      'linkedin': linkedin.trim(),
      'address': address.trim(),
      'support_hours': supportHours.trim(),
    };
  }

  bool get hasAnyContact =>
      phone.isNotEmpty || email.isNotEmpty || whatsapp.isNotEmpty || telegram.isNotEmpty;

  String get normalizedPhone {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return '+91$digits';
    }

    if (digits.length == 12 && digits.startsWith('91') && RegExp(r'^91[6-9]\d{9}$').hasMatch(digits)) {
      return '+$digits';
    }

    if (phone.trim().startsWith('+91') && RegExp(r'^\+91[6-9]\d{9}$').hasMatch(phone.replaceAll(' ', ''))) {
      return phone.replaceAll(' ', '');
    }

    return phone.trim();
  }

  String get phoneHref => normalizedPhone.isEmpty ? '' : 'tel:$normalizedPhone';
  String get emailHref => email.trim().isEmpty ? '' : 'mailto:${email.trim()}';

  String get whatsappHref {
    if (whatsapp.trim().isNotEmpty) {
      return whatsapp.trim();
    }

    final digits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? '' : 'https://wa.me/$digits';
  }

  String get telegramHref => telegram.trim();
  String get instagramHref => instagram.trim();
  String get facebookHref => facebook.trim();
  String get twitterHref => twitter.trim();
  String get youtubeHref => youtube.trim();
  String get linkedinHref => linkedin.trim();

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}