import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../models/orcamento.dart';
import '../models/transacao.dart';
import '../services/app_logger.dart';
import '../services/db_service.dart';
import '../models/nota.dart';
import '../models/user.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastErrorMessage;

  String? _activeUserId;
  bool _activeUserIsAdmin = false;

  static const _prefsKeyCustomMarcas = 'custom_vehicle_marcas';
  static const _prefsKeyCustomModelosPorMarca =
      'custom_vehicle_modelos_por_marca';
  static const _prefsKeyMarcasModelosMigrado = 'marcas_modelos_migrado_v1';

  final List<String> _customMarcas = [];
  final Map<String, List<String>> _customModelosPorMarca = {};

  final List<Cliente> _clientes = [];
  final List<Veiculo> _veiculos = [];
  final List<Orcamento> _orcamentos = [];
  final List<Transacao> _transacoes = [];

  final DBService _db = DBService.instance;

  // ✅ Travas contra duplicidade
  final Set<String> _orcamentosConcluindo = {};
  final Set<String> _orcamentosRecebendo = {};

  // ===================== GETTERS =====================

  List<Cliente> get clientes => _clientes;
  List<Veiculo> get veiculos => _veiculos;
  List<Orcamento> get orcamentos => _orcamentos;
  List<Transacao> get transacoes => _transacoes;

  bool get isLoading => _isLoading;
  String? get lastErrorMessage => _lastErrorMessage;

  String? get activeUserId => _activeUserId;

  void clearLastError() {
    _lastErrorMessage = null;
    notifyListeners();
  }

  Future<void> _ensureUserDbSelected() async {
    final userId = _activeUserId;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Usuário não autenticado');
    }
    await _db.setActiveUserId(userId);
  }

  // ===================== AUTH SYNC =====================

  void syncAuthUser(User? user) {
    final normalized = user?.id.trim();
    final next = (normalized == null || normalized.isEmpty) ? null : normalized;
    final nextIsAdmin = user?.role == UserRole.admin;
    if (next == _activeUserId) return;

    _activeUserId = next;
    _activeUserIsAdmin = nextIsAdmin;

    _clientes.clear();
    _veiculos.clear();
    _orcamentos.clear();
    _transacoes.clear();
    _customMarcas.clear();
    _customModelosPorMarca.clear();
    notifyListeners();

    unawaited(_reloadForActiveUser());
  }

  // ===================== CATÁLOGO VEÍCULOS =====================

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

    await _ensureUserDbSelected();

    final hasMarcaBase = AppConstants.marcas.any(
      (m) => m.toLowerCase() == fixedMarca.toLowerCase(),
    );
    final hasMarcaCustom = _customMarcas.any(
      (m) => m.toLowerCase() == fixedMarca.toLowerCase(),
    );
    if (!hasMarcaBase && !hasMarcaCustom) {
      _customMarcas.add(fixedMarca);
      await _db.insertMarcaModeloCustom(marca: fixedMarca);
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
        await _db.insertMarcaModeloCustom(marca: fixedMarca, modelo: fixedModelo);
      }
    }

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

  /// Busca o catálogo de marcas/modelos digitados manualmente a partir do
  /// banco da conta ativa. Na primeira vez que a tabela da conta estiver
  /// vazia, tenta migrar o catálogo antigo (compartilhado, gravado em
  /// SharedPreferences) para dentro do banco dessa conta — mas só se essa
  /// migração ainda não tiver sido feita para NENHUMA conta neste
  /// dispositivo (ver `_migrateLegacyVehicleCatalogFromPrefs`) — só como fallback
  /// de leitura nesse primeiro carregamento; nunca mais grava em prefs.
  Future<({List<String> marcas, Map<String, List<String>> modelosPorMarca})>
      _fetchVehicleCatalogFromDb() async {
    var rows = await _db.getMarcasModelosCustom();

    if (rows.isEmpty) {
      await _migrateLegacyVehicleCatalogFromPrefs();
      rows = await _db.getMarcasModelosCustom();
    }

    final marcas = <String>[];
    final modelosPorMarca = <String, List<String>>{};

    for (final row in rows) {
      final marca = (row['marca'] ?? '').trim();
      final modelo = (row['modelo'] ?? '').trim();
      if (marca.isEmpty) continue;

      if (modelo.isEmpty) {
        if (!marcas.any((m) => m.toLowerCase() == marca.toLowerCase())) {
          marcas.add(marca);
        }
        continue;
      }

      final list = modelosPorMarca.putIfAbsent(marca, () => <String>[]);
      if (!list.any((m) => m.toLowerCase() == modelo.toLowerCase())) {
        list.add(modelo);
      }
    }

    return (marcas: marcas, modelosPorMarca: modelosPorMarca);
  }

  /// Migra o catálogo legado do SharedPreferences (compartilhado entre
  /// TODAS as contas do aparelho) para o banco da conta atual — mas só uma
  /// única vez por dispositivo, nunca uma vez por conta. Sem essa trava,
  /// cada conta que carregasse pela primeira vez após o update herdaria o
  /// mesmo snapshot do catálogo antigo, duplicando o mesmo dado "vazado"
  /// em várias contas. A primeira conta a carregar após este update é a
  /// única que herda o catálogo histórico; qualquer conta seguinte (nova ou
  /// já existente) começa com o catálogo vazio.
  Future<void> _migrateLegacyVehicleCatalogFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jaMigradoNesteAparelho =
          prefs.getBool(_prefsKeyMarcasModelosMigrado) ?? false;
      if (jaMigradoNesteAparelho) return;

      final legacyMarcas =
          prefs.getStringList(_prefsKeyCustomMarcas) ?? const <String>[];

      final legacyModelosPorMarca = <String, List<String>>{};
      final raw = prefs.getString(_prefsKeyCustomModelosPorMarca);
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final key = entry.key?.toString() ?? '';
            final value = entry.value;
            if (key.isEmpty || value is! List) continue;
            legacyModelosPorMarca[key] = value
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList();
          }
        }
      }

      if (legacyMarcas.isEmpty && legacyModelosPorMarca.isEmpty) {
        await prefs.setBool(_prefsKeyMarcasModelosMigrado, true);
        return;
      }

      for (final marca in legacyMarcas) {
        await _db.insertMarcaModeloCustom(marca: marca);
      }
      for (final entry in legacyModelosPorMarca.entries) {
        for (final modelo in entry.value) {
          await _db.insertMarcaModeloCustom(marca: entry.key, modelo: modelo);
        }
      }

      // Só marca como concluído depois que todas as inserções deram certo —
      // se algo falhar no meio do caminho, a flag não é gravada e a próxima
      // conta a carregar tenta migrar de novo (retry seguro/idempotente).
      await prefs.setBool(_prefsKeyMarcasModelosMigrado, true);
    } catch (_) {
      debugPrint('Falha ao migrar catálogo legado de veículos (SharedPreferences)');
    }
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
      _validateCliente(cliente);
      await _ensureUserDbSelected();
      await _db.insertCliente(cliente);
      _clientes.add(cliente);
      notifyListeners();
      unawaited(AppLogger.instance.info('Cliente adicionado: ${cliente.nome}'));
    } catch (e) {
      _recordError('Erro ao adicionar cliente: $e');
      rethrow;
    }
  }

  Future<void> updateCliente(Cliente cliente) async {
    try {
      _validateCliente(cliente);
      await _ensureUserDbSelected();
      await _db.updateCliente(cliente);
      final index = _clientes.indexWhere((c) => c.id == cliente.id);
      if (index != -1) {
        _clientes[index] = cliente;
        notifyListeners();
        unawaited(
          AppLogger.instance.info('Cliente atualizado: ${cliente.nome}'),
        );
      }
    } catch (e) {
      _recordError('Erro ao atualizar cliente: $e');
      rethrow;
    }
  }

  /// Oculta o cliente (soft delete: ativo = false) e, em cascata, todos os
  /// veículos dele. Orçamentos e transações vinculados NÃO são tocados —
  /// permanecem intactos no histórico, com clienteId/veiculoId originais,
  /// já que cliente e veículo continuam existindo no banco (só inativos).
  Future<void> deleteCliente(String id) async {
    try {
      final index = _clientes.indexWhere((c) => c.id == id);
      if (index == -1) return;

      await _ensureUserDbSelected();

      final clienteOculto = _clientes[index].copyWith(ativo: false);
      await _db.updateCliente(clienteOculto);
      _clientes.removeAt(index);

      final veiculosDoCliente =
          _veiculos.where((v) => v.clienteId == id).toList();
      for (final veiculo in veiculosDoCliente) {
        await _db.updateVeiculo(veiculo.copyWith(ativo: false));
      }
      _veiculos.removeWhere((v) => v.clienteId == id);

      notifyListeners();
      unawaited(AppLogger.instance.warning('Cliente ocultado (soft delete): $id'));
    } catch (e) {
      _recordError('Erro ao excluir cliente: $e');
      rethrow;
    }
  }

  /// Reverte o soft delete de um cliente. Não é chamado por nenhuma tela
  /// hoje — deixado pronto para uma futura tela de "clientes ocultos".
  Future<void> reativarCliente(Cliente cliente) async {
    try {
      await _ensureUserDbSelected();
      final atualizado = cliente.copyWith(ativo: true);
      await _db.updateCliente(atualizado);
      final index = _clientes.indexWhere((c) => c.id == atualizado.id);
      if (index != -1) {
        _clientes[index] = atualizado;
      } else {
        _clientes.add(atualizado);
      }
      notifyListeners();
      unawaited(AppLogger.instance.info('Cliente reativado: ${atualizado.id}'));
    } catch (e) {
      _recordError('Erro ao reativar cliente: $e');
      rethrow;
    }
  }

  Cliente? getClienteById(String id) =>
      _clientes.where((c) => c.id == id).cast<Cliente?>().firstOrNull;

  // ===================== VEÍCULOS =====================

  Future<void> addVeiculo(Veiculo veiculo) async {
    try {
      _validateVeiculo(veiculo);
      await _ensureUserDbSelected();
      await _db.insertVeiculo(veiculo);
      _veiculos.add(veiculo);
      notifyListeners();
      unawaited(AppLogger.instance.info('Veiculo adicionado: ${veiculo.placa}'));
    } catch (e) {
      _recordError('Erro ao adicionar veiculo: $e');
      rethrow;
    }
  }

  Future<void> updateVeiculo(Veiculo veiculo) async {
    try {
      _validateVeiculo(veiculo);
      await _ensureUserDbSelected();
      await _db.updateVeiculo(veiculo);
      final index = _veiculos.indexWhere((v) => v.id == veiculo.id);
      if (index != -1) {
        _veiculos[index] = veiculo;
        notifyListeners();
        unawaited(
          AppLogger.instance.info('Veiculo atualizado: ${veiculo.placa}'),
        );
      }
    } catch (e) {
      _recordError('Erro ao atualizar veiculo: $e');
      rethrow;
    }
  }

  /// Oculta o veículo (soft delete: ativo = false via updateVeiculo).
  /// Orçamentos vinculados a ele não são tocados — permanecem no histórico.
  Future<void> deleteVeiculo(String id) async {
    try {
      final index = _veiculos.indexWhere((v) => v.id == id);
      if (index == -1) return;

      await _ensureUserDbSelected();
      final atualizado = _veiculos[index].copyWith(ativo: false);
      await _db.updateVeiculo(atualizado);
      _veiculos.removeAt(index);
      notifyListeners();
      unawaited(AppLogger.instance.warning('Veiculo ocultado (soft delete): $id'));
    } catch (e) {
      _recordError('Erro ao excluir veiculo: $e');
      rethrow;
    }
  }

  /// Reverte o soft delete de um veículo. Não é chamado por nenhuma tela
  /// hoje — deixado pronto para uso futuro.
  Future<void> reativarVeiculo(Veiculo veiculo) async {
    try {
      await _ensureUserDbSelected();
      final atualizado = veiculo.copyWith(ativo: true);
      await _db.updateVeiculo(atualizado);
      final index = _veiculos.indexWhere((v) => v.id == atualizado.id);
      if (index != -1) {
        _veiculos[index] = atualizado;
      } else {
        _veiculos.add(atualizado);
      }
      notifyListeners();
      unawaited(AppLogger.instance.info('Veiculo reativado: ${atualizado.id}'));
    } catch (e) {
      _recordError('Erro ao reativar veiculo: $e');
      rethrow;
    }
  }

  List<Veiculo> getVeiculosByCliente(String clienteId) =>
      _veiculos.where((v) => v.clienteId == clienteId).toList();

  // ===================== ORÇAMENTOS =====================

  Future<void> addOrcamento(Orcamento o) async {
    try {
      _validateOrcamento(o);
      await _ensureUserDbSelected();
      await _db.insertOrcamento(o);
      _orcamentos.add(o);
      notifyListeners();
      unawaited(AppLogger.instance.info('Orcamento criado: ${o.id}'));
    } catch (e) {
      _recordError('Erro ao adicionar orcamento: $e');
      rethrow;
    }
  }

  Future<void> updateOrcamento(Orcamento o) async {
    try {
      _validateOrcamento(o);
      await _ensureUserDbSelected();
      await _db.updateOrcamento(o);
      final index = _orcamentos.indexWhere((x) => x.id == o.id);
      if (index != -1) {
        _orcamentos[index] = o;
        notifyListeners();
        unawaited(AppLogger.instance.info('Orcamento atualizado: ${o.id}'));
      }
    } catch (e) {
      _recordError('Erro ao atualizar orcamento: $e');
      rethrow;
    }
  }

  Future<void> deleteOrcamento(String id) async {
    try {
      await _ensureUserDbSelected();
      await _db.deleteOrcamento(id);
      _orcamentos.removeWhere((o) => o.id == id);
      _transacoes.removeWhere((t) => t.orcamentoId == id);
      notifyListeners();
      unawaited(AppLogger.instance.warning('Orcamento removido: $id'));
    } catch (e) {
      _recordError('Erro ao excluir orcamento: $e');
      rethrow;
    }
  }

  Future<void> aprovarOrcamento(String id) async {
    try {
      final index = _orcamentos.indexWhere((o) => o.id == id);
      if (index == -1) return;

      final atual = _orcamentos[index];
      if (atual.status != OrcamentoStatus.pendente) return;

      final atualizado = atual.copyWith(
        status: OrcamentoStatus.aprovado,
        dataAprovacao: DateTime.now(),
      );
      _validateOrcamento(atualizado);

      await _ensureUserDbSelected();
      await _db.updateOrcamento(atualizado);
      _orcamentos[index] = atualizado;
      notifyListeners();
      unawaited(AppLogger.instance.info('Orcamento aprovado: $id'));
    } catch (e) {
      _recordError('Erro ao aprovar orcamento: $e');
      rethrow;
    }
  }

  Future<void> iniciarServico(String id) async {
    try {
      final index = _orcamentos.indexWhere((o) => o.id == id);
      if (index == -1) return;

      final atual = _orcamentos[index];
      if (atual.status != OrcamentoStatus.aprovado) return;

      final atualizado = atual.copyWith(status: OrcamentoStatus.emAndamento);
      _validateOrcamento(atualizado);

      await _ensureUserDbSelected();
      await _db.updateOrcamento(atualizado);
      _orcamentos[index] = atualizado;
      notifyListeners();
      unawaited(AppLogger.instance.info('Servico iniciado para orcamento: $id'));
    } catch (e) {
      _recordError('Erro ao iniciar servico: $e');
      rethrow;
    }
  }

  Future<void> concluirOrcamento(String id) async {
    if (_orcamentosConcluindo.contains(id)) return;

    final index = _orcamentos.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final atual = _orcamentos[index];

    if (atual.status != OrcamentoStatus.emAndamento) return;
    if (atual.dataConclusao != null) return;

    _orcamentosConcluindo.add(id);

    try {
      final atualizado = atual.copyWith(
        status: OrcamentoStatus.concluido,
        dataConclusao: DateTime.now(),
      );
      _validateOrcamento(atualizado);

      await _ensureUserDbSelected();
      await _db.updateOrcamento(atualizado);

      // ✅ Gera nota apenas uma vez
      // Mantendo compatibilidade com seu fluxo atual
      // A nota é um registro auxiliar (histórico), não crítico para o fluxo
      // principal: uma falha aqui não deve impedir a conclusão do orçamento,
      // mas também não deve passar em silêncio — só logamos.
      final nota = Nota.fromOrcamento(atualizado);
      try {
        await _db.insertNota(nota);
      } catch (e) {
        unawaited(
          AppLogger.instance.error(
            'Falha ao gravar nota auxiliar do orcamento $id: $e',
          ),
        );
      }

      _orcamentos[index] = atualizado;
      notifyListeners();
      unawaited(AppLogger.instance.info('Orcamento concluido: $id'));
    } catch (e) {
      _recordError('Erro ao concluir orcamento: $e');
      rethrow;
    } finally {
      _orcamentosConcluindo.remove(id);
    }
  }

  Future<void> registrarPagamento(String id) async {
    if (_orcamentosRecebendo.contains(id)) return;

    final index = _orcamentos.indexWhere((o) => o.id == id);
    if (index == -1) return;

    final atual = _orcamentos[index];

    if (atual.status != OrcamentoStatus.concluido) return;
    if (atual.pago) return;

    _orcamentosRecebendo.add(id);

    try {
      await _ensureUserDbSelected();

      // ✅ Antes de inserir, verifica se já existe transação para este orçamento
      final transacaoExistente = await _db.getTransacaoByOrcamentoId(id);

      if (transacaoExistente != null) {
        final atualizadoExistente = atual.copyWith(
          pago: true,
          dataPagamento: atual.dataPagamento ?? DateTime.now(),
        );

        await _db.updateOrcamento(atualizadoExistente);
        _orcamentos[index] = atualizadoExistente;

        if (!_transacoes.any((t) => t.id == transacaoExistente.id)) {
          _transacoes.add(transacaoExistente);
        }

        notifyListeners();
        unawaited(
          AppLogger.instance.info(
            'Pagamento reconhecido por transacao existente: $id',
          ),
        );
        return;
      }

      final atualizado = atual.copyWith(
        pago: true,
        dataPagamento: DateTime.now(),
      );

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

      _validateTransacao(transacao);
      await _db.insertTransacao(transacao);

      _orcamentos[index] = atualizado;
      _transacoes.add(transacao);

      notifyListeners();
      unawaited(AppLogger.instance.info('Pagamento registrado: $id'));
    } catch (e) {
      _recordError('Erro ao registrar pagamento: $e');
      rethrow;
    } finally {
      _orcamentosRecebendo.remove(id);
    }
  }

  /// Cancela um orçamento Pendente, Aprovado ou Em andamento. Recusa
  /// (lançando erro tratável) se já Concluído ou já Cancelado. [motivo] é
  /// opcional a partir de Pendente/Aprovado, mas obrigatório quando o
  /// status atual é Em andamento.
  Future<void> cancelarOrcamento(String id, {String? motivo}) async {
    try {
      final index = _orcamentos.indexWhere((o) => o.id == id);
      if (index == -1) return;

      final atual = _orcamentos[index];
      final statusAtual = atual.status;

      if (statusAtual == OrcamentoStatus.concluido) {
        throw StateError('Não é possível cancelar um orçamento já Concluído.');
      }
      if (statusAtual == OrcamentoStatus.cancelado) {
        throw StateError('Este orçamento já está Cancelado.');
      }

      final motivoTrimmed = motivo?.trim();
      if (statusAtual == OrcamentoStatus.emAndamento &&
          (motivoTrimmed == null || motivoTrimmed.isEmpty)) {
        throw StateError(
          'Informe o motivo do cancelamento para orçamentos Em andamento.',
        );
      }

      final atualizado = atual.copyWith(
        status: OrcamentoStatus.cancelado,
        motivoCancelamento:
            (motivoTrimmed != null && motivoTrimmed.isNotEmpty)
                ? motivoTrimmed
                : null,
      );

      await _ensureUserDbSelected();
      await _db.updateOrcamento(atualizado);
      _orcamentos[index] = atualizado;
      notifyListeners();
      unawaited(AppLogger.instance.warning('Orcamento cancelado: $id'));
    } catch (e) {
      _recordError('Erro ao cancelar orcamento: $e');
      rethrow;
    }
  }

  List<Orcamento> getOrcamentosByCliente(String clienteId) {
    return _orcamentos.where((o) => o.clienteId == clienteId).toList();
  }

  /// Histórico de serviços (notas) de um cliente. Diferente de
  /// clientes/veículos/orçamentos, notas não ficam em cache no provider —
  /// são lidas direto do banco da conta ativa.
  Future<List<Nota>> getNotasByCliente(String clienteId) async {
    try {
      await _ensureUserDbSelected();
      return await _db.getNotasByCliente(clienteId);
    } catch (e) {
      _recordError('Erro ao buscar histórico de serviços: $e');
      return const [];
    }
  }

  // ===================== TRANSAÇÕES =====================

  Future<void> addTransacao(Transacao t) async {
    try {
      _validateTransacao(t);
      await _ensureUserDbSelected();
      await _db.insertTransacao(t);
      _transacoes.add(t);
      notifyListeners();
      unawaited(AppLogger.instance.info('Transacao adicionada: ${t.id}'));
    } catch (e) {
      _recordError('Erro ao adicionar transacao: $e');
      rethrow;
    }
  }

  Future<void> deleteTransacao(String id) async {
    await _ensureUserDbSelected();

    // Se a transação é o pagamento de um orçamento, reverte o status de
    // pagamento do orçamento ANTES de excluir a transação — nessa ordem,
    // para que uma falha na reversão não deixe a transação apagada sem o
    // orçamento correspondente atualizado.
    final transacao =
        _transacoes.where((t) => t.id == id).cast<Transacao?>().firstOrNull;
    final orcamentoId = transacao?.orcamentoId;

    if (orcamentoId != null) {
      final index = _orcamentos.indexWhere((o) => o.id == orcamentoId);
      if (index != -1 && _orcamentos[index].pago) {
        try {
          final atual = _orcamentos[index];
          final revertido = Orcamento(
            id: atual.id,
            clienteId: atual.clienteId,
            clienteNome: atual.clienteNome,
            veiculoId: atual.veiculoId,
            veiculoDescricao: atual.veiculoDescricao,
            itens: atual.itens,
            valorTotal: atual.valorTotal,
            status: atual.status,
            dataCriacao: atual.dataCriacao,
            dataAprovacao: atual.dataAprovacao,
            dataConclusao: atual.dataConclusao,
            pago: false,
            dataPagamento: null,
            observacoes: atual.observacoes,
            observacoesCliente: atual.observacoesCliente,
            observacoesInternas: atual.observacoesInternas,
            dataPrevistaEntrega: atual.dataPrevistaEntrega,
            tipoAtendimento: atual.tipoAtendimento,
          );
          await _db.updateOrcamento(revertido);
          _orcamentos[index] = revertido;
          notifyListeners();
          unawaited(
            AppLogger.instance.info(
              'Pagamento revertido no orcamento $orcamentoId ao excluir transacao $id',
            ),
          );
        } catch (e) {
          _recordError('Erro ao reverter pagamento do orcamento: $e');
          rethrow;
        }
      }
    }

    try {
      await _db.deleteTransacao(id);
      _transacoes.removeWhere((t) => t.id == id);
      notifyListeners();
      unawaited(AppLogger.instance.warning('Transacao removida: $id'));
    } catch (e) {
      _recordError('Erro ao excluir transacao: $e');
      rethrow;
    }
  }

  // ===================== INIT / RELOAD =====================

  Future<void> initApp() async {
    // Catálogo de marca/modelo agora é carregado por conta em
    // _reloadForActiveUser (ver Parte 2), não há mais estado global para
    // inicializar antes do login.
  }

  Future<void> reloadActiveUserData() async {
    await _reloadForActiveUser();
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
        return;
      }

      final clientesDB = await _db.getClientes();
      final veiculosDB = await _db.getVeiculos();
      final orcamentosDB = await _db.getOrcamentos();
      final transacoesDB = await _db.getTransacoes();
      final catalogo = await _fetchVehicleCatalogFromDb();

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
      _customMarcas
        ..clear()
        ..addAll(catalogo.marcas);
      _customModelosPorMarca
        ..clear()
        ..addAll(catalogo.modelosPorMarca);
    } catch (e) {
      debugPrint('Erro ao recarregar dados do AppProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _recordError(String message) {
    _lastErrorMessage = message;
    debugPrint(message);
    unawaited(AppLogger.instance.error(message));
  }

  void _validateCliente(Cliente cliente) {
    if (cliente.nome.trim().isEmpty) {
      throw StateError('Informe o nome do cliente.');
    }
    if (cliente.telefone.trim().isEmpty) {
      throw StateError('Informe o telefone do cliente.');
    }
  }

  void _validateVeiculo(Veiculo veiculo) {
    if (veiculo.clienteId.trim().isEmpty || veiculo.clienteId == '__pending__') {
      throw StateError('Associe o veiculo a um cliente valido.');
    }
    if (veiculo.marca.trim().isEmpty || veiculo.modelo.trim().isEmpty) {
      throw StateError('Informe marca e modelo do veiculo.');
    }
    if (veiculo.placa.trim().isEmpty) {
      throw StateError('Informe a placa do veiculo.');
    }
  }

  void _validateOrcamento(Orcamento orcamento) {
    if (orcamento.clienteId.trim().isEmpty) {
      throw StateError('O orcamento precisa de um cliente valido.');
    }
    if (orcamento.veiculoId.trim().isEmpty) {
      throw StateError('O orcamento precisa de um veiculo valido.');
    }
    if (orcamento.itens.isEmpty) {
      throw StateError('Adicione pelo menos um item ao orcamento.');
    }
    if (orcamento.valorTotal <= 0) {
      throw StateError('O valor total do orcamento deve ser maior que zero.');
    }
  }

  void _validateTransacao(Transacao transacao) {
    if (transacao.descricao.trim().isEmpty) {
      throw StateError('Informe a descricao da transacao.');
    }
    if (transacao.categoria.trim().isEmpty) {
      throw StateError('Informe a categoria da transacao.');
    }
    if (transacao.valor <= 0) {
      throw StateError('O valor da transacao deve ser maior que zero.');
    }
  }
}
