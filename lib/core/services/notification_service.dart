import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/notification_config.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    // flutter_local_notifications requires a service worker on web — skip.
    if (kIsWeb) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _plugin.initialize(initSettings);

      // Request the POST_NOTIFICATIONS runtime permission on Android 13+
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (_) {
      // Initialization failure must not crash the app (e.g. permission denied,
      // unsupported platform). Notifications will silently be skipped.
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        NotificationConfig.budgetAlertsChannelId,
        NotificationConfig.budgetAlertsChannelName,
        channelDescription: NotificationConfig.budgetAlertsChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );
      await _plugin.show(id, title, body, details);
    } catch (_) {
      // Notification failure must not affect the rest of the app.
    }
  }
}
