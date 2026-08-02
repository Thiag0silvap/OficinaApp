import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/components/responsive_components.dart';
import '../core/components/common_widgets.dart';
import '../core/components/orcamento_form_dialog.dart';
// Sprint 1 — componentes do design system (mobile).
import '../core/components/app_card.dart';
import '../core/components/status_pill.dart';
import '../core/components/app_buttons.dart';
// Sprint 4 — lógica de ação compartilhada com o diálogo de detalhe.
import '../core/components/orcamento_actions.dart';
import '../core/components/orcamento_detail_dialog.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../models/orcamento.dart';

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
    final isMobile = ResponsiveUtils.isMobile(context);

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
              _OrcToolbar(
                isMobile: isMobile,
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
              Expanded(child: _buildBody(context, provider)),
            ],
          ),
        );
      },
    );
  }

  /// Decide entre esqueleto de carregamento, banner de erro ou a lista real
  /// — os 3 estados vêm do estado real do provider (Parte 3).
  Widget _buildBody(BuildContext context, AppProvider provider) {
    if (provider.isLoading) {
      return const _OrcamentosSkeletonList();
    }

    final error = provider.lastErrorMessage;
    if (error != null && error.trim().isNotEmpty) {
      return _OrcamentosErrorState(
        onRetry: () => provider.reloadActiveUserData(),
      );
    }

    return _buildOrcamentosList(
      context,
      _applyQueryAndSort(
        provider.orcamentos,
        query: _searchCtrl.text,
        sort: _sort,
      ),
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

    switch (sort) {
      case _OrcSort.recent:
        // Padrão: o que ainda precisa de ação (pendente/aprovado/em
        // andamento) primeiro, finalizados (concluído/cancelado) depois;
        // dentro de cada grupo, mais recentes primeiro.
        list.sort((a, b) {
          final groupCompare = _openRank(a.status).compareTo(
            _openRank(b.status),
          );
          if (groupCompare != 0) return groupCompare;
          return b.id.compareTo(a.id);
        });
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

  /// 0 para status ainda "abertos" (precisam de ação), 1 para finalizados.
  int _openRank(OrcamentoStatus status) {
    switch (status) {
      case OrcamentoStatus.pendente:
      case OrcamentoStatus.aprovado:
      case OrcamentoStatus.emAndamento:
        return 0;
      case OrcamentoStatus.concluido:
      case OrcamentoStatus.cancelado:
        return 1;
    }
  }

  Widget _buildOrcamentosList(
    BuildContext context,
    List<Orcamento> orcamentos,
  ) {
    if (orcamentos.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.description_outlined,
        title: _searchCtrl.text.trim().isEmpty
            ? 'Nenhum orçamento ainda'
            : 'Nenhum resultado para a busca',
        subtitle: _searchCtrl.text.trim().isEmpty
            ? 'Crie o primeiro orçamento para começar a acompanhar o serviço.'
            : 'Tente mudar os filtros ou limpar a pesquisa.',
        actionLabel: _searchCtrl.text.trim().isEmpty
            ? '+ Novo orçamento'
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

    final isMobile = ResponsiveUtils.isMobile(context);

    return ListView.separated(
      itemCount: orcamentos.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
      itemBuilder: (context, index) {
        final orcamento = orcamentos[index];

        Future<void> onEdit() async {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => OrcamentoFormDialog(orcamentoEditar: orcamento),
          );
        }

        // Mobile e desktop usam o mesmo padrão do design system (Sprint 3),
        // só o layout (empilhado x em linha) muda entre eles.
        if (isMobile) {
          return _OrcamentoMobileCard(
            orcamento: orcamento,
            onOpen: () => _openDetails(context, orcamento),
            onEdit: onEdit,
          );
        }

        return _OrcamentoPremiumCard(
          orcamento: orcamento,
          onOpen: () => _openDetails(context, orcamento),
          onEdit: onEdit,
        );
      },
    );
  }

  void _openDetails(BuildContext context, Orcamento orcamento) {
    showDialog(
      context: context,
      builder: (_) => OrcamentoDetailDialog(orcamento: orcamento),
    );
  }
}

// ===========================================================================
// SPRINT 1 — CARD MOBILE (novo, baseado no design system)
// A lógica de ação primária e do menu de 3 pontos foi extraída para
// core/components/orcamento_actions.dart no Sprint 4, para ser
// compartilhada também com o diálogo de detalhe.
// ===========================================================================

class _OrcamentoMobileCard extends StatelessWidget {
  final Orcamento orcamento;
  final VoidCallback onOpen;
  final Future<void> Function() onEdit;

  const _OrcamentoMobileCard({
    required this.orcamento,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final primary = resolvePrimaryOrcamentoAction(orcamento, context, provider);

    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: cliente + veículo à esquerda, status à direita.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orcamento.clienteNome,
                      style: AppText.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // veiculoDescricao já inclui a placa; PlateChip entra quando
                    // o model expuser a placa isolada.
                    Text(
                      orcamento.veiculoDescricao,
                      style: AppText.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              StatusPill(toAppStatus(orcamento.status)),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Valor.
          Text(Formatters.currency(orcamento.valorTotal), style: AppText.money),

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Linha de ações: primária (amarela) + PDF (ghost) + menu.
          Row(
            children: [
              if (primary != null) ...[
                Expanded(
                  child: PrimaryButton(
                    label: primary.label,
                    icon: primary.icon,
                    expanded: true,
                    onPressed: () => primary.onTap(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GhostButton(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () =>
                      OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
                ),
              ] else ...[
                GhostButton(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () =>
                      OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
                ),
                const Spacer(),
              ],
              const SizedBox(width: AppSpacing.sm),
              buildOrcamentoMenu(context, provider, orcamento, onEdit: onEdit),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// TOOLBAR — inalterada nesta sprint (exceto correção do typo).
// ===========================================================================

class _OrcToolbar extends StatelessWidget {
  final bool isMobile;
  final TextEditingController controller;
  final _OrcSort sort;
  final int totalCount;
  final ValueChanged<_OrcSort> onSortChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onChanged;

  const _OrcToolbar({
    required this.isMobile,
    required this.controller,
    required this.sort,
    required this.totalCount,
    required this.onSortChanged,
    required this.onClearSearch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Correção do typo: 'orcamento' -> 'orçamento'.
    final countLabel =
        '$totalCount ${totalCount == 1 ? 'orçamento' : 'orçamentos'}';

    if (isMobile) {
      return Column(
        children: [
          _SearchField(
            controller: controller,
            hint: 'Buscar por cliente, veículo ou ID...',
            onChanged: onChanged,
            onClear: onClearSearch,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
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
              _CountChip(label: countLabel),
            ],
          ),
        ],
      );
    }

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
          width: 180,
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
        _CountChip(label: countLabel),
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

// ===========================================================================
// PARTE 4 — CARD DESKTOP (espelha o mesmo padrão do card mobile)
// ===========================================================================

class _OrcamentoPremiumCard extends StatelessWidget {
  final Orcamento orcamento;
  final VoidCallback onOpen;
  final Future<void> Function() onEdit;

  const _OrcamentoPremiumCard({
    required this.orcamento,
    required this.onOpen,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final primary = resolvePrimaryOrcamentoAction(orcamento, context, provider);

    return AppCard(
      onTap: onOpen,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orcamento.clienteNome,
                  style: AppText.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  orcamento.veiculoDescricao,
                  style: AppText.bodySecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          StatusPill(toAppStatus(orcamento.status)),
          const SizedBox(width: AppSpacing.lg),
          SizedBox(
            width: 110,
            child: Text(
              Formatters.currency(orcamento.valorTotal),
              style: AppText.money,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          if (primary != null) ...[
            PrimaryButton(
              label: primary.label,
              icon: primary.icon,
              onPressed: () => primary.onTap(),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          GhostButton(
            label: 'PDF',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () =>
                OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
          ),
          const SizedBox(width: AppSpacing.sm),
          buildOrcamentoMenu(context, provider, orcamento, onEdit: onEdit),
        ],
      ),
    );
  }
}

// ===========================================================================
// PARTE 3 — ESTADOS DE CARREGAMENTO E ERRO DA LISTA
// ===========================================================================

/// Barra retangular com pulso de opacidade (0.35↔0.70, 1.4s) — placeholder
/// de skeleton loading, seguindo a animação do handoff.
class _PulseBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _PulseBox({
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(4)),
  });

  @override
  State<_PulseBox> createState() => _PulseBoxState();
}

class _PulseBoxState extends State<_PulseBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) =>
          Opacity(opacity: _opacity.value, child: child),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// Linha de esqueleto — mesma silhueta do card real (info + pill + valor).
class _OrcamentoSkeletonRow extends StatelessWidget {
  const _OrcamentoSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _PulseBox(width: 160, height: 12),
                SizedBox(height: 8),
                _PulseBox(width: 120, height: 10),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _PulseBox(
            width: 80,
            height: 22,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _PulseBox(
            width: 64,
            height: 22,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ],
      ),
    );
  }
}

class _OrcamentosSkeletonList extends StatelessWidget {
  const _OrcamentosSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
      itemBuilder: (context, index) => const _OrcamentoSkeletonRow(),
    );
  }
}

/// Banner de erro ao carregar a lista do banco local, com "Tentar
/// novamente" chamando reloadActiveUserData().
class _OrcamentosErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _OrcamentosErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: isDesktop ? 72 : 56,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não foi possível carregar os dados do banco local.',
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(fontSize: isDesktop ? 18 : 15),
            ),
            const SizedBox(height: AppSpacing.xl),
            GhostButton(
              label: 'Tentar novamente',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}