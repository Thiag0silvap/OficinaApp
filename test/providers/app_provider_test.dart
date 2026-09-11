import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/transacao.dart';
import 'package:oficina_app/models/veiculo.dart';
import 'package:oficina_app/providers/app_provider.dart';

Transacao _transacao({
  required TipoTransacao tipo,
  required double valor,
  required DateTime data,
  String categoria = 'Geral',
  String id = '',
  String descricao = 'transação de teste',
}) {
  return Transacao(
    id: id.isEmpty ? '${tipo.name}-${data.toIso8601String()}-$valor' : id,
    tipo: tipo,
    descricao: descricao,
    valor: valor,
    categoria: categoria,
    data: data,
  );
}

Veiculo _veiculo({
  required String id,
  required String clienteId,
  required String placa,
  String marca = 'Marca',
  String modelo = 'Modelo',
  String cor = 'Prata',
}) {
  return Veiculo(
    id: id,
    clienteId: clienteId,
    marca: marca,
    modelo: modelo,
    cor: cor,
    placa: placa,
  );
}

// addVeiculo/updateVeiculo validam a placa ANTES de tocar em banco/auth
// (_validateVeiculo roda antes de _ensureUserDbSelected), então o erro de
// duplicidade sempre aparece primeiro quando existe. Nos casos em que a
// validação DEVE passar, a chamada ainda lança 'Usuário não autenticado'
// (não há banco/usuário real neste teste) — o que importa é que o erro
// levantado não seja o de placa duplicada, provando que a validação em si
// não bateu falso positivo.
Future<Object?> _erroDe(Future<void> Function() acao) async {
  try {
    await acao();
    return null;
  } catch (e) {
    return e;
  }
}

void main() {
  group('totalEntradas / totalSaidas / saldo', () {
    test('lista vazia: tudo zero', () {
      final provider = AppProvider();
      provider.debugSetTransacoes([]);

      expect(provider.totalEntradas, 0);
      expect(provider.totalSaidas, 0);
      expect(provider.saldo, 0);
    });

    test('só entradas: saldo igual ao total de entradas', () {
      final provider = AppProvider();
      provider.debugSetTransacoes([
        _transacao(
          tipo: TipoTransacao.entrada,
          valor: 100,
          data: DateTime(2026, 1, 10),
        ),
        _transacao(
          tipo: TipoTransacao.entrada,
          valor: 50,
          data: DateTime(2026, 2, 5),
        ),
      ]);

      expect(provider.totalEntradas, 150);
      expect(provider.totalSaidas, 0);
      expect(provider.saldo, 150);
    });

    test('só saídas: saldo negativo igual ao total de saídas', () {
      final provider = AppProvider();
      provider.debugSetTransacoes([
        _transacao(
          tipo: TipoTransacao.saida,
          valor: 40,
          data: DateTime(2026, 1, 10),
        ),
        _transacao(
          tipo: TipoTransacao.saida,
          valor: 60,
          data: DateTime(2026, 2, 5),
        ),
      ]);

      expect(provider.totalEntradas, 0);
      expect(provider.totalSaidas, 100);
      expect(provider.saldo, -100);
    });

    test('mix de entradas e saídas: saldo é a diferença', () {
      final provider = AppProvider();
      provider.debugSetTransacoes([
        _transacao(
          tipo: TipoTransacao.entrada,
          valor: 200,
          data: DateTime(2026, 1, 10),
        ),
        _transacao(
          tipo: TipoTransacao.saida,
          valor: 80,
          data: DateTime(2026, 1, 15),
        ),
      ]);

      expect(provider.totalEntradas, 200);
      expect(provider.totalSaidas, 80);
      expect(provider.saldo, 120);
    });
  });

  group('entradasNoMes / saidasNoMes', () {
    test('filtra corretamente por mês e ano, ignorando outros meses', () {
      final provider = AppProvider();
      provider.debugSetTransacoes([
        _transacao(
          tipo: TipoTransacao.entrada,
          valor: 100,
          data: DateTime(2026, 3, 1),
        ),
        _transacao(
          tipo: TipoTransacao.entrada,
          valor: 999,
          data: DateTime(2026, 4, 1), // mês seguinte — não deve contar
        ),
        _transacao(
          tipo: TipoTransacao.entrada,
          valor: 999,
          data: DateTime(2025, 3, 1), // mesmo mês, ano anterior — não deve contar
        ),
        _transacao(
          tipo: TipoTransacao.saida,
          valor: 30,
          data: DateTime(2026, 3, 20),
        ),
        _transacao(
          tipo: TipoTransacao.saida,
          valor: 999,
          data: DateTime(2026, 2, 20), // mês anterior — não deve contar
        ),
      ]);

      final mesReferencia = DateTime(2026, 3, 1);
      expect(provider.entradasNoMes(mesReferencia), 100);
      expect(provider.saidasNoMes(mesReferencia), 30);
    });
  });

  group('resumoPorPeriodo', () {
    test(
      'meses sem transação aparecem com zero, não ausentes da lista',
      () {
        final provider = AppProvider();
        provider.debugSetTransacoes([
          _transacao(
            tipo: TipoTransacao.entrada,
            valor: 100,
            data: DateTime(2026, 1, 15),
          ),
          // Fevereiro/2026 fica sem nenhuma transação de propósito.
          _transacao(
            tipo: TipoTransacao.saida,
            valor: 50,
            data: DateTime(2026, 3, 10),
          ),
          // Fora do período (dezembro/2025) — não deve aparecer no resumo.
          _transacao(
            tipo: TipoTransacao.entrada,
            valor: 999,
            data: DateTime(2025, 12, 1),
          ),
        ]);

        final resumo = provider.resumoPorPeriodo(
          DateTime(2026, 1, 1),
          DateTime(2026, 3, 1),
        );

        expect(resumo.length, 3);

        expect(resumo[0].mes, DateTime(2026, 1, 1));
        expect(resumo[0].entradas, 100);
        expect(resumo[0].saidas, 0);
        expect(resumo[0].saldo, 100);

        expect(resumo[1].mes, DateTime(2026, 2, 1));
        expect(resumo[1].entradas, 0);
        expect(resumo[1].saidas, 0);
        expect(resumo[1].saldo, 0);

        expect(resumo[2].mes, DateTime(2026, 3, 1));
        expect(resumo[2].entradas, 0);
        expect(resumo[2].saidas, 50);
        expect(resumo[2].saldo, -50);
      },
    );
  });

  group('resumoPorCategoria', () {
    test(
      'agrupa grafias variadas da mesma categoria usando a mais frequente '
      'como rótulo, sem misturar com outras categorias',
      () {
        final provider = AppProvider();
        provider.debugSetTransacoes([
          _transacao(
            tipo: TipoTransacao.entrada,
            valor: 100,
            data: DateTime(2026, 1, 10),
            categoria: 'Peças',
          ),
          _transacao(
            tipo: TipoTransacao.entrada,
            valor: 50,
            data: DateTime(2026, 2, 5),
            categoria: 'peças',
          ),
          _transacao(
            tipo: TipoTransacao.entrada,
            valor: 30,
            data: DateTime(2026, 3, 1),
            categoria: 'PEÇAS',
          ),
          _transacao(
            tipo: TipoTransacao.saida,
            valor: 40,
            data: DateTime(2026, 2, 12),
            categoria: 'Serviço',
          ),
          // Fora do período — não deve entrar na agregação.
          _transacao(
            tipo: TipoTransacao.entrada,
            valor: 999,
            data: DateTime(2025, 12, 1),
            categoria: 'Peças',
          ),
        ]);

        final resumo = provider.resumoPorCategoria(
          DateTime(2026, 1, 1),
          DateTime(2026, 3, 1),
        );

        expect(resumo.length, 2);

        // "Peças" tem 3 ocorrências (a grafia mais frequente) contra 1 de
        // "peças" e 1 de "PEÇAS" — vira o rótulo de exibição do grupo.
        final pecas = resumo[0];
        expect(pecas.categoria, 'Peças');
        expect(pecas.entradas, 180); // 100 + 50 + 30
        expect(pecas.saidas, 0);
        expect(pecas.total, 180);

        final servico = resumo[1];
        expect(servico.categoria, 'Serviço');
        expect(servico.entradas, 0);
        expect(servico.saidas, 40);
        expect(servico.total, 40);

        // Ordenado por total decrescente.
        expect(resumo[0].total, greaterThan(resumo[1].total));
      },
    );
  });

  group('percentageChange', () {
    test('current > previous: variação positiva', () {
      final provider = AppProvider();
      final result = provider.percentageChange(150, 100);

      expect(result['label'], '+50%');
      expect(result['up'], isTrue);
    });

    test('current < previous: variação negativa', () {
      final provider = AppProvider();
      final result = provider.percentageChange(50, 100);

      expect(result['label'], '-50%');
      expect(result['up'], isFalse);
    });

    test('previous == 0 e current > 0: label "Novo"', () {
      final provider = AppProvider();
      final result = provider.percentageChange(100, 0);

      expect(result['label'], 'Novo');
      expect(result['up'], isTrue);
    });

    test('previous == 0 e current == 0: 0% sem variação', () {
      final provider = AppProvider();
      final result = provider.percentageChange(0, 0);

      expect(result['label'], '0%');
      expect(result['up'], isTrue);
    });

    test('current == previous (ambos iguais, não-zero): 0% de variação', () {
      final provider = AppProvider();
      final result = provider.percentageChange(100, 100);

      expect(result['label'], '+0%');
      expect(result['up'], isTrue);
    });
  });

  group('validação de placa duplicada (_validateVeiculo)', () {
    test(
      'duas tentativas com a mesma placa (mesmo formato) para clientes '
      'diferentes: a segunda é bloqueada',
      () async {
        final provider = AppProvider();
        provider.debugSetVeiculos([
          _veiculo(id: 'v1', clienteId: 'cliente-1', placa: 'ABC1234'),
        ]);

        final erro = await _erroDe(
          () => provider.addVeiculo(
            _veiculo(id: 'v2', clienteId: 'cliente-2', placa: 'ABC1234'),
          ),
        );

        expect(erro, isA<StateError>());
        expect(
          erro.toString(),
          contains('Já existe um veículo ativo cadastrado com esta placa'),
        );
      },
    );

    test(
      'placas com formatação diferente que normalizam igual também são '
      'bloqueadas',
      () async {
        final provider = AppProvider();
        provider.debugSetVeiculos([
          _veiculo(id: 'v1', clienteId: 'cliente-1', placa: 'ABC-1234'),
        ]);

        final erro = await _erroDe(
          () => provider.addVeiculo(
            _veiculo(id: 'v2', clienteId: 'cliente-2', placa: 'abc1234'),
          ),
        );

        expect(erro, isA<StateError>());
        expect(
          erro.toString(),
          contains('Já existe um veículo ativo cadastrado com esta placa'),
        );
      },
    );

    test(
      'editar outros campos de um veículo sem mudar a placa não bate como '
      'duplicado dele mesmo',
      () async {
        final provider = AppProvider();
        final original = _veiculo(
          id: 'v1',
          clienteId: 'cliente-1',
          placa: 'ABC1234',
        );
        provider.debugSetVeiculos([original]);

        final editado = original.copyWith(cor: 'Preto');
        final erro = await _erroDe(() => provider.updateVeiculo(editado));

        // Não há banco/usuário autenticado neste teste, então updateVeiculo
        // ainda falha — mas o que importa aqui é que NÃO é o erro de placa
        // duplicada, provando que a validação não colidiu com o próprio
        // registro.
        expect(erro, isA<StateError>());
        expect(erro.toString(), isNot(contains('placa')));
      },
    );

    test(
      'placa de um veículo removido (soft delete) pode ser reaproveitada '
      'em um novo cadastro',
      () async {
        final provider = AppProvider();
        // _veiculos só contém ativos (getVeiculos() já filtra no banco) —
        // um veículo removido simplesmente não aparece aqui, simulando o
        // soft delete real.
        provider.debugSetVeiculos([]);

        final erro = await _erroDe(
          () => provider.addVeiculo(
            _veiculo(id: 'v2', clienteId: 'cliente-2', placa: 'ABC1234'),
          ),
        );

        expect(erro, isA<StateError>());
        expect(erro.toString(), isNot(contains('placa')));
      },
    );
  });
}
