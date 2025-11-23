// lib/services/notification_service_web.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/love_signals_service.dart';

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

  /// Initialize web push notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🌐 Initializing Web Push Notifications...');

      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Web notification permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Web notification permission provisional');
      } else {
        print('❌ Web notification permission denied');
        return;
      }

      // ✨ CRITICAL: Get FCM token with VAPID key (Web Push certificate)
      // Replace with YOUR key from Firebase Console → Cloud Messaging → Web Push certificates
      _fcmToken = await _firebaseMessaging.getToken(
        vapidKey: 'BGaO7X_Mt1ZG2LRZ0ywNYkKHlGunUvgNdUnu2ZEh5638UktU7uTnu5AJmvFr_pEr8dUVjxpn8zLs_OEI08d1y3k', // ← IMPORTANT: Replace this!
      );

      if (_fcmToken != null) {
        print('📱 Web FCM Token obtained: $_fcmToken');
        await _saveFCMToken(_fcmToken!);
      } else {
        print('❌ Failed to get FCM token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('🔄 Web FCM Token refreshed');
        _fcmToken = newToken;
        _saveFCMToken(newToken);
      });

      // Listen for foreground messages (when app is open)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      _initialized = true;
      print('✅ Web Push Notifications initialized successfully');

    } catch (e) {
      print('❌ Error initializing web notifications: $e');
    }
  }

  /// Save FCM token to Firebase
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = await UserService.getUserId();
      final nickname = await UserService.getNickname();
      
      if (nickname == null) {
        print('⚠️ Cannot save FCM token: No nickname set');
        return;
      }

      await FirebaseService.instance.database
          .child('users')
          .child(userId)
          .update({
        'fcmToken': token,
        'nickname': nickname.toLowerCase(),
        'platform': 'web', // ✨ Mark as web user
        'lastTokenUpdate': ServerValue.timestamp,
      });

      print('💾 Web FCM token saved to Firebase');
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
    // You can add custom handling here if needed
  }

  /// Send notification to partner
  Future<bool> sendNotificationToPartner({
    required SignalType signalType,
    required String senderNickname,
  }) async {
    try {
      print('📤 Sending web notification...');

      // Get partner's FCM token
      final partnerNickname = await LoveSignalsService.instance.getPartnerNickname();
      if (partnerNickname == null) {
        print('❌ No partner found');
        return false;
      }

      final partnerToken = await _getPartnerFCMToken(partnerNickname);
      if (partnerToken == null) {
        print('❌ Partner FCM token not found');
        return false;
      }

      // Prepare notification data
      final isThinking = signalType == SignalType.thinkingOfYou;
      final title = 'Love Letters 💕';
      final body = isThinking
          ? '$senderNickname is thinking of you right now 💭✨'
          : '$senderNickname sent you a warm hug! 🤗💕';
      
      final signalTypeStr = isThinking ? 'thinkingOfYou' : 'virtualHug';

      // ✨ IMPORTANT: For web, we need to send via HTTP API or Cloud Functions
      // For now, we'll log what would be sent
      print('📤 Would send notification:');
      print('   To: $partnerNickname');
      print('   Token: $partnerToken');
      print('   Title: $title');
      print('   Body: $body');
      print('   Type: $signalTypeStr');
      
      // TODO: Implement actual sending via Cloud Functions or HTTP API
      // See instructions below in the setup guide
      
      return true;

    } catch (e) {
      print('❌ Error sending web notification: $e');
      return false;
    }
  }

  /// Get partner's FCM token from Firebase
  Future<String?> _getPartnerFCMToken(String partnerNickname) async {
    try {
      final snapshot = await FirebaseService.instance.database
          .child('users')
          .orderByChild('nickname')
          .equalTo(partnerNickname.toLowerCase())
          .once();

      if (snapshot.snapshot.value == null) {
        print('❌ Partner not found in Firebase');
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final userData = data.values.first as Map<String, dynamic>;
      
      final token = userData['fcmToken'] as String?;
      print('✅ Found partner FCM token');
      return token;
    } catch (e) {
      print('❌ Error getting partner FCM token: $e');
      return null;
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}