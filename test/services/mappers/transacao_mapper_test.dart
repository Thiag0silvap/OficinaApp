import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/transacao.dart';
import 'package:oficina_app/services/mappers/transacao_mapper.dart';

void main() {
  test('transacaoFromSupabase reconstrói todos os campos a partir do formato snake_case', () {
    final map = {
      'id': 't1',
      'oficina_id': 'oficina-x',
      'tipo': 'saida',
      'descricao': 'Compra de peça',
      'valor': 250.0,
      'categoria': 'Peças',
      'data': '2026-01-10T12:00:00.000',
      'orcamento_id': 'o1',
      'observacoes': 'nota fiscal 123',
      'valor_original': 300.0,
      'editado_em': '2026-01-11T09:00:00.000',
    };

    final transacao = transacaoFromSupabase(map);

    expect(transacao.id, 't1');
    expect(transacao.tipo, TipoTransacao.saida);
    expect(transacao.descricao, 'Compra de peça');
    expect(transacao.valor, 250.0);
    expect(transacao.categoria, 'Peças');
    expect(transacao.data, DateTime.parse('2026-01-10T12:00:00.000'));
    expect(transacao.orcamentoId, 'o1');
    expect(transacao.observacoes, 'nota fiscal 123');
    expect(transacao.valorOriginal, 300.0);
    expect(transacao.editadoEm, DateTime.parse('2026-01-11T09:00:00.000'));
  });

  test('transacaoFromSupabase traduz tipo (snake_case -> enum) nos dois valores', () {
    expect(transacaoFromSupabase({'tipo': 'entrada'}).tipo, TipoTransacao.entrada);
    expect(transacaoFromSupabase({'tipo': 'saida'}).tipo, TipoTransacao.saida);
  });

  test('transacaoFromSupabase mantém valorOriginal/editadoEm nulos quando ausentes', () {
    final transacao = transacaoFromSupabase({
      'id': 't2',
      'tipo': 'entrada',
      'valor': 100.0,
    });

    expect(transacao.valorOriginal, isNull);
    expect(transacao.editadoEm, isNull);
  });

  test('transacaoFromSupabase não lança em campos ausentes/nulos e aplica defaults seguros', () {
    final transacao = transacaoFromSupabase({});

    expect(transacao.id, '');
    expect(transacao.tipo, TipoTransacao.entrada);
    expect(transacao.descricao, '');
    expect(transacao.valor, 0.0);
    expect(transacao.orcamentoId, isNull);
  });

  test('paraSupabase -> transacaoFromSupabase é reversível (round-trip, com auditoria)', () {
    final original = Transacao(
      id: 't3',
      tipo: TipoTransacao.saida,
      descricao: 'Ajuste de valor',
      valor: 90.0,
      categoria: 'Serviço',
      data: DateTime.parse('2026-02-01T10:00:00.000'),
      orcamentoId: 'o3',
      valorOriginal: 100.0,
      editadoEm: DateTime.parse('2026-02-02T10:00:00.000'),
    );

    final supabaseMap = paraSupabase(original, 'oficina-1');
    final restaurado = transacaoFromSupabase(supabaseMap);

    expect(restaurado.id, original.id);
    expect(restaurado.tipo, original.tipo);
    expect(restaurado.valor, original.valor);
    expect(restaurado.data, original.data);
    expect(restaurado.orcamentoId, original.orcamentoId);
    expect(restaurado.valorOriginal, original.valorOriginal);
    expect(restaurado.editadoEm, original.editadoEm);
  });
}
