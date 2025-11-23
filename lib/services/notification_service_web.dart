// lib/services/notification_service_web.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/love_signals_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationServiceWeb {
  static NotificationServiceWeb? _instance;
  static NotificationServiceWeb get instance {
    _instance ??= NotificationServiceWeb._();
    return _instance!;
  }

  NotificationServiceWeb._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _initialized = false;
  String? _fcmToken;

  /// Initialize ONLY the listener (no auto-permission request)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🌐 Initializing Web Push Notifications (passive mode)...');

      // ✨ NEW: Check if permission already granted, if yes get token
      final hasPermission = await this.hasPermission();
      if (hasPermission) {
        print('🔔 Permission already granted, refreshing token...');
        await _obtainAndSaveToken();
      }

      // Listen for foreground messages (when app is open)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for token refresh (if user already granted permission)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 Web FCM Token refreshed');
        _fcmToken = newToken;
        _saveTokenToFirebase(newToken);
      });

      _initialized = true;
      print('✅ Web Push Notifications initialized (listening mode)');

    } catch (e) {
      print('❌ Error initializing web notifications: $e');
    }
  }

  /// Check if browser supports notifications
  Future<bool> isNotificationSupported() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus != AuthorizationStatus.notDetermined ||
             settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Notification support check failed: $e');
      return false;
    }
  }

  /// Get current permission status
  /// Returns: 'granted', 'denied', 'default', 'unsupported'
  Future<String> getPermissionStatus() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          return 'granted';
        case AuthorizationStatus.denied:
          return 'denied';
        case AuthorizationStatus.notDetermined:
          return 'default';
        case AuthorizationStatus.provisional:
          return 'provisional';
        default:
          return 'unsupported';
      }
    } catch (e) {
      print('❌ Error checking permission status: $e');
      return 'unsupported';
    }
  }

  /// Check if permission is already granted
  Future<bool> hasPermission() async {
    final status = await getPermissionStatus();
    return status == 'granted' || status == 'provisional';
  }

  /// Request notification permission from user
  /// This is the method called when user clicks the button
  Future<bool> requestPermission() async {
    try {
      print('🔔 Requesting notification permission...');

      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
        
        // Get FCM token
        await _obtainAndSaveToken();
        return true;
        
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Notification permission provisional');
        await _obtainAndSaveToken();
        return true;
        
      } else {
        print('❌ Notification permission denied');
        return false;
      }

    } catch (e) {
      print('❌ Error requesting permission: $e');
      return false;
    }
  }

  /// Get FCM token and save to Firebase
  Future<void> _obtainAndSaveToken() async {
    try {
      // Get FCM token with VAPID key
      _fcmToken = await _firebaseMessaging.getToken(
        vapidKey: 'BGaO7X_Mt1ZG2LRZ0ywNYkKHlGunUvgNdUnu2ZEh5638UktU7uTnu5AJmvFr_pEr8dUVjxpn8zLs_OEI08d1y3k',
      );

      if (_fcmToken != null) {
        print('📱 Web FCM Token obtained: $_fcmToken');
        await _saveTokenToFirebase(_fcmToken!);
      } else {
        print('❌ Failed to get FCM token');
      }
    } catch (e) {
      print('❌ Error obtaining FCM token: $e');
    }
  }

  /// Save FCM token to Firebase by nickname
  /// Structure: /notification_tokens/{nickname}
  /// Updates if exists, creates if new
  Future<void> _saveTokenToFirebase(String token) async {
    try {
      final nickname = await UserService.getNickname();
      
      if (nickname == null) {
        print('⚠️ Cannot save FCM token: No nickname set');
        return;
      }

      final lowercaseNickname = nickname.toLowerCase();

      // Save to /notification_tokens/{nickname}
      await FirebaseService.instance.database
          .child('notification_tokens')
          .child(lowercaseNickname)
          .set({
        'token': token,
        'nickname': lowercaseNickname,
        'platform': 'web',
        'timestamp': ServerValue.timestamp,
        'lastUpdated': ServerValue.timestamp,
      });

      print('💾 Web FCM token saved for: $lowercaseNickname');
      print('   Path: /notification_tokens/$lowercaseNickname');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Web foreground message received');
    print('   Title: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');
    
    // Browser will automatically show notification via service worker
  }

  /// Send notification to partner
  Future<bool> sendNotificationToPartner({
    required SignalType signalType,
    required String senderNickname,
  }) async {
    try {
      print('📤 Sending web notification...');

      final partnerNickname = await LoveSignalsService.instance.getPartnerNickname();
      if (partnerNickname == null) {
        print('❌ No partner found');
        return false;
      }

      final isThinking = signalType == SignalType.thinkingOfYou;
      final signalTypeStr = isThinking ? 'thinkingOfYou' : 'virtualHug';

      // Call Cloud Function
      final url = 'https://sendlovesignal-fpg5ddtutq-uc.a.run.app';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partnerNickname': partnerNickname,
          'senderNickname': senderNickname,
          'signalType': signalTypeStr,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Notification sent successfully: ${data['messageId']}');
        return true;
      } else {
        print('❌ Failed to send notification: ${response.body}');
        return false;
      }

    } catch (e) {
      print('❌ Error sending web notification: $e');
      return false;
    }
  }

  /// Get partner's FCM token from Firebase
  Future<String?> _getPartnerFCMToken(String partnerNickname) async {
    try {
      final lowercaseNickname = partnerNickname.toLowerCase();
      
      final snapshot = await FirebaseService.instance.database
          .child('notification_tokens')
          .child(lowercaseNickname)
          .once();

      if (snapshot.snapshot.value == null) {
        print('❌ Partner token not found for: $lowercaseNickname');
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final token = data['token'] as String?;
      
      print('✅ Found partner FCM token for: $lowercaseNickname');
      return token;
    } catch (e) {
      print('❌ Error getting partner FCM token: $e');
      return null;
    }
  }

  String? get fcmToken => _fcmToken;

  Future<bool> areNotificationsEnabled() async {
    return await hasPermission();
  }
}