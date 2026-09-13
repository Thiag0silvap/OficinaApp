import '../../models/veiculo.dart';

Map<String, dynamic> paraSupabase(Veiculo v, String oficinaId) {
  return {
    'id': v.id,
    'oficina_id': oficinaId,
    'cliente_id': v.clienteId,
    'marca': v.marca,
    'modelo': v.modelo,
    'cor': v.cor,
    'placa': v.placa,
    'ano': v.ano,
    'observacoes': v.observacoes,
    'ativo': v.ativo,
  };
}
