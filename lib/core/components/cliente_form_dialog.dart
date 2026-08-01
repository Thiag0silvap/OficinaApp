import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/cliente.dart';
import '../../models/veiculo.dart';
import '../../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/cnpj_input_formatter.dart';
import '../utils/phone_input_formatter.dart';
import 'form_styles.dart';
import 'responsive_components.dart';
import 'veiculo_form_fields.dart';

class ClienteFormDialog extends StatefulWidget {
  final Cliente? clienteEditar;

  const ClienteFormDialog({super.key, this.clienteEditar});

  @override
  State<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _observacoesController;
  late final TextEditingController _nomeSeguradoraController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _contatoController;

  final _nomeSeguradoraFocus = FocusNode();
  final _cnpjFocus = FocusNode();
  final _contatoFocus = FocusNode();
  final _nomeFocus = FocusNode();
  final _telefoneFocus = FocusNode();
  final _enderecoFocus = FocusNode();

  late TipoCliente _tipoSelecionado;
  bool _isSaving = false;

  // Estado exclusivo do fluxo de criação (passo do primeiro veículo).
  int _currentStep = 0;
  bool _showClientStepErrors = false;
  bool _showVehicleStepErrors = false;
  bool _showVehicleStepAlert = false;

  final _veiculoFormController = VeiculoFormController();

  Veiculo? _veiculoPreparado;

  bool get _isEdit => widget.clienteEditar != null;

  @override
  void initState() {
    super.initState();
    _veiculoFormController.addListener(_onVeiculoFormChanged);
    final cliente = widget.clienteEditar;
    _nomeController = TextEditingController(text: cliente?.nome ?? '');
    _telefoneController = TextEditingController(text: cliente?.telefone ?? '');
    _enderecoController =
        TextEditingController(text: cliente?.endereco ?? '');
    _observacoesController =
        TextEditingController(text: cliente?.observacoes ?? '');
    _nomeSeguradoraController =
        TextEditingController(text: cliente?.nomeSeguradora ?? '');
    _cnpjController = TextEditingController(text: cliente?.cnpj ?? '');
    _contatoController = TextEditingController(text: cliente?.contato ?? '');
    _tipoSelecionado = cliente?.tipo ?? TipoCliente.particular;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _observacoesController.dispose();
    _nomeSeguradoraController.dispose();
    _cnpjController.dispose();
    _contatoController.dispose();
    _nomeSeguradoraFocus.dispose();
    _cnpjFocus.dispose();
    _contatoFocus.dispose();
    _nomeFocus.dispose();
    _telefoneFocus.dispose();
    _enderecoFocus.dispose();
    _veiculoFormController.removeListener(_onVeiculoFormChanged);
    _veiculoFormController.dispose();
    super.dispose();
  }

  /// Um veículo já "preparado" deixa de ser válido se marca/modelo mudarem
  /// de novo (o controller só notifica nesses casos — ver setMarca/setModelo
  /// /reset em VeiculoFormController).
  void _onVeiculoFormChanged() {
    if (_veiculoPreparado != null && mounted) {
      setState(() => _veiculoPreparado = null);
    }
  }

  bool _validarPrimeiroVeiculo() {
    setState(() => _showVehicleStepErrors = true);
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _prepararPrimeiroVeiculo() async {
    if (!_validarPrimeiroVeiculo()) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final veiculo = _veiculoFormController.buildVeiculo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clienteId: '__pending__',
    );

    await provider.addMarcaModeloCustom(
      marca: _veiculoFormController.marcaFinal,
      modelo: _veiculoFormController.modeloFinal,
    );

    if (!mounted) return;
    setState(() {
      _veiculoPreparado = veiculo;
      _showVehicleStepAlert = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Primeiro veículo preparado com sucesso!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  bool _validarDadosCliente() {
    setState(() => _showClientStepErrors = true);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) return true;

    if (_tipoSelecionado == TipoCliente.seguradora &&
        _nomeSeguradoraController.text.trim().isEmpty) {
      _nomeSeguradoraFocus.requestFocus();
    } else if (_nomeController.text.trim().isEmpty) {
      _nomeFocus.requestFocus();
    } else if (_telefoneController.text.trim().isEmpty) {
      _telefoneFocus.requestFocus();
    }

    return false;
  }

  void _avancarPasso() {
    if (!_validarDadosCliente()) return;
    setState(() {
      _currentStep = 1;
      _showVehicleStepErrors = false;
      _showVehicleStepAlert = false;
    });
  }

  void _voltarPasso() {
    setState(() => _currentStep = 0);
  }

  Future<void> _submitAdd() async {
    if (_isSaving) return;
    if (!_validarDadosCliente()) {
      setState(() => _currentStep = 0);
      return;
    }

    if (_veiculoPreparado == null) {
      setState(() {
        _currentStep = 1;
        _showVehicleStepAlert = true;
      });
      return;
    }

    setState(() => _isSaving = true);

    final clienteId = DateTime.now().millisecondsSinceEpoch.toString();

    final cliente = Cliente(
      id: clienteId,
      nome: _nomeController.text.trim(),
      telefone: _telefoneController.text.trim(),
      endereco: _enderecoController.text.trim().isEmpty
          ? null
          : _enderecoController.text.trim(),
      dataCadastro: DateTime.now(),
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      tipo: _tipoSelecionado,
      nomeSeguradora: _tipoSelecionado == TipoCliente.seguradora &&
              _nomeSeguradoraController.text.trim().isNotEmpty
          ? _nomeSeguradoraController.text.trim()
          : null,
      cnpj: _tipoSelecionado == TipoCliente.seguradora &&
              _cnpjController.text.trim().isNotEmpty
          ? _cnpjController.text.trim()
          : null,
      contato: _tipoSelecionado == TipoCliente.seguradora &&
              _contatoController.text.trim().isNotEmpty
          ? _contatoController.text.trim()
          : null,
    );

    final veiculoFinal = _veiculoPreparado!.copyWith(clienteId: clienteId);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.addCliente(cliente);
      await provider.addVeiculo(veiculoFinal);

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cliente e primeiro veículo salvos com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao adicionar cliente: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitEdit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = widget.clienteEditar!.copyWith(
      nome: _nomeController.text,
      telefone: _telefoneController.text,
      endereco:
          _enderecoController.text.isEmpty ? null : _enderecoController.text,
      observacoes: _observacoesController.text.isEmpty
          ? null
          : _observacoesController.text,
      tipo: _tipoSelecionado,
      nomeSeguradora: _tipoSelecionado == TipoCliente.seguradora &&
              _nomeSeguradoraController.text.isNotEmpty
          ? _nomeSeguradoraController.text
          : null,
      cnpj: _tipoSelecionado == TipoCliente.seguradora &&
              _cnpjController.text.isNotEmpty
          ? _cnpjController.text
          : null,
      contato: _tipoSelecionado == TipoCliente.seguradora &&
              _contatoController.text.isNotEmpty
          ? _contatoController.text
          : null,
    );

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await Provider.of<AppProvider>(context, listen: false)
          .updateCliente(updated);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cliente atualizado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao atualizar cliente: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _isLastStep => _isEdit || _currentStep == 1;

  void _handlePrimaryAction() {
    if (_isSaving) return;
    if (_isEdit) {
      _submitEdit();
    } else if (_currentStep == 0) {
      _avancarPasso();
    } else {
      _submitAdd();
    }
  }

  Widget _buildStepChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStepChip(
          icon: Icons.person_outline,
          label: _currentStep == 0 ? '1. Dados do cliente' : '1. Cliente',
        ),
        _buildStepChip(
          icon: Icons.directions_car_outlined,
          label: _currentStep == 1 ? '2. Primeiro veículo' : '2. Veículo',
        ),
      ],
    );
  }

  Widget _buildClientFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<TipoCliente>(
          initialValue: _tipoSelecionado,
          decoration: formFieldDecoration(
            label: 'Tipo de Cliente *',
            prefixIcon: Icons.category,
          ),
          items: TipoCliente.values
              .map(
                (tipo) => DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo.displayName),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _tipoSelecionado = value!;
            if (_tipoSelecionado == TipoCliente.seguradora) {
              _nomeSeguradoraFocus.requestFocus();
            } else {
              _nomeFocus.requestFocus();
            }
          }),
        ),
        const SizedBox(height: 16),
        if (_tipoSelecionado == TipoCliente.seguradora) ...[
          TextFormField(
            controller: _nomeSeguradoraController,
            focusNode: _nomeSeguradoraFocus,
            autofocus: true,
            style: const TextStyle(color: AppColors.white),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _cnpjFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'Nome da Seguradora *',
              prefixIcon: Icons.business,
            ),
            validator: (value) {
              if (_tipoSelecionado == TipoCliente.seguradora &&
                  (value == null || value.trim().isEmpty)) {
                return 'Nome da seguradora é obrigatório';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cnpjController,
            focusNode: _cnpjFocus,
            style: const TextStyle(color: AppColors.white),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _contatoFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'CNPJ da Seguradora',
              prefixIcon: Icons.numbers,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CnpjInputFormatter(),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contatoController,
            focusNode: _contatoFocus,
            style: const TextStyle(color: AppColors.white),
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _nomeFocus.requestFocus(),
            decoration: formFieldDecoration(
              label: 'Pessoa de Contato',
              prefixIcon: Icons.contact_phone,
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _nomeController,
          focusNode: _nomeFocus,
          autofocus: _tipoSelecionado != TipoCliente.seguradora,
          style: const TextStyle(color: AppColors.white),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _telefoneFocus.requestFocus(),
          decoration: formFieldDecoration(
            label: 'Nome *',
            prefixIcon: Icons.person,
          ),
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? 'Nome é obrigatório' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telefoneController,
          focusNode: _telefoneFocus,
          style: const TextStyle(color: AppColors.white),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _enderecoFocus.requestFocus(),
          decoration: formFieldDecoration(
            label: 'Telefone *',
            prefixIcon: Icons.phone,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          validator: (value) => (value?.trim().isEmpty ?? true)
              ? 'Telefone é obrigatório'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _enderecoController,
          focusNode: _enderecoFocus,
          style: const TextStyle(color: AppColors.white),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: formFieldDecoration(
            label: 'Endereço',
            prefixIcon: Icons.location_on,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _observacoesController,
          style: const TextStyle(color: AppColors.white),
          decoration: formFieldDecoration(
            label: 'Observações',
            prefixIcon: Icons.note,
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildVehicleFields() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showVehicleStepAlert && _veiculoPreparado == null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.28),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adicione pelo menos um veículo para concluir o cadastro do cliente.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppColors.primaryYellow),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Primeiro veículo do cliente',
                  style: TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_veiculoPreparado != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Text(
                    'Veículo adicionado',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Para concluir o primeiro cadastro do cliente, é obrigatório adicionar pelo menos um veículo.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          VeiculoFormFields(controller: _veiculoFormController),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _prepararPrimeiroVeiculo,
                  icon: Icon(
                    _veiculoPreparado == null ? Icons.add : Icons.save,
                  ),
                  label: Text(
                    _veiculoPreparado == null
                        ? 'Adicionar primeiro veículo'
                        : 'Atualizar veículo',
                  ),
                ),
              ),
              if (_veiculoPreparado != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          _veiculoFormController.reset();
                          setState(() => _showVehicleStepAlert = false);
                        },
                  child: const Text('Limpar'),
                ),
              ],
            ],
          ),
          if (_veiculoPreparado != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo do primeiro veículo',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _veiculoPreparado!.descricaoCompleta,
                    style: const TextStyle(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    if (_isEdit) return _buildClientFields();
    return _currentStep == 0 ? _buildClientFields() : _buildVehicleFields();
  }

  AutovalidateMode get _autovalidateMode {
    if (_isEdit) return AutovalidateMode.disabled;
    return _currentStep == 0
        ? (_showClientStepErrors
            ? AutovalidateMode.always
            : AutovalidateMode.disabled)
        : (_showVehicleStepErrors
            ? AutovalidateMode.always
            : AutovalidateMode.disabled);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isEdit = _isEdit;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEdit ? 'Editar Cliente' : 'Novo Cliente',
            style: const TextStyle(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _handlePrimaryAction,
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryYellow,
                      ),
                    )
                  : Text(
                      _isLastStep ? 'Salvar' : 'Próximo',
                      style: const TextStyle(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            children: [
              if (!isEdit)
                Container(
                  color: AppColors.secondaryGray,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _buildStepperHeader(),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStepContent(),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    if (!isEdit && _currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _voltarPasso,
                          child: const Text('← Voltar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handlePrimaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _isLastStep ? 'Salvar' : 'Próximo →',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop: dialog original
    final dialog = ResponsiveDialog(
      title: isEdit ? 'Editar Cliente' : 'Novo Cliente',
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isEdit ? 600 : 700),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEdit) ...[
                  _buildStepperHeader(),
                  const SizedBox(height: 18),
                ],
                _buildCurrentStepContent(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (!isEdit && _currentStep > 0)
          OutlinedButton(
            onPressed: _isSaving ? null : _voltarPasso,
            child: const Text('Voltar'),
          ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handlePrimaryAction,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLastStep ? 'Salvar' : 'Próximo'),
        ),
      ],
    );

    return Focus(autofocus: false, child: dialog);
  }
}
