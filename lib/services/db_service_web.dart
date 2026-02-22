import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../models/nota.dart';

/// Web placeholder.
///
/// This project currently relies on `sqflite` + file-system backups (`dart:io`),
/// which are not supported on Flutter Web in the current architecture.
///
/// The app entrypoint shows a "Web not supported" screen and avoids creating
/// providers that would call into this service.
class DBService {
  static final DBService instance = DBService._internal();
  factory DBService() => instance;
  DBService._internal();

  Never _unsupported() => throw UnsupportedError(
        'DBService não é suportado no Web nesta versão do app.',
      );

  Future<void> insertCliente(Cliente cliente) async => _unsupported();
  Future<void> updateCliente(Cliente cliente) async => _unsupported();
  Future<void> deleteCliente(String id) async => _unsupported();
  Future<List<Cliente>> getClientes() async => _unsupported();

  Future<void> insertVeiculo(Veiculo veiculo) async => _unsupported();
  Future<void> updateVeiculo(Veiculo veiculo) async => _unsupported();
  Future<void> deleteVeiculo(String id) async => _unsupported();
  Future<List<Veiculo>> getVeiculos() async => _unsupported();

  Future<void> insertOrcamento(Orcamento o) async => _unsupported();
  Future<void> updateOrcamento(Orcamento o) async => _unsupported();
  Future<void> deleteOrcamento(String id) async => _unsupported();
  Future<List<Orcamento>> getOrcamentos() async => _unsupported();

  Future<void> insertNota(Nota n) async => _unsupported();

  Future<void> insertTransacao(Transacao t) async => _unsupported();
  Future<void> deleteTransacao(String id) async => _unsupported();
  Future<List<Transacao>> getTransacoes() async => _unsupported();

  Future<Map<String, String>> exportBackupToUserDocuments() async => _unsupported();
}
