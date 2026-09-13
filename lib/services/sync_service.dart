import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'db_service.dart';

/// Tenta sincronizar uma operação de escrita com o Supabase. Em caso de
/// falha por conectividade (não erro de banco/RLS/validação), grava a
/// operação na fila local `operacoes_pendentes` para reenvio posterior —
/// nunca lança nesse caso, silenciosamente enfileira. Erros de banco
/// (PostgrestException) e de autenticação (AuthException) SEMPRE
/// propagam: não são "offline", são erros reais que quem chama precisa
/// tratar (mostrar ao usuário, não esconder).
class SyncService {
  SyncService({DBService? db}) : _db = db ?? DBService.instance;

  final DBService _db;

  Future<void> sincronizar({
    required String entidade,
    required String operacao, // 'criar' | 'editar' | 'excluir'
    required String registroId,
    Map<String, dynamic>? payload, // nulo quando operacao == 'excluir'
  }) async {
    final client = SupabaseService.client;
    try {
      switch (operacao) {
        case 'criar':
          await client.from(entidade).insert(payload!);
          break;
        case 'editar':
          await client.from(entidade).update(payload!).eq('id', registroId);
          break;
        case 'excluir':
          await client.from(entidade).delete().eq('id', registroId);
          break;
        default:
          throw ArgumentError('Operação desconhecida: $operacao');
      }
      // Sucesso: se havia uma pendência antiga para este mesmo registro
      // (de uma tentativa anterior que falhou), remove — não é mais
      // necessária.
      await _removerPendenciaSeExistir(entidade, registroId, operacao);
    } on PostgrestException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      // Não é erro de banco/auth conhecido — trata como falha de
      // conectividade: enfileira para reenvio, não propaga.
      await _db.upsertOperacaoPendente(
        entidade: entidade,
        operacao: operacao,
        registroId: registroId,
        payloadJson: payload == null ? null : jsonEncode(payload),
      );
    }
  }

  Future<void> _removerPendenciaSeExistir(
    String entidade,
    String registroId,
    String operacao,
  ) async {
    final pendentes = await _db.getOperacoesPendentes();
    for (final p in pendentes) {
      if (p['entidade'] == entidade &&
          p['registro_id'] == registroId &&
          p['operacao'] == operacao) {
        await _db.removerOperacaoPendente(p['id'] as String);
      }
    }
  }

  /// Varre a fila local e tenta reenviar cada pendência, na ordem em que
  /// foram criadas. Uma falha em uma pendência não interrompe as
  /// seguintes — cada uma incrementa sua contagem de tentativas e segue
  /// na fila para a próxima chamada.
  Future<void> processarPendencias() async {
    final pendentes = await _db.getOperacoesPendentes();
    for (final p in pendentes) {
      final id = p['id'] as String;
      final entidade = p['entidade'] as String;
      final operacao = p['operacao'] as String;
      final registroId = p['registro_id'] as String;
      final payloadJson = p['payload'] as String?;
      final payload = payloadJson == null
          ? null
          : jsonDecode(payloadJson) as Map<String, dynamic>;

      try {
        final client = SupabaseService.client;
        switch (operacao) {
          case 'criar':
            await client.from(entidade).insert(payload!);
            break;
          case 'editar':
            await client.from(entidade).update(payload!).eq('id', registroId);
            break;
          case 'excluir':
            await client.from(entidade).delete().eq('id', registroId);
            break;
        }
        await _db.removerOperacaoPendente(id);
      } on PostgrestException {
        // Erro real (não é falta de conexão) — a pendência permanece na
        // fila, mas registra a tentativa para eventual diagnóstico.
        await _db.incrementarTentativaOperacaoPendente(id);
      } on AuthException {
        await _db.incrementarTentativaOperacaoPendente(id);
      } catch (e) {
        // Ainda sem conexão — mantém na fila sem incrementar tentativas
        // de forma agressiva; incrementa mesmo assim para visibilidade.
        await _db.incrementarTentativaOperacaoPendente(id);
      }
    }
  }
}
