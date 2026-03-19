class MemoryStore {
  static final Map<String, Object> _box = {};

  static T? get<T>(String key) => _box[key] as T?;

  static void set(String key, Object value) {
    _box[key] = value;
  }

  static void remove(String key) {
    _box.remove(key);
  }
}
