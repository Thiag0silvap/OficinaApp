import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:oficina_app/core/components/veiculo_form_fields.dart';
import 'package:oficina_app/providers/app_provider.dart';

void main() {
  testWidgets(
    'selecionar Marca habilita o campo de Modelo com as opções da marca',
    (WidgetTester tester) async {
      final controller = VeiculoFormController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: Form(
                child: VeiculoFormFields(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Antes de escolher a marca, o campo de Modelo nem existe.
      expect(find.text('Selecione a marca primeiro'), findsOneWidget);
      expect(find.text('Modelo *'), findsNothing);

      // Digita e seleciona "Chevrolet" (fallback fixo do AppConstants,
      // já que este AppProvider não tem catálogo FIPE nem custom carregado).
      await tester.enterText(find.byType(TextFormField).first, 'Chevrolet');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chevrolet').last);
      await tester.pumpAndSettle();

      // Regressão do bug real: sem o Consumer isolado em Marca/Modelo, o
      // campo de Modelo não aparecia habilitado com as opções da marca.
      expect(find.text('Selecione a marca primeiro'), findsNothing);
      expect(find.text('Modelo *'), findsOneWidget);

      // Confirma que o campo está de fato habilitado/interativo: digitar
      // nele mostra as opções de modelo da marca selecionada. find.text
      // sozinho bateria duas vezes (o texto digitado no campo + a sugestão
      // na lista), por isso o finder é restrito ao ListTile da sugestão.
      await tester.enterText(find.byType(TextFormField).at(1), 'Onix');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Onix'), findsOneWidget);
    },
  );
}
