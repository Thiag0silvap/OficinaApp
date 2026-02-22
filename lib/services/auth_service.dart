import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthService {
  static const _usersPrefsKey = 'auth_users_v1';

  final List<User> _users = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersPrefsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _users
            ..clear()
            ..addAll(
              decoded
                  .whereType<Map>()
                  .map((e) => User.fromMap(Map<String, dynamic>.from(e))),
            );
        }
      } catch (_) {
        // ignore malformed data
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _users.map((u) => u.toMap()).toList();
    await prefs.setString(_usersPrefsKey, jsonEncode(payload));
  }

  // Seed an admin user for initial access
  Future<void> seedAdmin({String name = 'admin', String password = 'admin'}) async {
    await ensureLoaded();
    if (_users.any((u) => u.name.toLowerCase() == name.toLowerCase())) return;
    final admin = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      password: password,
      role: UserRole.admin,
    );
    _users.add(admin);
    await _persist();
  }

  Future<User?> register({required String name, required String password}) async {
    await ensureLoaded();
    if (_users.any((u) => u.name.toLowerCase() == name.toLowerCase())) return null;
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      password: password,
      role: UserRole.user,
    );
    _users.add(user);
    await _persist();
    return user;
  }

  Future<User?> login(String name, String password) async {
    await ensureLoaded();
    for (final u in _users) {
      if (u.name.toLowerCase() == name.toLowerCase() && User.verifyPassword(password, u.password)) {
        return u;
      }
    }
    return null;
  }

  List<User> getAllUsers() => List.unmodifiable(_users);
}
