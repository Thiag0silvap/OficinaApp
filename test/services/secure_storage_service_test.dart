import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oficina_app/services/secure_storage_service.dart';

// SecureStorageService.write/read/delete delegam para o
// FlutterSecureStorage real (channel nativo). Em ambiente de teste unitário
// puro (sem mock do platform channel), a chamada ao channel nativo lança
// MissingPluginException — confirmado manualmente antes de escrever este
// teste. É esse comportamento natural do binding de teste que estamos
// verificando aqui: a mudança de segurança depende de write/read/delete
// propagarem a exceção (em vez de engolir e cair num fallback silencioso).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = SecureStorageService();

  group('write/read/delete propagam exceção do secure storage', () {
    test('write propaga exceção quando o platform channel falha', () {
      expect(() => service.write('k', 'v'), throwsA(anything));
    });

    test('read propaga exceção quando o platform channel falha', () {
      expect(() => service.read('k'), throwsA(anything));
    });

    test('delete propaga exceção quando o platform channel falha', () {
      expect(() => service.delete('k'), throwsA(anything));
    });
  });

  group('clearLegacyFallback', () {
    test('remove a chave de fallback legado quando ela existe', () async {
      SharedPreferences.setMockInitialValues({
        'secure_fallback_v1_supabase_session': 'valor-legado-em-texto-plano',
      });

      await service.clearLegacyFallback('supabase_session');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('secure_fallback_v1_supabase_session'), false);
    });

    test('não lança erro quando a chave não existe', () async {
      SharedPreferences.setMockInitialValues({});

      await expectLater(
        service.clearLegacyFallback('chave_inexistente'),
        completes,
      );
    });
  });
}
