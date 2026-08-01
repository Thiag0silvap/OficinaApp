import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/orcamento_form_dialog.dart';
import '../core/components/cliente_form_dialog.dart';
import '../core/components/veiculo_form_fields.dart';
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
    final veiculosVinculados = provider.getVeiculosByCliente(cliente.id).length;
    final orcamentosVinculados =
        provider.getOrcamentosByCliente(cliente.id).length;
    final isOrcamentoSingular = orcamentosVinculados == 1;
    final artigoOrcamentos = isOrcamentoSingular ? 'O' : 'Os';
    final sufixoOrcamentos = isOrcamentoSingular ? '' : 's';
    final verboContinuar = isOrcamentoSingular ? 'continua' : 'continuam';
    final adjetivoVisivel = isOrcamentoSingular ? 'visível' : 'visíveis';
    bool isDeleting = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: AppColors.secondaryGray,
            title: const Text(
              'Excluir Cliente',
              style: TextStyle(color: AppColors.white),
            ),
            content: Text(
              'Excluir ${cliente.nome} vai ocultar $veiculosVinculados '
              'veículo${veiculosVinculados == 1 ? '' : 's'} da lista ativa. '
              '$artigoOrcamentos $orcamentosVinculados '
              'orçamento$sufixoOrcamentos vinculado$sufixoOrcamentos a ele '
              '$verboContinuar ativo$sufixoOrcamentos e $adjetivoVisivel '
              'normalmente, mesmo sem o cliente aparecer mais na lista.',
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
                                content: Text('Cliente ocultado com sucesso!'),
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
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black,
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Ocultar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddVeiculoDialog(BuildContext context, Cliente cliente) {
    _showVeiculoFormDialog(context, cliente: cliente);
  }

  void _showEditVeiculoDialog(
    BuildContext context,
    Cliente cliente,
    Veiculo veiculo,
  ) {
    _showVeiculoFormDialog(context, cliente: cliente, veiculoEditar: veiculo);
  }

  /// Diálogo compartilhado de cadastro/edição de veículo avulso, construído
  /// em cima de [VeiculoFormFields]/[VeiculoFormController].
  void _showVeiculoFormDialog(
    BuildContext context, {
    required Cliente cliente,
    Veiculo? veiculoEditar,
  }) {
    final scaffoldContext = context;
    final formKey = GlobalKey<FormState>();
    final isEdit = veiculoEditar != null;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final controller = isEdit
        ? VeiculoFormController.fromVeiculo(veiculoEditar, provider)
        : VeiculoFormController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          Future<void> submit() async {
            if (isSaving) return;
            if (!formKey.currentState!.validate()) return;
            setState(() => isSaving = true);

            final providerLocal =
                Provider.of<AppProvider>(scaffoldContext, listen: false);

            final veiculo = controller.buildVeiculo(
              id: veiculoEditar?.id ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              clienteId: cliente.id,
            );

            try {
              await providerLocal.addMarcaModeloCustom(
                marca: controller.marcaFinal,
                modelo: controller.modeloFinal,
              );
              if (isEdit) {
                await providerLocal.updateVeiculo(veiculo);
              } else {
                await providerLocal.addVeiculo(veiculo);
              }
              if (dialogContext.mounted &&
                  Navigator.of(dialogContext).canPop()) {
                Navigator.pop(dialogContext);
              }
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit
                          ? 'Veículo atualizado com sucesso!'
                          : 'Veículo adicionado com sucesso!',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (e) {
              if (scaffoldContext.mounted) {
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(content: Text('Erro ao salvar veículo: $e')),
                );
              }
            } finally {
              if (dialogContext.mounted) setState(() => isSaving = false);
            }
          }

          final dialog = ResponsiveDialog(
            title: isEdit
                ? 'Editar Veículo - ${cliente.nome}'
                : 'Novo Veículo - ${cliente.nome}',
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: formKey,
                  child: VeiculoFormFields(controller: controller),
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
        controller.dispose();
      });
    });
  }

  void _showDeleteVeiculoDialog(
    BuildContext context,
    Veiculo veiculo,
    AppProvider provider,
  ) {
    final scaffoldContext = context;
    final orcamentosVinculados =
        provider.orcamentos.where((o) => o.veiculoId == veiculo.id).length;
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            backgroundColor: AppColors.secondaryGray,
            title: const Text(
              'Excluir Veículo',
              style: TextStyle(color: AppColors.white),
            ),
            content: Text(
              'Excluir ${veiculo.marca} ${veiculo.modelo}, placa ${veiculo.placa} '
              'vai ocultá-lo da lista. $orcamentosVinculados '
              'orçamento${orcamentosVinculados == 1 ? '' : 's'} vinculado'
              '${orcamentosVinculados == 1 ? '' : 's'} a ele serão preservados '
              'no histórico.',
              style: const TextStyle(color: AppColors.white),
            ),
            actions: [
              OutlinedButton(
                onPressed:
                    isDeleting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        try {
                          await provider.deleteVeiculo(veiculo.id);
                          if (dialogContext.mounted &&
                              Navigator.of(dialogContext).canPop()) {
                            Navigator.pop(dialogContext);
                          }
                          if (scaffoldContext.mounted) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text('Veículo ocultado com sucesso!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (scaffoldContext.mounted) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao excluir veículo: $e'),
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
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: Colors.black,
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Ocultar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateOrcamentoDialog(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          OrcamentoFormDialog(clientePreSelecionado: cliente),
    );
  }

  Future<void> _showClienteDetails(
    BuildContext context,
    Cliente cliente,
    AppProvider provider,
  ) async {
    final veiculos = provider.getVeiculosByCliente(cliente.id);
    final orcamentos = provider.getOrcamentosByCliente(cliente.id);
    final notas = await provider.getNotasByCliente(cliente.id);

    if (!context.mounted) return;

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
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: ResponsiveText('• ${v.descricaoCompleta}'),
                          ),
                          IconButton(
                            tooltip: 'Editar veículo',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.edit,
                              size: 18,
                              color: AppColors.primaryYellow,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditVeiculoDialog(context, cliente, v);
                            },
                          ),
                          IconButton(
                            tooltip: 'Excluir veículo',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteVeiculoDialog(context, v, provider);
                            },
                          ),
                        ],
                      ),
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
                const SizedBox(height: 16),
                ResponsiveText(
                  'Histórico de Serviços (${notas.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const SizedBox(height: 8),
                if (notas.isEmpty)
                  const ResponsiveText('Nenhum serviço concluído ainda')
                else
                  ...notas.map(
                    (n) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ResponsiveText(
                        '• ${Formatters.dateShort(n.dataEmissao)} - '
                        '${n.veiculoDescricao ?? '-'} - '
                        '${Formatters.currency(n.valorTotal)}',
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