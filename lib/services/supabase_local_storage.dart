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
    try {
      await _storage.clearLegacyFallback(_sessionKey);
    } catch (_) {
      await AppLogger.instance.warning(
        'Falha ao limpar sessão legada em texto plano do secure storage',
      );
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      final value = await _storage.read(_sessionKey);
      return value != null;
    } catch (_) {
      await AppLogger.instance.warning(
        'Falha ao ler sessão do secure storage',
      );
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(_sessionKey);
    } catch (_) {
      await AppLogger.instance.warning(
        'Falha ao ler sessão do secure storage',
      );
      return null;
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(_sessionKey);
    } catch (_) {
      await AppLogger.instance.warning(
        'Falha ao remover sessão do secure storage',
      );
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(_sessionKey, persistSessionString);
    } catch (_) {
      await AppLogger.instance.warning(
        'Falha ao persistir sessão no secure storage',
      );
    }
  }
}
