import 'dart:async';
import 'dart:convert';

import '../../models/nota.dart';
import '../../models/orcamento.dart' show ItemOrcamento;
import '../app_logger.dart';

Map<String, dynamic> paraSupabase(Nota n, String oficinaId) {
  return {
    'id': n.id,
    'oficina_id': oficinaId,
    'orcamento_id': n.orcamentoId,
    'cliente_id': n.clienteId,
    'cliente_nome': n.clienteNome,
    'veiculo_id': n.veiculoId,
    'veiculo_descricao': n.veiculoDescricao,
    'itens': n.itens.map((i) => i.toMap()).toList(),
    'valor_total': n.valorTotal,
    'data_emissao': n.dataEmissao.toIso8601String(),
  };
}

/// Reconstrói uma [Nota] a partir da linha crua (snake_case) devolvida
/// pelo supabase_flutter. `oficina_id` é ignorado de propósito — não é
/// campo do model.
Nota notaFromSupabase(Map<String, dynamic> map) {
  return Nota(
    id: map['id'] as String? ?? '',
    orcamentoId: map['orcamento_id'] as String?,
    clienteId: map['cliente_id'] as String?,
    clienteNome: map['cliente_nome'] as String? ?? '',
    veiculoId: map['veiculo_id'] as String?,
    veiculoDescricao: map['veiculo_descricao'] as String?,
    itens: _itensFromSupabase(map['itens']),
    valorTotal: (map['valor_total'] as num?)?.toDouble() ?? 0.0,
    dataEmissao: _dataEmissaoFromSupabase(map),
  );
}

DateTime _dataEmissaoFromSupabase(Map<String, dynamic> map) {
  final raw = map['data_emissao'];
  if (raw != null) return DateTime.parse(raw as String);
  final id = map['id'] ?? 'desconhecido';
  unawaited(
    AppLogger.instance.warning(
      'Nota $id veio do Supabase sem data_emissao — usando DateTime.now() como fallback',
    ),
  );
  return DateTime.now();
}

/// `itens` é jsonb no Supabase — o supabase_flutter já devolve List/Map
/// decodidos (não uma String JSON), mas aceita o formato String também
/// como rede de segurança caso isso mude.
List<ItemOrcamento> _itensFromSupabase(dynamic itens) {
  if (itens == null) return [];
  final lista =
      itens is String ? jsonDecode(itens) as List<dynamic> : itens as List<dynamic>;
  return lista
      .map((e) => ItemOrcamento.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();
}
