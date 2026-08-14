import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BudgetNotifications {
  BudgetNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showBudgetExceeded({
    required String category,
    required double spent,
    required double limit,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_exceeded',
      'Budget Alerts',
      channelDescription: 'Notifies when a category budget is exceeded',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: category.hashCode,
      title: 'Budget exceeded: $category',
      body:
          "You've spent RM ${spent.toStringAsFixed(2)} of your "
          'RM ${limit.toStringAsFixed(2)} $category budget this month.',
      notificationDetails: details,
    );
  }
}
