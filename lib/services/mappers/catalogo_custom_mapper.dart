Map<String, dynamic> marcaModeloParaSupabase({
  required String id,
  required String marca,
  String? modelo,
  required String oficinaId,
}) {
  return {
    'id': id,
    'oficina_id': oficinaId,
    'marca': marca,
    'modelo': modelo,
  };
}

Map<String, dynamic> pecaParaSupabase({
  required String id,
  required String peca,
  required String oficinaId,
}) {
  return {
    'id': id,
    'oficina_id': oficinaId,
    'peca': peca,
  };
}

Map<String, dynamic> servicoParaSupabase({
  required String id,
  required String servico,
  required String oficinaId,
}) {
  return {
    'id': id,
    'oficina_id': oficinaId,
    'servico': servico,
  };
}
