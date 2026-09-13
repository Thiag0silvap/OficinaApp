import '../../models/nota.dart';

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
