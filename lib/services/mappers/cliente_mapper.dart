import '../../models/cliente.dart';

Map<String, dynamic> paraSupabase(Cliente c, String oficinaId) {
  return {
    'id': c.id,
    'oficina_id': oficinaId,
    'nome': c.nome,
    'telefone': c.telefone,
    'endereco': c.endereco,
    'data_cadastro': c.dataCadastro.toIso8601String(),
    'observacoes': c.observacoes,
    'tipo': _tipoClienteParaSupabase(c.tipo),
    'nome_seguradora': c.nomeSeguradora,
    'cnpj': c.cnpj,
    'contato': c.contato,
    'ativo': c.ativo,
  };
}

String _tipoClienteParaSupabase(TipoCliente tipo) {
  switch (tipo) {
    case TipoCliente.particular:
      return 'particular';
    case TipoCliente.seguradora:
      return 'seguradora';
    case TipoCliente.oficinaParceira:
      return 'oficina_parceira';
    case TipoCliente.frota:
      return 'frota';
  }
}
