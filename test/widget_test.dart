import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oficina_app/providers/auth_provider.dart';
import 'package:oficina_app/screens/login_screen.dart';
import 'package:oficina_app/screens/register_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test (LoginScreen)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Acesse sua conta'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login mostra validacao para campos vazios', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Usuario e obrigatorio'), findsOneWidget);
    expect(find.text('Senha e obrigatoria'), findsOneWidget);
  });

  testWidgets('Register mostra validacao para campos vazios', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
    await tester.pump();

    expect(find.text('Usuario e obrigatorio'), findsOneWidget);
    expect(find.text('Senha e obrigatoria'), findsOneWidget);
  });

  testWidgets('Login mostra mensagem para senha curta', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'thiago');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Senha deve ter ao menos 6 caracteres'), findsOneWidget);
  });
}
