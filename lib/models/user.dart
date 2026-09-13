/// Usuário autenticado via Supabase Auth: id (UUID de auth.users),
/// e-mail de login, nome (vindo de user_metadata/perfis) e, se o cadastro
/// veio de um convite ainda não processado, o código do convite.
///
/// [role] (admin/colaborador, de perfis.role) e [oficinaId] (de
/// perfis.oficina_id) começam nulos: só são conhecidos depois que o perfil
/// existe em Supabase, o que pode acontecer depois do login/signup (ver
/// OnboardingGate em main.dart) — nunca inferir permissão a partir de
/// role == null, nem oficina a partir de oficinaId == null, trate como
/// "ainda não carregado".
class User {
  final String id;
  final String email;
  final String nome;
  final String? convite;
  final String? role;
  final String? oficinaId;

  const User({
    required this.id,
    required this.email,
    required this.nome,
    this.convite,
    this.role,
    this.oficinaId,
  });

  User copyWith({String? role, String? oficinaId}) {
    return User(
      id: id,
      email: email,
      nome: nome,
      convite: convite,
      role: role ?? this.role,
      oficinaId: oficinaId ?? this.oficinaId,
    );
  }
}
