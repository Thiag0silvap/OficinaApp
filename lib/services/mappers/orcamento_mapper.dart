import 'dart:async';
import 'dart:convert';

import '../../models/orcamento.dart';
import '../app_logger.dart';

Map<String, dynamic> paraSupabase(OrcamentoModel o, String oficinaId) {
  return {
    'id': o.id,
    'oficina_id': oficinaId,
    'cliente_id': o.clienteId,
    'cliente_nome': o.clienteNome,
    'veiculo_id': o.veiculoId,
    'veiculo_descricao': o.veiculoDescricao,
    'itens': o.itens.map((i) => i.toMap()).toList(),
    'valor_total': o.valorTotal,
    'status': _statusParaSupabase(o.status),
    'data_criacao': o.dataCriacao.toIso8601String(),
    'data_aprovacao': o.dataAprovacao?.toIso8601String(),
    'data_conclusao': o.dataConclusao?.toIso8601String(),
    'pago': o.pago,
    'data_pagamento': o.dataPagamento?.toIso8601String(),
    'observacoes': o.observacoes,
    'observacoes_cliente': o.observacoesCliente,
    'observacoes_internas': o.observacoesInternas,
    'data_prevista_entrega': o.dataPrevistaEntrega?.toIso8601String(),
    'tipo_atendimento': _tipoAtendimentoParaSupabase(o.tipoAtendimento),
    'motivo_cancelamento': o.motivoCancelamento,
  };
}

String _statusParaSupabase(OrcamentoStatus status) {
  switch (status) {
    case OrcamentoStatus.pendente:
      return 'pendente';
    case OrcamentoStatus.aprovado:
      return 'aprovado';
    case OrcamentoStatus.emAndamento:
      return 'em_andamento';
    case OrcamentoStatus.concluido:
      return 'concluido';
    case OrcamentoStatus.cancelado:
      return 'cancelado';
  }
}

String _tipoAtendimentoParaSupabase(TipoAtendimento tipo) {
  switch (tipo) {
    case TipoAtendimento.particular:
      return 'particular';
    case TipoAtendimento.seguro:
      return 'seguro';
  }
}

/// Reconstrói um [OrcamentoModel] a partir da linha crua (snake_case)
/// devolvida pelo supabase_flutter. `oficina_id` é ignorado de propósito —
/// não é campo do model.
OrcamentoModel orcamentoFromSupabase(Map<String, dynamic> map) {
  return OrcamentoModel(
    id: map['id'] as String? ?? '',
    clienteId: map['cliente_id'] as String? ?? '',
    clienteNome: map['cliente_nome'] as String? ?? '',
    veiculoId: map['veiculo_id'] as String? ?? '',
    veiculoDescricao: map['veiculo_descricao'] as String? ?? '',
    itens: _itensFromSupabase(map['itens']),
    valorTotal: (map['valor_total'] as num?)?.toDouble() ?? 0.0,
    status: _statusFromSupabase(map['status'] as String?),
    dataCriacao: _dataCriacaoFromSupabase(map),
    dataAprovacao: map['data_aprovacao'] != null
        ? DateTime.parse(map['data_aprovacao'] as String)
        : null,
    dataConclusao: map['data_conclusao'] != null
        ? DateTime.parse(map['data_conclusao'] as String)
        : null,
    pago: map['pago'] as bool? ?? false,
    dataPagamento: map['data_pagamento'] != null
        ? DateTime.parse(map['data_pagamento'] as String)
        : null,
    observacoes: map['observacoes'] as String?,
    observacoesCliente: map['observacoes_cliente'] as String?,
    observacoesInternas: map['observacoes_internas'] as String?,
    dataPrevistaEntrega: map['data_prevista_entrega'] != null
        ? DateTime.parse(map['data_prevista_entrega'] as String)
        : null,
    tipoAtendimento:
        _tipoAtendimentoFromSupabase(map['tipo_atendimento'] as String?),
    motivoCancelamento: map['motivo_cancelamento'] as String?,
  );
}

DateTime _dataCriacaoFromSupabase(Map<String, dynamic> map) {
  final raw = map['data_criacao'];
  if (raw != null) return DateTime.parse(raw as String);
  final id = map['id'] ?? 'desconhecido';
  unawaited(
    AppLogger.instance.warning(
      'Orçamento $id veio do Supabase sem data_criacao — usando DateTime.now() como fallback',
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

OrcamentoStatus _statusFromSupabase(String? status) {
  switch (status) {
    case 'aprovado':
      return OrcamentoStatus.aprovado;
    case 'em_andamento':
      return OrcamentoStatus.emAndamento;
    case 'concluido':
      return OrcamentoStatus.concluido;
    case 'cancelado':
      return OrcamentoStatus.cancelado;
    case 'pendente':
    default:
      return OrcamentoStatus.pendente;
  }
}

TipoAtendimento _tipoAtendimentoFromSupabase(String? tipo) {
  switch (tipo) {
    case 'seguro':
      return TipoAtendimento.seguro;
    case 'particular':
    default:
      return TipoAtendimento.particular;
  }
}
