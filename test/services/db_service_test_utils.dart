import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:oficina_app/services/db_service.dart';

/// Infraestrutura de teste para DBService (sqflite), inexistente no
/// projeto até aqui — todo teste anterior evitava tocar em DBService (ver
/// test/providers/app_provider_test.dart, que injeta dados prontos via
/// `debugSetTransacoes` em vez de passar por um banco real).
///
/// Usa sqflite_common_ffi (SQLite via FFI, roda no host do teste, sem
/// emulador Android) + mock do canal de método do path_provider (só
/// devolve um diretório temporário) — DBService.database já resolve o
/// caminho do arquivo via `getApplicationDocumentsDirectory()`, e essa
/// chamada trava/erra em `flutter test` sem esse mock.
///
/// Chame [setUpDbServiceTests] uma vez no `setUpAll` do arquivo de teste,
/// e [freshTestUserId] em cada teste pra garantir um arquivo `.db` isolado
/// (DBService é singleton — trocar o "usuário ativo" fecha o banco
/// anterior e abre um novo).
Directory? _tempDir;
int _counter = 0;

void setUpDbServiceTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  _tempDir = Directory.systemTemp.createTempSync('oficina_app_db_test_');

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    if (call.method == 'getApplicationDocumentsDirectory') {
      return _tempDir!.path;
    }
    return null;
  });
}

Future<void> tearDownDbServiceTests() async {
  await DBService.instance.setActiveUserId(null);
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
  if (_tempDir != null && _tempDir!.existsSync()) {
    _tempDir!.deleteSync(recursive: true);
  }
}

/// Um "userId" novo a cada chamada — força DBService a abrir um arquivo
/// `.db` isolado (dentro do diretório temporário do teste) para cada
/// teste, sem precisar limpar tabelas manualmente entre eles.
Future<String> freshTestUserId() async {
  final userId = 'test-user-${_counter++}';
  await DBService.instance.setActiveUserId(userId);
  return userId;
}
