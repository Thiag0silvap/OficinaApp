import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/nota.dart';
import 'package:oficina_app/models/orcamento.dart';
import 'package:oficina_app/services/mappers/nota_mapper.dart';

void main() {
  test('notaFromSupabase reconstrói todos os campos a partir do formato snake_case', () {
    final map = {
      'id': 'n1',
      'oficina_id': 'oficina-x',
      'orcamento_id': 'o1',
      'cliente_id': 'c1',
      'cliente_nome': 'João',
      'veiculo_id': 'v1',
      'veiculo_descricao': 'Fiat Uno Branco',
      'itens': [
        {'servico': 'Troca de óleo', 'peca': null, 'descricao': 'Óleo 5W30', 'valor': 150.0},
      ],
      'valor_total': 150.0,
      'data_emissao': '2026-01-05T14:00:00.000',
    };

    final nota = notaFromSupabase(map);

    expect(nota.id, 'n1');
    expect(nota.orcamentoId, 'o1');
    expect(nota.clienteId, 'c1');
    expect(nota.clienteNome, 'João');
    expect(nota.veiculoId, 'v1');
    expect(nota.veiculoDescricao, 'Fiat Uno Branco');
    expect(nota.itens, hasLength(1));
    expect(nota.itens.first.servico, 'Troca de óleo');
    expect(nota.valorTotal, 150.0);
    expect(nota.dataEmissao, DateTime.parse('2026-01-05T14:00:00.000'));
  });

  test('notaFromSupabase aceita itens como String JSON (rede de segurança)', () {
    final map = {
      'cliente_nome': 'Ana',
      'valor_total': 80.0,
      'itens': '[{"servico":"Alinhamento","peca":null,"descricao":"","valor":80.0}]',
    };

    final nota = notaFromSupabase(map);

    expect(nota.itens, hasLength(1));
    expect(nota.itens.first.servico, 'Alinhamento');
  });

  test('notaFromSupabase não lança em campos ausentes/nulos e aplica defaults seguros', () {
    final nota = notaFromSupabase({});

    expect(nota.id, '');
    expect(nota.orcamentoId, isNull);
    expect(nota.clienteId, isNull);
    expect(nota.clienteNome, '');
    expect(nota.itens, isEmpty);
    expect(nota.valorTotal, 0.0);
  });

  test('paraSupabase -> notaFromSupabase é reversível (round-trip)', () {
    final original = Nota(
      id: 'n2',
      orcamentoId: 'o2',
      clienteId: 'c2',
      clienteNome: 'Maria',
      veiculoId: 'v2',
      veiculoDescricao: 'VW Gol',
      itens: [
        ItemOrcamento(servico: 'Funilaria', peca: 'Para-choque', descricao: 'Troca', valor: 500.0),
      ],
      valorTotal: 500.0,
      dataEmissao: DateTime.parse('2026-03-01T08:00:00.000'),
    );

    final supabaseMap = paraSupabase(original, 'oficina-1');
    final restaurado = notaFromSupabase(supabaseMap);

    expect(restaurado.id, original.id);
    expect(restaurado.orcamentoId, original.orcamentoId);
    expect(restaurado.clienteNome, original.clienteNome);
    expect(restaurado.itens.first.servico, original.itens.first.servico);
    expect(restaurado.valorTotal, original.valorTotal);
    expect(restaurado.dataEmissao, original.dataEmissao);
  });
}
