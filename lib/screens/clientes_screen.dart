import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/orcamento_form_dialog.dart';
import '../core/components/cliente_form_dialog.dart';
import '../providers/app_provider.dart';
import '../models/cliente.dart';
import '../core/utils/formatters.dart';
import '../core/components/cliente_actions.dart';
import '../core/components/cliente_detail_dialog.dart';

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
            style: AppText.caption.copyWith(color: AppColors.textPrimary),
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
      trailing: buildClienteMenu(context, provider, cliente),
      onTap: () => showDialog(
        context: context,
        builder: (_) => ClienteDetailDialog(cliente: cliente),
      ),
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
  
  void _showCreateOrcamentoDialog(BuildContext context, Cliente cliente) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          OrcamentoFormDialog(clientePreSelecionado: cliente),
    );
  }
}