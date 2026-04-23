class ProfileModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? role;
  final DateTime? joinedAt;
  final String? phone;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.role,
    this.joinedAt,
    this.phone,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: (json['full_name'] ?? json['name']) as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
      joinedAt: _parseDate(json['created_at']),
      phone: json['phone'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}

class UserStatsModel {
  final String userId;
  final int enrolledCoursesCount;
  final int attemptsCount;
  final int completedAttemptsCount;
  final double? averageScorePercentage;

  const UserStatsModel({
    required this.userId,
    required this.enrolledCoursesCount,
    required this.attemptsCount,
    required this.completedAttemptsCount,
    this.averageScorePercentage,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      userId: json['user_id'] as String,
      enrolledCoursesCount: (json['enrolled_courses_count'] as num?)?.toInt() ?? 0,
      attemptsCount: (json['attempts_count'] as num?)?.toInt() ?? 0,
      completedAttemptsCount: (json['completed_attempts_count'] as num?)?.toInt() ?? 0,
      averageScorePercentage: (json['average_score_percentage'] as num?)?.toDouble(),
    );
  }
}

class ProfileViewState {
  final bool loading;
  final bool updating;
  final ProfileModel? profile;
  final UserStatsModel? stats;
  final String? error;

  const ProfileViewState({
    required this.loading,
    required this.updating,
    required this.profile,
    required this.stats,
    required this.error,
  });

  bool get hasData => profile != null;

  ProfileViewState copyWith({
    bool? loading,
    bool? updating,
    ProfileModel? profile,
    UserStatsModel? stats,
    String? error,
    bool clearError = false,
    bool keepProfile = true,
    bool keepStats = true,
  }) {
    return ProfileViewState(
      loading: loading ?? this.loading,
      updating: updating ?? this.updating,
      profile: keepProfile ? (profile ?? this.profile) : profile,
      stats: keepStats ? (stats ?? this.stats) : stats,
      error: clearError ? null : (error ?? this.error),
    );
  }

  static const ProfileViewState initial = ProfileViewState(
    loading: true,
    updating: false,
    profile: null,
    stats: null,
    error: null,
  );
}
