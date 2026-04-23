Map<String, dynamic> _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

String _readString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

double? _readDouble(dynamic value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}

int? _readInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

bool? _readBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return null;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const <String>[];
}

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String instructorName;
  final String? instructorAvatar;
  final double price;
  final double? originalPrice;
  final double? discountPrice;
  final int? discountPercentage;
  final String categoryName;
  final String? thumbnailUrl;
  final bool isFeatured;
  final List<String> tags;
  final List<LessonModel>? lessons;
  final String? status;
  final String? visibility;
  final int studentsCount;
  final String? author;
  final String? subtitle;
  final DateTime? updatedAt;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    this.instructorAvatar,
    required this.price,
    this.originalPrice,
    this.discountPrice,
    this.discountPercentage,
    required this.categoryName,
    this.thumbnailUrl,
    this.isFeatured = false,
    this.tags = const [],
    this.lessons,
    this.status,
    this.visibility,
    this.studentsCount = 0,
    this.author,
    this.subtitle,
    this.updatedAt,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final instructorRaw = json['instructors'] ?? json['instructor'];
    Map<String, dynamic> instructor = {};
    if (instructorRaw is Map<String, dynamic>) {
      instructor = instructorRaw;
    } else if (instructorRaw is List && instructorRaw.isNotEmpty) {
      instructor = (instructorRaw.first is Map<String, dynamic>)
          ? instructorRaw.first
          : {};
    }

    final String instructorFromNested =
        instructor['full_name'] ?? instructor['name'] ?? '';
    final String finalName = instructorFromNested.isNotEmpty
        ? instructorFromNested
        : (json['instructor_name'] ?? json['author'] ?? '');

    final sellingPrice =
        _readDouble(json['selling_price']) ?? _readDouble(json['price']) ?? 0;
    final originalPrice =
        _readDouble(json['buying_price']) ??
        _readDouble(json['original_price']) ??
        _readDouble(json['discount_price']);
    final computedDiscount =
        originalPrice != null && originalPrice > sellingPrice
        ? originalPrice - sellingPrice
        : _readDouble(json['discount_price']);
    final discountPercentage =
        computedDiscount != null && originalPrice != null && originalPrice > 0
        ? (((computedDiscount / originalPrice) * 100).round())
        : _readInt(json['discount_percentage']);
    final status = _readString(json['status'], '');
    final visibility = _readString(json['visibility'], '');

    return CourseModel(
      id: _readString(json['id']),
      title: _readString(json['title'], 'Untitled course'),
      description: _readString(json['description']),
      instructorName: _readString(
        finalName.isNotEmpty ? finalName : '',
        'Expert Faculty',
      ),
      instructorAvatar: _readString(
        instructor['profile_image'] ??
            instructor['avatar_url'] ??
            json['instructor_avatar'],
        '',
      ),
      price: sellingPrice,
      originalPrice: originalPrice,
      discountPrice: computedDiscount,
      discountPercentage: discountPercentage,
      categoryName: _readString(
        json['category'] ?? json['category_name'],
        'General',
      ),
      thumbnailUrl: _readString(json['thumbnail_url'], ''),
      isFeatured:
          _readBool(json['is_featured']) ?? status.toLowerCase() == 'published',
      tags: _readStringList(json['tags']),
      lessons: (json['lessons'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(LessonModel.fromJson)
          .toList(),
      status: status.isEmpty ? null : status,
      visibility: visibility.isEmpty ? null : visibility,
      studentsCount: _readInt(json['students_count']) ?? 0,
      author: _readString(json['author'], ''),
      subtitle: _readString(json['subtitle'], ''),
      updatedAt: _readDateTime(json['updated_at']),
    );
  }

  CourseModel copyWith({List<LessonModel>? lessons}) {
    return CourseModel(
      id: id,
      title: title,
      description: description,
      instructorName: instructorName,
      instructorAvatar: instructorAvatar,
      price: price,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      discountPercentage: discountPercentage,
      categoryName: categoryName,
      thumbnailUrl: thumbnailUrl,
      isFeatured: isFeatured,
      tags: tags,
      lessons: lessons ?? this.lessons,
      status: status,
      visibility: visibility,
      studentsCount: studentsCount,
      author: author,
      subtitle: subtitle,
      updatedAt: updatedAt,
    );
  }
}

class LessonModel {
  final String id;
  final String moduleId;
  final String title;
  final String lessonType;
  final String duration;
  final String? scheduledAt;
  final String? videoUrl;
  final String? liveUrl;
  final bool isLive;
  final DateTime? liveStartedAt;
  final DateTime? liveEndedAt;
  final String? liveBy;
  final int order;
  final LessonStatus status;

  const LessonModel({
    required this.id,
    this.moduleId = '',
    required this.title,
    this.lessonType = 'recorded',
    required this.duration,
    this.scheduledAt,
    this.videoUrl,
    this.liveUrl,
    this.isLive = false,
    this.liveStartedAt,
    this.liveEndedAt,
    this.liveBy,
    this.order = 0,
    this.status = LessonStatus.locked,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final statusText = _readString(json['status'], 'locked').toLowerCase();
    final lessonType = _readString(
      json['lesson_type'],
      'recorded',
    ).toLowerCase();
    final isLive = _readBool(json['is_live']) ?? lessonType == 'live';

    return LessonModel(
      id: _readString(json['id']),
      moduleId: _readString(
        json['module_id'],
        _readString(json['subject_id'], ''),
      ),
      title: _readString(json['title'], 'Untitled lesson'),
      lessonType: lessonType.isEmpty
          ? (isLive ? 'live' : 'recorded')
          : lessonType,
      duration: _readString(json['duration']),
      videoUrl: _readString(json['video_url'], ''),
      liveUrl: _readString(json['live_url'], ''),
      scheduledAt: _readString(json['scheduled_at'], ''),
      isLive: isLive,
      liveStartedAt: _readDateTime(json['live_started_at']),
      liveEndedAt: _readDateTime(json['live_ended_at']),
      liveBy: _readString(json['live_by'], ''),
      order: _readInt(json['order']) ?? 0,
      status: LessonStatus.values.firstWhere(
        (value) => value.name == statusText,
        orElse: () => LessonStatus.locked,
      ),
    );
  }

  bool get isLiveSession => lessonType == 'live';
  bool get hasEnded => isLiveSession && !isLive && liveEndedAt != null;
  bool get canJoin => isLiveSession && isLive;
  bool get isScheduled => isLiveSession && !isLive && liveEndedAt == null;

  LessonModel copyWith({
    String? title,
    String? duration,
    String? videoUrl,
    String? liveUrl,
    String? scheduledAt,
    bool? isLive,
    DateTime? liveStartedAt,
    DateTime? liveEndedAt,
    String? liveBy,
    int? order,
    String? lessonType,
    String? moduleId,
  }) {
    return LessonModel(
      id: id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      lessonType: lessonType ?? this.lessonType,
      duration: duration ?? this.duration,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      videoUrl: videoUrl ?? this.videoUrl,
      liveUrl: liveUrl ?? this.liveUrl,
      isLive: isLive ?? this.isLive,
      liveStartedAt: liveStartedAt ?? this.liveStartedAt,
      liveEndedAt: liveEndedAt ?? this.liveEndedAt,
      liveBy: liveBy ?? this.liveBy,
      order: order ?? this.order,
      status: status,
    );
  }
}

enum LessonStatus { playing, completed, locked }
