import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../utils/currency_input_formatter.dart';
import '../../models/cliente.dart';
import '../../models/veiculo.dart';
import '../../models/orcamento.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import 'form_styles.dart';
import 'responsive_components.dart';

class OrcamentoFormDialog extends StatefulWidget {
  final Cliente? clientePreSelecionado;
  final OrcamentoModel? orcamentoEditar;

  const OrcamentoFormDialog({
    super.key,
    this.clientePreSelecionado,
    this.orcamentoEditar,
  });

  @override
  State<OrcamentoFormDialog> createState() => _OrcamentoFormDialogState();
}

class _OrcamentoFormDialogState extends State<OrcamentoFormDialog> {
  static const int _maxObsLen = 300;
  static const int _maxItemDescLen = 200;
  static const double _maxCurrencyValue = 100000000.0;

  final _formKey = GlobalKey<FormState>();
  final _itemFormKey = GlobalKey<FormState>();

  Cliente? _selectedCliente;
  Veiculo? _selectedVeiculo;

  List<ItemOrcamento> _itens = [];
  int? _editingIndex;

  final _descricaoItemController = TextEditingController();
  final _valorItemController = TextEditingController();
  final _servicoManualController = TextEditingController();
  final _pecaController = TextEditingController();

  String? _servicoSelecionado;
  String? _pecaSelecionada;

  final _observacoesController = TextEditingController();
  final _descontoController = TextEditingController();

  bool _aplicarDesconto = false;
  bool _descricaoEditadaManual = false;

  final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

  String _formatValor(double v) => _currencyFmt.format(v);

  double? _parseCurrency(String text) {
    if (text.isEmpty) return null;

    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;

    return double.tryParse(digitsOnly) != null
        ? double.parse(digitsOnly) / 100
        : null;
  }

  bool get _isServicoManual => _servicoSelecionado == 'Outro';

  String _nomeServicoFinal() {
    if (_isServicoManual) {
      return _servicoManualController.text.trim();
    }
    return (_servicoSelecionado ?? '').trim();
  }

  String _normalize(String input) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';

    var out = input;
    for (int i = 0; i < comAcento.length; i++) {
      out = out.replaceAll(comAcento[i], semAcento[i]);
    }
    return out.toLowerCase().trim();
  }

  String _artigoParaPeca(String peca) {
    final p = _normalize(peca);

    // Casos masculinos
    if (p == 'capo' ||
        p == 'teto' ||
        p == 'porta-malas' ||
        p.startsWith('para-choque') ||
        p.startsWith('painel') ||
        p.startsWith('para-brisa') ||
        p.startsWith('para-lama')) {
      return 'no';
    }

    // Casos femininos
    if (p.startsWith('porta dianteira') ||
        p.startsWith('porta traseira') ||
        p == 'porta esquerda' ||
        p == 'porta direita' ||
        p.startsWith('lateral') ||
        p.startsWith('soleira') ||
        p.startsWith('peca') ||
        p.startsWith('moldura') ||
        p.startsWith('grade')) {
      return 'na';
    }

    return 'no';
  }

  String _montarDescricaoSugestao() {
    final servico = _nomeServicoFinal();
    final peca = (_pecaSelecionada ?? '').trim();

    if (servico.isEmpty) return '';
    if (peca.isEmpty) return servico;

    final artigo = _artigoParaPeca(peca);
    return '$servico $artigo ${peca.toLowerCase()}';
  }

  void _atualizarDescricaoSugestao({bool force = false}) {
    final sugestao = _montarDescricaoSugestao();
    if (sugestao.isEmpty) return;

    if (force || !_descricaoEditadaManual) {
      _descricaoItemController.text = sugestao;
    }
  }

  void _onDescontoChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _abrirSeletorPeca() async {
    final selecionada = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final searchController = TextEditingController(text: _pecaSelecionada);
        String filtro = _pecaSelecionada ?? '';

        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            final termos = _normalize(filtro);
            final pecasFiltradas = AppConstants.pecas.where((p) {
              if (termos.isEmpty) return true;
              return _normalize(p).contains(termos);
            }).toList();

            final textoDigitado = filtro.trim();
            final existeIgual = AppConstants.pecas.any(
              (p) => _normalize(p) == _normalize(textoDigitado),
            );

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 460,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecionar peça',
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: formFieldDecoration(
                        label: 'Pesquisar peça',
                        prefixIcon: Icons.search,
                      ).copyWith(
                        suffixIcon: filtro.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setLocalState(() => filtro = '');
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setLocalState(() => filtro = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Column(
                        children: [
                          if (textoDigitado.isNotEmpty && !existeIgual)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primaryYellow.withValues(alpha: 0.30),
                                ),
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.edit,
                                  color: AppColors.primaryYellow,
                                ),
                                title: Text(
                                  'Usar "$textoDigitado"',
                                  style: const TextStyle(
                                    color: AppColors.primaryYellow,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Adicionar peça digitada manualmente',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                onTap: () => Navigator.of(ctx).pop(textoDigitado),
                              ),
                            ),
                          Expanded(
                            child: pecasFiltradas.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Nenhuma peça encontrada',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: pecasFiltradas.length,
                                    separatorBuilder: (_, __) => Divider(
                                      color: AppColors.lightGray.withValues(alpha: 0.18),
                                      height: 1,
                                    ),
                                    itemBuilder: (_, index) {
                                      final peca = pecasFiltradas[index];
                                      final isSelected = peca == _pecaSelecionada;

                                      return ListTile(
                                        dense: true,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        tileColor: isSelected
                                            ? AppColors.primaryYellow.withValues(alpha: 0.10)
                                            : Colors.transparent,
                                        title: Text(
                                          peca,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppColors.primaryYellow
                                                : AppColors.white,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        onTap: () => Navigator.of(ctx).pop(peca),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        if (_pecaSelecionada != null && _pecaSelecionada!.isNotEmpty)
                          OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(''),
                            child: const Text('Limpar peça'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (selecionada == null) return;

    setState(() {
      _pecaSelecionada = selecionada.isEmpty ? null : selecionada;
      _pecaController.text = _pecaSelecionada ?? '';
      _descricaoEditadaManual = false;
      _atualizarDescricaoSugestao(force: true);
    });
  }

  void _limparFormularioItem() {
    _editingIndex = null;
    _servicoSelecionado = null;
    _pecaSelecionada = null;
    _servicoManualController.clear();
    _pecaController.clear();
    _descricaoItemController.clear();
    _valorItemController.clear();
    _descricaoEditadaManual = false;
  }

  @override
  void initState() {
    super.initState();

    _descontoController.addListener(_onDescontoChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);

      if (widget.orcamentoEditar != null) {
        final o = widget.orcamentoEditar!;
        setState(() {
          _itens = List.from(o.itens);
          _observacoesController.text = o.observacoes ?? '';

          final subtotal = _itens.fold<double>(0, (sum, item) => sum + item.valor);
          final desconto = (subtotal - o.valorTotal).clamp(0.0, subtotal);

          if (desconto > 0) {
            _aplicarDesconto = true;
            _descontoController.text = _formatValor(desconto);
          } else {
            _aplicarDesconto = false;
            _descontoController.clear();
          }

          _selectedCliente =
              provider.clientes.where((c) => c.id == o.clienteId).isNotEmpty
                  ? provider.clientes.firstWhere((c) => c.id == o.clienteId)
                  : null;

          if (_selectedCliente != null) {
            final veics = provider.getVeiculosByCliente(_selectedCliente!.id);
            _selectedVeiculo =
                veics.where((v) => v.id == o.veiculoId).isNotEmpty
                    ? veics.firstWhere((v) => v.id == o.veiculoId)
                    : null;
          }
        });
      } else if (widget.clientePreSelecionado != null) {
        setState(() => _selectedCliente = widget.clientePreSelecionado);
      }
    });
  }

  @override
  void dispose() {
    _descontoController.removeListener(_onDescontoChanged);
    _descricaoItemController.dispose();
    _valorItemController.dispose();
    _servicoManualController.dispose();
    _pecaController.dispose();
    _observacoesController.dispose();
    _descontoController.dispose();
    super.dispose();
  }

  double get _valorTotal => _itens.fold(0, (sum, item) => sum + item.valor);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final clientes = provider.clientes;

    final veiculosDisponiveis = _selectedCliente != null
        ? provider.getVeiculosByCliente(_selectedCliente!.id)
        : <Veiculo>[];

    final isEdit = widget.orcamentoEditar != null;
    final isMobile = ResponsiveUtils.isMobile(context);

    final dialog = ResponsiveDialog(
      title: isEdit ? 'Editar Orçamento' : 'Novo Orçamento',
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? MediaQuery.of(context).size.width * 0.95 : 860,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClienteVeiculoSection(
                  context,
                  clientes,
                  veiculosDisponiveis,
                  isEdit,
                  isMobile,
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.lightGray),
                const SizedBox(height: 16),
                _buildAdicionarItemSection(context, isMobile),
                const SizedBox(height: 16),
                _buildItensSection(context),
                const Divider(color: AppColors.lightGray),
                const SizedBox(height: 8),
                _buildDescontoSection(context, isMobile),
                const SizedBox(height: 8),
                _buildTotaisSection(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observacoesController,
                  decoration: formFieldDecoration(
                    label: 'Observações do Orçamento',
                    prefixIcon: Icons.note,
                  ),
                  maxLines: 2,
                  maxLength: _maxObsLen,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.length > _maxObsLen) return 'Observações muito longas';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvarOrcamento,
          child: Text(isEdit ? 'Salvar' : 'Gerar Orçamento'),
        ),
      ],
    );

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter, control: true): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              _salvarOrcamento();
              return null;
            },
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: dialog),
      ),
    );
  }

  Widget _buildClienteVeiculoSection(
    BuildContext context,
    List<Cliente> clientes,
    List<Veiculo> veiculosDisponiveis,
    bool isEdit,
    bool isMobile,
  ) {
    final clienteField = DropdownButtonFormField<Cliente>(
      isExpanded: true,
      initialValue: _selectedCliente,
      decoration: formFieldDecoration(
        label: 'Cliente *',
        prefixIcon: Icons.person,
      ),
      items: clientes
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(
                c.nome,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isEdit
          ? null
          : (value) {
              setState(() {
                _selectedCliente = value;
                _selectedVeiculo = null;
              });
            },
      validator: (v) => v == null ? 'Selecione um cliente' : null,
    );

    final veiculoField = DropdownButtonFormField<Veiculo>(
      isExpanded: true,
      initialValue: _selectedVeiculo,
      decoration: formFieldDecoration(
        label: 'Veículo *',
        prefixIcon: Icons.directions_car,
      ),
      items: veiculosDisponiveis
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(
                v.modelo,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isEdit
          ? null
          : (value) => setState(() => _selectedVeiculo = value),
      validator: (v) => v == null ? 'Selecione um veículo' : null,
      hint: Text(
        _selectedCliente == null ? 'Selecione o cliente' : 'Selecione o veículo',
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          clienteField,
          const SizedBox(height: 12),
          veiculoField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: clienteField),
        const SizedBox(width: 16),
        Expanded(child: veiculoField),
      ],
    );
  }

  Widget _buildAdicionarItemSection(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.lightGray.withValues(alpha: 0.25),
        ),
      ),
      child: Form(
        key: _itemFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingIndex == null ? 'Adicionar item' : 'Editar item',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 14),
            if (isMobile)
              Column(
                children: [
                  _buildServicoField(),
                  const SizedBox(height: 12),
                  _buildValorField(),
                  const SizedBox(height: 12),
                  _buildPecaSelectorField(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildServicoField()),
                  const SizedBox(width: 16),
                  SizedBox(width: 170, child: _buildValorField()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildPecaSelectorField()),
                ],
              ),
            if (_isServicoManual) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _servicoManualController,
                decoration: formFieldDecoration(
                  label: 'Nome do serviço',
                  dense: true,
                ),
                onChanged: (_) {
                  setState(() {
                    _descricaoEditadaManual = false;
                    _atualizarDescricaoSugestao(force: true);
                  });
                },
                validator: (_) {
                  if (_isServicoManual &&
                      _servicoManualController.text.trim().isEmpty) {
                    return 'Informe o nome do serviço';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            if (isMobile)
              Column(
                children: [
                  _buildDescricaoField(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _adicionarItem,
                          icon: Icon(_editingIndex == null ? Icons.add : Icons.save),
                          label: Text(
                            _editingIndex == null ? 'Adicionar item' : 'Salvar item',
                          ),
                        ),
                      ),
                      if (_editingIndex != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(_limparFormularioItem),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ],
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDescricaoField()),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _adicionarItem,
                          icon: Icon(_editingIndex == null ? Icons.add : Icons.save),
                          label: Text(_editingIndex == null ? 'Adicionar' : 'Salvar'),
                        ),
                      ),
                      if (_editingIndex != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => setState(_limparFormularioItem),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicoField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _servicoSelecionado,
      decoration: formFieldDecoration(
        label: 'Serviço *',
        dense: true,
      ),
      items: AppConstants.servicos
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _servicoSelecionado = value;
          _descricaoEditadaManual = false;

          if (value != null &&
              value != 'Outro' &&
              AppConstants.servicosPreco.containsKey(value)) {
            _valorItemController.text = _formatValor(
              AppConstants.servicosPreco[value]!,
            );
          }

          if (value != 'Outro') {
            _servicoManualController.clear();
          }

          _atualizarDescricaoSugestao(force: true);
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione um serviço';
        }
        return null;
      },
    );
  }

  Widget _buildValorField() {
    return TextFormField(
      controller: _valorItemController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyTextInputFormatter()],
      decoration: formFieldDecoration(
        label: 'Valor',
        dense: true,
      ).copyWith(prefixText: 'R\$ '),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Informe o valor';
        }
        final parsed = _parseCurrency(v);
        if (parsed == null || parsed <= 0) {
          return 'Valor inválido';
        }
        if (parsed > _maxCurrencyValue) {
          return 'Valor muito alto';
        }
        return null;
      },
    );
  }

  Widget _buildPecaSelectorField() {
    final hasPeca = _pecaSelecionada != null && _pecaSelecionada!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _abrirSeletorPeca,
          child: InputDecorator(
            decoration: formFieldDecoration(
              label: 'Peça (opcional)',
              dense: true,
              prefixIcon: hasPeca ? Icons.car_repair : Icons.search,
            ).copyWith(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPeca)
                    IconButton(
                      tooltip: 'Limpar peça',
                      onPressed: () {
                        setState(() {
                          _pecaSelecionada = null;
                          _pecaController.clear();
                          _descricaoEditadaManual = false;
                          _atualizarDescricaoSugestao(force: true);
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  IconButton(
                    tooltip: 'Selecionar peça',
                    onPressed: _abrirSeletorPeca,
                    icon: const Icon(Icons.arrow_drop_down),
                  ),
                ],
              ),
            ),
            isEmpty: !hasPeca,
            child: Text(
              hasPeca ? _pecaSelecionada! : 'Clique para selecionar ou pesquisar',
              style: TextStyle(
                color: hasPeca ? AppColors.white : AppColors.textSecondary,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (hasPeca) ...[
          const SizedBox(height: 6),
          Text(
            'Peça selecionada: ${_pecaSelecionada!}',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescricaoField() {
    return TextFormField(
      controller: _descricaoItemController,
      inputFormatters: [
        LengthLimitingTextInputFormatter(_maxItemDescLen),
      ],
      decoration: formFieldDecoration(
        label: 'Descrição do serviço',
        dense: true,
      ),
      onChanged: (_) {
        _descricaoEditadaManual = true;
      },
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'Descrição é obrigatória';
        if (v.length > _maxItemDescLen) {
          return 'Descrição muito longa';
        }
        return null;
      },
    );
  }

  Widget _buildItensSection(BuildContext context) {
    if (_itens.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Nenhum item adicionado',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            (ResponsiveUtils.isMobile(context) ? 0.34 : 0.28),
        minHeight: 90,
        maxWidth: double.infinity,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _itens.length,
        itemBuilder: (context, index) {
          final item = _itens[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.lightGray.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.build_circle_outlined,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.descricao,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.peca != null && item.peca!.isNotEmpty
                            ? 'Serviço: ${item.servico} • Peça: ${item.peca}'
                            : 'Serviço: ${item.servico}',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.70),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currencyFmt.format(item.valor),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: AppColors.primaryYellow,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _editingIndex = index;
                          _descricaoEditadaManual = true;

                          final servicoExisteNaLista =
                              AppConstants.servicos.contains(item.servico);

                          if (servicoExisteNaLista && item.servico != 'Outro') {
                            _servicoSelecionado = item.servico;
                            _servicoManualController.clear();
                          } else {
                            _servicoSelecionado = 'Outro';
                            _servicoManualController.text = item.servico;
                          }

                          _pecaSelecionada = item.peca;
                          _pecaController.text = item.peca ?? '';
                          _descricaoItemController.text = item.descricao;
                          _valorItemController.text = _formatValor(item.valor);
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _itens.removeAt(index);
                          if (_editingIndex == index) {
                            _limparFormularioItem();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescontoSection(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _aplicarDesconto,
                onChanged: (v) => setState(() => _aplicarDesconto = v ?? false),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Aplicar desconto (opcional)',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          if (_aplicarDesconto) const SizedBox(height: 8),
          if (_aplicarDesconto)
            TextFormField(
              controller: _descontoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CurrencyTextInputFormatter()],
              decoration: formFieldDecoration(
                label: 'Desconto (R\$)',
                dense: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final parsed = _parseCurrency(v) ?? 0.0;
                if (parsed < 0) return 'Desconto inválido';
                if (parsed > _maxCurrencyValue) return 'Valor muito alto';
                if (parsed > _valorTotal) return 'Maior que total';
                return null;
              },
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Checkbox(
                value: _aplicarDesconto,
                onChanged: (v) => setState(() => _aplicarDesconto = v ?? false),
              ),
              const SizedBox(width: 6),
              const Text(
                'Aplicar desconto (opcional)',
                style: TextStyle(color: AppColors.white),
              ),
            ],
          ),
        ),
        if (_aplicarDesconto)
          SizedBox(
            width: 170,
            child: TextFormField(
              controller: _descontoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CurrencyTextInputFormatter()],
              decoration: formFieldDecoration(
                label: 'Desconto (R\$)',
                dense: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final parsed = _parseCurrency(v) ?? 0.0;
                if (parsed < 0) return 'Desconto inválido';
                if (parsed > _maxCurrencyValue) return 'Valor muito alto';
                if (parsed > _valorTotal) return 'Maior que total';
                return null;
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTotaisSection() {
    final desconto =
        (_aplicarDesconto && _descontoController.text.trim().isNotEmpty)
            ? (_parseCurrency(_descontoController.text) ?? 0.0)
            : 0.0;

    final totalComDesconto = (_valorTotal - desconto).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Valor Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                _formatValor(_valorTotal),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          if (_aplicarDesconto && desconto > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Desconto:',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '- ${_formatValor(desconto)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total com desconto:',
                  style: TextStyle(
                    color: AppColors.primaryYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatValor(totalComDesconto),
                  style: const TextStyle(
                    color: AppColors.primaryYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _adicionarItem() {
    if (!(_itemFormKey.currentState?.validate() ?? false)) return;

    final valor = _parseCurrency(_valorItemController.text);
    if (valor == null || valor <= 0 || valor > _maxCurrencyValue) return;

    final nomeServico = _nomeServicoFinal();
    if (nomeServico.isEmpty) return;

    final descricao = _descricaoItemController.text.trim();
    if (descricao.isEmpty) return;

    setState(() {
      final novoItem = ItemOrcamento(
        servico: nomeServico,
        peca: (_pecaSelecionada != null && _pecaSelecionada!.trim().isNotEmpty)
            ? _pecaSelecionada!.trim()
            : null,
        descricao: descricao,
        valor: valor,
      );

      if (_editingIndex != null &&
          _editingIndex! >= 0 &&
          _editingIndex! < _itens.length) {
        _itens[_editingIndex!] = novoItem;
      } else {
        _itens.add(novoItem);
      }

      _limparFormularioItem();
    });
  }

  void _salvarOrcamento() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCliente == null || _selectedVeiculo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione cliente e veículo')),
      );
      return;
    }

    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um item ao orçamento'),
        ),
      );
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final id = widget.orcamentoEditar?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final currentObs = _observacoesController.text.trim();
    final responsavel = auth.currentUser?.name;

    final desconto =
        (_aplicarDesconto && _descontoController.text.trim().isNotEmpty)
            ? (_parseCurrency(_descontoController.text) ?? 0.0)
            : 0.0;

    final descontoAplicado = desconto.clamp(0.0, _valorTotal);
    final valorFinal =
        (_valorTotal - descontoAplicado).clamp(0.0, double.infinity);

    String? observacoesFinal;
    {
      final cleanedLines = currentObs
          .split('\n')
          .map((l) => l.trimRight())
          .where((l) => l.trim().isNotEmpty)
          .where((l) => !l.trimLeft().startsWith('Responsável:'))
          .toList();

      if (responsavel != null && responsavel.trim().isNotEmpty) {
        cleanedLines.add('Responsável: ${responsavel.trim()}');
      }

      final joined = cleanedLines.join('\n').trim();
      observacoesFinal = joined.isEmpty ? null : joined;
    }

    final novoOrcamento = OrcamentoModel(
      id: id,
      clienteId: _selectedCliente!.id,
      clienteNome: _selectedCliente!.nomeCompleto,
      veiculoId: _selectedVeiculo!.id,
      veiculoDescricao: _selectedVeiculo!.descricaoCompleta,
      itens: _itens,
      valorTotal: valorFinal,
      status: widget.orcamentoEditar?.status ?? OrcamentoStatus.pendente,
      dataCriacao: widget.orcamentoEditar?.dataCriacao ?? DateTime.now(),
      dataAprovacao: widget.orcamentoEditar?.dataAprovacao,
      dataConclusao: widget.orcamentoEditar?.dataConclusao,
      pago: widget.orcamentoEditar?.pago ?? false,
      dataPagamento: widget.orcamentoEditar?.dataPagamento,
      observacoes: observacoesFinal,
      tipoAtendimento:
          widget.orcamentoEditar?.tipoAtendimento ?? TipoAtendimento.particular,
      dataPrevistaEntrega: widget.orcamentoEditar?.dataPrevistaEntrega,
      observacoesCliente: widget.orcamentoEditar?.observacoesCliente,
      observacoesInternas: widget.orcamentoEditar?.observacoesInternas,
    );

    if (widget.orcamentoEditar != null) {
      appProvider.updateOrcamento(novoOrcamento);
    } else {
      appProvider.addOrcamento(novoOrcamento);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Orçamento salvo com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}