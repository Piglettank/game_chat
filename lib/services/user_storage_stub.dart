// Stub file for non-web platforms
// This file is only used when dart.library.html is not available (non-web)

class UserStoragePlatform {
  static String? getItem(String key) {
    // For non-web platforms, you can use shared_preferences here
    return null;
  }

  static void setItem(String key, String value) {
    // For non-web platforms, you can use shared_preferences here
  }

  static void removeItem(String key) {
    // For non-web platforms, you can use shared_preferences here
  }
}
