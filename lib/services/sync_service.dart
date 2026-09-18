import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'db_service.dart';

import '../models/cliente.dart';
import '../models/nota.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../models/veiculo.dart';
import 'mappers/cliente_mapper.dart' as cliente_mapper;
import 'mappers/nota_mapper.dart' as nota_mapper;
import 'mappers/orcamento_mapper.dart' as orcamento_mapper;
import 'mappers/transacao_mapper.dart' as transacao_mapper;
import 'mappers/veiculo_mapper.dart' as veiculo_mapper;

/// Linhas cruas (não mapeadas) dos 3 catálogos custom, sempre buscadas
/// juntas. Propositalmente CRUAS (não passadas pelos mappers *FromSupabase
/// da Etapa 1): esses mappers descartam o `id` da linha (não é campo de
/// nenhum model Dart, só existe pro catálogo mesmo), mas quem for gravar
/// o espelho local precisa desse `id` pra upsert/reconciliação — ver
/// DBService.aplicarMarcasModelosCustomRemoto/aplicarPecasCustomRemoto/
/// aplicarServicosCustomRemoto, que aplicam os mappers internamente
/// preservando o id da linha crua.
typedef CatalogosCustomRemoto = ({
  List<Map<String, dynamic>> marcasModelos,
  List<Map<String, dynamic>> pecas,
  List<Map<String, dynamic>> servicos,
});

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

  // ================= LEITURA REMOTA (online-first) =================
  //
  // Busca cada entidade direto do Supabase e aplica o mapper *FromSupabase
  // (Etapa 1) linha a linha. Erro NÃO é tratado aqui: PostgrestException e
  // AuthException propagam por serem erros reais (RLS, dado inválido,
  // sessão expirada), e qualquer outra exceção (rede) também propaga sem
  // cair em fallback algum — quem decide se uma falha genérica deve cair
  // pro cache local é o chamador (Etapa 3), não esta camada.
  //
  // oficina_id é sempre filtrado explicitamente, mesmo a RLS devendo
  // cobrir sozinha — mesmo padrão já usado em todo o resto do projeto
  // (OnboardingGate, EquipeScreen etc.), nenhuma leitura hoje confia só na
  // RLS sem filtro explícito também.

  Future<List<Cliente>> buscarClientesRemoto(String oficinaId) async {
    final rows = await SupabaseService.client
        .from('clientes')
        .select()
        .eq('oficina_id', oficinaId)
        .or('ativo.is.null,ativo.eq.true');
    return rows.map(cliente_mapper.clienteFromSupabase).toList();
  }

  Future<List<Veiculo>> buscarVeiculosRemoto(String oficinaId) async {
    final rows = await SupabaseService.client
        .from('veiculos')
        .select()
        .eq('oficina_id', oficinaId)
        .or('ativo.is.null,ativo.eq.true');
    return rows.map(veiculo_mapper.veiculoFromSupabase).toList();
  }

  Future<List<Orcamento>> buscarOrcamentosRemoto(String oficinaId) async {
    final rows = await SupabaseService.client
        .from('orcamentos')
        .select()
        .eq('oficina_id', oficinaId);
    return rows.map(orcamento_mapper.orcamentoFromSupabase).toList();
  }

  Future<List<Transacao>> buscarTransacoesRemoto(String oficinaId) async {
    final rows = await SupabaseService.client
        .from('transacoes')
        .select()
        .eq('oficina_id', oficinaId)
        .order('data', ascending: false);
    return rows.map(transacao_mapper.transacaoFromSupabase).toList();
  }

  /// Ordenação por `data_emissao DESC` não foi listada explicitamente na
  /// decisão de filtros/ordenação (que citou só clientes/veiculos/
  /// orcamentos/transacoes/catálogos) — segue o mesmo princípio geral
  /// ("espelhar o que a leitura local já aplica hoje"): DBService.getNotas
  /// já ordena assim.
  Future<List<Nota>> buscarNotasRemoto(String oficinaId) async {
    final rows = await SupabaseService.client
        .from('notas')
        .select()
        .eq('oficina_id', oficinaId)
        .order('data_emissao', ascending: false);
    return rows.map(nota_mapper.notaFromSupabase).toList();
  }

  /// Retorna as linhas cruas dos 3 catálogos — ver a nota no typedef
  /// [CatalogosCustomRemoto] sobre por que os mappers *FromSupabase não
  /// são aplicados aqui.
  Future<CatalogosCustomRemoto> buscarCatalogosCustomRemoto(
    String oficinaId,
  ) async {
    final client = SupabaseService.client;

    final marcasModelosRows = await client
        .from('marcas_modelos_custom')
        .select()
        .eq('oficina_id', oficinaId);
    final pecasRows =
        await client.from('pecas_custom').select().eq('oficina_id', oficinaId);
    final servicosRows = await client
        .from('servicos_custom')
        .select()
        .eq('oficina_id', oficinaId);

    return (
      marcasModelos: marcasModelosRows,
      pecas: pecasRows,
      servicos: servicosRows,
    );
  }
}
