import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oficina_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('valida senha fraca e usuario curto no cadastro', () {
    final service = AuthService();

    expect(
      service.validateRegistration(name: 'ab', password: '123'),
      isNotNull,
    );
    expect(
      service.validateRegistration(name: 'thiago', password: 'abcdef'),
      isNotNull,
    );
    expect(
      service.validateRegistration(name: 'thiago', password: 'abc123'),
      isNull,
    );
  });

  test('bloqueia login apos muitas tentativas falhas', () async {
    final service = AuthService();
    await service.register(name: 'thiago', password: 'abc123');

    for (var i = 0; i < AuthService.maxFailedAttempts; i++) {
      await service.login('thiago', 'senha_errada');
    }

    expect(await service.isUserLockedOut('thiago'), isTrue);
    expect(await service.getRemainingLockout('thiago'), isNotNull);
  });

  test('limpa tentativas falhas apos login bem-sucedido', () async {
    final service = AuthService();
    await service.register(name: 'thiago', password: 'abc123');

    await service.login('thiago', 'senha_errada');
    await service.login('thiago', 'senha_errada');

    expect(await service.isUserLockedOut('thiago'), isFalse);

    final user = await service.login('thiago', 'abc123');

    expect(user, isNotNull);
    expect(await service.getRemainingLockout('thiago'), isNull);
  });
}
