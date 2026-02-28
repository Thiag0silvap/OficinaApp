import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final SecureStorageService _secureStorage = SecureStorageService();
  User? _currentUser;
  static const _prefsKey = 'auth_user';
  static const _lastActiveKey = 'auth_last_active';
  static const _savedCredsKey = 'auth_saved_creds';

  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _init();
  }

  Future<void> _init() async {
    // Seed a default admin only in debug builds.
    // Shipping a predictable admin account in release is risky.
    if (kDebugMode) {
      try {
        await _service.seedAdmin(password: '123456');
      } catch (_) {}
    }
    await _restoreSession();
    notifyListeners();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  List<User> get users => _service.getAllUsers();

  Future<String?> login({
    required String name,
    required String password,
    bool rememberCredentials = true,
  }) async {
    final user = await _service.login(name, password);
    if (user == null) return 'Credenciais inválidas';
    _currentUser = user;
    await _saveSession();
    await _saveLastActive();

    if (rememberCredentials) {
      await _saveCredentials(name: name, password: password);
    } else {
      await _clearSavedCredentials();
    }
    notifyListeners();
    return null;
  }

  Future<String?> register({
    required String name,
    required String password,
    bool rememberCredentials = true,
  }) async {
    final user = await _service.register(name: name, password: password);
    if (user == null) return 'Usuário já cadastrado';
    _currentUser = user;
    await _saveSession();
    await _saveLastActive();

    if (rememberCredentials) {
      await _saveCredentials(name: name, password: password);
    } else {
      await _clearSavedCredentials();
    }
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _secureStorage.delete(_prefsKey);
    await _secureStorage.delete(_lastActiveKey);
    // keep saved credentials to allow quick re-login
    notifyListeners();
  }

  Future<void> _saveSession() async {
    if (_currentUser == null) return;
    await _secureStorage.write(_prefsKey, jsonEncode(_currentUser!.toMap()));
  }

  Future<void> _saveLastActive() async {
    await _secureStorage.write(
      _lastActiveKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _saveCredentials({
    required String name,
    required String password,
  }) async {
    // Never persist plaintext passwords on disk.
    final map = {'name': name, 'password': ''};
    await _secureStorage.write(_savedCredsKey, jsonEncode(map));
  }

  Future<void> _clearSavedCredentials() async {
    await _secureStorage.delete(_savedCredsKey);
  }

  /// Returns saved credentials if any (may be null).
  /// Note: password is intentionally blank for safety.
  Future<Map<String, String>?> getSavedCredentials() async {
    final secureValue = await _secureStorage.read(_savedCredsKey);
    if (secureValue != null) {
      return _decodeCredentials(secureValue);
    }

    // Migration path from older SharedPreferences storage.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_savedCredsKey);
    if (legacy == null) return null;
    await _secureStorage.write(_savedCredsKey, legacy);
    await prefs.remove(_savedCredsKey);
    return _decodeCredentials(legacy);
  }

  Map<String, String>? _decodeCredentials(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {'name': m['name'] ?? '', 'password': ''};
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreSession() async {
    final s = await _readWithMigration(_prefsKey);
    final last = await _readWithMigration(_lastActiveKey);

    // If there's no saved user, nothing to restore (but keep creds)
    if (s == null) return;

    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      final savedUser = User.fromMap(map);

      if (last != null) {
        try {
          final lastDt = DateTime.parse(last);
          final diff = DateTime.now().difference(lastDt);
          // If last activity within 10 minutes, restore session
          if (diff.inMinutes <= 10) {
            _currentUser = savedUser;
            notifyListeners();
            return;
          }
        } catch (_) {}
      }

      // Otherwise, do not auto-login but keep saved credentials for prefill
      _currentUser = null;
    } catch (_) {
      // ignore malformed data
    }
  }

  Future<String?> _readWithMigration(String key) async {
    final secureValue = await _secureStorage.read(key);
    if (secureValue != null) return secureValue;

    try {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(key);
      if (legacy == null) return null;
      await _secureStorage.write(key, legacy);
      await prefs.remove(key);
      return legacy;
    } catch (_) {
      return null;
    }
  }
}
