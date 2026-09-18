import 'dart:async';

import '../../models/transacao.dart';
import '../app_logger.dart';

Map<String, dynamic> paraSupabase(
  Transacao t,
  String oficinaId, {
  double? valorOriginal,
  DateTime? editadoEm,
}) {
  final valorOriginalFinal = valorOriginal ?? t.valorOriginal;
  final editadoEmFinal = editadoEm ?? t.editadoEm;
  return {
    'id': t.id,
    'oficina_id': oficinaId,
    'tipo': _tipoParaSupabase(t.tipo),
    'descricao': t.descricao,
    'valor': t.valor,
    'categoria': t.categoria,
    'data': t.data.toIso8601String(),
    'orcamento_id': t.orcamentoId,
    'observacoes': t.observacoes,
    if (valorOriginalFinal != null) 'valor_original': valorOriginalFinal,
    if (editadoEmFinal != null) 'editado_em': editadoEmFinal.toIso8601String(),
  };
}

String _tipoParaSupabase(TipoTransacao tipo) {
  switch (tipo) {
    case TipoTransacao.entrada:
      return 'entrada';
    case TipoTransacao.saida:
      return 'saida';
  }
}

/// Reconstrói uma [Transacao] a partir da linha crua (snake_case)
/// devolvida pelo supabase_flutter. `oficina_id` é ignorado de propósito —
/// não é campo do model.
Transacao transacaoFromSupabase(Map<String, dynamic> map) {
  return Transacao(
    id: map['id'] as String? ?? '',
    tipo: _tipoFromSupabase(map['tipo'] as String?),
    descricao: map['descricao'] as String? ?? '',
    valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
    categoria: map['categoria'] as String? ?? '',
    data: _dataFromSupabase(map),
    orcamentoId: map['orcamento_id'] as String?,
    observacoes: map['observacoes'] as String?,
    valorOriginal: (map['valor_original'] as num?)?.toDouble(),
    editadoEm: map['editado_em'] != null
        ? DateTime.parse(map['editado_em'] as String)
        : null,
  );
}

DateTime _dataFromSupabase(Map<String, dynamic> map) {
  final raw = map['data'];
  if (raw != null) return DateTime.parse(raw as String);
  final id = map['id'] ?? 'desconhecido';
  unawaited(
    AppLogger.instance.warning(
      'Transação $id veio do Supabase sem data — usando DateTime.now() como fallback',
    ),
  );
  return DateTime.now();
}

TipoTransacao _tipoFromSupabase(String? tipo) {
  switch (tipo) {
    case 'saida':
      return TipoTransacao.saida;
    case 'entrada':
    default:
      return TipoTransacao.entrada;
  }
}
