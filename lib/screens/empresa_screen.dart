import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/form_styles.dart';
import '../core/utils/phone_input_formatter.dart';
import '../core/utils/cnpj_input_formatter.dart';
import '../models/empresa.dart';
import '../services/db_service.dart';

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  static const String _empresaId = 'empresa_principal';

  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cnpjController = TextEditingController();

  final _nomeFocus = FocusNode();
  final _telefoneFocus = FocusNode();
  final _enderecoFocus = FocusNode();
  final _cnpjFocus = FocusNode();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _carregarEmpresa();
  }

  Future<void> _carregarEmpresa() async {
    try {
      final empresa = await DBService.instance.getEmpresa();
      if (!mounted) return;

      if (empresa != null) {
        _nomeController.text = empresa.nome;
        _telefoneController.text = empresa.telefone;
        _enderecoController.text = empresa.endereco;
        _cnpjController.text = empresa.cnpj ?? '';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados da oficina: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _salvar() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final empresa = Empresa(
        id: _empresaId,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        cnpj: _cnpjController.text.trim().isEmpty
            ? null
            : _cnpjController.text.trim(),
      );

      final empresaExistente = await DBService.instance.getEmpresa();

      if (empresaExistente == null) {
        await DBService.instance.saveEmpresa(empresa);
      } else {
        await DBService.instance.updateEmpresa(empresa);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dados da oficina salvos com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados da oficina: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _cnpjController.dispose();

    _nomeFocus.dispose();
    _telefoneFocus.dispose();
    _enderecoFocus.dispose();
    _cnpjFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados da Oficina'),
        centerTitle: true,
      ),
      body: ResponsiveContainer(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 700 : 520,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Informações da oficina',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.primaryYellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Esses dados serão usados no PDF do orçamento e da nota de serviço.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _nomeController,
                              focusNode: _nomeFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _telefoneFocus.requestFocus(),
                              decoration: formFieldDecoration(
                                label: 'Nome da oficina *',
                                prefixIcon: Icons.business,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome da oficina';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _telefoneController,
                              focusNode: _telefoneFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _enderecoFocus.requestFocus(),
                              decoration: formFieldDecoration(
                                label: 'Telefone *',
                                prefixIcon: Icons.phone,
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [PhoneInputFormatter()],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o telefone';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _enderecoController,
                              focusNode: _enderecoFocus,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _cnpjFocus.requestFocus(),
                              decoration: formFieldDecoration(
                                label: 'Endereço *',
                                prefixIcon: Icons.location_on,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o endereço';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _cnpjController,
                              focusNode: _cnpjFocus,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _salvar(),
                              decoration: formFieldDecoration(
                                label: 'CNPJ',
                                prefixIcon: Icons.badge,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CnpjInputFormatter(),
                              ],
                            ),

                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _saving
                                        ? null
                                        : () {
                                            Navigator.of(context).maybePop();
                                          },
                                    child: const Text('Voltar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _salvar,
                                    child: _saving
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Salvar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}