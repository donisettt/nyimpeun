import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  // Singleton
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint("[FCM-Flutter] 🚀 Initializing NotificationService...");

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle foreground notification click if needed
        debugPrint("Local notification clicked: ${details.payload}");
      },
    );

    // Create a high importance channel for Android
    const androidChannel = AndroidNotificationChannel(
      'nyimpeun_transactions', // id
      'Transaksi', // title
      description: 'Notifikasi saat ada transaksi baru',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Auto-refresh token when FCM rotates it
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM Token refreshed: $newToken");
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await saveTokenToSupabase(user.id);
      }
    });

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message, androidChannel);
      }
    });

    _isInitialized = true;
  }

  void _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> saveTokenToSupabase(String userId) async {
    try {
      debugPrint("[FCM-Flutter] Attempting getToken() for userId: $userId");
      
      // Add timeout — getToken() can hang if Firebase is not ready
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("[FCM-Flutter] ⚠️ getToken() timed out after 10 seconds");
          return null;
        },
      );

      if (token == null) {
        debugPrint("[FCM-Flutter] ❌ getToken() returned null — Firebase not ready or no Play Services");
        return;
      }
      
      debugPrint("[FCM-Flutter] ✅ FCM Token obtained: ${token.substring(0, 30)}...");

      final supabase = Supabase.instance.client;
      final response = await supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'device_name': 'Android Device',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, fcm_token');
      
      debugPrint("[FCM-Flutter] ✅ Token saved to Supabase. Response: $response");
    } catch (e, stackTrace) {
      debugPrint("[FCM-Flutter] ❌ Failed to save FCM token: $e");
      debugPrint("[FCM-Flutter] StackTrace: $stackTrace");
    }
  }

  Future<void> removeTokenFromSupabase(String userId) async {
    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (token == null) return;

      final supabase = Supabase.instance.client;
      await supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', token);
      
      debugPrint("[FCM-Flutter] ✅ Token removed from Supabase");
    } catch (e) {
      debugPrint("[FCM-Flutter] ❌ Failed to remove FCM token: $e");
    }
  }
}
