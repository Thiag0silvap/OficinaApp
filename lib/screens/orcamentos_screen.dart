import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/orcamento_form_dialog.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../models/orcamento.dart';
import '../services/pdf_service.dart';
import '../core/widgets/pdf_preview_dialog.dart';
import 'order_detail_screen.dart';

/// Patch 5 – Orçamentos Premium (Desktop-first)
/// - Tabs com fundo e Material (corrige "No Material widget found")
/// - Toolbar com Busca + Ordenação + Contador
/// - Cards mais "executivos" (status pill + ações compactas)
class OrcamentosScreen extends StatefulWidget {
  const OrcamentosScreen({super.key});

  @override
  State<OrcamentosScreen> createState() => _OrcamentosScreenState();
}

enum _OrcSort { recent, valorDesc, valorAsc, nomeAZ }

class _OrcamentosScreenState extends State<OrcamentosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  _OrcSort _sort = _OrcSort.recent;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateOrcamentoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OrcamentoFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderWithAction(
                title: 'Orçamentos',
                onAdd: () => _showCreateOrcamentoDialog(context),
                addLabelLong: 'Novo Orçamento',
                addLabelShort: 'Novo',
              ),
              SizedBox(height: ResponsiveUtils.getCardSpacing(context)),

              // Toolbar
              _OrcToolbar(
                controller: _searchCtrl,
                sort: _sort,
                totalCount: provider.orcamentos.length,
                onSortChanged: (v) => setState(() => _sort = v),
                onClearSearch: () {
                  _searchCtrl.clear();
                  setState(() {});
                },
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: ResponsiveUtils.getCardSpacing(context)),

              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      _PremiumTabBar(isDesktop: isDesktop),
                      const SizedBox(height: 14),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosPendentes,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosAprovados,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosEmAndamento,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                            _buildOrcamentosList(
                              context,
                              _applyQueryAndSort(
                                provider.orcamentosConcluidos,
                                query: _searchCtrl.text,
                                sort: _sort,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Orcamento> _applyQueryAndSort(
    List<Orcamento> src, {
    required String query,
    required _OrcSort sort,
  }) {
    final q = query.trim().toLowerCase();
    var list = src;

    if (q.isNotEmpty) {
      list = list.where((o) {
        final a = o.clienteNome.toLowerCase();
        final b = o.veiculoDescricao.toLowerCase();
        final c = o.id.toString();
        return a.contains(q) || b.contains(q) || c.contains(q);
      }).toList();
    } else {
      list = List<Orcamento>.from(list);
    }

    // Ordenação
    switch (sort) {
      case _OrcSort.recent:
        // Sem data? usa id como aproximação de "mais recente".
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      case _OrcSort.valorDesc:
        list.sort((a, b) => b.valorTotal.compareTo(a.valorTotal));
        break;
      case _OrcSort.valorAsc:
        list.sort((a, b) => a.valorTotal.compareTo(b.valorTotal));
        break;
      case _OrcSort.nomeAZ:
        list.sort(
          (a, b) => a.clienteNome.toLowerCase().compareTo(
            b.clienteNome.toLowerCase(),
          ),
        );
        break;
    }

    return list;
  }

  Widget _buildOrcamentosList(
    BuildContext context,
    List<Orcamento> orcamentos,
  ) {
    if (orcamentos.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.description_outlined,
        title: _searchCtrl.text.trim().isEmpty
            ? 'Nenhum orçamento nesta categoria'
            : 'Nenhum resultado para a busca',
        subtitle: _searchCtrl.text.trim().isEmpty
            ? ''
            : 'Tente mudar os filtros ou limpar a pesquisa.',
        actionLabel: _searchCtrl.text.trim().isEmpty
            ? 'Novo Orçamento'
            : 'Limpar pesquisa',
        onAction: () {
          if (_searchCtrl.text.trim().isEmpty) {
            _showCreateOrcamentoDialog(context);
          } else {
            _searchCtrl.clear();
            setState(() {});
          }
        },
      );
    }

    return ListView.separated(
      itemCount: orcamentos.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
      itemBuilder: (context, index) {
        final orcamento = orcamentos[index];
        return _OrcamentoPremiumCard(
          orcamento: orcamento,
          onOpen: () => _openDetails(context, orcamento),
          onEdit: () async {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => OrcamentoFormDialog(orcamentoEditar: orcamento),
            );
          },
        );
      },
    );
  }

  void _openDetails(BuildContext context, Orcamento orcamento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orcamento: orcamento),
      ),
    );
  }
}

class _PremiumTabBar extends StatelessWidget {
  final bool isDesktop;
  const _PremiumTabBar({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    // Importante: TabBar precisa de Material acima.
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.secondaryGray,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: TabBar(
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          isScrollable: !isDesktop,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          // Indicator mais discreto e "premium": underline com espessura.
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: AppColors.primaryYellow.withValues(alpha: 0.95),
              width: 3,
            ),
            insets: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          ),
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Aprovados'),
            Tab(text: 'Em Andamento'),
            Tab(text: 'Concluídos'),
          ],
        ),
      ),
    );
  }
}

class _OrcToolbar extends StatelessWidget {
  final TextEditingController controller;
  final _OrcSort sort;
  final int totalCount;
  final ValueChanged<_OrcSort> onSortChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onChanged;

  const _OrcToolbar({
    required this.controller,
    required this.sort,
    required this.totalCount,
    required this.onSortChanged,
    required this.onClearSearch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Row(
      children: [
        Expanded(
          child: _SearchField(
            controller: controller,
            hint: 'Buscar por cliente, veículo ou ID…',
            onChanged: onChanged,
            onClear: onClearSearch,
          ),
        ),
        const SizedBox(width: 12),

        SizedBox(
          width: isDesktop ? 180 : 160,
          child: _ToolbarSelect<_OrcSort>(
            value: sort,
            items: const {
              _OrcSort.recent: 'Recentes',
              _OrcSort.valorDesc: 'Maior valor',
              _OrcSort.valorAsc: 'Menor valor',
              _OrcSort.nomeAZ: 'Nome A–Z',
            },
            icon: Icons.sort,
            onChanged: onSortChanged,
          ),
        ),
        const SizedBox(width: 12),

        _CountChip(label: '$totalCount orçamentos'),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
                // Remove o visual de "input dentro do input" (herança do tema)
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            IconButton(
              tooltip: 'Limpar',
              onPressed: onClear,
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolbarSelect<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final IconData icon;
  final ValueChanged<T> onChanged;

  const _ToolbarSelect({
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: AppColors.secondaryGray,
          icon: Icon(
            Icons.expand_more,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e.key,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        e.value,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  const _CountChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.secondaryGray,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.95),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrcamentoPremiumCard extends StatelessWidget {
  final Orcamento orcamento;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  const _OrcamentoPremiumCard({
    required this.orcamento,
    required this.onOpen,
    required this.onEdit,
  });

  Color _statusColor(OrcamentoStatus status) {
    switch (status) {
      case OrcamentoStatus.pendente:
        return AppColors.warning;
      case OrcamentoStatus.aprovado:
        return AppColors.info;
      case OrcamentoStatus.emAndamento:
        return AppColors.primaryYellow;
      case OrcamentoStatus.concluido:
        return AppColors.success;
      case OrcamentoStatus.cancelado:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(orcamento.status);

    final subtitle =
        '${orcamento.veiculoDescricao} • ${Formatters.currency(orcamento.valorTotal)}';

    return ResponsiveListCard(
      title: orcamento.clienteNome,
      subtitle: subtitle,
      trailing: _StatusPill(
        text: orcamento.statusDescricao,
        color: statusColor,
        suffixIcon:
            (orcamento.status == OrcamentoStatus.concluido && orcamento.pago)
            ? Icons.verified
            : null,
      ),
      onTap: onOpen,
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final List<Widget> actions = [];

    // Ação principal por status (compacta)
    switch (orcamento.status) {
      case OrcamentoStatus.pendente:
        actions.addAll([
          _ActionPill(
            icon: Icons.edit,
            label: 'Editar',
            tone: _ActionTone.neutral,
            onPressed: onEdit,
          ),
          _ActionPill(
            icon: Icons.check,
            label: 'Aprovar',
            tone: _ActionTone.success,
            onPressed: () async {
              await provider.aprovarOrcamento(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orçamento aprovado!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          _ActionPill(
            icon: Icons.cancel,
            label: 'Cancelar',
            tone: _ActionTone.danger,
            onPressed: () async {
              await provider.cancelarOrcamento(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Orçamento cancelado!'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
          ),
        ]);
        break;

      case OrcamentoStatus.aprovado:
        actions.add(
          _ActionPill(
            icon: Icons.play_arrow,
            label: 'Iniciar',
            tone: _ActionTone.primary,
            onPressed: () async {
              await provider.iniciarServico(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Serviço iniciado!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        );
        break;

      case OrcamentoStatus.emAndamento:
        actions.add(
          _ActionPill(
            icon: Icons.done,
            label: 'Concluir',
            tone: _ActionTone.success,
            onPressed: () async {
              await provider.concluirOrcamento(orcamento.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Serviço concluído! Pagamento pendente.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        );
        break;

      case OrcamentoStatus.concluido:
        if (!orcamento.pago) {
          actions.add(
            _ActionPill(
              icon: Icons.attach_money,
              label: 'Receber',
              tone: _ActionTone.success,
              onPressed: () async {
                await provider.registrarPagamento(orcamento.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pagamento registrado!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          );
        }
        break;

      case OrcamentoStatus.cancelado:
        break;
    }

    // PDF / Imprimir
    actions.addAll([
      _ActionPill(
        icon: Icons.picture_as_pdf,
        label: 'Enviar PDF',
        tone: _ActionTone.primary,
        onPressed: () async {
          try {
            final bytes = await PDFService.generateOrcamentoPdf(orcamento);
            final prefix = orcamento.status == OrcamentoStatus.concluido
                ? 'nota_servico'
                : 'orcamento';
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${prefix}_${orcamento.id}.pdf',
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao gerar/compartilhar PDF: $e')),
            );
          }
        },
      ),
      _ActionPill(
        icon: Icons.print,
        label: 'Imprimir',
        tone: _ActionTone.neutral,
        onPressed: () async {
          final filename = orcamento.status == OrcamentoStatus.concluido
              ? 'nota_servico_${orcamento.id}.pdf'
              : 'orcamento_${orcamento.id}.pdf';
          final title = orcamento.status == OrcamentoStatus.concluido
              ? 'Nota de Serviço'
              : 'Orçamento';
          await showPdfPreviewDialog(
            context,
            title: title,
            fileName: filename,
            buildPdf: (_) => PDFService.generateOrcamentoPdf(orcamento),
          );
        },
      ),
      _ActionPill(
        icon: Icons.delete_outline,
        label: 'Excluir',
        tone: _ActionTone.danger,
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Excluir orçamento?'),
              content: const Text('Esta ação não pode ser desfeita.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          );

          if (!context.mounted) return;

          if (confirmed == true) {
            await provider.deleteOrcamento(orcamento.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Orçamento excluído'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    ]);

    return actions;
  }
}

enum _ActionTone { primary, success, danger, neutral }

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final _ActionTone tone;
  final VoidCallback onPressed;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onPressed,
  });

  Color _fg() {
    switch (tone) {
      case _ActionTone.primary:
        return AppColors.primaryYellow;
      case _ActionTone.success:
        return AppColors.success;
      case _ActionTone.danger:
        return AppColors.error;
      case _ActionTone.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg();

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? suffixIcon;

  const _StatusPill({required this.text, required this.color, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (suffixIcon != null) ...[
            const SizedBox(width: 6),
            Icon(suffixIcon, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}
