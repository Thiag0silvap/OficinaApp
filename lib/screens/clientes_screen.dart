import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/form_styles.dart';
import '../core/components/orcamento_form_dialog.dart';
import '../core/components/cliente_form_dialog.dart';
import '../providers/app_provider.dart';
import '../models/cliente.dart';
import '../models/veiculo.dart';
import '../core/utils/formatters.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

enum _SortClientes { nomeAsc, recentes }

class _ClienteInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ClienteInfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _ClientesScreenState extends State<ClientesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  TipoCliente? _tipoFiltro;
  _SortClientes _sort = _SortClientes.nomeAsc;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final filtered = _applyFilters(provider.clientes);

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
              const SizedBox(height: 12),
              _buildToolbar(
                context,
                total: provider.clientes.length,
                showing: filtered.length,
              ),
              SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
              Flexible(
                child: provider.clientes.isEmpty
                    ? _buildEmptyState(context)
                    : (filtered.isEmpty
                          ? _buildNoResults(context)
                          : ResponsiveWidget(
                              mobile: _buildMobileList(
                                context,
                                filtered,
                                provider,
                              ),
                              tablet: _buildTabletGrid(
                                context,
                                filtered,
                                provider,
                              ),
                              desktop: _buildDesktopGrid(
                                context,
                                filtered,
                                provider,
                              ),
                            )),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Cliente> _applyFilters(List<Cliente> src) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = src.where((c) {
      if (_tipoFiltro != null && c.tipo != _tipoFiltro) return false;
      if (q.isEmpty) return true;
      final nome = c.nome.toLowerCase();
      final tel = c.telefone.toLowerCase();
      final seg = (c.nomeSeguradora ?? '').toLowerCase();
      return nome.contains(q) || tel.contains(q) || seg.contains(q);
    }).toList();

    switch (_sort) {
      case _SortClientes.nomeAsc:
        list.sort(
          (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
        );
        break;
      case _SortClientes.recentes:
        list.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
        break;
    }
    return list;
  }

  Widget _buildToolbar(
    BuildContext context, {
    required int total,
    required int showing,
  }) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final isTablet = ResponsiveUtils.isTablet(context);
    final theme = Theme.of(context);

    const double kToolbarHeight = 48;

    final search = SizedBox(
      width: isDesktop ? 420 : double.infinity,
      child: TextField(
        controller: _searchCtrl,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar clientes por nome, telefone ou seguradora…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar',
                  onPressed: () {
                    _searchCtrl.clear();
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );

    final count = SizedBox(
      height: kToolbarHeight,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Text(
          showing == total ? '$total clientes' : '$showing de $total',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // Desktop e tablet: tudo em linha
    if (isDesktop || isTablet) {
      final tipo = DropdownButtonHideUnderline(
        child: DropdownButton<TipoCliente?>(
          value: _tipoFiltro,
          onChanged: (v) => setState(() => _tipoFiltro = v),
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem<TipoCliente?>(value: null, child: Text('Todos')),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.particular,
              child: Text('Particular'),
            ),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.seguradora,
              child: Text('Seguradora'),
            ),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.frota,
              child: Text('Frota'),
            ),
            DropdownMenuItem<TipoCliente?>(
              value: TipoCliente.oficinaParceira,
              child: Text('Oficina parceira'),
            ),
          ],
        ),
      );

      final sort = DropdownButtonHideUnderline(
        child: DropdownButton<_SortClientes>(
          value: _sort,
          onChanged: (v) => setState(() => _sort = v ?? _SortClientes.nomeAsc),
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(value: _SortClientes.nomeAsc, child: Text('A–Z')),
            DropdownMenuItem(
              value: _SortClientes.recentes,
              child: Text('Recentes'),
            ),
          ],
        ),
      );

      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          _toolbarChip(
            context,
            icon: Icons.filter_list,
            child: tipo,
            height: kToolbarHeight,
          ),
          const SizedBox(width: 12),
          _toolbarChip(
            context,
            icon: Icons.sort,
            child: sort,
            height: kToolbarHeight,
          ),
          const SizedBox(width: 12),
          count,
        ],
      );
    }

    // Mobile: busca em cima, filtros embaixo com isExpanded: true
    return Column(
      children: [
        search,
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _toolbarChip(
                context,
                icon: Icons.filter_list,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TipoCliente?>(
                    value: _tipoFiltro,
                    isExpanded: true,
                    onChanged: (v) => setState(() => _tipoFiltro = v),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem<TipoCliente?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.particular,
                        child: Text('Particular'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.seguradora,
                        child: Text('Seguradora'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.frota,
                        child: Text('Frota'),
                      ),
                      DropdownMenuItem<TipoCliente?>(
                        value: TipoCliente.oficinaParceira,
                        child: Text('Oficina parceira'),
                      ),
                    ],
                  ),
                ),
                height: kToolbarHeight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _toolbarChip(
                context,
                icon: Icons.sort,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_SortClientes>(
                    value: _sort,
                    isExpanded: true,
                    onChanged: (v) =>
                        setState(() => _sort = v ?? _SortClientes.nomeAsc),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: _SortClientes.nomeAsc,
                        child: Text('A–Z'),
                      ),
                      DropdownMenuItem(
                        value: _SortClientes.recentes,
                        child: Text('Recentes'),
                      ),
                    ],
                  ),
                ),
                height: kToolbarHeight,
              ),
            ),
            const SizedBox(width: 10),
            count,
          ],
        ),
      ],
    );
  }

  Widget _toolbarChip(
    BuildContext context, {
    required IconData icon,
    required Widget child,
    double height = 48,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      ),
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

  Widget _buildMobileList(
    BuildContext context,
    List<Cliente> clientes,
    AppProvider provider,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: clientes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildTabletGrid(
    BuildContext context,
    List<Cliente> clientes,
    AppProvider provider,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildDesktopGrid(
    BuildContext context,
    List<Cliente> clientes,
    AppProvider provider,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(context, cliente, provider);
      },
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Nenhum resultado',
      subtitle: 'Tente ajustar o termo de busca ou remover filtros.',
      actionLabel: 'Limpar filtros',
      onAction: () {
        setState(() {
          _searchCtrl.clear();
          _tipoFiltro = null;
          _sort = _SortClientes.nomeAsc;
        });
      },
    );
  }

  Widget _buildClienteCard(
    BuildContext context,
    Cliente cliente,
    AppProvider provider,
  ) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final veiculos = provider.getVeiculosByCliente(cliente.id);
    final orcamentos = provider.getOrcamentosByCliente(cliente.id);
    final ultimoOrcamento = orcamentos.isEmpty
        ? null
        : (List.of(orcamentos)
              ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao)))
            .first;

    return ResponsiveListCard(
      title: cliente.nome,
      subtitle:
          '${cliente.telefone}${cliente.nomeSeguradora != null ? ' • ${cliente.nomeSeguradora}' : ''}',
      leading: CircleAvatar(
        backgroundColor: _getTipoClienteColor(cliente.tipo),
        radius: isMobile ? 20 : 24,
        child: Text(
          cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 18,
          ),
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
        color: AppColors.secondaryGray,
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
          const PopupMenuItem(
            value: 'orcamento',
            child: Row(children: [
              Icon(Icons.description, size: 20),
              SizedBox(width: 8),
              Text('Novo Orçamento'),
            ]),
          ),
          const PopupMenuItem(
            value: 'veiculo',
            child: Row(children: [
              Icon(Icons.directions_car, size: 20),
              SizedBox(width: 8),
              Text('Add Veículo'),
            ]),
          ),
          const PopupMenuItem(
            value: 'editar',
            child: Row(children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Editar'),
            ]),
          ),
          PopupMenuItem(
            value: 'excluir',
            child: Row(children: [
              Icon(Icons.delete, size: 20, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Excluir', style: TextStyle(color: AppColors.error)),
            ]),
          ),
        ],
      ),
      onTap: () => _showClienteDetails(context, cliente, provider),
      actions: isMobile
          ? [
              _ClienteInfoChip(
                icon: Icons.directions_car_outlined,
                label:
                    '${veiculos.length} veículo${veiculos.length == 1 ? '' : 's'}',
              ),
              _ClienteInfoChip(
                icon: Icons.description_outlined,
                label:
                    '${orcamentos.length} orçamento${orcamentos.length == 1 ? '' : 's'}',
              ),
              if (ultimoOrcamento != null)
                _ClienteInfoChip(
                  icon: Icons.schedule,
                  label:
                      'Último ${Formatters.dateShort(ultimoOrcamento.dataCriacao)}',
                ),
            ]
          : [
              _ClienteInfoChip(
                icon: Icons.directions_car_outlined,
                label:
                    '${veiculos.length} veiculo${veiculos.length == 1 ? '' : 's'}',
              ),
              _ClienteInfoChip(
                icon: Icons.description_outlined,
                label:
                    '${orcamentos.length} orcamento${orcamentos.length == 1 ? '' : 's'}',
              ),
              if (ultimoOrcamento != null)
                _ClienteInfoChip(
                  icon: Icons.schedule,
                  label:
                      'Ultimo em ${Formatters.dateShort(ultimoOrcamento.dataCriacao)}',
                ),
              FilledButton.tonalIcon(
                onPressed: () => _showCreateOrcamentoDialog(context, cliente),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Orcamento'),
              ),
            ],
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ClienteFormDialog(),
    );
  }

  void _showEditClienteDialog(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      builder: (_) => ClienteFormDialog(clienteEditar: cliente),
    );
  }

  void _showDeleteClienteDialog(
    BuildContext context,
    Cliente cliente,
    AppProvider provider,
  ) {
    final scaffoldContext = context;
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
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
                onPressed: isDeleting
                    ? null
                    : () => Navigator.pop(dialogContext),
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
                              SnackBar(
                                content: Text('Erro ao excluir cliente: $e'),
                              ),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setState(() => isDeleting = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
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

            final provider =
                Provider.of<AppProvider>(scaffoldContext, listen: false);

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
                  const SnackBar(
                      content: Text('Ano inválido. Use apenas números.')),
                );
              }
              if (dialogContext.mounted) setState(() => isSaving = false);
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
              observacoes: observacoesController.text.isEmpty
                  ? null
                  : observacoesController.text,
            );
            try {
              await provider.addMarcaModeloCustom(
                  marca: marcaFinal, modelo: modeloFinal);
              await provider.addVeiculo(veiculo);
              if (dialogContext.mounted &&
                  Navigator.of(dialogContext).canPop()) {
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
              if (dialogContext.mounted) setState(() => isSaving = false);
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
                        decoration: formFieldDecoration(
                          label: 'Marca *',
                          prefixIcon: Icons.directions_car,
                        ),
                        items: [
                          ...Provider.of<AppProvider>(scaffoldContext,
                                  listen: false)
                              .marcasDisponiveis
                              .map<DropdownMenuItem<String>>(
                                (m) =>
                                    DropdownMenuItem<String>(
                                        value: m, child: Text(m)),
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
                          if (v == otherOptionValue &&
                              marcaCustomController.text.trim().isEmpty) {
                            return 'Informe a marca';
                          }
                          return null;
                        },
                      ),
                      if (selectedMarca == otherOptionValue) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: marcaCustomController,
                          decoration: formFieldDecoration(
                            label: 'Digite a marca *',
                            prefixIcon: Icons.edit,
                          ),
                          validator: (v) {
                            if (selectedMarca != otherOptionValue) return null;
                            return (v == null || v.trim().isEmpty)
                                ? 'Marca é obrigatória'
                                : null;
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
                          decoration: formFieldDecoration(
                            label: 'Modelo *',
                            prefixIcon: Icons.drive_eta,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Modelo é obrigatório'
                              : null,
                        )
                      else
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedModelo,
                          decoration: formFieldDecoration(
                            label: 'Modelo *',
                            prefixIcon: Icons.drive_eta,
                          ),
                          items: [
                            ...Provider.of<AppProvider>(scaffoldContext,
                                    listen: false)
                                .modelosDisponiveis(selectedMarca)
                                .map<DropdownMenuItem<String>>(
                                  (m) => DropdownMenuItem<String>(
                                      value: m, child: Text(m)),
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
                            if (selectedMarca == null)
                              return 'Selecione a marca';
                            if (v == null) return 'Modelo é obrigatório';
                            if (v == otherOptionValue &&
                                modeloCustomController.text.trim().isEmpty) {
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
                          decoration: formFieldDecoration(
                            label: 'Digite o modelo *',
                            prefixIcon: Icons.edit,
                          ),
                          validator: (v) {
                            if (selectedModelo != otherOptionValue) return null;
                            return (v == null || v.trim().isEmpty)
                                ? 'Modelo é obrigatório'
                                : null;
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
                        validator: (value) => (value?.isEmpty ?? true)
                            ? 'Cor é obrigatória'
                            : null,
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
                      TextFormField(
                        controller: observacoesController,
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

          return Focus(autofocus: false, child: dialog);
        },
      ),
    ).then((_) {
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
      builder: (context) =>
          OrcamentoFormDialog(clientePreSelecionado: cliente),
    );
  }

  void _showClienteDetails(
    BuildContext context,
    Cliente cliente,
    AppProvider provider,
  ) {
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
                  _buildDetailRow(
                      Icons.location_on, 'Endereço', cliente.endereco!),
                if (cliente.observacoes != null)
                  _buildDetailRow(
                      Icons.note, 'Observações', cliente.observacoes!),
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

        return Focus(autofocus: false, child: dialog);
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
                ResponsiveText(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
                ResponsiveText(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}