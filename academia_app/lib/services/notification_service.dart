import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_launcher');

    final InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(settings);
  }

  // Show notification immediately
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon:"ic_launcher",
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, platformDetails);
  }

  // Schedule notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime, // optional
    );
  }
}
