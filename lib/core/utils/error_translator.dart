import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduz qualquer exceção para uma mensagem amigável ao usuário final.
/// PostgrestException e AuthException já carregam mensagens específicas
/// tratadas caso a caso onde já existem (ex.: AuthProvider._translateAuthError);
/// esta função é o fallback genérico para qualquer OUTRA exceção, cobrindo
/// principalmente falha de conectividade (que é a esmagadora maioria dos
/// casos de "erro não classificado" no app) sem nunca expor texto técnico
/// bruto (nome da classe de exceção, stack trace, mensagens de socket) ao
/// usuário.
String traduzirErro(Object erro) {
  if (erro is PostgrestException) {
    return 'Erro ao acessar os dados: ${erro.message}';
  }
  if (erro is AuthException) {
    return erro.message;
  }
  // Qualquer outra coisa (SocketException, ClientException, TimeoutException,
  // FormatException, etc.) é tratada como falta de conectividade — é o
  // cenário mais comum e o usuário sabe exatamente o que fazer.
  return 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
}
