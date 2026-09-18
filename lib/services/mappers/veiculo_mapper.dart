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

/// Reconstrói um [Veiculo] a partir da linha crua (snake_case) devolvida
/// pelo supabase_flutter. `oficina_id` é ignorado de propósito — não é
/// campo do model.
Veiculo veiculoFromSupabase(Map<String, dynamic> map) {
  return Veiculo(
    id: map['id'] as String? ?? '',
    clienteId: map['cliente_id'] as String? ?? '',
    marca: map['marca'] as String? ?? '',
    modelo: map['modelo'] as String? ?? '',
    cor: map['cor'] as String? ?? '',
    placa: map['placa'] as String? ?? '',
    ano: (map['ano'] as num?)?.toInt(),
    observacoes: map['observacoes'] as String?,
    ativo: map['ativo'] as bool? ?? true,
  );
}
