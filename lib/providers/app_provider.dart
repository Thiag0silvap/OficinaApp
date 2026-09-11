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
import '../services/fipe_service.dart';
import '../models/nota.dart';
import '../models/relatorio_financeiro.dart';
import '../models/user.dart';
import '../core/utils/text_normalize.dart';

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
  final List<String> _customPecas = [];
  final List<String> _customServicos = [];

  // Catálogo FIPE (marca/modelo), cacheado localmente — ver
  // "CATÁLOGO FIPE MARCA/MODELO" mais abaixo.
  static const _fipeCacheTtl = Duration(days: 30);
  List<FipeMarca> _fipeMarcas = [];
  DateTime? _fipeMarcasAtualizadoEm;
  bool _fipeMarcasSincronizando = false;
  final Map<String, List<String>> _fipeModelosPorMarcaCodigo = {};
  final Set<String> _fipeModelosCarregando = {};

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

  // Seam de teste: popula _transacoes em memória, sem banco/rede, pra
  // testar a lógica de agregação (saldo, resumoPorPeriodo, etc.) isolada
  // de I/O. Nunca chamado em código de produção.
  @visibleForTesting
  void debugSetTransacoes(List<Transacao> transacoes) {
    _transacoes
      ..clear()
      ..addAll(transacoes);
  }

  // Seam de teste: popula _veiculos em memória, sem banco/rede, pra
  // testar a validação de duplicidade de placa isolada de I/O. Nunca
  // chamado em código de produção.
  @visibleForTesting
  void debugSetVeiculos(List<Veiculo> veiculos) {
    _veiculos
      ..clear()
      ..addAll(veiculos);
  }

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
    _customPecas.clear();
    _customServicos.clear();
    _fipeMarcas = [];
    _fipeMarcasAtualizadoEm = null;
    _fipeModelosPorMarcaCodigo.clear();
    _fipeModelosCarregando.clear();
    notifyListeners();

    unawaited(_reloadForActiveUser());
  }

  // ===================== CATÁLOGO VEÍCULOS =====================

  // Fonte de marcas: catálogo FIPE em cache, se já sincronizado alguma vez
  // nesta conta; senão a lista fixa (AppConstants.marcas) como último
  // recurso — nunca os dois misturados, pra não ter marca duplicada com
  // grafia diferente entre as duas fontes.
  List<String> get marcasDisponiveis {
    final baseNomes = _fipeMarcas.isNotEmpty
        ? _fipeMarcas.map((m) => m.nome)
        : AppConstants.marcas;
    final merged = <String>{...baseNomes, ..._customMarcas};
    final list = merged.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // Mesmo raciocínio de marcasDisponiveis, mas por marca: se a marca veio da
  // FIPE, busca modelos no cache FIPE daquela marca (por código) e dispara
  // sincronização em background se estiver vazio/desatualizado — sem travar
  // a UI, retorna o que já tiver na hora (cache, ou o fallback fixo da
  // marca, se existir). Se a marca não é uma marca FIPE conhecida (ex: veio
  // só da lista fixa antiga ou é uma marca custom sem equivalente FIPE),
  // usa o fallback fixo direto.
  List<String> modelosDisponiveis(String? marca) {
    if (marca == null || marca.trim().isEmpty) return const [];

    final fipeMarca = _fipeMarcaPorNome(marca);
    List<String> base;
    if (fipeMarca != null) {
      final cache = _fipeModelosPorMarcaCodigo[fipeMarca.codigo];
      base = cache ?? (AppConstants.modelosPorMarca[marca] ?? const <String>[]);
      unawaited(_ensureFipeModelosCarregados(fipeMarca));
    } else {
      base = AppConstants.modelosPorMarca[marca] ?? const <String>[];
    }

    final custom = _customModelosPorMarca[marca] ?? const <String>[];
    final merged = <String>{...base, ...custom};
    final list = merged.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  FipeMarca? _fipeMarcaPorNome(String marca) {
    for (final m in _fipeMarcas) {
      if (m.nome.toLowerCase() == marca.toLowerCase()) return m;
    }
    return null;
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
        await _db.insertMarcaModeloCustom(
          marca: fixedMarca,
          modelo: fixedModelo,
        );
      }
    }

    notifyListeners();
  }

  // ===================== CATÁLOGO PEÇAS/SERVIÇOS =====================

  List<String> get pecasDisponiveis {
    final merged = <String>{...AppConstants.pecas, ..._customPecas};
    final list = merged.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  // 'Outro' é o catch-all do dropdown de Serviço e precisa continuar sendo o
  // último item (é assim que o AppConstants.servicos já está organizado) —
  // por isso ele é excluído do merge/sort e reanexado manualmente no fim.
  List<String> get servicosDisponiveis {
    const outro = 'Outro';
    final base = AppConstants.servicos.where((s) => s != outro);
    final custom = _customServicos.where((s) => s != outro);
    final merged = <String>{...base, ...custom};
    final list = merged.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    list.add(outro);
    return list;
  }

  Future<void> addPecaCustom(String peca) async {
    final fixed = _sentenceCase(peca);
    if (fixed.isEmpty) return;

    await _ensureUserDbSelected();

    final hasBase = AppConstants.pecas.any(
      (p) => p.toLowerCase() == fixed.toLowerCase(),
    );
    final hasCustom = _customPecas.any(
      (p) => p.toLowerCase() == fixed.toLowerCase(),
    );
    if (!hasBase && !hasCustom) {
      _customPecas.add(fixed);
      await _db.insertPecaCustom(fixed);
    }

    notifyListeners();
  }

  Future<void> addServicoCustom(String servico) async {
    final fixed = _sentenceCase(servico);
    if (fixed.isEmpty) return;

    await _ensureUserDbSelected();

    final hasBase = AppConstants.servicos.any(
      (s) => s.toLowerCase() == fixed.toLowerCase(),
    );
    final hasCustom = _customServicos.any(
      (s) => s.toLowerCase() == fixed.toLowerCase(),
    );
    if (!hasBase && !hasCustom) {
      _customServicos.add(fixed);
      await _db.insertServicoCustom(fixed);
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

  // Peças e serviços seguem o padrão de frase (só a primeira letra
  // maiúscula) já usado em AppConstants.pecas/AppConstants.servicos —
  // diferente de _prettyName (Title Case por palavra), que é o padrão certo
  // pra marca/modelo de veículo.
  String _sentenceCase(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  // ===================== CATÁLOGO FIPE MARCA/MODELO =====================
  //
  // marcasDisponiveis/modelosDisponiveis (acima) leem só o estado em
  // memória (_fipeMarcas / _fipeModelosPorMarcaCodigo) — carregado do cache
  // SQLite em _carregarCatalogoFipeDoCache (chamado em _reloadForActiveUser,
  // igual ao catálogo de marca/modelo custom). A sincronização com a API
  // roda sempre em background (nunca bloqueia a UI): dispara quando o cache
  // está vazio ou mais velho que _fipeCacheTtl, atualiza o SQLite e o estado
  // em memória, e chama notifyListeners() quando termina — se a API falhar
  // e já havia cache, o cache velho continua sendo usado; se falhar e nunca
  // houve cache, marcasDisponiveis/modelosDisponiveis caem pro fallback fixo
  // (AppConstants.marcas/modelosPorMarca) automaticamente, sem tratamento
  // especial aqui.

  Future<void> _carregarCatalogoFipeDoCache() async {
    final marcasCache = await _db.getFipeMarcasCache();

    _fipeMarcas = marcasCache
        .map(
          (row) => FipeMarca(
            codigo: row['codigo'] ?? '',
            nome: row['nome'] ?? '',
          ),
        )
        .where((m) => m.codigo.isNotEmpty && m.nome.isNotEmpty)
        .toList();

    _fipeMarcasAtualizadoEm = marcasCache.isNotEmpty
        ? DateTime.tryParse(marcasCache.first['atualizadoEm'] ?? '')
        : null;

    _fipeModelosPorMarcaCodigo.clear();
  }

  bool _fipeDesatualizado(DateTime? atualizadoEm) {
    return atualizadoEm == null ||
        DateTime.now().difference(atualizadoEm) > _fipeCacheTtl;
  }

  void _sincronizarFipeMarcasSeNecessario() {
    if (_fipeMarcasSincronizando) return;
    if (!_fipeDesatualizado(_fipeMarcasAtualizadoEm)) return;

    _fipeMarcasSincronizando = true;
    unawaited(_sincronizarFipeMarcas());
  }

  Future<void> _sincronizarFipeMarcas() async {
    final userIdAtStart = _activeUserId;
    try {
      final marcasApi = await FipeService.getMarcas();
      if (marcasApi == null || marcasApi.isEmpty) return;
      if (_activeUserId != userIdAtStart) return;

      await _db.replaceFipeMarcasCache(
        marcasApi.map((m) => {'codigo': m.codigo, 'nome': m.nome}).toList(),
      );

      if (_activeUserId != userIdAtStart) return;
      _fipeMarcas = marcasApi;
      _fipeMarcasAtualizadoEm = DateTime.now();
      _fipeModelosPorMarcaCodigo.clear();
      notifyListeners();
    } catch (e) {
      unawaited(
        AppLogger.instance.warning('Falha ao sincronizar marcas FIPE: $e'),
      );
    } finally {
      _fipeMarcasSincronizando = false;
    }
  }

  Future<void> _ensureFipeModelosCarregados(FipeMarca marca) async {
    if (_fipeModelosPorMarcaCodigo.containsKey(marca.codigo) &&
        !_fipeDesatualizado(_fipeMarcasAtualizadoEm)) {
      return;
    }
    if (_fipeModelosCarregando.contains(marca.codigo)) return;
    _fipeModelosCarregando.add(marca.codigo);

    final userIdAtStart = _activeUserId;
    try {
      final cache = await _db.getFipeModelosCache(marca.codigo);
      if (_activeUserId != userIdAtStart) return;

      DateTime? atualizadoEm;
      if (cache.isNotEmpty) {
        atualizadoEm = DateTime.tryParse(cache.first['atualizadoEm'] ?? '');
        _fipeModelosPorMarcaCodigo[marca.codigo] = cache
            .map((row) => row['nome'] ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        notifyListeners();
      }

      if (!_fipeDesatualizado(atualizadoEm)) return;

      final modelosApi = await FipeService.getModelos(marca.codigo);
      if (modelosApi == null || modelosApi.isEmpty) return;
      if (_activeUserId != userIdAtStart) return;

      await _db.replaceFipeModelosCache(
        marca.codigo,
        modelosApi.map((m) => {'codigo': m.codigo, 'nome': m.nome}).toList(),
      );

      if (_activeUserId != userIdAtStart) return;
      _fipeModelosPorMarcaCodigo[marca.codigo] =
          modelosApi.map((m) => m.nome).toList();
      notifyListeners();
    } catch (e) {
      unawaited(
        AppLogger.instance.warning(
          'Falha ao sincronizar modelos FIPE (${marca.codigo}): $e',
        ),
      );
    } finally {
      _fipeModelosCarregando.remove(marca.codigo);
    }
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
      debugPrint(
        'Falha ao migrar catálogo legado de veículos (SharedPreferences)',
      );
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

  double get saidasMesAtual {
    final now = DateTime.now();
    return _transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.saida &&
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

  double entradasNoMes(DateTime mes) {
    return _transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.entrada &&
              t.data.month == mes.month &&
              t.data.year == mes.year,
        )
        .fold(0, (sum, t) => sum + t.valor);
  }

  double saidasNoMes(DateTime mes) {
    return _transacoes
        .where(
          (t) =>
              t.tipo == TipoTransacao.saida &&
              t.data.month == mes.month &&
              t.data.year == mes.year,
        )
        .fold(0, (sum, t) => sum + t.valor);
  }

  /// Meses (dia 1) entre [inicio] e [fim], inclusive, um por posição.
  List<DateTime> _mesesEntre(DateTime inicio, DateTime fim) {
    final ini = DateTime(inicio.year, inicio.month, 1);
    final end = DateTime(fim.year, fim.month, 1);
    final meses = <DateTime>[];
    var cursor = ini;
    while (!cursor.isAfter(end)) {
      meses.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return meses;
  }

  /// Um registro por mês no intervalo [inicio, fim] (dia ignorado, só
  /// mês/ano importam), com entradas/saídas exatas daquele mês.
  List<ResumoMensal> resumoPorPeriodo(DateTime inicio, DateTime fim) {
    return _mesesEntre(inicio, fim)
        .map(
          (m) => ResumoMensal(
            mes: m,
            entradas: entradasNoMes(m),
            saidas: saidasNoMes(m),
          ),
        )
        .toList();
  }

  /// Totais de entradas/saídas por categoria dentro do intervalo [inicio,
  /// fim], agrupando categorias que só diferem em acento/maiúscula. O
  /// rótulo de exibição é a grafia mais frequente entre as variações — a
  /// grafia salva em cada transação nunca é alterada, só a exibição
  /// agregada. Ordenado por total (entradas + saídas) decrescente.
  List<ResumoCategoria> resumoPorCategoria(DateTime inicio, DateTime fim) {
    final mesesValidos = _mesesEntre(
      inicio,
      fim,
    ).map((m) => '${m.year}-${m.month}').toSet();

    final entradasPorChave = <String, double>{};
    final saidasPorChave = <String, double>{};
    final grafiasPorChave = <String, Map<String, int>>{};

    for (final t in _transacoes) {
      final chaveMes = '${t.data.year}-${t.data.month}';
      if (!mesesValidos.contains(chaveMes)) continue;

      final categoria = t.categoria.trim();
      if (categoria.isEmpty) continue;
      final chave = normalizeText(categoria);

      if (t.tipo == TipoTransacao.entrada) {
        entradasPorChave[chave] = (entradasPorChave[chave] ?? 0) + t.valor;
      } else {
        saidasPorChave[chave] = (saidasPorChave[chave] ?? 0) + t.valor;
      }

      final grafias = grafiasPorChave.putIfAbsent(chave, () => {});
      grafias[categoria] = (grafias[categoria] ?? 0) + 1;
    }

    final chaves = <String>{...entradasPorChave.keys, ...saidasPorChave.keys};
    final resultado = chaves.map((chave) {
      final grafias = grafiasPorChave[chave]!;
      final rotulo = grafias.entries
          .reduce((a, b) => b.value > a.value ? b : a)
          .key;
      return ResumoCategoria(
        categoria: rotulo,
        entradas: entradasPorChave[chave] ?? 0,
        saidas: saidasPorChave[chave] ?? 0,
      );
    }).toList();

    resultado.sort((a, b) => b.total.compareTo(a.total));
    return resultado;
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

      final veiculosDoCliente = _veiculos
          .where((v) => v.clienteId == id)
          .toList();
      for (final veiculo in veiculosDoCliente) {
        await _db.updateVeiculo(veiculo.copyWith(ativo: false));
      }
      _veiculos.removeWhere((v) => v.clienteId == id);

      notifyListeners();
      unawaited(
        AppLogger.instance.warning('Cliente ocultado (soft delete): $id'),
      );
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
      unawaited(
        AppLogger.instance.info('Veiculo adicionado: ${veiculo.placa}'),
      );
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
      unawaited(
        AppLogger.instance.warning('Veiculo ocultado (soft delete): $id'),
      );
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
      final hasPagamentoVinculado =
          _transacoes.any((t) => t.orcamentoId == id) ||
          (await _db.getTransacaoByOrcamentoId(id)) != null;
      if (hasPagamentoVinculado) {
        throw StateError(
          'Este orçamento tem um pagamento registrado. Exclua a transação financeira correspondente primeiro.',
        );
      }
      await _db.deleteOrcamento(id);
      _orcamentos.removeWhere((o) => o.id == id);
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
      unawaited(
        AppLogger.instance.info('Servico iniciado para orcamento: $id'),
      );
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
        motivoCancelamento: (motivoTrimmed != null && motivoTrimmed.isNotEmpty)
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
    final transacao = _transacoes
        .where((t) => t.id == id)
        .cast<Transacao?>()
        .firstOrNull;
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
    _lastErrorMessage = null;
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
      final pecasCustomDB = await _db.getPecasCustom();
      final servicosCustomDB = await _db.getServicosCustom();

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
      _customPecas
        ..clear()
        ..addAll(pecasCustomDB);
      _customServicos
        ..clear()
        ..addAll(servicosCustomDB);

      await _carregarCatalogoFipeDoCache();
      if (_activeUserId != userIdAtStart) return;
      _sincronizarFipeMarcasSeNecessario();
    } catch (e) {
      _recordError('Erro ao recarregar dados do AppProvider: $e');
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

    final telefoneDigits = _onlyDigits(cliente.telefone);
    final cnpjDigits = _onlyDigits(cliente.cnpj ?? '');

    // Compara só contra clientes ativos (o próprio _clientes já é só
    // ativos) e ignora o registro sendo editado, senão editar um cliente
    // sem mudar telefone/CNPJ sempre bateria como duplicado dele mesmo.
    for (final outro in _clientes) {
      if (outro.id == cliente.id) continue;
      if (_onlyDigits(outro.telefone) == telefoneDigits) {
        throw StateError(
          'Já existe um cliente cadastrado com esse telefone: ${outro.nome}.',
        );
      }
      if (cnpjDigits.isNotEmpty && _onlyDigits(outro.cnpj ?? '') == cnpjDigits) {
        throw StateError(
          'Já existe um cliente cadastrado com esse CNPJ: ${outro.nome}.',
        );
      }
    }
  }

  String _onlyDigits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  String _normalizePlaca(String p) =>
      normalizeText(p).replaceAll(RegExp(r'[^a-z0-9]'), '');

  void _validateVeiculo(Veiculo veiculo) {
    if (veiculo.clienteId.trim().isEmpty ||
        veiculo.clienteId == '__pending__') {
      throw StateError('Associe o veiculo a um cliente valido.');
    }
    if (veiculo.marca.trim().isEmpty || veiculo.modelo.trim().isEmpty) {
      throw StateError('Informe marca e modelo do veiculo.');
    }
    if (veiculo.placa.trim().isEmpty) {
      throw StateError('Informe a placa do veiculo.');
    }

    // Compara só contra veículos ativos (o próprio _veiculos já é só
    // ativos — getVeiculos() filtra no banco) e ignora o registro sendo
    // editado, senão editar um veículo sem mudar a placa sempre bateria
    // como duplicado dele mesmo.
    final placaNormalizada = _normalizePlaca(veiculo.placa);
    for (final outro in _veiculos) {
      if (outro.id == veiculo.id) continue;
      if (_normalizePlaca(outro.placa) == placaNormalizada) {
        throw StateError(
          'Já existe um veículo ativo cadastrado com esta placa: ${outro.placa}.',
        );
      }
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
