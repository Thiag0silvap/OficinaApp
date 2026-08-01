import 'dart:convert';
import 'package:crypto/crypto.dart';

enum UserRole { admin, user }

extension UserRoleExt on UserRole {
  String get name => toString().split('.').last;
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.user:
        return 'Usuário';
    }
  }
}

class User {
  final String id;
  final String name;
  // Stored as SHA-256 hex hash.
  final String password;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required String password,
    this.role = UserRole.user,
  }) : password = _looksHashed(password) ? password : hashPassword(password);

  User copyWith({
    String? id,
    String? name,
    String? password,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // persist the hashed password
      'password': password,
      'role': role.name,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      // assume stored value is already a hash; constructor will not double-hash
      password: map['password'] as String,
      role: UserRole.values.firstWhere((e) => e.name == (map['role'] ?? 'user')),
    );
  }

  // Hash a plaintext password using SHA-256 and return hex string.
  static String hashPassword(String plain) {
    final bytes = utf8.encode(plain);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify plaintext password against stored hash.
  static bool verifyPassword(String plain, String hash) {
    return hashPassword(plain) == hash;
  }

  // Heuristic to detect if a string is already a SHA-256 hex hash.
  static bool _looksHashed(String s) => RegExp(r'^[a-f0-9]{64}$').hasMatch(s);
}
