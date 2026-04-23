class BatchModel {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String instructorName;
  final int totalLessons;
  final int completedLessons;
  final double progressPercentage;
  final DateTime enrolledAt;
  final DateTime? expiresAt;

  BatchModel({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.instructorName = 'Expert Faculty',
    required this.totalLessons,
    this.completedLessons = 0,
    this.progressPercentage = 0.0,
    required this.enrolledAt,
    this.expiresAt,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>? ?? {};
    final instructor = course['instructors'] as Map<String, dynamic>? ?? {};
    final modules = course['modules'] as List? ?? const [];

    int countLessons(dynamic moduleList) {
      if (moduleList is! List) return 0;

      var total = 0;
      for (final module in moduleList) {
        if (module is Map<String, dynamic>) {
          final lessons = module['lessons'];
          if (lessons is List) {
            total += lessons.length;
          }
        }
      }
      return total;
    }

    return BatchModel(
      id: course['id'] ?? json['course_id'] ?? '',
      title: course['title'] ?? 'Unknown Course',
      description: course['description'],
      thumbnailUrl: course['thumbnail_url'],
      instructorName: instructor['full_name'] ?? instructor['name'] ?? 'Expert Faculty',
      totalLessons: (json['total_lessons'] ?? countLessons(modules) ?? 0).toInt(),
      completedLessons: (json['completed_lessons'] ?? 0).toInt(),
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
      enrolledAt: DateTime.parse(json['created_at'] ?? json['enrolled_at'] ?? DateTime.now().toIso8601String()),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}

class EnrollmentModel {
  final String id;
  final String userId;
  final String courseId;
  final String status;
  final int progressPercentage;
  final int completedLessons;
  final int totalLessons;
  final DateTime enrolledAt;

  EnrollmentModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.status,
    required this.progressPercentage,
    required this.completedLessons,
    required this.totalLessons,
    required this.enrolledAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'],
      userId: json['user_id'],
      courseId: json['course_id'],
      status: json['status'] ?? 'Active',
      progressPercentage: json['progress_percentage'] ?? 0,
      completedLessons: (json['completed_lessons'] ?? 0).toInt(),
      totalLessons: (json['total_lessons'] ?? 0).toInt(),
      enrolledAt: DateTime.parse(json['created_at'] ?? json['enrolled_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
