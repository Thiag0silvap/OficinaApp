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
import '../core/components/app_snackbar.dart';
import '../core/utils/formatters.dart';
import '../providers/app_provider.dart';
import '../models/orcamento.dart';
import '../services/pdf_service.dart';
import '../services/pdf_file_service.dart';
import '../services/whatsapp_service.dart';
import '../core/widgets/pdf_preview_dialog.dart';
import 'order_detail_screen.dart';

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

    switch (sort) {
      case _OrcSort.recent:
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

        // Mobile: card redesenhado (design system). Desktop: card atual intacto.
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orcamento: orcamento),
      ),
    );
  }
}

// ===========================================================================
// SPRINT 1 — CARD MOBILE (novo, baseado no design system)
// ===========================================================================

/// Mapeia o status de domínio para o status visual do design system.
AppStatus _toAppStatus(OrcamentoStatus s) {
  switch (s) {
    case OrcamentoStatus.pendente:
      return AppStatus.pendente;
    case OrcamentoStatus.aprovado:
      return AppStatus.aprovado;
    case OrcamentoStatus.emAndamento:
      return AppStatus.emAndamento;
    case OrcamentoStatus.concluido:
      return AppStatus.concluido;
    case OrcamentoStatus.cancelado:
      return AppStatus.cancelado;
  }
}

/// Descreve a ação primária (amarela) de um card conforme o status.
class _PrimaryAction {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;
  const _PrimaryAction(this.label, this.icon, this.onTap);
}

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
    final primary = _resolvePrimary(context, provider);

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
              StatusPill(_toAppStatus(orcamento.status)),
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
                      _OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
                ),
              ] else ...[
                GhostButton(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: () =>
                      _OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
                ),
                const Spacer(),
              ],
              const SizedBox(width: AppSpacing.sm),
              _buildMenu(context, provider),
            ],
          ),
        ],
      ),
    );
  }

  /// Ação primária por status (mesma posição, sempre amarela).
  _PrimaryAction? _resolvePrimary(BuildContext context, AppProvider provider) {
    switch (orcamento.status) {
      case OrcamentoStatus.pendente:
        return _PrimaryAction(
          'Aprovar',
          Icons.check,
          () => _OrcamentoActions.aprovar(context, provider, orcamento),
        );
      case OrcamentoStatus.aprovado:
        return _PrimaryAction(
          'Iniciar',
          Icons.play_arrow,
          () => _OrcamentoActions.iniciar(context, provider, orcamento),
        );
      case OrcamentoStatus.emAndamento:
        return _PrimaryAction(
          'Concluir',
          Icons.done,
          () => _OrcamentoActions.concluir(context, provider, orcamento),
        );
      case OrcamentoStatus.concluido:
        if (!orcamento.pago) {
          return _PrimaryAction(
            'Receber',
            Icons.attach_money,
            () => _OrcamentoActions.receber(context, provider, orcamento),
          );
        }
        return null;
      case OrcamentoStatus.cancelado:
        return null;
    }
  }

  Widget _buildMenu(BuildContext context, AppProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
      color: AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
        side: const BorderSide(color: AppColors.line),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'editar':
            await onEdit();
            break;
          case 'imprimir':
            await _OrcamentoActions.imprimir(context, orcamento);
            break;
          case 'cancelar':
            await _OrcamentoActions.cancelar(context, provider, orcamento);
            break;
          case 'excluir':
            await _OrcamentoActions.excluir(context, provider, orcamento);
            break;
        }
      },
      itemBuilder: (_) => [
        if (orcamento.status == OrcamentoStatus.pendente)
          const PopupMenuItem(
            value: 'editar',
            child: Row(children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Editar'),
            ]),
          ),
        const PopupMenuItem(
          value: 'imprimir',
          child: Row(children: [
            Icon(Icons.print, size: 18),
            SizedBox(width: 8),
            Text('Imprimir'),
          ]),
        ),
        if (orcamento.status == OrcamentoStatus.pendente)
          const PopupMenuItem(
            value: 'cancelar',
            child: Row(children: [
              Icon(Icons.cancel, size: 18),
              SizedBox(width: 8),
              Text('Cancelar'),
            ]),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'excluir',
          child: Row(children: [
            const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ]),
        ),
      ],
    );
  }
}

/// Ações de negócio dos orçamentos — fonte única de verdade para o card mobile.
/// (O card desktop mantém suas chamadas inline até ser migrado.)
class _OrcamentoActions {
  const _OrcamentoActions._();

  static Future<void> aprovar(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.aprovarOrcamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Orçamento aprovado!', type: SnackType.success);
  }

  static Future<void> iniciar(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.iniciarServico(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Serviço iniciado!', type: SnackType.success);
  }

  static Future<void> concluir(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.concluirOrcamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Serviço concluído! Pagamento pendente.',
        type: SnackType.success);
  }

  static Future<void> receber(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.registrarPagamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Pagamento registrado!', type: SnackType.success);
  }

  static Future<void> cancelar(
      BuildContext context, AppProvider provider, Orcamento o) async {
    await provider.cancelarOrcamento(o.id);
    if (!context.mounted) return;
    AppSnackbar.show(context, 'Orçamento cancelado!', type: SnackType.info);
  }

  static Future<void> imprimir(BuildContext context, Orcamento o) async {
    final filename = PDFService.buildPdfFilename(o);
    final title =
        o.status == OrcamentoStatus.concluido ? 'Nota de Serviço' : 'Orçamento';
    await showPdfPreviewDialog(
      context,
      title: title,
      fileName: filename,
      buildPdf: (_) => PDFService.generateOrcamentoPdf(o),
    );
  }

  static Future<void> excluir(
      BuildContext context, AppProvider provider, Orcamento o) async {
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
      await provider.deleteOrcamento(o.id);
      if (!context.mounted) return;
      AppSnackbar.show(context, 'Orçamento excluído', type: SnackType.error);
    }
  }

  /// Gera PDF e abre o WhatsApp. Lógica preservada da versão original;
  /// o tratamento amigável do PlatformException fica para a Sprint 5.
  static Future<void> pdfWhatsapp(
      BuildContext context, AppProvider provider, Orcamento o) async {
    try {
      final cliente = provider.getClienteById(o.clienteId);
      if (cliente == null || cliente.telefone.trim().isEmpty) {
        if (!context.mounted) return;
        AppSnackbar.show(context, 'Cliente sem telefone cadastrado.',
            type: SnackType.info);
        return;
      }
      final bytes = await PDFService.generateOrcamentoPdf(o);
      final filename = PDFService.buildPdfFilename(o);
      final savedPath = await PdfFileService.savePdfToUserFolder(
        bytes: bytes,
        filename: filename,
      );
      final mensagem =
          'Olá ${o.clienteNome}, segue seu orçamento referente ao veículo '
          '${o.veiculoDescricao}.';
      await PdfFileService.openFileFolder(savedPath);
      await WhatsAppService.openChat(
        phone: cliente.telefone,
        message: mensagem,
      );
      if (!context.mounted) return;
      AppSnackbar.show(context, 'PDF gerado! Escolha o app para compartilhar.',
          type: SnackType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(context, 'Erro ao preparar envio: $e',
          type: SnackType.error);
    }
  }
}

// ===========================================================================
// DESKTOP + TOOLBAR — inalterados nesta sprint (exceto correção do typo).
// ===========================================================================

class _PremiumTabBar extends StatelessWidget {
  final bool isDesktop;
  const _PremiumTabBar({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
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

    return ResponsiveListCard(
      title: orcamento.clienteNome,
      subtitle: orcamento.veiculoDescricao,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusPill(
            text: orcamento.statusDescricao,
            color: statusColor,
            suffixIcon:
                (orcamento.status == OrcamentoStatus.concluido && orcamento.pago)
                ? Icons.verified
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(orcamento.valorTotal),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
      onTap: onOpen,
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final provider = Provider.of<AppProvider>(context, listen: false);
    final List<Widget> actions = [];

    // Ação principal por status
    switch (orcamento.status) {
      case OrcamentoStatus.pendente:
        actions.addAll([
          _ActionPill(
            icon: Icons.check,
            label: 'Aprovar',
            tone: _ActionTone.success,
            filled: true,
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
          if (!isMobile)
            _ActionPill(
              icon: Icons.edit,
              label: 'Editar',
              tone: _ActionTone.neutral,
              onPressed: onEdit,
            ),
          if (!isMobile)
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
            filled: true,
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
            filled: true,
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
              filled: true,
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

    // PDF + WhatsApp — sempre visível
    actions.add(
      _ActionPill(
        icon: Icons.chat,
        label: isMobile ? 'PDF' : 'PDF + WhatsApp',
        tone: _ActionTone.success,
        filled: true,
        onPressed: () async {
          try {
            final cliente = provider.getClienteById(orcamento.clienteId);
            if (cliente == null || cliente.telefone.trim().isEmpty) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente sem telefone cadastrado.'),
                ),
              );
              return;
            }
            final bytes = await PDFService.generateOrcamentoPdf(orcamento);
            final filename = PDFService.buildPdfFilename(orcamento);
            final savedPath = await PdfFileService.savePdfToUserFolder(
              bytes: bytes,
              filename: filename,
            );
            final mensagem =
                'Olá ${orcamento.clienteNome}, segue seu orçamento referente ao veículo '
                '${orcamento.veiculoDescricao}.';
            await PdfFileService.openFileFolder(savedPath);
            await WhatsAppService.openChat(
              phone: cliente.telefone,
              message: mensagem,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF gerado! Escolha o app para compartilhar.'),
                backgroundColor: AppColors.success,
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao preparar envio: $e')),
            );
          }
        },
      ),
    );

    // No mobile: botões secundários condensados num menu
    if (isMobile) {
      actions.add(
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz,
            color: AppColors.textSecondary,
          ),
          color: AppColors.secondaryGray,
          onSelected: (value) async {
            switch (value) {
              case 'editar':
                onEdit();
                break;
              case 'imprimir':
                final filename = PDFService.buildPdfFilename(orcamento);
                final title = orcamento.status == OrcamentoStatus.concluido
                    ? 'Nota de Serviço'
                    : 'Orçamento';
                await showPdfPreviewDialog(
                  context,
                  title: title,
                  fileName: filename,
                  buildPdf: (_) => PDFService.generateOrcamentoPdf(orcamento),
                );
                break;
              case 'cancelar':
                await provider.cancelarOrcamento(orcamento.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orçamento cancelado!')),
                );
                break;
              case 'excluir':
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
                break;
            }
          },
          itemBuilder: (_) => [
            if (orcamento.status == OrcamentoStatus.pendente)
              const PopupMenuItem(
                value: 'editar',
                child: Row(children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ]),
              ),
            const PopupMenuItem(
              value: 'imprimir',
              child: Row(children: [
                Icon(Icons.print, size: 18),
                SizedBox(width: 8),
                Text('Imprimir'),
              ]),
            ),
            if (orcamento.status == OrcamentoStatus.pendente)
              const PopupMenuItem(
                value: 'cancelar',
                child: Row(children: [
                  Icon(Icons.cancel, size: 18),
                  SizedBox(width: 8),
                  Text('Cancelar'),
                ]),
              ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'excluir',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Excluir', style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      );
    } else {
      // Desktop: botões completos
      actions.addAll([
        _ActionPill(
          icon: Icons.print,
          label: 'Imprimir',
          tone: _ActionTone.neutral,
          onPressed: () async {
            final filename = PDFService.buildPdfFilename(orcamento);
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
    }

    return actions;
  }
}

enum _ActionTone { primary, success, danger, neutral }

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final _ActionTone tone;
  final bool filled;
  final VoidCallback onPressed;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.tone,
    this.filled = false,
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
    final background = filled ? fg : fg.withValues(alpha: 0.10);
    final foreground = filled
        ? ((tone == _ActionTone.primary) ? Colors.black : Colors.white)
        : fg;
    final borderColor = filled ? fg : fg.withValues(alpha: 0.35);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foreground,
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