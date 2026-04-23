import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_service.dart';
import '../../domain/models/notification_models.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationServiceProvider).listenNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});

final notificationControllerProvider = StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(ref.read(notificationServiceProvider));
});

class NotificationController extends StateNotifier<AsyncValue<void>> {
  NotificationController(this._service) : super(const AsyncValue.data(null));

  final NotificationService _service;

  Future<void> markAsRead(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.markAsRead(id));
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.markAllAsRead());
  }

  Future<void> deleteNotification(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.deleteNotification(id));
  }
}
