import '../../models/orcamento.dart';

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
