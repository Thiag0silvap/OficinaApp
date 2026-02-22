import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oficina_app/providers/auth_provider.dart';
import 'package:oficina_app/screens/login_screen.dart';

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
}
