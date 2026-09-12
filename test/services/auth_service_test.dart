import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:oficina_app/services/auth_service.dart';

// AuthService.signUp/signIn/resetPassword/signOut chamam o Supabase Auth de
// verdade (GoTrueClient) — não fazem sentido como teste unitário sem rede.
// O que sobra testável isoladamente é a validação de formulário local.
//
// AuthService() ainda assim exige Supabase.instance já inicializado (é
// resolvido no construtor via SupabaseService.client.auth), daí o
// Supabase.initialize() de teste abaixo — nenhuma chamada de rede real
// acontece nos testes, só a validação local é exercitada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  test('validateRegistration rejeita nome vazio', () {
    final service = AuthService();

    expect(
      service.validateRegistration(
        nome: '',
        email: 'thiago@oficina.com',
        password: 'abc123',
      ),
      isNotNull,
    );
  });

  test('validateRegistration rejeita e-mail com formato invalido', () {
    final service = AuthService();

    expect(
      service.validateRegistration(
        nome: 'Thiago',
        email: 'nao-e-email',
        password: 'abc123',
      ),
      isNotNull,
    );
  });

  test('validateRegistration rejeita senha curta ou sem letra+numero', () {
    final service = AuthService();

    expect(
      service.validateRegistration(
        nome: 'Thiago',
        email: 'thiago@oficina.com',
        password: '123',
      ),
      isNotNull,
    );
    expect(
      service.validateRegistration(
        nome: 'Thiago',
        email: 'thiago@oficina.com',
        password: 'abcdef',
      ),
      isNotNull,
    );
  });

  test('validateRegistration aceita nome, e-mail e senha validos', () {
    final service = AuthService();

    expect(
      service.validateRegistration(
        nome: 'Thiago',
        email: 'thiago@oficina.com',
        password: 'abc123',
      ),
      isNull,
    );
  });
}
