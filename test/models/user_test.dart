import 'package:flutter_test/flutter_test.dart';
import 'package:oficina_app/models/user.dart';

void main() {
  test('User guarda id, email e nome vindos do Supabase Auth', () {
    final user = User(
      id: 'a1b2c3',
      email: 'thiago@oficina.com',
      nome: 'Thiago',
    );

    expect(user.id, 'a1b2c3');
    expect(user.email, 'thiago@oficina.com');
    expect(user.nome, 'Thiago');
  });
}
