import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService_firestore {
  // Singleton pattern to access it easily
  static final NotificationService_firestore _instance = NotificationService_firestore._internal();
  factory NotificationService_firestore() => _instance;
  NotificationService_firestore._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize notification service
  Future<void> init() async {
    // Request permission (iOS / Android)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User permission: ${settings.authorizationStatus}');

    // Subscribe to topic (optional)
    await _messaging.subscribeToTopic("allUsers");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      // You can show a local notification here if needed
    });

    // Handle background & terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}

/// Must be a top-level function for background handling
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}
