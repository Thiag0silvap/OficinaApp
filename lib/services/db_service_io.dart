import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/user.dart';
import '../models/cliente.dart';
import '../models/attachment.dart';
import '../models/veiculo.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../models/nota.dart';

class DBService {
  static final DBService instance = DBService._internal();
  factory DBService() => instance;
  DBService._internal();

  static const String _legacyDbFileName = 'app_funilaria.db';
  static const String _prefsKeyDbMigratedV1 = 'db_migrated_to_user_db_v1';
  static const String _prefsKeyDbMigratedToUserIdV1 = 'db_migrated_to_user_db_user_id_v1';

  String _activeDbFileName = _legacyDbFileName;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB(_activeDbFileName);
    return _db!;
  }

  /// Switches the active SQLite database file to be per-user.
  ///
  /// This prevents one user from seeing another user's data.
  ///
  /// Migration behavior:
  /// - On the first time a user is set, if the legacy DB exists and the
  ///   user-specific DB does not, it copies the legacy DB into the user's DB.
  Future<void> setActiveUserId(String? userId, {bool migrateLegacyIfNeeded = false}) async {
    final newFileName = (userId == null || userId.trim().isEmpty)
        ? _legacyDbFileName
        : 'app_funilaria_user_${userId.trim()}.db';

    if (newFileName == _activeDbFileName) return;

    // Close current DB handle before switching files.
    await close();

    if (migrateLegacyIfNeeded && userId != null && userId.trim().isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final migrated = prefs.getBool(_prefsKeyDbMigratedV1) ?? false;

        if (!migrated) {
          final databasesPath = await getDatabasesPath();
          final legacyPath = p.join(databasesPath, _legacyDbFileName);
          final newPath = p.join(databasesPath, newFileName);

          final legacyFile = File(legacyPath);
          final newFile = File(newPath);

          if (await legacyFile.exists() && !await newFile.exists()) {
            await legacyFile.copy(newPath);
            await prefs.setBool(_prefsKeyDbMigratedV1, true);
            await prefs.setString(_prefsKeyDbMigratedToUserIdV1, userId.trim());
          }
        }
      } catch (_) {
        // ignore migration failures; app will start with empty user DB.
      }
    }

    _activeDbFileName = newFileName;
  }

    Future<Database> _initDB(String fileName) async {
    // ✅ GARANTE que no desktop o sqflite_ffi foi setado ANTES do openDatabase
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, fileName);

    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        // ✅ habilita chaves estrangeiras
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }


  // ===================== HELPERS =====================
  static String _safeTs() {
    // yyyy-MM-dd_HH-mm-ss
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}-${two(now.second)}';
  }

  static Future<Map<String, dynamic>> _checksumForFile(File file) async {
    final bytes = await file.readAsBytes();
    return {
      'sha256': sha256.convert(bytes).toString(),
      'size': bytes.length,
    };
  }

  static String _encodeItens(List<dynamic> itens) {
    // itens pode ser List<ItemOrcamento> (tem toMap)
    try {
      return jsonEncode(itens.map((e) => (e as dynamic).toMap()).toList());
    } catch (_) {
      // fallback
      return jsonEncode([]);
    }
  }

  static List<Map<String, dynamic>> _decodeItens(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  // ===================== CREATE / MIGRATE =====================
  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE clientes (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        telefone TEXT NOT NULL,
        endereco TEXT,
        dataCadastro TEXT NOT NULL,
        observacoes TEXT,
        tipo TEXT NOT NULL,
        nomeSeguradora TEXT,
        cnpj TEXT,
        contato TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        filename TEXT NOT NULL,
        path TEXT NOT NULL,
        type TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        mime TEXT,
        note TEXT,
        parentId TEXT,
        parentType TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE veiculos (
        id TEXT PRIMARY KEY,
        clienteId TEXT NOT NULL,
        marca TEXT NOT NULL,
        modelo TEXT NOT NULL,
        cor TEXT NOT NULL,
        placa TEXT NOT NULL,
        ano INTEGER,
        observacoes TEXT,
        FOREIGN KEY (clienteId) REFERENCES clientes(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE orcamentos (
        id TEXT PRIMARY KEY,
        clienteId TEXT NOT NULL,
        clienteNome TEXT NOT NULL,
        veiculoId TEXT,
        veiculoDescricao TEXT,
        itens TEXT NOT NULL,
        valorTotal REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'pendente',
        dataCriacao TEXT NOT NULL,
        dataAprovacao TEXT,
        dataConclusao TEXT,

        -- financeiro / processo
        pago INTEGER NOT NULL DEFAULT 0,
        dataPagamento TEXT,
        observacoes TEXT,
        observacoesCliente TEXT,
        observacoesInternas TEXT,
        dataPrevistaEntrega TEXT,
        tipoAtendimento TEXT NOT NULL DEFAULT 'particular',

        FOREIGN KEY (clienteId) REFERENCES clientes(id) ON DELETE CASCADE,
        FOREIGN KEY (veiculoId) REFERENCES veiculos(id) ON DELETE SET NULL
      );
    ''');

    // ✅ Ajuste: Nota.clienteId no seu model é String? (nullable)
    await db.execute('''
      CREATE TABLE notas (
        id TEXT PRIMARY KEY,
        orcamentoId TEXT,
        clienteId TEXT,
        clienteNome TEXT NOT NULL,
        veiculoId TEXT,
        veiculoDescricao TEXT,
        itens TEXT NOT NULL,
        valorTotal REAL NOT NULL DEFAULT 0.0,
        dataEmissao TEXT NOT NULL,
        FOREIGN KEY (orcamentoId) REFERENCES orcamentos(id) ON DELETE SET NULL,
        FOREIGN KEY (clienteId) REFERENCES clientes(id) ON DELETE SET NULL,
        FOREIGN KEY (veiculoId) REFERENCES veiculos(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE transacoes (
        id TEXT PRIMARY KEY,
        tipo TEXT NOT NULL,
        descricao TEXT,
        valor REAL NOT NULL DEFAULT 0.0,
        categoria TEXT,
        data TEXT NOT NULL,
        orcamentoId TEXT,
        observacoes TEXT,
        FOREIGN KEY (orcamentoId) REFERENCES orcamentos(id) ON DELETE SET NULL
      );
    ''');

    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_veiculos_clienteId ON veiculos(clienteId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_veiculos_placa ON veiculos(placa);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orcamentos_clienteId ON orcamentos(clienteId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orcamentos_veiculoId ON orcamentos(veiculoId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orcamentos_status ON orcamentos(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_orcamentos_dataCriacao ON orcamentos(dataCriacao);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notas_clienteId ON notas(clienteId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notas_orcamentoId ON notas(orcamentoId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notas_dataEmissao ON notas(dataEmissao);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transacoes_data ON transacoes(data);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transacoes_tipo ON transacoes(tipo);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transacoes_orcamentoId ON transacoes(orcamentoId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_attachments_parentId ON attachments(parentId);');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Future<void> addCol(String sql) async {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    if (oldVersion < 2) {
      await addCol('ALTER TABLE attachments ADD COLUMN parentId TEXT;');
      await addCol('ALTER TABLE attachments ADD COLUMN parentType TEXT;');

      // Tabelas (caso existam apps instalados com versões antigas)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS veiculos (
          id TEXT PRIMARY KEY,
          clienteId TEXT NOT NULL,
          marca TEXT NOT NULL,
          modelo TEXT NOT NULL,
          cor TEXT NOT NULL,
          placa TEXT NOT NULL,
          ano INTEGER,
          observacoes TEXT,
          FOREIGN KEY (clienteId) REFERENCES clientes(id) ON DELETE CASCADE
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS orcamentos (
          id TEXT PRIMARY KEY,
          clienteId TEXT NOT NULL,
          clienteNome TEXT NOT NULL,
          veiculoId TEXT,
          veiculoDescricao TEXT,
          itens TEXT NOT NULL,
          valorTotal REAL NOT NULL DEFAULT 0.0,
          status TEXT NOT NULL DEFAULT 'pendente',
          dataCriacao TEXT NOT NULL,
          dataAprovacao TEXT,
          dataConclusao TEXT,
          observacoes TEXT,
          FOREIGN KEY (clienteId) REFERENCES clientes(id) ON DELETE CASCADE,
          FOREIGN KEY (veiculoId) REFERENCES veiculos(id) ON DELETE SET NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS notas (
          id TEXT PRIMARY KEY,
          orcamentoId TEXT,
          clienteId TEXT,
          clienteNome TEXT NOT NULL,
          veiculoId TEXT,
          veiculoDescricao TEXT,
          itens TEXT NOT NULL,
          valorTotal REAL NOT NULL DEFAULT 0.0,
          dataEmissao TEXT NOT NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS transacoes (
          id TEXT PRIMARY KEY,
          tipo TEXT NOT NULL,
          descricao TEXT,
          valor REAL NOT NULL DEFAULT 0.0,
          categoria TEXT,
          data TEXT NOT NULL,
          orcamentoId TEXT,
          observacoes TEXT
        );
      ''');
    }

    if (oldVersion < 3) {
      await addCol("ALTER TABLE orcamentos ADD COLUMN pago INTEGER NOT NULL DEFAULT 0;");
      await addCol("ALTER TABLE orcamentos ADD COLUMN dataPagamento TEXT;");
      await addCol("ALTER TABLE orcamentos ADD COLUMN observacoesCliente TEXT;");
      await addCol("ALTER TABLE orcamentos ADD COLUMN observacoesInternas TEXT;");
      await addCol("ALTER TABLE orcamentos ADD COLUMN dataPrevistaEntrega TEXT;");
      await addCol("ALTER TABLE orcamentos ADD COLUMN tipoAtendimento TEXT NOT NULL DEFAULT 'particular';");
    }

    await _createIndexes(db);
  }

  // ===================== LIFECYCLE =====================
  Future<void> close() async {
    if (_db != null) await _db!.close();
    _db = null;
  }

  // ===================== BACKUP =====================
  Timer? _backupTimer;

  void startAutoBackup({Duration interval = const Duration(hours: 24)}) {
    _backupTimer?.cancel();
    _backupTimer = Timer.periodic(interval, (_) async {
      try {
        await exportBackupToUserDocuments();
      } catch (_) {}
    });
  }

  void stopAutoBackup() {
    _backupTimer?.cancel();
    _backupTimer = null;
  }

  Future<Map<String, String>> exportBackupToUserDocuments() async {
    final exports = await exportBackup();

    String docsPath;
    if (Platform.isAndroid) {
      // App-specific external storage (no broad storage permissions required).
      final dir = await getExternalStorageDirectory();
      docsPath = (dir ?? await getApplicationDocumentsDirectory()).path;
    } else if (Platform.isIOS) {
      // iOS apps cannot write to arbitrary user folders.
      docsPath = (await getApplicationDocumentsDirectory()).path;
    } else {
      // Desktop: try to use the OS Documents folder, fallback to app docs.
      try {
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          docsPath = p.join(userProfile ?? '.', 'Documents');
        } else {
          final home = Platform.environment['HOME'] ?? '.';
          docsPath = p.join(home, 'Documents');
        }
      } catch (_) {
        docsPath = (await getApplicationDocumentsDirectory()).path;
      }
    }

    final destDir = Directory(p.join(docsPath, 'backups_app_funilaria'));
    if (!await destDir.exists()) await destDir.create(recursive: true);

    final dbSrc = File(exports['db']!);
    final jsonSrc = File(exports['json']!);
    final manifestSrc = exports['manifest'] != null ? File(exports['manifest']!) : null;

    final dbDest = p.join(destDir.path, p.basename(exports['db']!));
    final jsonDest = p.join(destDir.path, p.basename(exports['json']!));
    final manifestDest = manifestSrc != null
      ? p.join(destDir.path, p.basename(exports['manifest']!))
      : null;

    await dbSrc.copy(dbDest);
    await jsonSrc.copy(jsonDest);
    if (manifestSrc != null && manifestDest != null) {
      await manifestSrc.copy(manifestDest);
    }

    return {
      'db': dbDest,
      'json': jsonDest,
      if (manifestDest != null) 'manifest': manifestDest,
    };
  }

  Future<Map<String, String>> exportBackup() async {
    final databasesPath = await getDatabasesPath();
    final dbFile = File(p.join(databasesPath, _activeDbFileName));

    final docDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docDir.path, 'backups'));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);

    final ts = _safeTs();
    final dbBackupPath = p.join(backupDir.path, 'app_funilaria_backup_$ts.db');
    await dbFile.copy(dbBackupPath);

    final db = await database;
    final exportData = <String, List<Map<String, dynamic>>>{};
    final tables = ['users', 'clientes', 'veiculos', 'orcamentos', 'notas', 'transacoes', 'attachments'];

    for (final t in tables) {
      try {
        final rows = await db.query(t);
        exportData[t] = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      } catch (_) {
        exportData[t] = [];
      }
    }

    final jsonPath = p.join(backupDir.path, 'app_funilaria_backup_$ts.json');
    await File(jsonPath).writeAsString(jsonEncode(exportData));

    final dbMeta = await _checksumForFile(File(dbBackupPath));
    final jsonMeta = await _checksumForFile(File(jsonPath));
    final manifestPath = p.join(backupDir.path, 'app_funilaria_backup_$ts.manifest.json');
    final manifest = {
      'createdAt': DateTime.now().toIso8601String(),
      'db': {
        'file': p.basename(dbBackupPath),
        'sha256': dbMeta['sha256'],
        'size': dbMeta['size'],
      },
      'json': {
        'file': p.basename(jsonPath),
        'sha256': jsonMeta['sha256'],
        'size': jsonMeta['size'],
      },
    };
    await File(manifestPath).writeAsString(jsonEncode(manifest));

    return {'db': dbBackupPath, 'json': jsonPath, 'manifest': manifestPath};
  }

  Future<void> restoreFromBackup(String backupDbPath) async {
    await close();
    final databasesPath = await getDatabasesPath();
    final dbPath = p.join(databasesPath, _activeDbFileName);
    final src = File(backupDbPath);
    if (!await src.exists()) {
      throw Exception('Arquivo de backup não encontrado.');
    }

    // Verify checksum if a manifest exists next to the backup.
    final manifestPath = '${p.withoutExtension(backupDbPath)}.manifest.json';
    final manifestFile = File(manifestPath);
    if (await manifestFile.exists()) {
      final raw = await manifestFile.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final dbInfo = decoded['db'] as Map<String, dynamic>?;
        if (dbInfo != null) {
          final expectedHash = dbInfo['sha256'] as String?;
          final expectedSize = dbInfo['size'] as int?;
          final actual = await _checksumForFile(src);
          if (expectedHash != null && expectedHash != actual['sha256']) {
            throw Exception('Backup corrompido (hash inválido).');
          }
          if (expectedSize != null && expectedSize != actual['size']) {
            throw Exception('Backup corrompido (tamanho inválido).');
          }
        }
      }
    }

    await src.copy(dbPath);
    _db = null; // força reabrir
  }

  // ==================== CRUD USERS ====================
  Future<void> insertUser(User u) async {
    final db = await database;
    await db.insert('users', u.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final rows = await db.query('users');
    return rows.map((r) => User.fromMap(r)).toList();
  }

  Future<void> updateUser(User u) async {
    final db = await database;
    await db.update('users', u.toMap(), where: 'id = ?', whereArgs: [u.id]);
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD CLIENTES ====================
  Future<void> insertCliente(Cliente c) async {
    final db = await database;
    await db.insert('clientes', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Cliente>> getClientes() async {
    final db = await database;
    final rows = await db.query('clientes', orderBy: 'nome ASC');
    return rows.map((r) => Cliente.fromMap(r)).toList();
  }

  Future<Cliente?> getClienteById(String id) async {
    final db = await database;
    final rows = await db.query('clientes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Cliente.fromMap(rows.first);
  }

  Future<void> updateCliente(Cliente c) async {
    final db = await database;
    await db.update('clientes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCliente(String id) async {
    final db = await database;
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD ATTACHMENTS ====================
  Future<void> insertAttachment(Attachment a) async {
    final db = await database;
    await db.insert('attachments', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Attachment>> getAttachments() async {
    final db = await database;
    final rows = await db.query('attachments', orderBy: 'createdAt DESC');
    return rows.map((r) => Attachment.fromMap(r)).toList();
  }

  Future<List<Attachment>> getAttachmentsByParent(String parentId) async {
    final db = await database;
    final rows = await db.query('attachments', where: 'parentId = ?', whereArgs: [parentId], orderBy: 'createdAt DESC');
    return rows.map((r) => Attachment.fromMap(r)).toList();
  }

  Future<void> deleteAttachment(String id) async {
    final db = await database;
    await db.delete('attachments', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD VEÍCULOS ====================
  Future<void> insertVeiculo(Veiculo v) async {
    final db = await database;
    await db.insert('veiculos', v.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Veiculo>> getVeiculos() async {
    final db = await database;
    final rows = await db.query('veiculos', orderBy: 'marca ASC, modelo ASC');
    return rows.map((r) => Veiculo.fromMap(r)).toList();
  }

  Future<List<Veiculo>> getVeiculosByCliente(String clienteId) async {
    final db = await database;
    final rows = await db.query('veiculos', where: 'clienteId = ?', whereArgs: [clienteId], orderBy: 'marca ASC');
    return rows.map((r) => Veiculo.fromMap(r)).toList();
  }

  Future<Veiculo?> getVeiculoById(String id) async {
    final db = await database;
    final rows = await db.query('veiculos', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Veiculo.fromMap(rows.first);
  }

  Future<void> updateVeiculo(Veiculo v) async {
    final db = await database;
    await db.update('veiculos', v.toMap(), where: 'id = ?', whereArgs: [v.id]);
  }

  Future<void> deleteVeiculo(String id) async {
    final db = await database;
    await db.delete('veiculos', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD ORÇAMENTOS ====================
  Future<void> insertOrcamento(Orcamento o) async {
    final db = await database;
    final map = o.toMap();
    map['itens'] = _encodeItens(o.itens);
    await db.insert('orcamentos', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateOrcamento(Orcamento o) async {
    final db = await database;
    final map = o.toMap();
    map['itens'] = _encodeItens(o.itens);
    await db.update('orcamentos', map, where: 'id = ?', whereArgs: [o.id]);
  }

  Future<List<Orcamento>> getOrcamentos() async {
    final db = await database;
    final rows = await db.query('orcamentos', orderBy: 'dataCriacao DESC');

    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['itens'] = _decodeItens(m['itens']);
      return Orcamento.fromMap(m);
    }).toList();
  }

  Future<List<Orcamento>> getOrcamentosByCliente(String clienteId) async {
    final db = await database;
    final rows = await db.query(
      'orcamentos',
      where: 'clienteId = ?',
      whereArgs: [clienteId],
      orderBy: 'dataCriacao DESC',
    );

    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['itens'] = _decodeItens(m['itens']);
      return Orcamento.fromMap(m);
    }).toList();
  }

  Future<List<Orcamento>> getOrcamentosByStatus(String status) async {
    final db = await database;
    final rows = await db.query(
      'orcamentos',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'dataCriacao DESC',
    );

    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['itens'] = _decodeItens(m['itens']);
      return Orcamento.fromMap(m);
    }).toList();
  }

  Future<Orcamento?> getOrcamentoById(String id) async {
    final db = await database;
    final rows = await db.query('orcamentos', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;

    final m = Map<String, dynamic>.from(rows.first);
    m['itens'] = _decodeItens(m['itens']);
    return Orcamento.fromMap(m);
  }

  Future<void> deleteOrcamento(String id) async {
    final db = await database;
    await db.delete('orcamentos', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD NOTAS ====================
  Future<void> insertNota(Nota n) async {
    final db = await database;
    final map = n.toMap();
    map['itens'] = _encodeItens(n.itens);
    await db.insert('notas', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Nota>> getNotas() async {
    final db = await database;
    final rows = await db.query('notas', orderBy: 'dataEmissao DESC');

    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['itens'] = _decodeItens(m['itens']);
      return Nota.fromMap(m);
    }).toList();
  }

  Future<List<Nota>> getNotasByCliente(String clienteId) async {
    final db = await database;
    final rows = await db.query(
      'notas',
      where: 'clienteId = ?',
      whereArgs: [clienteId],
      orderBy: 'dataEmissao DESC',
    );

    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['itens'] = _decodeItens(m['itens']);
      return Nota.fromMap(m);
    }).toList();
  }

  Future<Nota?> getNotaById(String id) async {
    final db = await database;
    final rows = await db.query('notas', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;

    final m = Map<String, dynamic>.from(rows.first);
    m['itens'] = _decodeItens(m['itens']);
    return Nota.fromMap(m);
  }

  Future<void> updateNota(Nota n) async {
    final db = await database;
    final map = n.toMap();
    map['itens'] = _encodeItens(n.itens);
    await db.update('notas', map, where: 'id = ?', whereArgs: [n.id]);
  }

  Future<void> deleteNota(String id) async {
    final db = await database;
    await db.delete('notas', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CRUD TRANSAÇÕES ====================
  Future<void> insertTransacao(Transacao t) async {
    final db = await database;
    await db.insert('transacoes', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Transacao>> getTransacoes() async {
    final db = await database;
    final rows = await db.query('transacoes', orderBy: 'data DESC');
    return rows.map((r) => Transacao.fromMap(r)).toList();
  }

  Future<List<Transacao>> getTransacoesByTipo(String tipo) async {
    final db = await database;
    final rows = await db.query('transacoes', where: 'tipo = ?', whereArgs: [tipo], orderBy: 'data DESC');
    return rows.map((r) => Transacao.fromMap(r)).toList();
  }

  Future<List<Transacao>> getTransacoesByPeriodo(String dataInicio, String dataFim) async {
    final db = await database;
    final rows = await db.query(
      'transacoes',
      where: 'data >= ? AND data <= ?',
      whereArgs: [dataInicio, dataFim],
      orderBy: 'data DESC',
    );
    return rows.map((r) => Transacao.fromMap(r)).toList();
  }

  Future<Transacao?> getTransacaoById(String id) async {
    final db = await database;
    final rows = await db.query('transacoes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Transacao.fromMap(rows.first);
  }

  Future<void> updateTransacao(Transacao t) async {
    final db = await database;
    await db.update('transacoes', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTransacao(String id) async {
    final db = await database;
    await db.delete('transacoes', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MÉTODOS AUXILIARES ====================
  Future<double> getTotalReceitas({String? dataInicio, String? dataFim}) async {
    final db = await database;
    String where = "tipo = 'entrada'";
    List<dynamic> whereArgs = [];

    if (dataInicio != null && dataFim != null) {
      where += " AND data >= ? AND data <= ?";
      whereArgs = [dataInicio, dataFim];
    }

    final result =
        await db.rawQuery('SELECT SUM(valor) as total FROM transacoes WHERE $where', whereArgs);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalDespesas({String? dataInicio, String? dataFim}) async {
    final db = await database;
    String where = "tipo = 'saida'";
    List<dynamic> whereArgs = [];

    if (dataInicio != null && dataFim != null) {
      where += " AND data >= ? AND data <= ?";
      whereArgs = [dataInicio, dataFim];
    }

    final result =
        await db.rawQuery('SELECT SUM(valor) as total FROM transacoes WHERE $where', whereArgs);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, int>> getOrcamentosCountByStatus() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT status, COUNT(*) as count FROM orcamentos GROUP BY status');

    final result = <String, int>{};
    for (final row in rows) {
      result[row['status'] as String] = (row['count'] as int?) ?? 0;
    }
    return result;
  }
}
