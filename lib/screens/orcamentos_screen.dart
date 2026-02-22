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
import 'order_detail_screen.dart'; // ✅ abre a tela de detalhes

class OrcamentosScreen extends StatelessWidget {
  const OrcamentosScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

              if (ResponsiveUtils.isDesktop(context))
                _buildDesktopTabs(context, provider)
              else
                _buildMobileTabs(context, provider),
            ],
          ),
        );
      },
    );
  }

  void _showCreateOrcamentoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OrcamentoFormDialog(),
    );
  }

  Widget _buildDesktopTabs(BuildContext context, AppProvider provider) {
    return Expanded(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primaryYellow,
              unselectedLabelColor: AppColors.white,
              indicatorColor: AppColors.primaryYellow,
              tabs: [
                Tab(text: 'Pendentes'),
                Tab(text: 'Aprovados'),
                Tab(text: 'Em Andamento'),
                Tab(text: 'Concluídos'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrcamentosList(context, provider.orcamentosPendentes),
                  _buildOrcamentosList(context, provider.orcamentosAprovados),
                  _buildOrcamentosList(context, provider.orcamentosEmAndamento),
                  _buildOrcamentosList(context, provider.orcamentosConcluidos),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabs(BuildContext context, AppProvider provider) {
    return Expanded(
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primaryYellow,
              unselectedLabelColor: AppColors.white,
              indicatorColor: AppColors.primaryYellow,
              isScrollable: true,
              tabs: [
                Tab(text: 'Pendentes'),
                Tab(text: 'Aprovados'),
                Tab(text: 'Andamento'),
                Tab(text: 'Concluídos'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrcamentosList(context, provider.orcamentosPendentes),
                  _buildOrcamentosList(context, provider.orcamentosAprovados),
                  _buildOrcamentosList(context, provider.orcamentosEmAndamento),
                  _buildOrcamentosList(context, provider.orcamentosConcluidos),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrcamentosList(
    BuildContext context,
    List<Orcamento> orcamentos,
  ) {
    if (orcamentos.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.description_outlined,
        title: 'Nenhum orçamento nesta categoria',
        subtitle: '',
        actionLabel: 'Novo Orçamento',
        onAction: () => _showCreateOrcamentoDialog(context),
      );
    }

    return ListView.separated(
      itemCount: orcamentos.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: ResponsiveUtils.getCardSpacing(context)),
      itemBuilder: (context, index) {
        final orcamento = orcamentos[index];
        return _buildOrcamentoCard(context, orcamento);
      },
    );
  }

  Widget _buildOrcamentoCard(BuildContext context, Orcamento orcamento) {
    final statusColor = _statusColor(orcamento.status);

    // ✅ Subtitulo mais “profissional” e legível
    final subtitle =
        '${orcamento.veiculoDescricao} • ${Formatters.currency(orcamento.valorTotal)}';

    return ResponsiveListCard(
      title: orcamento.clienteNome,
      subtitle: subtitle,
      trailing: _StatusPill(
        text: orcamento.statusDescricao,
        color: statusColor,
        // bônus visual: mostra pago no concluído
        suffixIcon:
            (orcamento.status == OrcamentoStatus.concluido && orcamento.pago)
            ? Icons.verified
            : null,
      ),
      onTap: () => _openDetails(context, orcamento),
      actions: _buildOrcamentoActions(context, orcamento),
    );
  }

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

  void _openDetails(BuildContext context, Orcamento orcamento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orcamento: orcamento),
      ),
    );
  }

  List<Widget> _buildOrcamentoActions(
    BuildContext context,
    Orcamento orcamento,
  ) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final List<Widget> actions = [];

    switch (orcamento.status) {
      case OrcamentoStatus.pendente:
        actions.addAll([
          TextButton.icon(
            onPressed: () async {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => OrcamentoFormDialog(orcamentoEditar: orcamento),
              );
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Editar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryYellow,
            ),
          ),
          TextButton.icon(
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
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Aprovar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
          ),
          TextButton.icon(
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
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Cancelar'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ]);
        break;

      case OrcamentoStatus.aprovado:
        actions.add(
          TextButton.icon(
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
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Iniciar'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryYellow,
            ),
          ),
        );
        break;

      case OrcamentoStatus.emAndamento:
        actions.add(
          TextButton.icon(
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
            icon: const Icon(Icons.done, size: 16),
            label: const Text('Concluir'),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
          ),
        );
        break;

      case OrcamentoStatus.concluido:
        // ✅ Bônus de fluxo: se concluído e não pago, já dá pra registrar pagamento daqui
        if (!orcamento.pago) {
          actions.add(
            TextButton.icon(
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
              icon: const Icon(Icons.attach_money, size: 16),
              label: const Text('Receber'),
              style: TextButton.styleFrom(foregroundColor: AppColors.success),
            ),
          );
        }
        break;

      case OrcamentoStatus.cancelado:
        // sem ações principais
        break;
    }

    // ✅ PDF / Enviar ao cliente
    actions.add(
      TextButton.icon(
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
        icon: const Icon(Icons.picture_as_pdf, size: 16),
        label: const Text('Enviar PDF'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryYellow),
      ),
    );

    // ✅ Pré-visualizar / Imprimir (sem precisar salvar)
    actions.add(
      TextButton.icon(
        onPressed: () async {
          final filename = orcamento.status == OrcamentoStatus.concluido
              ? 'nota_servico_${orcamento.id}.pdf'
              : 'orcamento_${orcamento.id}.pdf';
          final title = orcamento.status == OrcamentoStatus.concluido ? 'Nota de Serviço' : 'Orçamento';
          await showPdfPreviewDialog(
            context,
            title: title,
            fileName: filename,
            buildPdf: (_) => PDFService.generateOrcamentoPdf(orcamento),
          );
        },
        icon: const Icon(Icons.print, size: 16),
        label: const Text('Imprimir'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryYellow),
      ),
    );

    // ✅ Excluir
    actions.add(
      TextButton.icon(
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
        icon: const Icon(Icons.delete_outline, size: 16),
        label: const Text('Excluir'),
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
      ),
    );

    return actions;
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
              fontWeight: FontWeight.w600,
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
