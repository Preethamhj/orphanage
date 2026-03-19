import 'package:shared_preferences/shared_preferences.dart';

class SyncState {
  static const _prefix = 'dirty_';

  static Future<bool> isDirty(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$key') ?? true;
  }

  static Future<void> markDirty(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', true);
  }

  static Future<void> clearDirty(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', false);
  }
}
