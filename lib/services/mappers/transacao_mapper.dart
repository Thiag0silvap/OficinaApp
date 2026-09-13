import '../../models/transacao.dart';

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
