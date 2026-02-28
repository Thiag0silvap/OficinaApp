import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../services/db_service.dart';
import '../models/nota.dart';
import '../models/user.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = false;

  String? _activeUserId;
  bool _activeUserIsAdmin = false;

  static const _prefsKeyCustomMarcas = 'custom_vehicle_marcas';
  static const _prefsKeyCustomModelosPorMarca =
      'custom_vehicle_modelos_por_marca';

  final List<String> _customMarcas = [];
  final Map<String, List<String>> _customModelosPorMarca = {};

  final List<Cliente> _clientes = [];
  final List<Veiculo> _veiculos = [];
  final List<Orcamento> _orcamentos = [];
  final List<Transacao> _transacoes = [];

  final DBService _db = DBService.instance;

  // ===================== GETTERS =====================

  List<Cliente> get clientes => _clientes;
  List<Veiculo> get veiculos => _veiculos;
  List<Orcamento> get orcamentos => _orcamentos;
  List<Transacao> get transacoes => _transacoes;

  bool get isLoading => _isLoading;

  String? get activeUserId => _activeUserId;

  Future<void> _ensureUserDbSelected() async {
    final userId = _activeUserId;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Usuário não autenticado');
    }
    await _db.setActiveUserId(userId);
  }

  // ===================== AUTH SYNC =====================

  /// Called whenever authentication changes.
  ///
  /// This keeps all app data (SQLite) isolated per user.
  void syncAuthUser(User? user) {
    final normalized = user?.id.trim();
    final next = (normalized == null || normalized.isEmpty) ? null : normalized;
    final nextIsAdmin = user?.role == UserRole.admin;
    if (next == _activeUserId) return;

    _activeUserId = next;
    _activeUserIsAdmin = nextIsAdmin;

    // Clear immediately to avoid showing previous user's data.
    _clientes.clear();
    _veiculos.clear();
    _orcamentos.clear();
    _transacoes.clear();
    notifyListeners();

    // Switch DB + reload in background.
    unawaited(_reloadForActiveUser());
  }

  // ===================== CATÁLOGO VEÍCULOS (MARCA/MODELO) =====================

  List<String> get marcasDisponiveis {
    final merged = <String>{...AppConstants.marcas, ..._customMarcas};
    final list = merged.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<String> modelosDisponiveis(String? marca) {
    if (marca == null || marca.trim().isEmpty) return const [];
    final base = AppConstants.modelosPorMarca[marca] ?? const <String>[];
    final custom = _customModelosPorMarca[marca] ?? const <String>[];
    final merged = <String>{...base, ...custom};
    final list = merged.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<void> addMarcaModeloCustom({
    required String marca,
    String? modelo,
  }) async {
    final fixedMarca = _prettyName(marca);
    if (fixedMarca.isEmpty) return;

    final hasMarcaBase = AppConstants.marcas.any(
      (m) => m.toLowerCase() == fixedMarca.toLowerCase(),
    );
    final hasMarcaCustom = _customMarcas.any(
      (m) => m.toLowerCase() == fixedMarca.toLowerCase(),
    );
    if (!hasMarcaBase && !hasMarcaCustom) {
      _customMarcas.add(fixedMarca);
    }

    final fixedModelo = _prettyName(modelo ?? '');
    if (fixedModelo.isNotEmpty) {
      final baseModelos =
          AppConstants.modelosPorMarca[fixedMarca] ?? const <String>[];
      final hasModeloBase = baseModelos.any(
        (m) => m.toLowerCase() == fixedModelo.toLowerCase(),
      );

      final list = _customModelosPorMarca.putIfAbsent(
        fixedMarca,
        () => <String>[],
      );
      final hasModeloCustom = list.any(
        (m) => m.toLowerCase() == fixedModelo.toLowerCase(),
      );

      if (!hasModeloBase && !hasModeloCustom) {
        list.add(fixedModelo);
      }
    }

    await _saveVehicleCatalogToPrefs();
    notifyListeners();
  }

  String _prettyName(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _loadVehicleCatalogFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final marcas =
        prefs.getStringList(_prefsKeyCustomMarcas) ?? const <String>[];
    _customMarcas
      ..clear()
      ..addAll(marcas);

    final raw = prefs.getString(_prefsKeyCustomModelosPorMarca);
    _customModelosPorMarca.clear();
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      for (final entry in decoded.entries) {
        final key = entry.key?.toString() ?? '';
        final value = entry.value;
        if (key.isEmpty) continue;
        if (value is List) {
          _customModelosPorMarca[key] = value
              .map((e) => e.toString())
              .where((s) => s.trim().isNotEmpty)
              .toList();
        }
      }
    } catch (_) {
      // ignore: avoid_print
      debugPrint('Falha ao ler catálogo de veículos do SharedPreferences');
    }
  }

  Future<void> _saveVehicleCatalogToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyCustomMarcas, _customMarcas);
    await prefs.setString(
      _prefsKeyCustomModelosPorMarca,
      jsonEncode(_customModelosPorMarca),
    );
  }

  double get totalEntradas => _transacoes
      .where((t) => t.tipo == TipoTransacao.entrada)
      .fold(0, (s, t) => s + t.valor);

  double get totalSaidas => _transacoes
      .where((t) => t.tipo == TipoTransacao.saida)
      .fold(0, (s, t) => s + t.valor);

  double get saldo => totalEntradas - totalSaidas;

  List<Orcamento> get orcamentosPendentes =>
      _orcamentos.where((o) => o.status == OrcamentoStatus.pendente).toList();

  List<Orcamento> get orcamentosAprovados =>
      _orcamentos.where((o) => o.status == OrcamentoStatus.aprovado).toList();

  List<Orcamento> get orcamentosEmAndamento => _orcamentos
      .where((o) => o.status == OrcamentoStatus.emAndamento)
      .toList();

  List<Orcamento> get orcamentosConcluidos =>
      _orcamentos.where((o) => o.status == OrcamentoStatus.concluido).toList();

  double get entradasMesAtual {
    final now = DateTime.now();
    return _transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.entrada &&
              t.data.month == now.month &&
              t.data.year == now.year,
        )
        .fold(0, (sum, t) => sum + t.valor);
  }

  double get entradasMesAnterior {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    return _transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.entrada &&
              t.data.month == prev.month &&
              t.data.year == prev.year,
        )
        .fold(0, (sum, t) => sum + t.valor);
  }

  Map<String, dynamic> percentageChange(double current, double previous) {
    if (previous == 0) {
      if (current == 0) return {'label': '0%', 'up': true};
      // Quando o valor anterior é zero, a variação percentual é indefinida.
      // Evita exibir um "traço" (—) e mostra um rótulo mais útil no dashboard.
      return {'label': 'Novo', 'up': current >= 0};
    }
    final diff = current - previous;
    final pct = (diff / previous) * 100;
    final rounded = pct.abs().round();
    final sign = pct >= 0 ? '+' : '-';
    return {'label': '$sign$rounded%', 'up': pct >= 0};
  }

  int get pendingPaymentsCount => _orcamentos
      .where((o) => o.status == OrcamentoStatus.concluido && !o.pago)
      .length;

  double get pendingPaymentsTotal => _orcamentos
      .where((o) => o.status == OrcamentoStatus.concluido && !o.pago)
      .fold(0, (sum, o) => sum + o.valorTotal);

  // ===================== CLIENTES =====================

  Future<void> addCliente(Cliente cliente) async {
    try {
      await _ensureUserDbSelected();
      await _db.insertCliente(cliente);
      _clientes.add(cliente);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao adicionar cliente: $e');
      rethrow;
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    try {
      await _ensureUserDbSelected();
      await _db.updateCliente(cliente);
      final index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = cliente;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao atualizar cliente: $e');
      rethrow;
    }
  }

  Future<void> deleteCliente(String id) async {
    try {
      await _ensureUserDbSelected();
      await _db.deleteCliente(id);
      _clientes.removeWhere((c) => c.id == id);
      _veiculos.removeWhere((v) => v.clienteId == id);

      // Keep in-memory state consistent with DB cascades
      final removedOrcamentoIds = _orcamentos
          .where((o) => o.clienteId == id)
          .map((o) => o.id)
          .toSet();
      _orcamentos.removeWhere((o) => o.clienteId == id);
      _transacoes.removeWhere(
        (t) =>
            t.orcamentoId != null &&
            removedOrcamentoIds.contains(t.orcamentoId),
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao excluir cliente: $e');
      rethrow;
    }
  }

  Cliente? getClienteById(String id) =>
      _clientes.where((c) => c.id == id).cast<Cliente?>().firstOrNull;

  // ===================== VEÍCULOS =====================

  Future<void> addVeiculo(Veiculo veiculo) async {
    await _ensureUserDbSelected();
    await _db.insertVeiculo(veiculo);
    _veiculos.add(veiculo);
    notifyListeners();
  }

  Future<void> updateVeiculo(Veiculo veiculo) async {
    await _ensureUserDbSelected();
    await _db.updateVeiculo(veiculo);
    final index = _veiculos.indexWhere((v) => v.id == veiculo.id);
    if (index != -1) {
      _veiculos[index] = veiculo;
      notifyListeners();
    }
  }

  Future<void> deleteVeiculo(String id) async {
    await _ensureUserDbSelected();
    await _db.deleteVeiculo(id);
    _veiculos.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  List<Veiculo> getVeiculosByCliente(String clienteId) =>
      _veiculos.where((v) => v.clienteId == clienteId).toList();

  // ===================== ORÇAMENTOS =====================

  Future<void> addOrcamento(Orcamento o) async {
    await _ensureUserDbSelected();
    await _db.insertOrcamento(o);
    _orcamentos.add(o);
    notifyListeners();
  }

  Future<void> updateOrcamento(Orcamento o) async {
    await _ensureUserDbSelected();
    await _db.updateOrcamento(o);
    final index = _orcamentos.indexWhere((x) => x.id == o.id);
    if (index != -1) {
      _orcamentos[index] = o;
      notifyListeners();
    }
  }

  Future<void> deleteOrcamento(String id) async {
    await _ensureUserDbSelected();
    await _db.deleteOrcamento(id);
    _orcamentos.removeWhere((o) => o.id == id);
    _transacoes.removeWhere((t) => t.orcamentoId == id);
    notifyListeners();
  }

  Future<void> aprovarOrcamento(String id) async {
    final index = _orcamentos.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final atual = _orcamentos[index];
    if (atual.status != OrcamentoStatus.pendente) return;

    final atualizado = atual.copyWith(
      status: OrcamentoStatus.aprovado,
      dataAprovacao: DateTime.now(),
    );

    await _ensureUserDbSelected();
    await _db.updateOrcamento(atualizado);
    _orcamentos[index] = atualizado;
    notifyListeners();
  }

  Future<void> iniciarServico(String id) async {
    final index = _orcamentos.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final atual = _orcamentos[index];
    if (atual.status != OrcamentoStatus.aprovado) return;

    final atualizado = atual.copyWith(status: OrcamentoStatus.emAndamento);

    await _ensureUserDbSelected();
    await _db.updateOrcamento(atualizado);
    _orcamentos[index] = atualizado;
    notifyListeners();
  }

  Future<void> concluirOrcamento(String id) async {
    final index = _orcamentos.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final atual = _orcamentos[index];

    // 🔒 trava fluxo
    if (atual.status != OrcamentoStatus.emAndamento) return;
    if (atual.dataConclusao != null) return;

    final atualizado = atual.copyWith(
      status: OrcamentoStatus.concluido,
      dataConclusao: DateTime.now(),
    );

    await _ensureUserDbSelected();
    await _db.updateOrcamento(atualizado);

    // 🔒 Gera nota uma única vez
    final nota = Nota.fromOrcamento(atualizado);
    await _db.insertNota(nota);

    _orcamentos[index] = atualizado;
    notifyListeners();
  }

  Future<void> registrarPagamento(String id) async {
    final index = _orcamentos.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final atual = _orcamentos[index];

    if (atual.status != OrcamentoStatus.concluido) return;
    if (atual.pago) return;

    final atualizado = atual.copyWith(
      pago: true,
      dataPagamento: DateTime.now(),
    );

    await _ensureUserDbSelected();
    await _db.updateOrcamento(atualizado);

    final transacao = Transacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tipo: TipoTransacao.entrada,
      descricao: 'Pagamento serviço - ${atual.clienteNome}',
      valor: atual.valorTotal,
      categoria: 'Serviço',
      data: DateTime.now(),
      orcamentoId: id,
    );

    await _db.insertTransacao(transacao);

    _orcamentos[index] = atualizado;
    _transacoes.add(transacao);

    notifyListeners();
  }

  Future<void> cancelarOrcamento(String id) async {
    final index = _orcamentos.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final atual = _orcamentos[index];
    if (atual.status == OrcamentoStatus.cancelado) return;

    final atualizado = atual.copyWith(status: OrcamentoStatus.cancelado);

    await _ensureUserDbSelected();
    await _db.updateOrcamento(atualizado);
    _orcamentos[index] = atualizado;
    notifyListeners();
  }

  List<Orcamento> getOrcamentosByCliente(String clienteId) {
    return _orcamentos.where((o) => o.clienteId == clienteId).toList();
  }

  // ===================== TRANSAÇÕES =====================

  Future<void> addTransacao(Transacao t) async {
    await _ensureUserDbSelected();
    await _db.insertTransacao(t);
    _transacoes.add(t);
    notifyListeners();
  }

  Future<void> deleteTransacao(String id) async {
    await _ensureUserDbSelected();
    await _db.deleteTransacao(id);
    _transacoes.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ===================== INIT / RELOAD =====================

  Future<void> initApp() async {
    try {
      await _loadVehicleCatalogFromPrefs();
    } catch (e) {
      debugPrint('Erro ao inicializar preferências do AppProvider: $e');
    }
  }

  Future<void> _reloadForActiveUser() async {
    final userIdAtStart = _activeUserId;
    final isAdminAtStart = _activeUserIsAdmin;

    _isLoading = true;
    notifyListeners();

    try {
      await _db.setActiveUserId(
        userIdAtStart,
        migrateLegacyIfNeeded: isAdminAtStart,
      );

      if (userIdAtStart == null) {
        // Not authenticated: keep empty in-memory lists.
        return;
      }

      final clientesDB = await _db.getClientes();
      final veiculosDB = await _db.getVeiculos();
      final orcamentosDB = await _db.getOrcamentos();
      final transacoesDB = await _db.getTransacoes();

      // If user changed mid-flight, don't apply stale results.
      if (_activeUserId != userIdAtStart) return;

      _clientes
        ..clear()
        ..addAll(clientesDB);
      _veiculos
        ..clear()
        ..addAll(veiculosDB);
      _orcamentos
        ..clear()
        ..addAll(orcamentosDB);
      _transacoes
        ..clear()
        ..addAll(transacoesDB);
    } catch (e) {
      debugPrint('Erro ao recarregar dados do AppProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
