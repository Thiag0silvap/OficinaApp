import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/cliente.dart';
import 'package:oficina_app/services/mappers/cliente_mapper.dart';

void main() {
  test('clienteFromSupabase reconstrói todos os campos a partir do formato snake_case', () {
    final map = {
      'id': 'c1',
      'oficina_id': 'oficina-x',
      'nome': 'João',
      'telefone': '11999998888',
      'endereco': 'Rua A, 123',
      'data_cadastro': '2026-01-10T12:00:00.000',
      'observacoes': 'cliente antigo',
      'tipo': 'oficina_parceira',
      'nome_seguradora': null,
      'cnpj': '12345678000199',
      'contato': 'Maria',
      'ativo': true,
    };

    final cliente = clienteFromSupabase(map);

    expect(cliente.id, 'c1');
    expect(cliente.nome, 'João');
    expect(cliente.telefone, '11999998888');
    expect(cliente.endereco, 'Rua A, 123');
    expect(cliente.dataCadastro, DateTime.parse('2026-01-10T12:00:00.000'));
    expect(cliente.observacoes, 'cliente antigo');
    expect(cliente.tipo, TipoCliente.oficinaParceira);
    expect(cliente.nomeSeguradora, isNull);
    expect(cliente.cnpj, '12345678000199');
    expect(cliente.contato, 'Maria');
    expect(cliente.ativo, true);
  });

  test('clienteFromSupabase traduz cada valor de tipo (snake_case -> enum)', () {
    expect(clienteFromSupabase({'tipo': 'particular'}).tipo, TipoCliente.particular);
    expect(clienteFromSupabase({'tipo': 'seguradora'}).tipo, TipoCliente.seguradora);
    expect(
      clienteFromSupabase({'tipo': 'oficina_parceira'}).tipo,
      TipoCliente.oficinaParceira,
    );
    expect(clienteFromSupabase({'tipo': 'frota'}).tipo, TipoCliente.frota);
  });

  test('clienteFromSupabase não lança em campos ausentes/nulos e aplica defaults seguros', () {
    final cliente = clienteFromSupabase({});

    expect(cliente.id, '');
    expect(cliente.nome, '');
    expect(cliente.telefone, '');
    expect(cliente.endereco, isNull);
    expect(cliente.observacoes, isNull);
    expect(cliente.tipo, TipoCliente.particular);
    expect(cliente.ativo, true);
  });

  test('paraSupabase -> clienteFromSupabase é reversível (round-trip)', () {
    final original = Cliente(
      id: 'c2',
      nome: 'Ana',
      telefone: '11888887777',
      dataCadastro: DateTime.parse('2026-02-01T09:30:00.000'),
      tipo: TipoCliente.seguradora,
      nomeSeguradora: 'Porto Seguro',
      ativo: false,
    );

    final supabaseMap = paraSupabase(original, 'oficina-1');
    final restaurado = clienteFromSupabase(supabaseMap);

    expect(restaurado.id, original.id);
    expect(restaurado.nome, original.nome);
    expect(restaurado.telefone, original.telefone);
    expect(restaurado.dataCadastro, original.dataCadastro);
    expect(restaurado.tipo, original.tipo);
    expect(restaurado.nomeSeguradora, original.nomeSeguradora);
    expect(restaurado.ativo, original.ativo);
  });
}
