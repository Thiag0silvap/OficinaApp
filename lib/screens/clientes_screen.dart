import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/form_styles.dart';
import '../core/components/orcamento_form_dialog.dart'; // Importe o novo dialog
import '../providers/app_provider.dart';
import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../core/utils/formatters.dart';
import '../core/utils/phone_input_formatter.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderWithAction(
                title: 'Clientes',
                onAdd: () => _showAddClienteDialog(context),
                addLabelLong: 'Novo Cliente',
                addLabelShort: 'Novo',
              ),
              SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
              Flexible(
                child: provider.clientes.isEmpty
                    ? _buildEmptyState(context)
                    : ResponsiveWidget(
                        mobile: _buildMobileList(context, provider),
                        tablet: _buildTabletGrid(context, provider),
                        desktop: _buildDesktopGrid(context, provider),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      title: 'Nenhum cliente cadastrado',
      subtitle: 'Adicione seu primeiro cliente para começar',
      actionLabel: 'Adicionar Cliente',
      onAction: () => _showAddClienteDialog(context),
    );
  }

  Widget _buildMobileList(BuildContext context, AppProvider provider) {
    return ListView.separated(
      itemCount: provider.clientes.length,
      separatorBuilder: (context, index) => SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
      itemBuilder: (context, index) {
        final cliente = provider.clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildTabletGrid(BuildContext context, AppProvider provider) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.clientes.length,
      itemBuilder: (context, index) {
        final cliente = provider.clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildDesktopGrid(BuildContext context, AppProvider provider) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: provider.clientes.length,
      itemBuilder: (context, index) {
        final cliente = provider.clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildClienteCard(BuildContext context, Cliente cliente, AppProvider provider) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return ResponsiveListCard(
      title: cliente.nome,
      subtitle: '${cliente.telefone}${cliente.nomeSeguradora != null ? ' • ${cliente.nomeSeguradora}' : ''}',
      leading: CircleAvatar(
        backgroundColor: _getTipoClienteColor(cliente.tipo),
        radius: isDesktop ? 24 : 20,
        child: ResponsiveText(
          cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 18 : 16,
          ),
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'editar':
              _showEditClienteDialog(context, cliente);
              break;
            case 'veiculo':
              _showAddVeiculoDialog(context, cliente);
              break;
            case 'orcamento':
              _showCreateOrcamentoDialog(context, cliente);
              break;
            case 'excluir':
              _showDeleteClienteDialog(context, cliente, provider);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'editar', child: Row(children: const [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')])),
          PopupMenuItem(value: 'veiculo', child: Row(children: const [Icon(Icons.directions_car, size: 20), SizedBox(width: 8), Text('Add Veículo')])),
          PopupMenuItem(value: 'orcamento', child: Row(children: const [Icon(Icons.description, size: 20), SizedBox(width: 8), Text('Novo Orçamento')])),
          PopupMenuItem(value: 'excluir', child: Row(children: [Icon(Icons.delete, size: 20, color: AppColors.error), const SizedBox(width: 8), const Text('Excluir', style: TextStyle(color: AppColors.error))])),
        ],
      ),
      onTap: () => _showClienteDetails(context, cliente, provider),
      actions: const <Widget>[],
    );
  }

  Color _getTipoClienteColor(TipoCliente tipo) {
    switch (tipo) {
      case TipoCliente.particular:
        return AppColors.primaryYellow;
      case TipoCliente.seguradora:
        return AppColors.info;
      case TipoCliente.oficinaParceira:
        return AppColors.success;
      case TipoCliente.frota:
        return AppColors.warning;
    }
  }

  void _showAddClienteDialog(BuildContext context) {
    final scaffoldContext = context;
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();
    final enderecoController = TextEditingController();
    final observacoesController = TextEditingController();
    final nomeSeguradoraController = TextEditingController();
    final cnpjController = TextEditingController();
    final contatoController = TextEditingController();

    final nomeSeguradoraFocus = FocusNode();
    final cnpjFocus = FocusNode();
    final contatoFocus = FocusNode();
    final nomeFocus = FocusNode();
    final telefoneFocus = FocusNode();
    final enderecoFocus = FocusNode();

    TipoCliente tipoSelecionado = TipoCliente.particular;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            setState(() => isSaving = true);
            final cliente = Cliente(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              nome: nomeController.text,
              telefone: telefoneController.text,
              endereco: enderecoController.text.isEmpty ? null : enderecoController.text,
              dataCadastro: DateTime.now(),
              observacoes: observacoesController.text.isEmpty
                  ? null
                  : observacoesController.text,
              tipo: tipoSelecionado,
              nomeSeguradora: tipoSelecionado == TipoCliente.seguradora &&
                      nomeSeguradoraController.text.isNotEmpty
                  ? nomeSeguradoraController.text
                  : null,
              cnpj: tipoSelecionado == TipoCliente.seguradora &&
                      cnpjController.text.isNotEmpty
                  ? cnpjController.text
                  : null,
              contato: tipoSelecionado == TipoCliente.seguradora &&
                      contatoController.text.isNotEmpty
                  ? contatoController.text
                  : null,
            );
            try {
              await Provider.of<AppProvider>(scaffoldContext, listen: false)
                  .addCliente(cliente);

              if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                Navigator.pop(dialogContext);
              }

              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente adicionado com sucesso!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar cliente: $e')),
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setState(() => isSaving = false);
              }
            }
          }

          final dialog = ResponsiveDialog(
            title: 'Novo Cliente',
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<TipoCliente>(
                        initialValue: tipoSelecionado,
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
                          tipoSelecionado = value!;
                          if (tipoSelecionado == TipoCliente.seguradora) {
                            nomeSeguradoraFocus.requestFocus();
                          } else {
                            nomeFocus.requestFocus();
                          }
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (tipoSelecionado == TipoCliente.seguradora) ...[
                        TextFormField(
                          controller: nomeSeguradoraController,
                          focusNode: nomeSeguradoraFocus,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => cnpjFocus.requestFocus(),
                          decoration: formFieldDecoration(
                            label: 'Nome da Seguradora *',
                            prefixIcon: Icons.business,
                          ),
                          validator: (value) {
                            if (tipoSelecionado == TipoCliente.seguradora &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Nome da seguradora é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cnpjController,
                          focusNode: cnpjFocus,
                          style: const TextStyle(color: AppColors.white),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => contatoFocus.requestFocus(),
                          decoration: formFieldDecoration(
                            label: 'CNPJ da Seguradora',
                            prefixIcon: Icons.numbers,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: contatoController,
                          focusNode: contatoFocus,
                          style: const TextStyle(color: AppColors.white),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => nomeFocus.requestFocus(),
                          decoration: formFieldDecoration(
                            label: 'Pessoa de Contato',
                            prefixIcon: Icons.contact_phone,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: nomeController,
                        focusNode: nomeFocus,
                        autofocus: tipoSelecionado != TipoCliente.seguradora,
                        style: const TextStyle(color: AppColors.white),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => telefoneFocus.requestFocus(),
                        decoration: formFieldDecoration(
                          label: 'Nome *',
                          prefixIcon: Icons.person,
                        ),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Nome é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: telefoneController,
                        focusNode: telefoneFocus,
                        style: const TextStyle(color: AppColors.white),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => enderecoFocus.requestFocus(),
                        decoration: formFieldDecoration(
                          label: 'Telefone *',
                          prefixIcon: Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Telefone é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: enderecoController,
                        focusNode: enderecoFocus,
                        style: const TextStyle(color: AppColors.white),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(dialogContext).nextFocus(),
                        decoration: formFieldDecoration(
                          label: 'Endereço',
                          prefixIcon: Icons.location_on,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: observacoesController,
                        style: const TextStyle(color: AppColors.white),
                        decoration: formFieldDecoration(
                          label: 'Observações',
                          prefixIcon: Icons.note,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : submit,
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
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
                    submit();
                    return null;
                  },
                ),
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (intent) {
                    if (!isSaving) {
                      Navigator.of(dialogContext).maybePop();
                    }
                    return null;
                  },
                ),
              },
              child: Focus(autofocus: true, child: dialog),
            ),
          );
        },
      ),
    ).then((_) {
      // Evita dispose durante a animação de fechamento do dialog.
      Future.delayed(const Duration(milliseconds: 350), () {
        nomeController.dispose();
        telefoneController.dispose();
        enderecoController.dispose();
        observacoesController.dispose();
        nomeSeguradoraController.dispose();
        cnpjController.dispose();
        contatoController.dispose();

        nomeSeguradoraFocus.dispose();
        cnpjFocus.dispose();
        contatoFocus.dispose();
        nomeFocus.dispose();
        telefoneFocus.dispose();
        enderecoFocus.dispose();
      });
    });
  }

  void _showEditClienteDialog(BuildContext context, Cliente cliente) {
    final scaffoldContext = context;
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: cliente.nome);
    final telefoneController = TextEditingController(text: cliente.telefone);
    final enderecoController = TextEditingController(text: cliente.endereco ?? '');
    final observacoesController = TextEditingController(text: cliente.observacoes ?? '');
    final nomeSeguradoraController = TextEditingController(text: cliente.nomeSeguradora ?? '');
    final cnpjController = TextEditingController(text: cliente.cnpj ?? '');
    final contatoController = TextEditingController(text: cliente.contato ?? '');

    final nomeSeguradoraFocus = FocusNode();
    final cnpjFocus = FocusNode();
    final contatoFocus = FocusNode();
    final nomeFocus = FocusNode();
    final telefoneFocus = FocusNode();
    final enderecoFocus = FocusNode();

    TipoCliente tipoSelecionado = cliente.tipo;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            setState(() => isSaving = true);
            final updated = cliente.copyWith(
              nome: nomeController.text,
              telefone: telefoneController.text,
              endereco: enderecoController.text.isEmpty
                  ? null
                  : enderecoController.text,
              observacoes: observacoesController.text.isEmpty
                  ? null
                  : observacoesController.text,
              tipo: tipoSelecionado,
              nomeSeguradora: tipoSelecionado == TipoCliente.seguradora &&
                      nomeSeguradoraController.text.isNotEmpty
                  ? nomeSeguradoraController.text
                  : null,
              cnpj: tipoSelecionado == TipoCliente.seguradora &&
                      cnpjController.text.isNotEmpty
                  ? cnpjController.text
                  : null,
              contato: tipoSelecionado == TipoCliente.seguradora &&
                      contatoController.text.isNotEmpty
                  ? contatoController.text
                  : null,
            );
            try {
              await Provider.of<AppProvider>(scaffoldContext, listen: false)
                  .updateCliente(updated);

              if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                Navigator.pop(dialogContext);
              }

              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente atualizado com sucesso!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(content: Text('Erro ao atualizar cliente: $e')),
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setState(() => isSaving = false);
              }
            }
          }

          final dialog = ResponsiveDialog(
            title: 'Editar Cliente',
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<TipoCliente>(
                        initialValue: tipoSelecionado,
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
                          tipoSelecionado = value!;
                          if (tipoSelecionado == TipoCliente.seguradora) {
                            nomeSeguradoraFocus.requestFocus();
                          } else {
                            nomeFocus.requestFocus();
                          }
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (tipoSelecionado == TipoCliente.seguradora) ...[
                        TextFormField(
                          controller: nomeSeguradoraController,
                          focusNode: nomeSeguradoraFocus,
                          autofocus: true,
                          style: const TextStyle(color: AppColors.white),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => cnpjFocus.requestFocus(),
                          decoration: formFieldDecoration(
                            label: 'Nome da Seguradora *',
                            prefixIcon: Icons.business,
                          ),
                          validator: (value) {
                            if (tipoSelecionado == TipoCliente.seguradora &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Nome da seguradora é obrigatório';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: cnpjController,
                          focusNode: cnpjFocus,
                          style: const TextStyle(color: AppColors.white),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => contatoFocus.requestFocus(),
                          decoration: formFieldDecoration(
                            label: 'CNPJ da Seguradora',
                            prefixIcon: Icons.numbers,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: contatoController,
                          focusNode: contatoFocus,
                          style: const TextStyle(color: AppColors.white),
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => nomeFocus.requestFocus(),
                          decoration: formFieldDecoration(
                            label: 'Pessoa de Contato',
                            prefixIcon: Icons.contact_phone,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: nomeController,
                        focusNode: nomeFocus,
                        autofocus: tipoSelecionado != TipoCliente.seguradora,
                        style: const TextStyle(color: AppColors.white),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => telefoneFocus.requestFocus(),
                        decoration: formFieldDecoration(
                          label: 'Nome *',
                          prefixIcon: Icons.person,
                        ),
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Nome é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: telefoneController,
                        focusNode: telefoneFocus,
                        style: const TextStyle(color: AppColors.white),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => enderecoFocus.requestFocus(),
                        decoration: formFieldDecoration(
                          label: 'Telefone *',
                          prefixIcon: Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Telefone é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: enderecoController,
                        focusNode: enderecoFocus,
                        style: const TextStyle(color: AppColors.white),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(dialogContext).nextFocus(),
                        decoration: formFieldDecoration(
                          label: 'Endereço',
                          prefixIcon: Icons.location_on,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: observacoesController,
                        style: const TextStyle(color: AppColors.white),
                        decoration: formFieldDecoration(
                          label: 'Observações',
                          prefixIcon: Icons.note,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : submit,
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
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
                    submit();
                    return null;
                  },
                ),
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (intent) {
                    if (!isSaving) {
                      Navigator.of(dialogContext).maybePop();
                    }
                    return null;
                  },
                ),
              },
              child: Focus(autofocus: true, child: dialog),
            ),
          );
        },
      ),
    ).then((_) {
      // Evita dispose durante a animação de fechamento do dialog.
      Future.delayed(const Duration(milliseconds: 350), () {
        nomeController.dispose();
        telefoneController.dispose();
        enderecoController.dispose();
        observacoesController.dispose();
        nomeSeguradoraController.dispose();
        cnpjController.dispose();
        contatoController.dispose();

        nomeSeguradoraFocus.dispose();
        cnpjFocus.dispose();
        contatoFocus.dispose();
        nomeFocus.dispose();
        telefoneFocus.dispose();
        enderecoFocus.dispose();
      });
    });
  }

  void _showDeleteClienteDialog(BuildContext context, Cliente cliente, AppProvider provider) {
    final scaffoldContext = context;
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final dialog = AlertDialog(
            backgroundColor: AppColors.secondaryGray,
            title: const Text(
              'Excluir Cliente',
              style: TextStyle(color: AppColors.error),
            ),
            content: Text(
              'Tem certeza que deseja excluir o cliente ${cliente.nome}? Esta ação não pode ser desfeita.',
              style: const TextStyle(color: AppColors.white),
            ),
            actions: [
              OutlinedButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        try {
                          await provider.deleteCliente(cliente.id);

                          if (dialogContext.mounted &&
                              Navigator.of(dialogContext).canPop()) {
                            Navigator.pop(dialogContext);
                          }

                          if (scaffoldContext.mounted) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text('Cliente excluído com sucesso!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (scaffoldContext.mounted) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(content: Text('Erro ao excluir cliente: $e')),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setState(() => isDeleting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Excluir'),
              ),
            ],
          );

          return Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (intent) {
                    if (!isDeleting) {
                      Navigator.of(dialogContext).maybePop();
                    }
                    return null;
                  },
                ),
              },
              child: Focus(autofocus: true, child: dialog),
            ),
          );
        },
      ),
    );
  }

  void _showAddVeiculoDialog(BuildContext context, Cliente cliente) {
    final scaffoldContext = context;
    final formKey = GlobalKey<FormState>();

    const otherOptionValue = '__other__';

    String? selectedMarca;
    String? selectedModelo;
    final marcaCustomController = TextEditingController();
    final modeloCustomController = TextEditingController();

    final corController = TextEditingController();
    final placaController = TextEditingController();
    final anoController = TextEditingController();
    final observacoesController = TextEditingController();

    final corFocus = FocusNode();
    final placaFocus = FocusNode();
    final anoFocus = FocusNode();

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            setState(() => isSaving = true);

            final provider = Provider.of<AppProvider>(scaffoldContext, listen: false);

            final marcaFinal = (selectedMarca == otherOptionValue)
                ? marcaCustomController.text.trim()
                : (selectedMarca ?? '').trim();
            final modeloFinal = (selectedMarca == otherOptionValue)
                ? modeloCustomController.text.trim()
                : (selectedModelo == otherOptionValue)
                    ? modeloCustomController.text.trim()
                    : (selectedModelo ?? '').trim();

            final anoText = anoController.text.trim();
            final anoValue = anoText.isEmpty ? null : int.tryParse(anoText);
            if (anoText.isNotEmpty && anoValue == null) {
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(content: Text('Ano inválido. Use apenas números.')),
                );
              }
              if (dialogContext.mounted) {
                setState(() => isSaving = false);
              }
              return;
            }

            final veiculo = Veiculo(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              clienteId: cliente.id,
              marca: marcaFinal,
              modelo: modeloFinal,
              cor: corController.text,
              placa: placaController.text,
              ano: anoValue,
              observacoes:
                  observacoesController.text.isEmpty ? null : observacoesController.text,
            );
            try {
              await provider.addMarcaModeloCustom(
                marca: marcaFinal,
                modelo: modeloFinal,
              );
              await provider.addVeiculo(veiculo);

              if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                Navigator.pop(dialogContext);
              }

              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  const SnackBar(
                    content: Text('Veículo adicionado com sucesso!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar veículo: $e')),
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setState(() => isSaving = false);
              }
            }
          }

          final dialog = ResponsiveDialog(
            title: 'Novo Veículo - ${cliente.nome}',
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedMarca,
                      decoration: formFieldDecoration(label: 'Marca *', prefixIcon: Icons.directions_car),
                      items: [
                        ...Provider.of<AppProvider>(scaffoldContext, listen: false)
                            .marcasDisponiveis
                            .map<DropdownMenuItem<String>>(
                              (m) => DropdownMenuItem<String>(value: m, child: Text(m)),
                            ),
                        const DropdownMenuItem<String>(
                          value: otherOptionValue,
                          child: Text('Outra... (digitar)'),
                        ),
                      ],
                      onChanged: (v) => setState(() {
                        selectedMarca = v;
                        selectedModelo = null;
                        if (v != otherOptionValue) {
                          marcaCustomController.clear();
                        }
                        modeloCustomController.clear();
                      }),
                      validator: (v) {
                        if (v == null) return 'Marca é obrigatória';
                        if (v == otherOptionValue && marcaCustomController.text.trim().isEmpty) {
                          return 'Informe a marca';
                        }
                        return null;
                      },
                    ),
                    if (selectedMarca == otherOptionValue) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: marcaCustomController,
                        decoration: formFieldDecoration(label: 'Digite a marca *', prefixIcon: Icons.edit),
                        validator: (v) {
                          if (selectedMarca != otherOptionValue) return null;
                          return (v == null || v.trim().isEmpty) ? 'Marca é obrigatória' : null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    if (selectedMarca == null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selecione a marca primeiro',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    else if (selectedMarca == otherOptionValue)
                      TextFormField(
                        controller: modeloCustomController,
                        decoration: formFieldDecoration(label: 'Modelo *', prefixIcon: Icons.drive_eta),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Modelo é obrigatório' : null,
                      )
                    else
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedModelo,
                        decoration: formFieldDecoration(label: 'Modelo *', prefixIcon: Icons.drive_eta),
                        items: [
                          ...Provider.of<AppProvider>(scaffoldContext, listen: false)
                              .modelosDisponiveis(selectedMarca)
                              .map<DropdownMenuItem<String>>(
                                (m) => DropdownMenuItem<String>(value: m, child: Text(m)),
                              ),
                          const DropdownMenuItem<String>(
                            value: otherOptionValue,
                            child: Text('Outro... (digitar)'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          selectedModelo = v;
                          if (v != otherOptionValue) {
                            modeloCustomController.clear();
                          }
                        }),
                        validator: (v) {
                          if (selectedMarca == null) return 'Selecione a marca';
                          if (v == null) return 'Modelo é obrigatório';
                          if (v == otherOptionValue && modeloCustomController.text.trim().isEmpty) {
                            return 'Informe o modelo';
                          }
                          return null;
                        },
                        hint: const Text('Selecione o modelo'),
                      ),

                    if (selectedMarca != null &&
                        selectedMarca != otherOptionValue &&
                        selectedModelo == otherOptionValue) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: modeloCustomController,
                        decoration: formFieldDecoration(label: 'Digite o modelo *', prefixIcon: Icons.edit),
                        validator: (v) {
                          if (selectedModelo != otherOptionValue) return null;
                          return (v == null || v.trim().isEmpty) ? 'Modelo é obrigatório' : null;
                        },
                      ),
                    ],

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: corController,
                      focusNode: corFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => placaFocus.requestFocus(),
                      decoration: formFieldDecoration(
                        label: 'Cor *',
                        prefixIcon: Icons.color_lens,
                      ),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Cor é obrigatória' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: placaController,
                      focusNode: placaFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => anoFocus.requestFocus(),
                      decoration: formFieldDecoration(
                        label: 'Placa *',
                        prefixIcon: Icons.confirmation_number,
                      ),
                      validator: (value) => (value?.isEmpty ?? true)
                          ? 'Placa é obrigatória'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: anoController,
                      focusNode: anoFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(dialogContext).nextFocus(),
                      decoration: formFieldDecoration(
                        label: 'Ano',
                        prefixIcon: Icons.calendar_today,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: observacoesController, decoration: formFieldDecoration(label: 'Observações', prefixIcon: Icons.note), maxLines: 3),
                  ],
                ),
              ),
            ),
            ),
            actions: [
              OutlinedButton(
                onPressed:
                    isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : submit,
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
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
                    submit();
                    return null;
                  },
                ),
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (intent) {
                    if (!isSaving) {
                      Navigator.of(dialogContext).maybePop();
                    }
                    return null;
                  },
                ),
              },
              child: Focus(autofocus: true, child: dialog),
            ),
          );
        },
      ),
    ).then((_) {
      // Evita dispose durante a animação de fechamento do dialog.
      Future.delayed(const Duration(milliseconds: 350), () {
        marcaCustomController.dispose();
        modeloCustomController.dispose();
        corController.dispose();
        placaController.dispose();
        anoController.dispose();
        observacoesController.dispose();

        corFocus.dispose();
        placaFocus.dispose();
        anoFocus.dispose();
      });
    });
  }

  void _showCreateOrcamentoDialog(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrcamentoFormDialog(clientePreSelecionado: cliente),
    );
  }

  void _showClienteDetails(BuildContext context, Cliente cliente, AppProvider provider) {
    final veiculos = provider.getVeiculosByCliente(cliente.id);
    final orcamentos = provider.getOrcamentosByCliente(cliente.id);

    showDialog(
      context: context,
      builder: (context) {
        final dialog = ResponsiveDialog(
          title: cliente.nome,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(Icons.phone, 'Telefone', cliente.telefone),
                if (cliente.endereco != null)
                  _buildDetailRow(Icons.location_on, 'Endereço', cliente.endereco!),
                if (cliente.observacoes != null)
                  _buildDetailRow(Icons.note, 'Observações', cliente.observacoes!),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                ResponsiveText(
                  'Veículos (${veiculos.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 8),
                if (veiculos.isEmpty)
                  const ResponsiveText('Nenhum veículo cadastrado')
                else
                  ...veiculos.map(
                    (v) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ResponsiveText('• ${v.descricaoCompleta}'),
                    ),
                  ),
                const SizedBox(height: 16),
                ResponsiveText(
                  'Orçamentos (${orcamentos.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 8),
                if (orcamentos.isEmpty)
                  const ResponsiveText('Nenhum orçamento criado')
                else
                  ...orcamentos.map(
                    (o) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ResponsiveText(
                        '• ${o.status} - ${Formatters.currency(o.valorTotal)}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showEditClienteDialog(context, cliente);
              },
              child: const Text('Editar'),
            ),
          ],
        );

        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
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
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryYellow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(label, style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.7))),
                ResponsiveText(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}