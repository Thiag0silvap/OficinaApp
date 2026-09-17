import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';
import 'secure_storage_service.dart';

/// Persiste a sessão do Supabase Auth via [SecureStorageService]
/// (flutter_secure_storage) em vez do SharedPreferences puro que o
/// supabase_flutter usa por padrão.
class SupabaseSecureLocalStorage extends LocalStorage {
  SupabaseSecureLocalStorage({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  final SecureStorageService _storage;
  static const _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {
    await _storage.clearLegacyFallback(_sessionKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      final value = await _storage.read(_sessionKey);
      return value != null;
    } catch (e) {
      await AppLogger.instance.warning(
        'Falha ao ler sessão do secure storage: ${e.runtimeType}',
      );
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(_sessionKey);
    } catch (e) {
      await AppLogger.instance.warning(
        'Falha ao ler sessão do secure storage: ${e.runtimeType}',
      );
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(_sessionKey);
    } catch (e) {
      await AppLogger.instance.warning(
        'Falha ao remover sessão do secure storage: ${e.runtimeType}',
      );
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(_sessionKey, persistSessionString);
    } catch (e) {
      await AppLogger.instance.warning(
        'Falha ao persistir sessão no secure storage: ${e.runtimeType}',
      );
    }
  }
}
