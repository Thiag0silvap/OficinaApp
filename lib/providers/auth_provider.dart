import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  User? _currentUser;
  static const _prefsKey = 'auth_user';
  static const _lastActiveKey = 'auth_last_active';
  static const _savedCredsKey = 'auth_saved_creds';

  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _init();
  }

  Future<void> _init() async {
    // Seed a default admin for testing (username: admin, password: 123456)
    try {
      await _service.seedAdmin(password: '123456');
    } catch (_) {}
    await _restoreSession();
    notifyListeners();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  List<User> get users => _service.getAllUsers();

  Future<String?> login({required String name, required String password}) async {
    final user = await _service.login(name, password);
    if (user == null) return 'Credenciais inválidas';
    _currentUser = user;
    await _saveSession();
    await _saveLastActive();
    await _saveCredentials(name: name, password: password);
    notifyListeners();
    return null;
  }

  Future<String?> register({required String name, required String password}) async {
    final user = await _service.register(name: name, password: password);
    if (user == null) return 'Usuário já cadastrado';
    _currentUser = user;
    await _saveSession();
    await _saveLastActive();
    await _saveCredentials(name: name, password: password);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_lastActiveKey);
    // keep saved credentials to allow quick re-login
    notifyListeners();
  }

  Future<void> _saveSession() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_currentUser!.toMap()));
  }

  Future<void> _saveLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
  }

  Future<void> _saveCredentials({required String name, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {'name': name, 'password': password};
    await prefs.setString(_savedCredsKey, jsonEncode(map));
  }

  /// Returns saved credentials if any (may be null)
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_savedCredsKey);
    if (s == null) return null;
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return {'name': m['name'] ?? '', 'password': m['password'] ?? ''};
    } catch (_) {
      return null;
    }
  }

  Future<void> _restoreSession() async {
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return;
    }

    final s = prefs.getString(_prefsKey);
    final last = prefs.getString(_lastActiveKey);

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
}
