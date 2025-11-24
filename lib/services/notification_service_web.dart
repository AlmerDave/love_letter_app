// lib/services/notification_service_web.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/love_signals_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

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

  // ✨ NEW: Debug callback for UI
  Function(String)? onDebugLog;

  void _log(String message) {
    print(message);
    onDebugLog?.call(message);
  }

  /// Initialize ONLY the listener (no auto-permission request)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _log('🌐 Initializing Web Push Notifications (passive mode)...');

      // ✨ ENHANCED: Check permission via both Firebase AND browser API
      final hasPermission = await this.hasPermission();
      _log('📋 Initial permission check: $hasPermission');
      
      if (hasPermission) {
        _log('🔔 Permission already granted, refreshing token...');
        await _obtainAndSaveToken();
      }

      // Listen for foreground messages (when app is open)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for token refresh (if user already granted permission)
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _log('🔄 Web FCM Token refreshed');
        _fcmToken = newToken;
        _saveTokenToFirebase(newToken);
      });

      _initialized = true;
      _log('✅ Web Push Notifications initialized (listening mode)');

    } catch (e) {
      _log('❌ Error initializing web notifications: $e');
    }
  }

  /// ✨ ENHANCED: Check browser notification permission directly
  Future<String> getBrowserPermissionStatus() async {
    try {
      // Check if Notification API is available
      if (html.Notification.supported) {
        final permission = html.Notification.permission;
        _log('🌐 Browser Notification.permission: $permission');
        return permission ?? 'unsupported'; // 'granted', 'denied', or 'default'
      } else {
        _log('❌ Browser Notification API not supported');
        return 'unsupported';
      }
    } catch (e) {
      _log('❌ Error checking browser permission: $e');
      return 'error';
    }
  }

  /// Check if browser supports notifications
  Future<bool> isNotificationSupported() async {
    try {
      return html.Notification.supported;
    } catch (e) {
      _log('❌ Notification support check failed: $e');
      return false;
    }
  }

  /// ✨ ENHANCED: Get current permission status with dual check
  /// Returns: 'granted', 'denied', 'default', 'unsupported'
  Future<String> getPermissionStatus() async {
    try {
      // 1️⃣ Check browser API first (more reliable for PWA)
      final browserPermission = await getBrowserPermissionStatus();
      _log('📱 Browser permission: $browserPermission');

      // 2️⃣ Check Firebase settings
      final settings = await _firebaseMessaging.getNotificationSettings();
      String firebasePermission;
      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          firebasePermission = 'granted';
          break;
        case AuthorizationStatus.denied:
          firebasePermission = 'denied';
          break;
        case AuthorizationStatus.notDetermined:
          firebasePermission = 'default';
          break;
        case AuthorizationStatus.provisional:
          firebasePermission = 'provisional';
          break;
        default:
          firebasePermission = 'unsupported';
      }
      
      _log('🔥 Firebase permission: $firebasePermission');

      // ✨ CRITICAL: Trust browser API over Firebase for PWA
      // Browser API is more reliable for installed PWAs
      if (browserPermission == 'granted') {
        _log('✅ Using browser permission (granted)');
        return 'granted';
      } else if (browserPermission == 'denied') {
        _log('❌ Using browser permission (denied)');
        return 'denied';
      } else if (browserPermission == 'default') {
        _log('⚠️ Using browser permission (default)');
        return 'default';
      }

      // Fallback to Firebase if browser API fails
      _log('⚠️ Falling back to Firebase permission');
      return firebasePermission;

    } catch (e) {
      _log('❌ Error checking permission status: $e');
      return 'unsupported';
    }
  }

  /// ✨ ENHANCED: Check if permission is already granted
  Future<bool> hasPermission() async {
    try {
      // Direct browser check (most reliable for PWA)
      if (html.Notification.supported) {
        final browserPerm = html.Notification.permission;
        _log('🔍 Browser permission check: $browserPerm');
        
        if (browserPerm == 'granted') {
          _log('✅ Browser reports: GRANTED');
          return true;
        } else if (browserPerm == 'denied') {
          _log('❌ Browser reports: DENIED');
          return false;
        }
      }

      // Fallback to Firebase check
      final status = await getPermissionStatus();
      final hasIt = status == 'granted' || status == 'provisional';
      _log('📋 Final hasPermission result: $hasIt');
      return hasIt;
    } catch (e) {
      _log('❌ hasPermission error: $e');
      return false;
    }
  }

  /// Request notification permission from user
  /// This is the method called when user clicks the button
  Future<bool> requestPermission() async {
    try {
      _log('🔔 Requesting notification permission...');
      _log('📱 Current browser permission: ${html.Notification.permission}');

      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _log('📋 Permission status after request: ${settings.authorizationStatus}');
      
      // ✨ NEW: Check browser permission after request
      final browserPermAfter = html.Notification.permission;
      _log('🌐 Browser permission after request: $browserPermAfter');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          browserPermAfter == 'granted') {
        _log('✅ Notification permission granted');
        
        // Get FCM token
        await _obtainAndSaveToken();
        
        if (_fcmToken != null) {
          _log('✅ Token obtained and saved successfully');
          return true;
        } else {
          _log('❌ Permission granted but token is null');
          return false;
        }
        
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        _log('⚠️ Notification permission provisional');
        await _obtainAndSaveToken();
        
        if (_fcmToken != null) {
          return true;
        } else {
          _log('❌ Provisional permission but token is null');
          return false;
        }
        
      } else {
        _log('❌ Notification permission denied: ${settings.authorizationStatus}');
        return false;
      }

    } catch (e, stackTrace) {
      _log('❌ Error requesting permission: $e');
      _log('Stack trace: ${stackTrace.toString().substring(0, 200)}');
      return false;
    }
  }

  /// Get FCM token and save to Firebase
  Future<void> _obtainAndSaveToken() async {
    try {
      _log('🔑 Obtaining FCM token...');
      
      final browserPerm = html.Notification.permission;
      _log('📱 Browser permission before getToken: $browserPerm');
      
      if (browserPerm != 'granted') {
        _log('⚠️ WARNING: Browser permission not granted, getToken may fail');
      }
      
      // ✅ Get the service worker registration first
      final swRegistration = await html.window.navigator.serviceWorker?.getRegistration('/love_letter_app/');
      
      if (swRegistration == null) {
        _log('❌ No service worker registration found');
        return;
      }
      
      _log('✅ Found service worker: ${swRegistration.scope}');
      
      // ✅ Get FCM token WITHOUT specifying vapidKey in getToken
      // The service worker should handle the VAPID key
      _fcmToken = await _firebaseMessaging.getToken(
        vapidKey: 'BGaO7X_Mt1ZG2LRZ0ywNYkKHlGunUvgNdUnu2ZEh5638UktU7uTnu5AJmvFr_pEr8dUVjxpn8zLs_OEI08d1y3k',
      );

      if (_fcmToken != null) {
        _log('📱 Web FCM Token obtained: ${_fcmToken!.substring(0, 30)}...');
        await _saveTokenToFirebase(_fcmToken!);
        _log('✅ Token saved to Firebase successfully');
      } else {
        _log('❌ Failed to get FCM token - token is null');
      }
    } catch (e, stackTrace) {
      _log('❌ Error obtaining FCM token: $e');
      _log('Stack trace: ${stackTrace.toString().substring(0, 300)}');
    }
  }

  /// Save FCM token to Firebase by nickname
  Future<void> _saveTokenToFirebase(String token) async {
    try {
      final nickname = await UserService.getNickname();
      
      if (nickname == null) {
        _log('⚠️ Cannot save FCM token: No nickname set');
        return;
      }

      final lowercaseNickname = nickname.toLowerCase();

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

      _log('💾 Web FCM token saved for: $lowercaseNickname');
      _log('   Path: /notification_tokens/$lowercaseNickname');
    } catch (e) {
      _log('❌ Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _log('📩 Web foreground message received');
    _log('   Title: ${message.notification?.title}');
    _log('   Body: ${message.notification?.body}');
    
    // ✅ SHOW NOTIFICATION in foreground
    try {
      if (html.Notification.supported && html.Notification.permission == 'granted') {
        final notification = html.Notification(
          message.notification?.title ?? 'Love Signal',
          body: message.notification?.body ?? 'You received a love signal!',
          icon: '/icons/Icon-192.png',
          tag: 'love-signal-${DateTime.now().millisecondsSinceEpoch}',
        );
        
        _log('✅ Notification displayed');
        
        // Optional: Handle click
        notification.onClick.listen((event) {
          _log('🖱️ Notification clicked');
          notification.close();
        });
      } else {
        _log('⚠️ Cannot show notification - permission: ${html.Notification.permission}');
      }
    } catch (e) {
      _log('❌ Error showing notification: $e');
    }
  }

  Future<bool> sendNotificationToPartner({
    required SignalType signalType,
    required String senderNickname,
  }) async {
    try {
      _log('📤 Sending web notification...');

      final partnerNickname = await LoveSignalsService.instance.getPartnerNickname();
      if (partnerNickname == null) {
        _log('❌ No partner found');
        return false;
      }

      final isThinking = signalType == SignalType.thinkingOfYou;
      final signalTypeStr = isThinking ? 'thinkingOfYou' : 'virtualHug';

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
        _log('✅ Notification sent successfully: ${data['messageId']}');
        return true;
      } else {
        _log('❌ Failed to send notification: ${response.body}');
        return false;
      }

    } catch (e) {
      _log('❌ Error sending web notification: $e');
      return false;
    }
  }

  Future<String?> _getPartnerFCMToken(String partnerNickname) async {
    try {
      final lowercaseNickname = partnerNickname.toLowerCase();
      
      final snapshot = await FirebaseService.instance.database
          .child('notification_tokens')
          .child(lowercaseNickname)
          .once();

      if (snapshot.snapshot.value == null) {
        _log('❌ Partner token not found for: $lowercaseNickname');
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      final token = data['token'] as String?;
      
      _log('✅ Found partner FCM token for: $lowercaseNickname');
      return token;
    } catch (e) {
      _log('❌ Error getting partner FCM token: $e');
      return null;
    }
  }

  String? get fcmToken => _fcmToken;

  Future<bool> areNotificationsEnabled() async {
    return await hasPermission();
  }

  /// ✨ ENHANCED: Force refresh token with detailed debugging
  Future<bool> forceRefreshToken() async {
    try {
      _log('🔄 === FORCE REFRESH TOKEN START ===');
      
      // 1️⃣ Check browser permission
      final browserPerm = html.Notification.permission;
      _log('1️⃣ Browser permission: $browserPerm');
      
      // 2️⃣ Check Firebase permission
      final settings = await _firebaseMessaging.getNotificationSettings();
      _log('2️⃣ Firebase authStatus: ${settings.authorizationStatus}');
      
      // 3️⃣ Check our hasPermission method
      final hasPermission = await this.hasPermission();
      _log('3️⃣ hasPermission() result: $hasPermission');
      
      if (!hasPermission) {
        _log('❌ No permission - cannot refresh');
        _log('💡 TIP: User needs to grant permission first');
        return false;
      }

      // 4️⃣ Try to get token
      _log('4️⃣ Attempting to get FCM token...');
      await _obtainAndSaveToken();
      
      // 5️⃣ Verify token was obtained
      final success = _fcmToken != null;
      _log('5️⃣ Token obtained: $success');
      
      if (success) {
        _log('✅ Token: ${_fcmToken!.substring(0, 30)}...');
      } else {
        _log('❌ Token is still null');
      }
      
      _log('🔄 === FORCE REFRESH TOKEN END ===');
      return success;
      
    } catch (e, stackTrace) {
      _log('❌ Error force refreshing: $e');
      _log('Stack: ${stackTrace.toString().substring(0, 200)}');
      return false;
    }
  }

  /// ✨ NEW: Comprehensive debug info
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final browserPerm = html.Notification.permission;
      final browserSupported = html.Notification.supported;
      final settings = await _firebaseMessaging.getNotificationSettings();
      final hasPermResult = await hasPermission();
      
      return {
        'browser': {
          'supported': browserSupported,
          'permission': browserPerm,
        },
        'firebase': {
          'authStatus': settings.authorizationStatus.toString(),
          'alert': settings.alert.toString(),
          'badge': settings.badge.toString(),
          'sound': settings.sound.toString(),
        },
        'service': {
          'initialized': _initialized,
          'hasToken': _fcmToken != null,
          'tokenPreview': _fcmToken?.substring(0, 20) ?? 'null',
          'hasPermission': hasPermResult,
        },
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}