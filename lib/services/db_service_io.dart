import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/cliente.dart';
import '../models/backup_manifest.dart';
import '../models/empresa.dart';
import '../models/nota.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../models/veiculo.dart';
import '../core/constants/app_version.dart';
import 'app_logger.dart';

class DBService {
  DBService._();
  static final DBService instance = DBService._();
  static const int schemaVersion = 2;
  static const String _backupFolderName = 'OficinaAppBackups';

  Database? _database;
  String? _activeUserId;

  Future<void> setActiveUserId(
    String? userId, {
    bool migrateLegacyIfNeeded = false,
  }) async {
    if (_activeUserId == userId) return;

    _activeUserId = userId;

    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    sqfliteFfiInit();

    final factory = databaseFactoryFfi;
    final dir = await getApplicationDocumentsDirectory();

    final path = join(
      dir.path,
      "oficina_${_activeUserId ?? "default"}.db",
    );

    _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE clientes(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
dataCadastro TEXT,
observacoes TEXT,
tipo TEXT,
nomeSeguradora TEXT,
cnpj TEXT,
contato TEXT
)
''');

    await db.execute('''
CREATE TABLE veiculos(
id TEXT PRIMARY KEY,
clienteId TEXT,
marca TEXT,
modelo TEXT,
cor TEXT,
placa TEXT,
ano INTEGER,
observacoes TEXT
)
''');

    await db.execute('''
CREATE TABLE orcamentos(
id TEXT PRIMARY KEY,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
status TEXT,
dataCriacao TEXT,
dataAprovacao TEXT,
dataConclusao TEXT,
dataPagamento TEXT,
pago INTEGER,
observacoes TEXT,
observacoesCliente TEXT,
observacoesInternas TEXT,
dataPrevistaEntrega TEXT,
tipoAtendimento TEXT
)
''');

    await db.execute('''
CREATE TABLE transacoes(
id TEXT PRIMARY KEY,
tipo TEXT,
descricao TEXT,
valor REAL,
categoria TEXT,
data TEXT,
orcamentoId TEXT,
observacoes TEXT
)
''');

    await db.execute('''
CREATE TABLE notas(
id TEXT PRIMARY KEY,
orcamentoId TEXT,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
dataEmissao TEXT
)
''');

    await db.execute('''
CREATE TABLE empresa(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
cnpj TEXT
)
''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await AppLogger.instance.info(
      'Migrando banco do schema $oldVersion para $newVersion',
    );
    await _ensureLatestSchema(db);
  }

  Future<void> _onOpen(Database db) async {
    await _ensureLatestSchema(db);
    await _validateDatabaseIntegrity(db);
  }

  Future<void> _ensureLatestSchema(Database db) async {
    await _ensureTableExists(
      db,
      'clientes',
      '''
CREATE TABLE clientes(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
dataCadastro TEXT,
observacoes TEXT,
tipo TEXT,
nomeSeguradora TEXT,
cnpj TEXT,
contato TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'veiculos',
      '''
CREATE TABLE veiculos(
id TEXT PRIMARY KEY,
clienteId TEXT,
marca TEXT,
modelo TEXT,
cor TEXT,
placa TEXT,
ano INTEGER,
observacoes TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'orcamentos',
      '''
CREATE TABLE orcamentos(
id TEXT PRIMARY KEY,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
status TEXT,
dataCriacao TEXT,
dataAprovacao TEXT,
dataConclusao TEXT,
dataPagamento TEXT,
pago INTEGER,
observacoes TEXT,
observacoesCliente TEXT,
observacoesInternas TEXT,
dataPrevistaEntrega TEXT,
tipoAtendimento TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'transacoes',
      '''
CREATE TABLE transacoes(
id TEXT PRIMARY KEY,
tipo TEXT,
descricao TEXT,
valor REAL,
categoria TEXT,
data TEXT,
orcamentoId TEXT,
observacoes TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'notas',
      '''
CREATE TABLE notas(
id TEXT PRIMARY KEY,
orcamentoId TEXT,
clienteId TEXT,
clienteNome TEXT,
veiculoId TEXT,
veiculoDescricao TEXT,
itens TEXT,
valorTotal REAL,
dataEmissao TEXT
)
''',
    );
    await _ensureTableExists(
      db,
      'empresa',
      '''
CREATE TABLE empresa(
id TEXT PRIMARY KEY,
nome TEXT,
telefone TEXT,
endereco TEXT,
cnpj TEXT
)
''',
    );

    await _ensureColumnExists(db, 'clientes', 'endereco', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'dataCadastro', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'observacoes', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'tipo', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'nomeSeguradora', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'cnpj', 'TEXT');
    await _ensureColumnExists(db, 'clientes', 'contato', 'TEXT');

    await _ensureColumnExists(db, 'veiculos', 'cor', 'TEXT');
    await _ensureColumnExists(db, 'veiculos', 'observacoes', 'TEXT');

    await _ensureColumnExists(db, 'orcamentos', 'veiculoId', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'veiculoDescricao', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'itens', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'observacoes', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'observacoesCliente', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'observacoesInternas', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'dataPrevistaEntrega', 'TEXT');
    await _ensureColumnExists(db, 'orcamentos', 'tipoAtendimento', 'TEXT');

    await _ensureColumnExists(db, 'transacoes', 'observacoes', 'TEXT');

    await _ensureColumnExists(db, 'notas', 'clienteId', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'veiculoId', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'veiculoDescricao', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'itens', 'TEXT');
    await _ensureColumnExists(db, 'notas', 'valorTotal', 'REAL');
    await _ensureColumnExists(db, 'notas', 'dataEmissao', 'TEXT');

    await _ensureColumnExists(db, 'empresa', 'cnpj', 'TEXT');

    await _migrateLegacyData(db);
    await _createIndexes(db);
  }

  Future<void> _ensureTableExists(
    Database db,
    String table,
    String createSql,
  ) async {
    final rows = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', table],
      limit: 1,
    );
    if (rows.isNotEmpty) return;
    await db.execute(createSql);
  }

  Future<void> _ensureColumnExists(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _migrateLegacyData(Database db) async {
    await db.execute('''
UPDATE clientes
SET dataCadastro = COALESCE(dataCadastro, CURRENT_TIMESTAMP),
    tipo = COALESCE(tipo, 'particular')
''');

    final notaColumns = await db.rawQuery('PRAGMA table_info(notas)');
    final hasLegacyDataColumn = notaColumns.any((row) => row['name'] == 'data');
    final hasValorTotalColumn =
        notaColumns.any((row) => row['name'] == 'valorTotal');
    final hasLegacyValorColumn =
        notaColumns.any((row) => row['name'] == 'valor');

    if (hasLegacyDataColumn) {
      await db.execute('''
UPDATE notas
SET dataEmissao = COALESCE(dataEmissao, data)
''');
    }

    if (hasLegacyValorColumn && hasValorTotalColumn) {
      await db.execute('''
UPDATE notas
SET valorTotal = COALESCE(valorTotal, valor)
''');
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
CREATE UNIQUE INDEX IF NOT EXISTS idx_transacoes_orcamento_unique
ON transacoes(orcamentoId)
WHERE orcamentoId IS NOT NULL
''');
  }

  Future<void> _validateDatabaseIntegrity(Database db) async {
    final result = await db.rawQuery('PRAGMA integrity_check');
    final value = result.isNotEmpty ? result.first.values.first?.toString() : null;
    if (value != 'ok') {
      throw StateError('Falha na integridade do banco local.');
    }
  }

  // ================= CLIENTES =================

  Future<void> insertCliente(Cliente c) async {
    final db = await database;

    await db.insert(
      "clientes",
      c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Cliente>> getClientes() async {
    final db = await database;
    final result = await db.query("clientes");

    return result.map((e) => Cliente.fromMap(e)).toList();
  }

  Future<void> updateCliente(Cliente c) async {
    final db = await database;

    await db.update(
      "clientes",
      c.toMap(),
      where: "id = ?",
      whereArgs: [c.id],
    );
  }

  Future<void> deleteCliente(String id) async {
    final db = await database;

    await db.delete(
      "clientes",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ================= VEÍCULOS =================

  Future<void> insertVeiculo(Veiculo v) async {
    final db = await database;

    await db.insert(
      "veiculos",
      v.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Veiculo>> getVeiculos() async {
    final db = await database;

    final result = await db.query("veiculos");

    return result.map((e) => Veiculo.fromMap(e)).toList();
  }

  Future<void> updateVeiculo(Veiculo v) async {
    final db = await database;

    await db.update(
      "veiculos",
      v.toMap(),
      where: "id = ?",
      whereArgs: [v.id],
    );
  }

  Future<void> deleteVeiculo(String id) async {
    final db = await database;

    await db.delete(
      "veiculos",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ================= ORÇAMENTOS =================

  Future<void> insertOrcamento(Orcamento o) async {
    final db = await database;

    await db.insert(
      "orcamentos",
      _serializeOrcamento(o),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Orcamento>> getOrcamentos() async {
    final db = await database;

    final result = await db.query("orcamentos");

    return result.map((e) => Orcamento.fromMap(_deserializeOrcamento(e))).toList();
  }

  Future<void> updateOrcamento(Orcamento o) async {
    final db = await database;

    await db.update(
      "orcamentos",
      _serializeOrcamento(o),
      where: "id = ?",
      whereArgs: [o.id],
    );
  }

  Future<void> deleteOrcamento(String id) async {
    final db = await database;

    await db.delete(
      "orcamentos",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ================= TRANSAÇÕES =================

  Future<void> insertTransacao(Transacao t) async {
    final db = await database;

    await db.insert(
      "transacoes",
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Transacao>> getTransacoes() async {
    final db = await database;

    final result = await db.query(
      "transacoes",
      orderBy: "data DESC",
    );

    return result.map((e) => Transacao.fromMap(e)).toList();
  }

  Future<void> deleteTransacao(String id) async {
    final db = await database;

    await db.delete(
      "transacoes",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<Transacao?> getTransacaoById(String id) async {
    final db = await database;

    final rows = await db.query(
      "transacoes",
      where: "id = ?",
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Transacao.fromMap(rows.first);
  }

  // 🔐 proteção contra duplicidade por orçamento

  Future<Transacao?> getTransacaoByOrcamentoId(String orcamentoId) async {
    final db = await database;

    final rows = await db.query(
      "transacoes",
      where: "orcamentoId = ?",
      whereArgs: [orcamentoId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Transacao.fromMap(rows.first);
  }

  // ================= NOTAS =================

  Future<void> insertNota(Nota nota) async {
    final db = await database;

    await db.insert(
      "notas",
      _serializeNota(nota),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Nota>> getNotas() async {
    final db = await database;

    final result = await db.query(
      "notas",
      orderBy: "dataEmissao DESC",
    );

    return result.map((e) => Nota.fromMap(_deserializeNota(e))).toList();
  }

  // ================= EMPRESA =================

  Future<Empresa?> getEmpresa() async {
    final db = await database;

    final result = await db.query("empresa", limit: 1);

    if (result.isEmpty) return null;

    return Empresa.fromMap(result.first);
  }

  Future<void> saveEmpresa(Empresa empresa) async {
    final db = await database;

    await db.insert(
      "empresa",
      empresa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEmpresa(Empresa empresa) async {
    final db = await database;

    await db.update(
      "empresa",
      empresa.toMap(),
      where: "id = ?",
      whereArgs: [empresa.id],
    );
  }

  // ================= BACKUP =================

  Future<String> exportBackupToUserDocuments() async {
    final db = await database;

    final dbPath = db.path;
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = await _ensureBackupDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final userId = _activeUserId ?? 'default';
    final backupBaseName = 'backup_oficina_${userId}_$stamp';
    final backupPath = join(backupDir.path, '$backupBaseName.db');
    final manifestPath = join(backupDir.path, '$backupBaseName.json');
    final legacyBackupPath = join(docsDir.path, 'backup_oficina.db');

    final backupFile = await File(dbPath).copy(backupPath);
    await File(dbPath).copy(legacyBackupPath);
    final manifest = BackupManifest(
      id: backupBaseName,
      dbPath: backupFile.path,
      manifestPath: manifestPath,
      fileName: '$backupBaseName.db',
      createdAtIso: DateTime.now().toIso8601String(),
      userId: userId,
      appVersion: AppVersion.current,
      schemaVersion: schemaVersion,
      fileSizeBytes: await backupFile.length(),
    );

    await File(manifestPath).writeAsString(jsonEncode(manifest.toMap()));
    await AppLogger.instance.info('Backup exportado: ${backupFile.path}');
    return backupFile.path;
  }

  Future<List<BackupManifest>> listAvailableBackups() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = await _ensureBackupDirectory();
    final manifestFiles = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => extension(f.path).toLowerCase() == '.json')
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    final backups = <BackupManifest>[];
    for (final file in manifestFiles) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) continue;
        final manifest = BackupManifest.fromMap(decoded);
        final dbFile = File(manifest.dbPath);
        if (!await dbFile.exists()) continue;
        backups.add(manifest);
      } catch (_) {
        continue;
      }
    }

    final legacyBackup = File(join(docsDir.path, 'backup_oficina.db'));
    if (await legacyBackup.exists()) {
      final stat = await legacyBackup.stat();
      backups.add(
        BackupManifest(
          id: 'legacy_backup_oficina',
          dbPath: legacyBackup.path,
          manifestPath: '',
          fileName: 'backup_oficina.db',
          createdAtIso: stat.modified.toIso8601String(),
          userId: _activeUserId ?? 'default',
          appVersion: 'legado',
          schemaVersion: 1,
          fileSizeBytes: await legacyBackup.length(),
        ),
      );
    }

    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  Future<String> restoreBackupFromUserDocuments([String? manifestId]) async {
    final backups = await listAvailableBackups();
    if (backups.isEmpty) {
      throw StateError('Nenhum backup dispon\u00edvel para restaura\u00e7\u00e3o.');
    }

    BackupManifest? selected;
    if (manifestId == null) {
      selected = backups.first;
    } else {
      for (final backup in backups) {
        if (backup.id == manifestId) {
          selected = backup;
          break;
        }
      }
    }

    if (selected == null) {
      throw StateError('Backup selecionado n\u00e3o encontrado.');
    }

    await _validateBackupManifest(selected);

    final dir = await getApplicationDocumentsDirectory();
    final targetPath = join(dir.path, "oficina_${_activeUserId ?? "default"}.db");

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      final safetyPath = join(
        dir.path,
        "oficina_${_activeUserId ?? "default"}_antes_restauracao.db",
      );
      await targetFile.copy(safetyPath);
      await targetFile.delete();
    }

    await _deleteIfExists('$targetPath-wal');
    await _deleteIfExists('$targetPath-shm');

    await File(selected.dbPath).copy(targetPath);
    await AppLogger.instance.warning(
      'Backup restaurado para ${_activeUserId ?? "default"} a partir de ${selected.fileName}',
    );
    return targetPath;
  }

  Future<void> _validateBackupManifest(BackupManifest manifest) async {
    if (manifest.userId.trim().isEmpty) {
      throw StateError('Backup inv\u00e1lido: usu\u00e1rio n\u00e3o informado.');
    }
    if (_activeUserId != null && manifest.userId != _activeUserId) {
      throw StateError(
        'Este backup pertence ao usu\u00e1rio ${manifest.userId} e n\u00e3o ao usu\u00e1rio atual.',
      );
    }
    if (manifest.schemaVersion > schemaVersion) {
      throw StateError(
        'O backup foi criado por uma vers\u00e3o mais nova do aplicativo.',
      );
    }
    final dbFile = File(manifest.dbPath);
    if (!await dbFile.exists()) {
      throw StateError('Arquivo do backup n\u00e3o encontrado.');
    }
    if (await dbFile.length() <= 0) {
      throw StateError('Arquivo do backup est\u00e1 vazio.');
    }
  }

  Map<String, dynamic> _serializeOrcamento(Orcamento o) {
    final map = Map<String, dynamic>.from(o.toMap());
    map['itens'] = jsonEncode(map['itens']);
    return map;
  }

  Map<String, dynamic> _deserializeOrcamento(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['itens'] = _decodeJsonList(map['itens']);
    return map;
  }

  Map<String, dynamic> _serializeNota(Nota nota) {
    final map = Map<String, dynamic>.from(nota.toMap());
    map['itens'] = jsonEncode(map['itens']);
    return map;
  }

  Map<String, dynamic> _deserializeNota(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['itens'] = _decodeJsonList(map['itens']);
    if (map['dataEmissao'] == null && row['data'] != null) {
      map['dataEmissao'] = row['data'];
    }
    if (map['valorTotal'] == null && row['valor'] != null) {
      map['valorTotal'] = row['valor'];
    }
    return map;
  }

  List<dynamic> _decodeJsonList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    }
    return const [];
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _ensureBackupDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(docsDir.path, _backupFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
