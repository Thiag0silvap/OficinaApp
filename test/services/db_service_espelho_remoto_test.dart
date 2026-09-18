import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/cliente.dart';
import 'package:oficina_app/models/orcamento.dart';
import 'package:oficina_app/models/transacao.dart';
import 'package:oficina_app/services/db_service.dart';

import 'db_service_test_utils.dart';

Cliente _cliente({required String id, required String nome}) {
  return Cliente(
    id: id,
    nome: nome,
    telefone: '11999990000',
    dataCadastro: DateTime(2026, 1, 1),
    tipo: TipoCliente.particular,
  );
}

OrcamentoModel _orcamento({required String id, required double valorTotal}) {
  return OrcamentoModel(
    id: id,
    clienteId: 'c1',
    clienteNome: 'Cliente Teste',
    veiculoId: 'v1',
    veiculoDescricao: 'Fiat Uno',
    itens: const [],
    valorTotal: valorTotal,
    status: OrcamentoStatus.pendente,
    dataCriacao: DateTime(2026, 1, 1),
  );
}

void main() {
  final db = DBService.instance;

  setUpAll(setUpDbServiceTests);
  tearDownAll(tearDownDbServiceTests);

  group('temPendenciaPara', () {
    test('retorna true quando existe pendência para entidade+registroId', () async {
      await freshTestUserId();
      await db.upsertOperacaoPendente(
        entidade: 'clientes',
        operacao: 'editar',
        registroId: 'c1',
        payloadJson: null,
      );

      expect(await db.temPendenciaPara('clientes', 'c1'), true);
    });

    test('retorna false quando não existe pendência', () async {
      await freshTestUserId();

      expect(await db.temPendenciaPara('clientes', 'inexistente'), false);
    });
  });

  group('aplicarClientesRemoto', () {
    test('não sobrescreve registro com pendência, mas sobrescreve o sem pendência', () async {
      await freshTestUserId();

      await db.insertCliente(_cliente(id: 'c1', nome: 'Original com pendência'));
      await db.insertCliente(_cliente(id: 'c2', nome: 'Original sem pendência'));
      await db.upsertOperacaoPendente(
        entidade: 'clientes',
        operacao: 'editar',
        registroId: 'c1',
        payloadJson: null,
      );

      await db.aplicarClientesRemoto([
        _cliente(id: 'c1', nome: 'Veio do Supabase (não deveria aparecer)'),
        _cliente(id: 'c2', nome: 'Veio do Supabase (deveria aparecer)'),
      ]);

      final clientes = {for (final c in await db.getClientes()) c.id: c.nome};
      expect(clientes['c1'], 'Original com pendência');
      expect(clientes['c2'], 'Veio do Supabase (deveria aparecer)');
    });

    test('insere um cliente novo (sem pendência, ainda não existia local)', () async {
      await freshTestUserId();

      await db.aplicarClientesRemoto([_cliente(id: 'c3', nome: 'Novo do Supabase')]);

      final clientes = {for (final c in await db.getClientes()) c.id: c.nome};
      expect(clientes['c3'], 'Novo do Supabase');
    });
  });

  group('aplicarOrcamentosRemoto (reconciliarDelecao)', () {
    test('remove registro local ausente da lista remota e sem pendência de criar', () async {
      await freshTestUserId();

      await db.insertOrcamento(_orcamento(id: 'o1', valorTotal: 100));

      await db.aplicarOrcamentosRemoto([]);

      final ids = (await db.getOrcamentos()).map((o) => o.id).toSet();
      expect(ids.contains('o1'), false);
    });

    test('preserva registro local ausente da lista remota mas com pendência de criar', () async {
      await freshTestUserId();

      await db.insertOrcamento(_orcamento(id: 'o2', valorTotal: 200));
      await db.upsertOperacaoPendente(
        entidade: 'orcamentos',
        operacao: 'criar',
        registroId: 'o2',
        payloadJson: null,
      );

      await db.aplicarOrcamentosRemoto([]);

      final ids = (await db.getOrcamentos()).map((o) => o.id).toSet();
      expect(ids.contains('o2'), true);
    });

    test('upserta um registro presente na lista remota normalmente', () async {
      await freshTestUserId();

      await db.insertOrcamento(_orcamento(id: 'o3', valorTotal: 300));

      await db.aplicarOrcamentosRemoto([_orcamento(id: 'o3', valorTotal: 999)]);

      final orcamento = (await db.getOrcamentos()).firstWhere((o) => o.id == 'o3');
      expect(orcamento.valorTotal, 999);
    });
  });

  group('aplicarTransacoesRemoto (reconciliarDelecao)', () {
    test('remove registro local ausente da lista remota e sem pendência de criar', () async {
      await freshTestUserId();

      await db.insertTransacao(
        Transacao(
          id: 't1',
          tipo: TipoTransacao.entrada,
          descricao: 'teste',
          valor: 50,
          categoria: 'Geral',
          data: DateTime(2026, 1, 1),
        ),
      );

      await db.aplicarTransacoesRemoto([]);

      final ids = (await db.getTransacoes()).map((t) => t.id).toSet();
      expect(ids.contains('t1'), false);
    });

    test('preserva registro local ausente da lista remota mas com pendência de criar', () async {
      await freshTestUserId();

      await db.insertTransacao(
        Transacao(
          id: 't2',
          tipo: TipoTransacao.saida,
          descricao: 'teste',
          valor: 70,
          categoria: 'Geral',
          data: DateTime(2026, 1, 1),
        ),
      );
      await db.upsertOperacaoPendente(
        entidade: 'transacoes',
        operacao: 'criar',
        registroId: 't2',
        payloadJson: null,
      );

      await db.aplicarTransacoesRemoto([]);

      final ids = (await db.getTransacoes()).map((t) => t.id).toSet();
      expect(ids.contains('t2'), true);
    });
  });

  group('aplicarPecasCustomRemoto / aplicarServicosCustomRemoto / aplicarMarcasModelosCustomRemoto', () {
    test('upsert e reconciliação de deleção funcionam com linhas cruas (id preservado)', () async {
      await freshTestUserId();

      await db.insertPecaCustom('Peça antiga');

      // Lista remota vazia + sem pendência -> reconciliação remove a peça.
      await db.aplicarPecasCustomRemoto([]);
      final pecasAposRemocao = await db.getPecasCustom();
      expect(pecasAposRemocao.contains('Peça antiga'), false);

      // Upsert normal a partir de uma linha crua (como viria do Supabase,
      // com id preservado mesmo o mapper *FromSupabase descartando-o).
      await db.aplicarPecasCustomRemoto([
        {'id': 'para-choque', 'peca': 'Para-choque', 'oficina_id': 'oficina-1'},
      ]);
      final pecas = await db.getPecasCustom();
      expect(pecas.contains('Para-choque'), true);
    });
  });
}
