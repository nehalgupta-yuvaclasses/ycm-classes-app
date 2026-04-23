class NotificationModel {
  final String id;
  final String userId;
  final String? announcementId;
  final String title;
  final String message;
  final String channel;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.announcementId,
    required this.title,
    required this.message,
    required this.channel,
    required this.isRead,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: '',
      announcementId: null,
      title: json['title'] as String,
      message: json['message'] as String,
      channel: json['target_type'] as String? ?? 'all',
      isRead: false,
      deliveredAt: null,
      readAt: null,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      announcementId: announcementId,
      title: title,
      message: message,
      channel: channel,
      isRead: isRead ?? this.isRead,
      deliveredAt: deliveredAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
