import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _fallbackPrefix = 'secure_fallback_v1_';

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      // best-effort cleanup of any fallback value
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_fallbackPrefix$key');
      } catch (_) {}
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_fallbackPrefix$key', value);
    }
  }

  Future<String?> read(String key) async {
    try {
      final v = await _storage.read(key: key);
      if (v != null) return v;
    } catch (_) {
      // ignore and fallback
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_fallbackPrefix$key');
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // ignore and fallback
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_fallbackPrefix$key');
  }
}
