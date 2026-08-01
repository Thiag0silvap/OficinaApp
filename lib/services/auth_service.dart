import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'app_logger.dart';

class AuthService {
  static const _usersPrefsKey = 'auth_users_v1';
  static const _failedAttemptsKey = 'auth_failed_attempts_v1';
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);
  static const int minPasswordLength = 6;
  static const int minUserNameLength = 3;

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

  String? validateRegistration({
    required String name,
    required String password,
  }) {
    final normalizedName = name.trim();
    if (normalizedName.length < minUserNameLength) {
      return 'O usuario deve ter pelo menos $minUserNameLength caracteres.';
    }
    final invalidChars = RegExp(r'[^a-zA-Z0-9._-]');
    if (invalidChars.hasMatch(normalizedName)) {
      return 'Use apenas letras, numeros, ponto, underline ou hifen no usuario.';
    }
    if (password.length < minPasswordLength) {
      return 'A senha deve ter pelo menos $minPasswordLength caracteres.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    if (!hasLetter || !hasNumber) {
      return 'A senha deve conter pelo menos uma letra e um numero.';
    }
    return null;
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
    final validation = validateRegistration(name: name, password: password);
    if (validation != null) {
      await AppLogger.instance.warning('Registro rejeitado para "$name": $validation');
      return null;
    }
    if (_users.any((u) => u.name.toLowerCase() == name.toLowerCase())) return null;
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      password: password,
      role: UserRole.user,
    );
    _users.add(user);
    await _persist();
    await AppLogger.instance.info('Usuario registrado: ${user.name}');
    return user;
  }

  Future<User?> login(String name, String password) async {
    await ensureLoaded();
    final normalizedName = name.trim().toLowerCase();
    if (normalizedName.isEmpty || password.isEmpty) return null;

    if (await isUserLockedOut(normalizedName)) {
      await AppLogger.instance.warning('Login bloqueado temporariamente para "$normalizedName"');
      return null;
    }

    for (final u in _users) {
      if (u.name.toLowerCase() == normalizedName && User.verifyPassword(password, u.password)) {
        await clearFailedAttempts(normalizedName);
        await AppLogger.instance.info('Login realizado: ${u.name}');
        return u;
      }
    }
    await registerFailedAttempt(normalizedName);
    await AppLogger.instance.warning('Falha de login para "$normalizedName"');
    return null;
  }

  List<User> getAllUsers() => List.unmodifiable(_users);

  Future<bool> isUserLockedOut(String normalizedName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_failedAttemptsKey);
    if (raw == null || raw.trim().isEmpty) return false;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return false;
      final entry = decoded[normalizedName];
      if (entry is! Map<String, dynamic>) return false;
      final count = int.tryParse(entry['count']?.toString() ?? '') ?? 0;
      final lastAttemptRaw = entry['lastAttempt']?.toString();
      if (count < maxFailedAttempts || lastAttemptRaw == null) return false;
      final lastAttempt = DateTime.tryParse(lastAttemptRaw);
      if (lastAttempt == null) return false;
      return DateTime.now().difference(lastAttempt) < lockoutDuration;
    } catch (_) {
      return false;
    }
  }

  Future<Duration?> getRemainingLockout(String normalizedName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_failedAttemptsKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final entry = decoded[normalizedName];
      if (entry is! Map<String, dynamic>) return null;
      final lastAttempt = DateTime.tryParse(entry['lastAttempt']?.toString() ?? '');
      if (lastAttempt == null) return null;
      final end = lastAttempt.add(lockoutDuration);
      final remaining = end.difference(DateTime.now());
      return remaining.isNegative ? null : remaining;
    } catch (_) {
      return null;
    }
  }

  Future<void> registerFailedAttempt(String normalizedName) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await _loadFailedAttempts();
    final current = attempts[normalizedName] as Map<String, dynamic>? ?? {};
    final currentCount = int.tryParse(current['count']?.toString() ?? '') ?? 0;
    attempts[normalizedName] = {
      'count': currentCount + 1,
      'lastAttempt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_failedAttemptsKey, jsonEncode(attempts));
  }

  Future<void> clearFailedAttempts(String normalizedName) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await _loadFailedAttempts();
    attempts.remove(normalizedName);
    await prefs.setString(_failedAttemptsKey, jsonEncode(attempts));
  }

  Future<Map<String, dynamic>> _loadFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_failedAttemptsKey);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return <String, dynamic>{};
  }
}
