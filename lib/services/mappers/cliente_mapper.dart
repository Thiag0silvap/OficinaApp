import 'dart:async';

import '../../models/cliente.dart';
import '../app_logger.dart';

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

/// Reconstrói um [Cliente] a partir da linha crua (snake_case) devolvida
/// pelo supabase_flutter. `oficina_id` é ignorado de propósito — não é
/// campo do model, só existe do lado Supabase/contexto.
Cliente clienteFromSupabase(Map<String, dynamic> map) {
  return Cliente(
    id: map['id'] as String? ?? '',
    nome: map['nome'] as String? ?? '',
    telefone: map['telefone'] as String? ?? '',
    endereco: map['endereco'] as String?,
    dataCadastro: _dataCadastroFromSupabase(map),
    observacoes: map['observacoes'] as String?,
    tipo: _tipoClienteFromSupabase(map['tipo'] as String?),
    nomeSeguradora: map['nome_seguradora'] as String?,
    cnpj: map['cnpj'] as String?,
    contato: map['contato'] as String?,
    ativo: map['ativo'] as bool? ?? true,
  );
}

DateTime _dataCadastroFromSupabase(Map<String, dynamic> map) {
  final raw = map['data_cadastro'];
  if (raw != null) return DateTime.parse(raw as String);
  final id = map['id'] ?? 'desconhecido';
  unawaited(
    AppLogger.instance.warning(
      'Cliente $id veio do Supabase sem data_cadastro — usando DateTime.now() como fallback',
    ),
  );
  return DateTime.now();
}

TipoCliente _tipoClienteFromSupabase(String? tipo) {
  switch (tipo) {
    case 'seguradora':
      return TipoCliente.seguradora;
    case 'oficina_parceira':
      return TipoCliente.oficinaParceira;
    case 'frota':
      return TipoCliente.frota;
    case 'particular':
    default:
      return TipoCliente.particular;
  }
}
