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

/// Reconstrói o par marca/modelo a partir da linha crua (snake_case)
/// devolvida pelo supabase_flutter — mesmo formato que
/// `DBService.getMarcasModelosCustom()` já retorna. `oficina_id` é
/// ignorado de propósito.
Map<String, String?> marcaModeloFromSupabase(Map<String, dynamic> map) {
  return {
    'marca': map['marca'] as String?,
    'modelo': map['modelo'] as String?,
  };
}

/// Mesmo formato que `DBService.getPecasCustom()` já retorna (String).
String pecaFromSupabase(Map<String, dynamic> map) {
  return map['peca'] as String? ?? '';
}

/// Mesmo formato que `DBService.getServicosCustom()` já retorna (String).
String servicoFromSupabase(Map<String, dynamic> map) {
  return map['servico'] as String? ?? '';
}
