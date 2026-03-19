import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheStore {
  static const Duration ttl = Duration(minutes: 10);

  static Future<void> writeJson(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'savedAt': DateTime.now().millisecondsSinceEpoch,
      'value': value,
    });
    await prefs.setString(key, payload);
  }

  static Future<T?> readJson<T>(String key, T Function(Object? json) parser) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    final savedAt = map['savedAt'] as int?;
    if (savedAt == null) return null;

    final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
    if (age > ttl) return null;

    return parser(map['value']);
  }

  static Future<T?> readJsonAny<T>(String key, T Function(Object? json) parser) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return parser(map['value']);
  }

  static Future<void> writeString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<DateTime?> readSavedAt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final savedAt = map['savedAt'] as int?;
    if (savedAt == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(savedAt);
  }
}
