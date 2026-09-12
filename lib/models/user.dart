/// Usuário autenticado via Supabase Auth: id (UUID de auth.users),
/// e-mail de login, nome (vindo de user_metadata/perfis) e, se o cadastro
/// veio de um convite ainda não processado, o código do convite.
///
/// [role] (admin/colaborador, de perfis.role) começa nulo: só é conhecido
/// depois que o perfil existe em Supabase, o que pode acontecer depois do
/// login/signup (ver OnboardingGate em main.dart) — nunca inferir
/// permissão a partir de role == null, trate como "ainda não carregado".
class User {
  final String id;
  final String email;
  final String nome;
  final String? convite;
  final String? role;

  const User({
    required this.id,
    required this.email,
    required this.nome,
    this.convite,
    this.role,
  });

  User copyWith({String? role}) {
    return User(
      id: id,
      email: email,
      nome: nome,
      convite: convite,
      role: role ?? this.role,
    );
  }
}
