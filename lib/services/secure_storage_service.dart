import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _fallbackPrefix = 'secure_fallback_v1_';

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Remove qualquer entrada residual em texto plano deixada por versões
  /// anteriores do app, que usavam SharedPreferences como fallback do
  /// secure storage. Best-effort: nunca lança erro.
  Future<void> clearLegacyFallback(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_fallbackPrefix$key');
    } catch (_) {
      // limpeza de dado legado: falha aqui não deve afetar o app.
    }
  }
}
