import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../models/user.dart';
import '../services/app_logger.dart';
import '../services/auth_service.dart';
import '../services/supabase_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  User? _currentUser;
  StreamSubscription<supa.AuthState>? _authSub;

  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _init();
  }

  void _init() {
    _syncFromSupabaseUser(SupabaseService.client.auth.currentUser);
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((state) {
      _syncFromSupabaseUser(state.session?.user);
    });
  }

  void _syncFromSupabaseUser(supa.User? supaUser) {
    if (supaUser == null) {
      _currentUser = null;
    } else {
      final metaNome = (supaUser.userMetadata?['nome'] as String?)?.trim();
      final metaConvite = (supaUser.userMetadata?['convite'] as String?)
          ?.trim();
      _currentUser = User(
        id: supaUser.id,
        email: supaUser.email ?? '',
        nome: (metaNome == null || metaNome.isEmpty)
            ? (supaUser.email ?? '')
            : metaNome,
        convite: (metaConvite == null || metaConvite.isEmpty)
            ? null
            : metaConvite,
      );
    }
    notifyListeners();
  }

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Aplica um role já obtido em outra consulta (ex.: o OnboardingGate já
  /// buscou o perfil inteiro e não precisa de um round-trip extra só pra
  /// isso). Para buscar do zero, use [refreshRole].
  void applyRole(String? role) {
    final user = _currentUser;
    if (user == null || role == null) return;
    _currentUser = user.copyWith(role: role);
    notifyListeners();
  }

  /// Busca perfis.role do usuário atual e atualiza currentUser. Não é
  /// chamado automaticamente em _syncFromSupabaseUser: o perfil (e portanto
  /// o role) só passa a existir depois do onboarding, que roda depois do
  /// login/signup — chamar aqui cedo demais sempre acharia null.
  Future<void> refreshRole() async {
    final user = _currentUser;
    if (user == null) return;
    final perfil = await SupabaseService.client
        .from('perfis')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    applyRole(perfil?['role'] as String?);
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return 'Informe e-mail e senha.';
    }

    try {
      await _service.signIn(email: normalizedEmail, password: password);
      await AppLogger.instance.info('Sessao iniciada para $normalizedEmail');
      return null;
    } on supa.AuthException catch (e) {
      return _translateAuthError(e);
    } catch (_) {
      return 'Não foi possível entrar. Tente novamente.';
    }
  }

  Future<String?> register({
    required String nome,
    required String email,
    required String password,
    String? convite,
  }) async {
    final validation = _service.validateRegistration(
      nome: nome,
      email: email,
      password: password,
    );
    if (validation != null) return validation;

    final normalizedConvite = convite?.trim();

    try {
      final response = await _service.signUp(
        nome: nome.trim(),
        email: email.trim(),
        password: password,
        convite: (normalizedConvite == null || normalizedConvite.isEmpty)
            ? null
            : normalizedConvite,
      );
      // Sincroniza direto da resposta em vez de esperar o stream de
      // onAuthStateChange: quem chama register() precisa saber JÁ nesta
      // volta, via isAuthenticated, se a conta ficou confirmada na hora
      // (sessão presente) ou se falta confirmar o e-mail (sessão nula).
      _syncFromSupabaseUser(response.session?.user);
      await AppLogger.instance.info('Cadastro realizado para ${email.trim()}');
      return null;
    } on supa.AuthException catch (e) {
      return _translateAuthError(e);
    } catch (_) {
      return 'Não foi possível criar a conta. Tente novamente.';
    }
  }

  Future<String?> resetPassword(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return 'Informe seu e-mail.';
    }
    try {
      await _service.resetPassword(normalizedEmail);
      return null;
    } on supa.AuthException catch (e) {
      return _translateAuthError(e);
    } catch (_) {
      return 'Não foi possível enviar o e-mail de redefinição.';
    }
  }

  Future<void> logout() async {
    final currentEmail = _currentUser?.email;
    await _service.signOut();
    if (currentEmail != null) {
      await AppLogger.instance.info('Logout realizado para $currentEmail');
    }
  }

  String? _pendingNotice;

  /// Guarda uma mensagem pra ser mostrada na próxima tela que a ler (ex.:
  /// LoginScreen, após um logout forçado por código de convite inválido) —
  /// necessário porque quem detecta o erro (OnboardingGate) é desmontado
  /// assim que o logout muda isAuthenticated, antes de poder mostrar um
  /// SnackBar com o próprio context.
  void setPendingNotice(String message) {
    _pendingNotice = message;
  }

  String? consumePendingNotice() {
    final notice = _pendingNotice;
    _pendingNotice = null;
    return notice;
  }

  String _translateAuthError(supa.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    if (msg.contains('user already registered')) {
      return 'Já existe uma conta com este e-mail.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    return e.message;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
