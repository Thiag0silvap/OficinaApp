import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/user.dart';

void main() {
  test('User armazena senha com hash SHA-256', () {
    final user = User(id: '1', name: 'thiago', password: '123456');

    expect(user.password, isNot('123456'));
    expect(user.password.length, 64);
  });

  test('User.verifyPassword valida senha correta e rejeita incorreta', () {
    final user = User(id: '1', name: 'thiago', password: '123456');

    expect(User.verifyPassword('123456', user.password), isTrue);
    expect(User.verifyPassword('senha_errada', user.password), isFalse);
  });
}
