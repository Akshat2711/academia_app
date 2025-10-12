import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize plugin
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_notification');

    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification clicked: ${response.payload}');
      },
    );

    // Request notification permission
    await _requestNotificationsPermission();
    
    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create notification channels (IMPORTANT for Android 8+)
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default_channel',
      'Default Channel',
      description: 'General notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
      'scheduled_channel',
      'Scheduled Notifications',
      description: 'Notifications scheduled for a specific time',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(scheduledChannel);
        
    print('Notification channels created');
  }

  /// Request notification permission (Android 13+)
  static Future<void> _requestNotificationsPermission() async {
    // For Android 13+ (API 33+)
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      print('Notification permission: $status');
    }
    
    // For exact alarms (Android 12+) - CRITICAL for scheduled notifications
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      print('Exact alarm permission: $status');
    }
    
    // Check if permissions are granted
    final notifStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;
    print('Final notification status: $notifStatus');
    print('Final exact alarm status: $alarmStatus');
  }

  /// Show a notification immediately
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
      icon: 'ic_stat_notification',
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, platformDetails);
    print('Immediate notification shown with ID: $id');
  }

  /// Schedule notification with enhanced debugging
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    // Check permissions first
    final alarmPermission = await Permission.scheduleExactAlarm.status;
    if (!alarmPermission.isGranted) {
      print('ERROR: Exact alarm permission not granted!');
      await Permission.scheduleExactAlarm.request();
      return;
    }

    // Ensure we're using local timezone
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime.from(dateTime, tz.local);
    
    // Debug: Print scheduled time
    print('═══════════════════════════════════════');
    print('SCHEDULING NOTIFICATION');
    print('Current time (local): $now');
    print('Scheduled time (local): $scheduledTime');
    print('Time difference: ${scheduledTime.difference(now).inSeconds} seconds');
    print('═══════════════════════════════════════');
    
    // Safety check: Don't schedule in the past
    if (scheduledTime.isBefore(now)) {
      print('ERROR: Cannot schedule notification in the past!');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'Scheduled Notifications',
      channelDescription: 'Notifications scheduled for a specific time',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_stat_notification',
      playSound: true,
      enableVibration: true,
      enableLights: true,
      color:Color(0xFF00FF00),
      ledColor: Color(0xFF00FF00),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Notification scheduled successfully with ID: $id');
      
      // Verify it was scheduled
      await checkPendingNotifications();
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
    print('Notification $id cancelled');
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('All notifications cancelled');
  }
  
  /// Check pending notifications (for debugging)
  static Future<void> checkPendingNotifications() async {
    final pendingNotifications = await _notificationsPlugin.pendingNotificationRequests();
    print('───────────────────────────────────────');
    print('Pending notifications: ${pendingNotifications.length}');
    for (var notification in pendingNotifications) {
      print('  ID: ${notification.id}, Title: ${notification.title}');
    }
    print('───────────────────────────────────────');
  }}