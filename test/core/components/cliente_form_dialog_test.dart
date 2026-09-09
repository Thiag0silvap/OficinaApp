import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:oficina_app/core/components/cliente_form_dialog.dart';
import 'package:oficina_app/providers/app_provider.dart';

void main() {
  testWidgets(
    'tentar avançar com nome e telefone vazios mostra validação',
    (WidgetTester tester) async {
      // Viewport maior que o padrão de teste (800x600): mesmo aberto via
      // showDialog, o ResponsiveDialog do formulário de cliente precisa de
      // mais altura do que 600px para caber sem cortar as ações no rodapé.
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Abre via showDialog (uso real) em vez de montar ClienteFormDialog
      // como home: montado direto, ResponsiveDialog não fica centralizado
      // pela rota de diálogo.
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const ClienteFormDialog(),
                    ),
                    child: const Text('Abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Nome é obrigatório'), findsOneWidget);
      expect(find.text('Telefone é obrigatório'), findsOneWidget);
    },
  );
}
