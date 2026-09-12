import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'supabase_client.dart';

/// Fina camada sobre Supabase Auth: validação de formulário local +
/// chamadas de signUp/signIn/reset/signOut. Autenticação e proteção
/// contra brute-force (lockout) ficam por conta do próprio Supabase Auth.
class AuthService {
  AuthService({supa.GoTrueClient? auth})
      : _auth = auth ?? SupabaseService.client.auth;

  final supa.GoTrueClient _auth;

  static const int minPasswordLength = 6;
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? validateRegistration({
    required String nome,
    required String email,
    required String password,
  }) {
    if (nome.trim().isEmpty) {
      return 'Informe seu nome.';
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      return 'Informe um e-mail válido.';
    }
    if (password.length < minPasswordLength) {
      return 'A senha deve ter pelo menos $minPasswordLength caracteres.';
    }
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    if (!hasLetter || !hasNumber) {
      return 'A senha deve conter pelo menos uma letra e um número.';
    }
    return null;
  }

  Future<supa.AuthResponse> signUp({
    required String nome,
    required String email,
    required String password,
    String? convite,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {
        'nome': nome,
        if (convite != null && convite.isNotEmpty) 'convite': convite,
      },
    );
  }

  Future<supa.AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => _auth.signOut();
}
