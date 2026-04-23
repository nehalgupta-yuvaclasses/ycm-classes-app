import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/utils/app_error.dart';
import '../domain/models/notification_models.dart';

class NotificationService {
  NotificationService();

  SupabaseClient get _client => SupabaseClientManager.client;

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _client
          .from('notifications')
          .select('id, title, message, target_type, created_at')
          .order('created_at', ascending: false);

      return (response as List).map((e) => NotificationModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppError(e.message);
    }
  }

  Stream<List<NotificationModel>> listenNotifications() async* {
    yield* _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((e) => NotificationModel.fromJson(e)).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    return;
  }

  Future<void> markAllAsRead() async {
    return;
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _client.from('notifications').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw AppError(e.message);
    }
  }
}
