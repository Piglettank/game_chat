import 'dart:math';
import 'package:flutter/foundation.dart';

// Conditional import for web vs native
import 'user_storage_stub.dart'
    if (dart.library.html) 'user_storage_web.dart'
    as platform;

class UserStorage {
  static const String _userIdKey = 'game_chat_user_id';
  static const String _userNameKey = 'game_chat_user_name';

  static String _generateUserId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(10000);
    return 'user-$timestamp-$randomNum';
  }

  /// Get stored user ID, or generate a new one if not present
  static String getUserId() {
    final stored = platform.UserStoragePlatform.getItem(_userIdKey);
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    // Generate and store new ID
    final newId = _generateUserId();
    platform.UserStoragePlatform.setItem(_userIdKey, newId);
    return newId;
  }

  /// Get stored user name, or null if not present
  static String? getUserName() {
    return platform.UserStoragePlatform.getItem(_userNameKey);
  }

  /// Save user name and ID to storage
  static Future<void> saveUser(String userId, String userName) async {
    platform.UserStoragePlatform.setItem(_userIdKey, userId);
    platform.UserStoragePlatform.setItem(_userNameKey, userName);
  }

  /// Check if user data exists
  static bool hasUserData() {
    final userId = platform.UserStoragePlatform.getItem(_userIdKey);
    final userName = platform.UserStoragePlatform.getItem(_userNameKey);
    return userId != null &&
        userId.isNotEmpty &&
        userName != null &&
        userName.isNotEmpty;
  }

  /// Clear user data (for testing/logout)
  static Future<void> clearUserData() async {
    platform.UserStoragePlatform.removeItem(_userIdKey);
    platform.UserStoragePlatform.removeItem(_userNameKey);
  }
}
