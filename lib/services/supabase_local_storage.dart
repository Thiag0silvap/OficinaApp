import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_storage_service.dart';

/// Persiste a sessão do Supabase Auth via [SecureStorageService]
/// (flutter_secure_storage, com fallback já embutido) em vez do
/// SharedPreferences puro que o supabase_flutter usa por padrão.
class SupabaseSecureLocalStorage extends LocalStorage {
  SupabaseSecureLocalStorage({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  final SecureStorageService _storage;
  static const _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final value = await _storage.read(_sessionKey);
    return value != null;
  }

  @override
  Future<String?> accessToken() => _storage.read(_sessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(_sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(_sessionKey, persistSessionString);
}
