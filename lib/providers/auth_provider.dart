import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/app_logger.dart';
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
    final normalizedName = name.trim().toLowerCase();
    if (normalizedName.isEmpty || password.isEmpty) {
      return 'Informe usuario e senha.';
    }

    final locked = await _service.isUserLockedOut(normalizedName);
    if (locked) {
      final remaining = await _service.getRemainingLockout(normalizedName);
      final minutes = remaining == null
          ? 5
          : remaining.inMinutes.clamp(1, AuthService.lockoutDuration.inMinutes);
      return 'Muitas tentativas. Tente novamente em aproximadamente $minutes minuto(s).';
    }

    final user = await _service.login(name, password);
    if (user == null) return 'Credenciais invalidas';

    _currentUser = user;
    await _saveSession();
    await _saveLastActive();

    if (rememberCredentials) {
      await _saveCredentials(name: name, password: password);
    } else {
      await _clearSavedCredentials();
    }

    notifyListeners();
    await AppLogger.instance.info('Sessao iniciada para ${user.name}');
    return null;
  }

  Future<String?> register({
    required String name,
    required String password,
    bool rememberCredentials = true,
  }) async {
    final validation = _service.validateRegistration(
      name: name,
      password: password,
    );
    if (validation != null) return validation;

    final user = await _service.register(name: name, password: password);
    if (user == null) return 'Usuario ja cadastrado';

    _currentUser = user;
    await _saveSession();
    await _saveLastActive();

    if (rememberCredentials) {
      await _saveCredentials(name: name, password: password);
    } else {
      await _clearSavedCredentials();
    }

    notifyListeners();
    await AppLogger.instance.info('Sessao criada para ${user.name}');
    return null;
  }

  Future<void> logout() async {
    final currentName = _currentUser?.name;
    _currentUser = null;
    await _secureStorage.delete(_prefsKey);
    await _secureStorage.delete(_lastActiveKey);
    notifyListeners();
    if (currentName != null) {
      await AppLogger.instance.info('Logout realizado para $currentName');
    }
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
    final map = {'name': name, 'password': ''};
    await _secureStorage.write(_savedCredsKey, jsonEncode(map));
  }

  Future<void> _clearSavedCredentials() async {
    await _secureStorage.delete(_savedCredsKey);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final secureValue = await _secureStorage.read(_savedCredsKey);
    if (secureValue != null) {
      return _decodeCredentials(secureValue);
    }

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

    if (s == null) return;

    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      final savedUser = User.fromMap(map);

      if (last != null) {
        try {
          final lastDt = DateTime.parse(last);
          final diff = DateTime.now().difference(lastDt);
          if (diff.inMinutes <= 10) {
            _currentUser = savedUser;
            notifyListeners();
            await AppLogger.instance.info(
              'Sessao restaurada para ${savedUser.name}',
            );
            return;
          }
        } catch (_) {}
      }

      _currentUser = null;
    } catch (_) {}
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
