import 'package:web/web.dart' as web;

class UserStoragePlatform {
  static String? getItem(String key) {
    return web.window.localStorage.getItem(key);
  }

  static void setItem(String key, String value) {
    web.window.localStorage.setItem(key, value);
  }

  static void removeItem(String key) {
    web.window.localStorage.removeItem(key);
  }
}
