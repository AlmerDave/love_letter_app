import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  // Storage keys
  static const String _userIdKey = 'user_device_id';
  static const String _nicknameKey = 'user_nickname';

  /// Get or generate user ID
  /// This creates a unique ID for the device
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);
    
    if (userId == null) {
      // Generate new unique ID
      userId = const Uuid().v4();  // e.g., "550e8400-e29b-41d4-a716-446655440000"
      await prefs.setString(_userIdKey, userId);
      print('🆔 Generated new user ID: $userId');
    } else {
      print('🆔 Found existing user ID: $userId');
    }
    
    return userId;
  }

  /// Get saved nickname
  static Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    String? nickname = prefs.getString(_nicknameKey);
    print('👤 Nickname: ${nickname ?? "Not set"}');
    return nickname;
  }

  /// Save nickname to local storage
  static Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, nickname);
    print('💾 Saved nickname: $nickname');
  }

  /// Check if user has set nickname
  static Future<bool> hasNickname() async {
    final nickname = await getNickname();
    return nickname != null && nickname.isNotEmpty;
  }

  /// Clear all user data (for testing)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_nicknameKey);
    print('🗑️ Cleared all user data');
  }
}