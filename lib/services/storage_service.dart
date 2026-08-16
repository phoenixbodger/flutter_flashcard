import 'package:universal_html/html.dart' as html;

class StorageService {
  static bool _isPersistent = true;
  static Map<String, String> _memoryStore = {};
  static bool _initialized = false;

  static bool get isPersistent => _isPersistent;

  static void _initialize() {
    if (_initialized) return;
    _initialized = true;

    try {
      final testKey = '__storage_test__';
      html.window.localStorage[testKey] = '1';
      final testVal = html.window.localStorage[testKey];
      html.window.localStorage.remove(testKey);
      _isPersistent = testVal == '1';
    } catch (e) {
      _isPersistent = false;
    }
  }

  static String? read(String key) {
    _initialize();
    if (!_isPersistent) {
      return _memoryStore[key];
    }
    try {
      return html.window.localStorage[key];
    } catch (e) {
      _isPersistent = false;
      return _memoryStore[key];
    }
  }

  static void write(String key, String value) {
    _initialize();
    if (!_isPersistent) {
      _memoryStore[key] = value;
      return;
    }
    try {
      html.window.localStorage[key] = value;
    } catch (e) {
      _isPersistent = false;
      _memoryStore[key] = value;
    }
  }

  static void remove(String key) {
    _initialize();
    if (!_isPersistent) {
      _memoryStore.remove(key);
      return;
    }
    try {
      html.window.localStorage.remove(key);
    } catch (e) {
      _isPersistent = false;
      _memoryStore.remove(key);
    }
  }
}
