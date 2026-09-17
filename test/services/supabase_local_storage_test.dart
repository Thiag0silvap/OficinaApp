import 'package:flutter_test/flutter_test.dart';

import 'package:oficina_app/services/secure_storage_service.dart';
import 'package:oficina_app/services/supabase_local_storage.dart';

// SecureStorageService de teste cujo write/read/delete sempre lançam uma
// exceção controlada, simulando uma falha real do secure storage nativo
// (ex.: keystore corrompido/indisponível no dispositivo). Cobre o
// comportamento crítico da mudança de segurança: SupabaseSecureLocalStorage
// não deve deixar essa exceção escapar nem cair em nenhum fallback em texto
// plano — apenas registrar o log e retornar um resultado "vazio" seguro.
class _FailingSecureStorageService extends SecureStorageService {
  @override
  Future<void> write(String key, String value) async {
    throw Exception('secure storage indisponível (teste)');
  }

  @override
  Future<String?> read(String key) async {
    throw Exception('secure storage indisponível (teste)');
  }

  @override
  Future<void> delete(String key) async {
    throw Exception('secure storage indisponível (teste)');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseSecureLocalStorage storage;

  setUp(() {
    storage = SupabaseSecureLocalStorage(storage: _FailingSecureStorageService());
  });

  group('SupabaseSecureLocalStorage com secure storage indisponível', () {
    test('persistSession não lança exceção', () async {
      await expectLater(
        storage.persistSession('sessao-fake'),
        completes,
      );
    });

    test('accessToken retorna null', () async {
      expect(await storage.accessToken(), isNull);
    });

    test('hasAccessToken retorna false', () async {
      expect(await storage.hasAccessToken(), false);
    });

    test('removePersistedSession não lança exceção', () async {
      await expectLater(
        storage.removePersistedSession(),
        completes,
      );
    });
  });
}
