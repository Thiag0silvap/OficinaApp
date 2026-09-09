import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:oficina_app/models/transacao.dart';
import 'package:oficina_app/providers/app_provider.dart';
import 'package:oficina_app/screens/financeiro_screen.dart';

void main() {
  testWidgets(
    'filtro de data restringe a lista às transações do dia selecionado',
    (WidgetTester tester) async {
      final hoje = DateTime.now();
      final provider = AppProvider();
      provider.debugSetTransacoes([
        Transacao(
          id: '1',
          tipo: TipoTransacao.entrada,
          descricao: 'Compra de hoje',
          valor: 100,
          categoria: 'Geral',
          data: hoje,
        ),
        Transacao(
          id: '2',
          tipo: TipoTransacao.saida,
          descricao: 'Compra antiga',
          valor: 50,
          categoria: 'Geral',
          data: hoje.subtract(const Duration(days: 10)),
        ),
      ]);

      // Viewport maior que o padrão de teste (800x600): nesse tamanho
      // padrão o corpo da tela já estoura por conta própria (bug de layout
      // preexistente, fora do escopo deste teste de filtro).
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: FinanceiroScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Antes do filtro, as duas transações aparecem.
      expect(find.text('Compra de hoje'), findsOneWidget);
      expect(find.text('Compra antiga'), findsOneWidget);
      expect(find.text('2 transações'), findsOneWidget);

      // Abre o seletor de data (initialDate = hoje, já que nenhum filtro
      // está aplicado ainda) e confirma a data destacada por padrão.
      await tester.tap(find.byTooltip('Filtrar por data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Depois do filtro, só a transação de hoje deve restar.
      expect(find.text('Compra de hoje'), findsOneWidget);
      expect(find.text('Compra antiga'), findsNothing);
      expect(find.text('1 transações'), findsOneWidget);
    },
  );
}
