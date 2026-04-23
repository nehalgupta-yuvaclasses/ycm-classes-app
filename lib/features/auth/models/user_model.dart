const List<String> aspirantTypeOptions = <String>[
  'SSC Aspirant',
  'BPSC Aspirant',
  'Competitive Exams',
  'Other',
];

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsOnboarding,
  otpSent,
  error,
}

enum AuthMethod {
  unknown,
  firebasePhone,
  google,
  supabaseEmail,
}

class UserModel {
  final String id;
  final String? userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? firebaseUid;
  final String? aspirantType;
  final String? city;
  final String? state;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.firebaseUid,
    this.aspirantType,
    this.city,
    this.state,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasRequiredProfile =>
      fullName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      (aspirantType?.trim().isNotEmpty ?? false);

  UserModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phone,
    String? firebaseUid,
    String? aspirantType,
    String? city,
    String? state,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      aspirantType: aspirantType ?? this.aspirantType,
      city: city ?? this.city,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserModel mergeWith(UserModel other) {
    return copyWith(
      id: other.id.isNotEmpty ? other.id : id,
      userId: other.userId ?? userId,
      fullName: other.fullName.trim().isNotEmpty ? other.fullName : fullName,
      email: other.email.trim().isNotEmpty ? other.email : email,
      phone: other.phone ?? phone,
      firebaseUid: other.firebaseUid ?? firebaseUid,
      aspirantType: other.aspirantType?.trim().isNotEmpty == true ? other.aspirantType : aspirantType,
      city: other.city ?? city,
      state: other.state ?? state,
      createdAt: other.createdAt ?? createdAt,
      updatedAt: other.updatedAt ?? updatedAt,
    );
  }

  factory UserModel.empty({
    String? userId,
    String? email,
    String? phone,
    String? firebaseUid,
  }) {
    return UserModel(
      id: '',
      userId: userId,
      fullName: '',
      email: email ?? '',
      phone: phone,
      firebaseUid: firebaseUid,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '') as String,
      userId: json['user_id'] as String?,
      fullName: (json['full_name'] ?? json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phone: json['phone'] as String?,
      firebaseUid: json['firebase_uid'] as String?,
      aspirantType: json['aspirant_type'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'full_name': fullName.trim(),
      'name': fullName.trim(),
      'email': email.trim(),
    };

    if (userId != null && userId!.isNotEmpty) {
      data['user_id'] = userId;
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      data['phone'] = phone!.trim();
    }
    if (firebaseUid != null && firebaseUid!.trim().isNotEmpty) {
      data['firebase_uid'] = firebaseUid!.trim();
    }
    if (aspirantType != null && aspirantType!.trim().isNotEmpty) {
      data['aspirant_type'] = aspirantType!.trim();
    }
    if (city != null && city!.trim().isNotEmpty) {
      data['city'] = city!.trim();
    }
    if (state != null && state!.trim().isNotEmpty) {
      data['state'] = state!.trim();
    }

    return data;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.userId == userId &&
        other.fullName == fullName &&
        other.email == email &&
        other.phone == phone &&
        other.firebaseUid == firebaseUid &&
        other.aspirantType == aspirantType &&
        other.city == city &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        fullName,
        email,
        phone,
        firebaseUid,
        aspirantType,
        city,
        state,
      );
}

class AuthViewState {
  final AuthStatus status;
  final UserModel? user;
  final String? verificationId;
  final int? resendToken;
  final String? pendingPhone;
  final String? errorMessage;
  final AuthMethod authMethod;
  final bool restoringSession;

  const AuthViewState({
    required this.status,
    this.user,
    this.verificationId,
    this.resendToken,
    this.pendingPhone,
    this.errorMessage,
    this.authMethod = AuthMethod.unknown,
    this.restoringSession = false,
  });

  static const AuthViewState initial = AuthViewState(status: AuthStatus.initial);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isOtpSent => status == AuthStatus.otpSent && verificationId != null;
  bool get needsOnboarding => status == AuthStatus.needsOnboarding && user != null;
  bool get isBootstrapping => status == AuthStatus.initial || restoringSession;
  bool get hasPendingPhoneOtp => pendingPhone != null && verificationId != null;

  AuthViewState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool clearUser = false,
    String? verificationId,
    bool clearVerificationId = false,
    int? resendToken,
    bool clearResendToken = false,
    String? pendingPhone,
    bool clearPendingPhone = false,
    String? errorMessage,
    bool clearError = false,
    AuthMethod? authMethod,
    bool? restoringSession,
  }) {
    return AuthViewState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      verificationId: clearVerificationId ? null : (verificationId ?? this.verificationId),
      resendToken: clearResendToken ? null : (resendToken ?? this.resendToken),
      pendingPhone: clearPendingPhone ? null : (pendingPhone ?? this.pendingPhone),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      authMethod: authMethod ?? this.authMethod,
      restoringSession: restoringSession ?? this.restoringSession,
    );
  }
}
