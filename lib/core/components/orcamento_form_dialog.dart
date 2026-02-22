import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/currency_input_formatter.dart';
import 'package:provider/provider.dart';
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
  final _formKey = GlobalKey<FormState>();

  Cliente? _selectedCliente;
  Veiculo? _selectedVeiculo;

  List<ItemOrcamento> _itens = [];
  int? _editingIndex;

  bool _isPecaSelected = false;

  final _descricaoItemController = TextEditingController();
  final _valorItemController = TextEditingController();
  String? _servicoSelecionado;
  String? _pecaSelecionada;

  final _observacoesController = TextEditingController();

  final _descontoController = TextEditingController();
  bool _aplicarDesconto = false;

  void _onDescontoChanged() {
    if (!mounted) return;
    setState(() {});
  }

  final NumberFormat _currencyFmt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );
  String _formatValor(double v) => _currencyFmt.format(v);

  double? _parseCurrency(String text) {
    if (text.isEmpty) return null;
    // remove tudo, exceto números e vírgula
    final cleaned = text.replaceAll(RegExp(r'[^0-9,]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned.replaceAll(',', '.'));
  }

  @override
  void initState() {
    super.initState();

    _descontoController.addListener(_onDescontoChanged);

    // ✅ Preenche dados na edição e resolve cliente/veículo usando provider depois do build
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

    final List<String> itemOptions = _isPecaSelected
        ? AppConstants.pecas
        : AppConstants.servicos;
    final Map<String, String> itemDescriptions = _isPecaSelected
      ? AppConstants.pecasDescricao
      : AppConstants.servicosDescricao;
    final String itemLabel = _isPecaSelected ? 'Peça' : 'Serviço';

    final isEdit = widget.orcamentoEditar != null;

    final dialog = ResponsiveDialog(
      title: isEdit ? 'Editar Orçamento' : 'Novo Orçamento',
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.isMobile(context)
                ? MediaQuery.of(context).size.width * 0.95
                : 800,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveUtils.isMobile(context)
                    ? Column(
                        children: [
                          DropdownButtonFormField<Cliente>(
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
                            validator: (v) =>
                                v == null ? 'Selecione um cliente' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Veiculo>(
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
                                : (value) =>
                                      setState(() => _selectedVeiculo = value),
                            validator: (v) =>
                                v == null ? 'Selecione um veículo' : null,
                            hint: Text(
                              _selectedCliente == null
                                  ? 'Selecione o cliente'
                                  : 'Selecione o veículo',
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Cliente>(
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
                              validator: (v) =>
                                  v == null ? 'Selecione um cliente' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<Veiculo>(
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
                                  : (value) => setState(
                                      () => _selectedVeiculo = value,
                                    ),
                              validator: (v) =>
                                  v == null ? 'Selecione um veículo' : null,
                              hint: Text(
                                _selectedCliente == null
                                    ? 'Selecione o cliente'
                                    : 'Selecione o veículo',
                              ),
                            ),
                          ),
                        ],
                      ),

                const SizedBox(height: 24),
                const Divider(color: AppColors.lightGray),
                const SizedBox(height: 16),

                Text(
                  'Itens do Serviço',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.lightGray.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Tipo:',
                            style: TextStyle(color: AppColors.white),
                          ),
                          const SizedBox(width: 8),
                          ToggleButtons(
                            isSelected: [
                              _isPecaSelected == false,
                              _isPecaSelected == true,
                            ],
                            onPressed: (index) {
                              setState(() {
                                _isPecaSelected = index == 1;
                                _servicoSelecionado = null;
                                _pecaSelecionada = null;
                                _descricaoItemController.clear();
                                _valorItemController.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            selectedColor: AppColors.primaryYellow,
                            fillColor: AppColors.primaryYellow.withValues(alpha: 0.1),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Serviço'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('Peça'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ResponsiveUtils.isMobile(context)
                          ? Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _servicoSelecionado,
                                  decoration: formFieldDecoration(
                                    label: itemLabel,
                                    dense: true,
                                  ),
                                  items: itemOptions
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
                                      if (value != null &&
                                          itemDescriptions.containsKey(value)) {
                                        _descricaoItemController.text =
                                            itemDescriptions[value]!;
                                      }
                                      if (!_isPecaSelected &&
                                          value != null &&
                                          AppConstants.servicosPreco
                                              .containsKey(value)) {
                                        _valorItemController
                                            .text = _formatValor(
                                          AppConstants.servicosPreco[value]!,
                                        );
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),

                                if (!_isPecaSelected)
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _pecaSelecionada,
                                    decoration: formFieldDecoration(
                                      label: 'Peça (opcional)',
                                      dense: true,
                                    ),
                                    items: AppConstants.pecas
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _pecaSelecionada = v),
                                    hint: const Text(
                                      'Selecione uma peça (opcional)',
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                TextFormField(
                                  controller: _valorItemController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    CurrencyTextInputFormatter(),
                                  ],
                                  decoration: formFieldDecoration(
                                    label: 'Valor (R\$)',
                                    dense: true,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return null;
                                    return _parseCurrency(v) == null
                                        ? 'Valor inválido'
                                        : null;
                                  },
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: _servicoSelecionado,
                                    decoration: formFieldDecoration(
                                      label: itemLabel,
                                      dense: true,
                                    ),
                                    items: itemOptions
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
                                        if (value != null &&
                                            itemDescriptions.containsKey(
                                              value,
                                            )) {
                                          _descricaoItemController.text =
                                              itemDescriptions[value]!;
                                        }
                                        if (!_isPecaSelected &&
                                            value != null &&
                                            AppConstants.servicosPreco
                                                .containsKey(value)) {
                                          _valorItemController
                                              .text = _formatValor(
                                            AppConstants.servicosPreco[value]!,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _valorItemController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      CurrencyTextInputFormatter(),
                                    ],
                                    decoration: formFieldDecoration(
                                      label: 'Valor (R\$)',
                                      dense: true,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return null;
                                      return _parseCurrency(v) == null
                                          ? 'Valor inválido'
                                          : null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (!_isPecaSelected)
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _pecaSelecionada,
                                      decoration: formFieldDecoration(
                                        label: 'Peça (opcional)',
                                        dense: true,
                                      ),
                                      items: AppConstants.pecas
                                          .map(
                                            (p) => DropdownMenuItem(
                                              value: p,
                                              child: Text(p),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _pecaSelecionada = v),
                                      hint: const Text('Peça (opcional)'),
                                    ),
                                  ),
                              ],
                            ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _descricaoItemController,
                              decoration: formFieldDecoration(
                                label: 'Detalhes do item',
                                dense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _adicionarItem,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                minimumSize: const Size(44, 48),
                              ),
                              child: Icon(
                                _editingIndex == null ? Icons.add : Icons.save,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_itens.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          (ResponsiveUtils.isMobile(context) ? 0.28 : 0.22),
                      minHeight: 80,
                      maxWidth: double.infinity,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _itens.length,
                      itemBuilder: (context, index) {
                        final item = _itens[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
                          leading: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 20,
                          ),
                          title: Text(
                            item.servico,
                            style: const TextStyle(color: AppColors.white),
                          ),
                          subtitle: Text(
                            item.descricao,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currencyFmt.format(item.valor),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.primaryYellow,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _editingIndex = index;
                                    _servicoSelecionado = item.servico;
                                    _descricaoItemController.text =
                                        item.descricao;
                                    _valorItemController.text = _formatValor(
                                      item.valor,
                                    );

                                    final parts = item.descricao.split(' - ');
                                    if (parts.length > 1 &&
                                        AppConstants.pecas.contains(parts[0])) {
                                      _pecaSelecionada = parts[0];
                                      _descricaoItemController.text = parts
                                          .skip(1)
                                          .join(' - ');
                                    } else {
                                      _pecaSelecionada = null;
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _itens.removeAt(index)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Nenhum item adicionado',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),

                const Divider(color: AppColors.lightGray),

                // Desconto opcional (visual)
                if (ResponsiveUtils.isMobile(context)) ...[
                  Row(
                    children: [
                      Checkbox(
                        value: _aplicarDesconto,
                        onChanged: (v) =>
                            setState(() => _aplicarDesconto = v ?? false),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [CurrencyTextInputFormatter()],
                      decoration: formFieldDecoration(
                        label: 'Desconto (R\$)',
                        dense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final parsed = _parseCurrency(v) ?? 0.0;
                        if (parsed < 0) return 'Desconto inválido';
                        if (parsed > _valorTotal) return 'Maior que total';
                        return null;
                      },
                    ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: _aplicarDesconto,
                              onChanged: (v) =>
                                  setState(() => _aplicarDesconto = v ?? false),
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
                          width: 160,
                          child: TextFormField(
                            controller: _descontoController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [CurrencyTextInputFormatter()],
                            decoration: formFieldDecoration(
                              label: 'Desconto (R\$)',
                              dense: true,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              final parsed = _parseCurrency(v) ?? 0.0;
                              if (parsed < 0) return 'Desconto inválido';
                              if (parsed > _valorTotal) {
                                return 'Maior que total';
                              }
                              return null;
                            },
                          ),
                        ),
                    ],
                  ),
                ],

                Padding(
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
                      if (_aplicarDesconto &&
                          _descontoController.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Builder(
                          builder: (ctx) {
                            final desconto =
                                _parseCurrency(_descontoController.text) ?? 0.0;
                            final totalComDesconto = (_valorTotal - desconto)
                                .clamp(0.0, double.infinity);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _observacoesController,
                  decoration: formFieldDecoration(
                    label: 'Observações do Orçamento',
                    prefixIcon: Icons.note,
                  ),
                  maxLines: 2,
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
        SingleActivator(LogicalKeyboardKey.enter, control: true):
            ActivateIntent(),
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

  void _adicionarItem() {
    if (_servicoSelecionado == null || _valorItemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o serviço e o valor')),
      );
      return;
    }

    // ✅ parse correto (R$ 1.234,56)
    final valor = _parseCurrency(_valorItemController.text);
    if (valor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Valor inválido')));
      return;
    }

    setState(() {
      final descricaoFinal =
          (_pecaSelecionada != null && _pecaSelecionada!.isNotEmpty)
          ? '${_pecaSelecionada!} - ${_descricaoItemController.text}'.trim()
          : _descricaoItemController.text.trim();

      final novoItem = ItemOrcamento(
        servico: _servicoSelecionado!,
        descricao: descricaoFinal,
        valor: valor,
      );

      if (_editingIndex != null &&
          _editingIndex! >= 0 &&
          _editingIndex! < _itens.length) {
        _itens[_editingIndex!] = novoItem;
        _editingIndex = null;
      } else {
        _itens.add(novoItem);
      }

      _valorItemController.clear();
      _descricaoItemController.clear();
      _servicoSelecionado = null;
      _pecaSelecionada = null;
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

    final id =
        widget.orcamentoEditar?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final currentObs = _observacoesController.text.trim();
    final responsavel = auth.currentUser?.name;

    final desconto = (_aplicarDesconto && _descontoController.text.trim().isNotEmpty)
      ? (_parseCurrency(_descontoController.text) ?? 0.0)
      : 0.0;
    final descontoAplicado = desconto.clamp(0.0, _valorTotal);
    final valorFinal = (_valorTotal - descontoAplicado).clamp(0.0, double.infinity);

    String? observacoesFinal;
    {
      // Evita duplicar a linha "Responsável:" a cada edição/salvamento.
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
      // Persistimos o total final (com desconto, se informado)
      valorTotal: valorFinal,
      status: widget.orcamentoEditar?.status ?? OrcamentoStatus.pendente,
      dataCriacao: widget.orcamentoEditar?.dataCriacao ?? DateTime.now(),
      dataAprovacao: widget.orcamentoEditar?.dataAprovacao,
      dataConclusao: widget.orcamentoEditar?.dataConclusao,
      pago: widget.orcamentoEditar?.pago ?? false,
      dataPagamento: widget.orcamentoEditar?.dataPagamento,
      observacoes: observacoesFinal,
      // mantém defaults:
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
