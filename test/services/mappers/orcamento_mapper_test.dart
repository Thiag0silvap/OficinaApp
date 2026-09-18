import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/orcamento.dart';
import 'package:oficina_app/services/mappers/orcamento_mapper.dart';

void main() {
  test('orcamentoFromSupabase reconstrói todos os campos a partir do formato snake_case', () {
    final map = {
      'id': 'o1',
      'oficina_id': 'oficina-x',
      'cliente_id': 'c1',
      'cliente_nome': 'João',
      'veiculo_id': 'v1',
      'veiculo_descricao': 'Fiat Uno Branco',
      // supabase_flutter já devolve jsonb decodificado (List<Map>), não String.
      'itens': [
        {'servico': 'Troca de óleo', 'peca': null, 'descricao': 'Óleo 5W30', 'valor': 150.0},
      ],
      'valor_total': 150.0,
      'status': 'em_andamento',
      'data_criacao': '2026-01-01T10:00:00.000',
      'data_aprovacao': '2026-01-02T10:00:00.000',
      'data_conclusao': null,
      'pago': false,
      'data_pagamento': null,
      'observacoes': 'obs gerais',
      'observacoes_cliente': 'obs pro PDF',
      'observacoes_internas': 'obs só da oficina',
      'data_prevista_entrega': '2026-01-05T10:00:00.000',
      'tipo_atendimento': 'seguro',
      'motivo_cancelamento': null,
    };

    final orcamento = orcamentoFromSupabase(map);

    expect(orcamento.id, 'o1');
    expect(orcamento.clienteId, 'c1');
    expect(orcamento.clienteNome, 'João');
    expect(orcamento.veiculoId, 'v1');
    expect(orcamento.veiculoDescricao, 'Fiat Uno Branco');
    expect(orcamento.itens, hasLength(1));
    expect(orcamento.itens.first.servico, 'Troca de óleo');
    expect(orcamento.itens.first.valor, 150.0);
    expect(orcamento.valorTotal, 150.0);
    expect(orcamento.status, OrcamentoStatus.emAndamento);
    expect(orcamento.dataCriacao, DateTime.parse('2026-01-01T10:00:00.000'));
    expect(orcamento.dataAprovacao, DateTime.parse('2026-01-02T10:00:00.000'));
    expect(orcamento.dataConclusao, isNull);
    expect(orcamento.pago, false);
    expect(orcamento.observacoes, 'obs gerais');
    expect(orcamento.observacoesCliente, 'obs pro PDF');
    expect(orcamento.observacoesInternas, 'obs só da oficina');
    expect(orcamento.dataPrevistaEntrega, DateTime.parse('2026-01-05T10:00:00.000'));
    expect(orcamento.tipoAtendimento, TipoAtendimento.seguro);
    expect(orcamento.motivoCancelamento, isNull);
  });

  test('orcamentoFromSupabase traduz cada valor de status (snake_case -> enum)', () {
    expect(orcamentoFromSupabase({'status': 'pendente'}).status, OrcamentoStatus.pendente);
    expect(orcamentoFromSupabase({'status': 'aprovado'}).status, OrcamentoStatus.aprovado);
    expect(
      orcamentoFromSupabase({'status': 'em_andamento'}).status,
      OrcamentoStatus.emAndamento,
    );
    expect(orcamentoFromSupabase({'status': 'concluido'}).status, OrcamentoStatus.concluido);
    expect(orcamentoFromSupabase({'status': 'cancelado'}).status, OrcamentoStatus.cancelado);
  });

  test('orcamentoFromSupabase aceita itens como String JSON (rede de segurança)', () {
    final map = {
      'itens': '[{"servico":"Alinhamento","peca":null,"descricao":"","valor":80.0}]',
    };

    final orcamento = orcamentoFromSupabase(map);

    expect(orcamento.itens, hasLength(1));
    expect(orcamento.itens.first.servico, 'Alinhamento');
  });

  test('orcamentoFromSupabase não lança em campos ausentes/nulos e aplica defaults seguros', () {
    final orcamento = orcamentoFromSupabase({});

    expect(orcamento.id, '');
    expect(orcamento.itens, isEmpty);
    expect(orcamento.valorTotal, 0.0);
    expect(orcamento.status, OrcamentoStatus.pendente);
    expect(orcamento.pago, false);
    expect(orcamento.tipoAtendimento, TipoAtendimento.particular);
  });

  test('paraSupabase -> orcamentoFromSupabase é reversível (round-trip)', () {
    final original = OrcamentoModel(
      id: 'o2',
      clienteId: 'c2',
      clienteNome: 'Maria',
      veiculoId: 'v2',
      veiculoDescricao: 'VW Gol',
      itens: [
        ItemOrcamento(servico: 'Funilaria', peca: 'Para-choque', descricao: 'Troca', valor: 500.0),
      ],
      valorTotal: 500.0,
      status: OrcamentoStatus.cancelado,
      dataCriacao: DateTime.parse('2026-03-01T08:00:00.000'),
      tipoAtendimento: TipoAtendimento.seguro,
      motivoCancelamento: 'Cliente desistiu',
    );

    final supabaseMap = paraSupabase(original, 'oficina-1');
    final restaurado = orcamentoFromSupabase(supabaseMap);

    expect(restaurado.id, original.id);
    expect(restaurado.clienteId, original.clienteId);
    expect(restaurado.status, original.status);
    expect(restaurado.itens.first.servico, original.itens.first.servico);
    expect(restaurado.itens.first.peca, original.itens.first.peca);
    expect(restaurado.valorTotal, original.valorTotal);
    expect(restaurado.tipoAtendimento, original.tipoAtendimento);
    expect(restaurado.motivoCancelamento, original.motivoCancelamento);
  });
}
