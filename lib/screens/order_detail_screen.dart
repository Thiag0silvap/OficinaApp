import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../models/orcamento.dart';
import '../providers/app_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/pdf_preview_dialog.dart';
import '../core/components/orcamento_form_dialog.dart';
import '../services/pdf_service.dart';

class OrderDetailScreen extends StatelessWidget {
  final Orcamento orcamento;
  const OrderDetailScreen({super.key, required this.orcamento});

  @override
  Widget build(BuildContext context) {
    // ✅ pega sempre a versão atualizada no provider
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final current = provider.orcamentos.firstWhere(
          (o) => o.id == orcamento.id,
          orElse: () => orcamento,
        );

        final status = current.status;
        final isConcluido = status == OrcamentoStatus.concluido;
        final isCancelado = status == OrcamentoStatus.cancelado;
        final isPago = current.pago;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhe da Ordem'),
            actions: [
              if (status == OrcamentoStatus.pendente)
                IconButton(
                  tooltip: 'Editar orçamento',
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => OrcamentoFormDialog(
                        orcamentoEditar: current,
                      ),
                    );
                  },
                ),
              IconButton(
                tooltip: 'Pré-visualizar / Imprimir',
                icon: const Icon(Icons.print),
                onPressed: () async {
                  final filename = current.status == OrcamentoStatus.concluido
                      ? 'nota_servico_${current.id}.pdf'
                      : 'orcamento_${current.id}.pdf';
                  final title = current.status == OrcamentoStatus.concluido ? 'Nota de Serviço' : 'Orçamento';
                  await showPdfPreviewDialog(
                    context,
                    title: title,
                    fileName: filename,
                    buildPdf: (_) => PDFService.generateOrcamentoPdf(current),
                  );
                },
              ),
              IconButton(
                tooltip: 'Enviar/Compartilhar PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () async => _sharePdf(context, current),
              ),
              PopupMenuButton<String>(
                tooltip: 'Mais opções',
                onSelected: (v) async {
                  if (v == 'save') {
                    await _savePdf(context, current);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'save', child: Text('Salvar PDF no aparelho')),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(orcamento: current),
                const SizedBox(height: 14),

                if (current.dataAprovacao != null ||
                    current.dataConclusao != null ||
                    current.dataPagamento != null)
                  _DatesCard(orcamento: current),

                const SizedBox(height: 14),
                _ItensCard(orcamento: current),

                const SizedBox(height: 14),
                if ((current.observacoes ?? '').trim().isNotEmpty)
                  _ObservacoesCard(text: current.observacoes!.trim()),

                const SizedBox(height: 18),
                _TotalCard(total: current.valorTotal),

                const SizedBox(height: 18),
                if (!isCancelado) _ActionsCard(orcamento: current),

                if (isCancelado) ...[
                  const SizedBox(height: 18),
                  _InfoBanner(
                    icon: Icons.cancel,
                    text: 'Orçamento cancelado. Nenhuma ação disponível.',
                    color: AppColors.error,
                  ),
                ],

                // ✅ se for concluído e pago, dá um “ok” visual
                if (isConcluido && isPago) ...[
                  const SizedBox(height: 18),
                  _InfoBanner(
                    icon: Icons.verified,
                    text: 'Pagamento confirmado em ${Formatters.dateShort(current.dataPagamento ?? DateTime.now())}.',
                    color: AppColors.success,
                  ),
                ],

                // ✅ se for concluído e NÃO pago, reforça pendência
                if (isConcluido && !isPago) ...[
                  const SizedBox(height: 18),
                  _InfoBanner(
                    icon: Icons.pending_actions,
                    text: 'Serviço concluído, mas o pagamento ainda não foi registrado.',
                    color: AppColors.warning,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== PDF =====================

  Future<void> _sharePdf(BuildContext context, Orcamento o) async {
    try {
      final bytes = await PDFService.generateOrcamentoPdf(o);
      final filename = o.status == OrcamentoStatus.concluido ? 'nota_servico_${o.id}.pdf' : 'orcamento_${o.id}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    }
  }

  Future<void> _savePdf(BuildContext context, Orcamento o) async {
    try {
      final bytes = await PDFService.generateOrcamentoPdf(o);
      final filename = o.status == OrcamentoStatus.concluido ? 'nota_servico_${o.id}.pdf' : 'orcamento_${o.id}.pdf';
      final savedPath = await _savePdfLocally(bytes, filename);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF salvo em: $savedPath')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar PDF: $e')),
      );
    }
  }

  Future<String> _savePdfLocally(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

// ===================== WIDGETS =====================

class _HeaderCard extends StatelessWidget {
  final Orcamento orcamento;
  const _HeaderCard({required this.orcamento});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(orcamento.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            orcamento.clienteNome,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            orcamento.veiculoDescricao,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusBadge(status: orcamento.status),
              const SizedBox(width: 10),
              _PaymentBadge(pago: orcamento.pago),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Criado: ${Formatters.dateShort(orcamento.dataCriacao)}',
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
        ],
      ),
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
}

class _DatesCard extends StatelessWidget {
  final Orcamento orcamento;
  const _DatesCard({required this.orcamento});

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime? d) => d == null ? '—' : Formatters.dateShort(d);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datas', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _kv('Aprovação', fmt(orcamento.dataAprovacao)),
          _kv('Conclusão', fmt(orcamento.dataConclusao)),
          _kv('Pagamento', fmt(orcamento.dataPagamento)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.grey)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ItensCard extends StatelessWidget {
  final Orcamento orcamento;
  const _ItensCard({required this.orcamento});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Serviços', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...orcamento.itens.map(
            (i) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i.servico,
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    Formatters.currency(i.valor),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservacoesCard extends StatelessWidget {
  final String text;
  const _ObservacoesCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Observações', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(
            Formatters.currency(total),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final Orcamento orcamento;
  const _ActionsCard({required this.orcamento});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final status = orcamento.status;
    final isPago = orcamento.pago;

    final actions = <Widget>[];

    // ✅ fluxo claro
    if (status == OrcamentoStatus.pendente) {
      actions.add(
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    'Cancelar orçamento?',
                    'Essa ação muda o status para cancelado.',
                  );
                  if (ok) await provider.cancelarOrcamento(orcamento.id);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Aprovar'),
                onPressed: () async {
                  final ok = await _confirm(
                    context,
                    'Aprovar orçamento?',
                    'Deseja aprovar este orçamento?',
                  );
                  if (ok) await provider.aprovarOrcamento(orcamento.id);
                },
              ),
            ),
          ],
        ),
      );
    }

    if (status == OrcamentoStatus.aprovado) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar serviço'),
            onPressed: () async {
              final ok = await _confirm(context, 'Iniciar serviço?', 'Deseja iniciar o serviço para esta ordem?');
              if (ok) await provider.iniciarServico(orcamento.id);
            },
          ),
        ),
      );
    }

    if (status == OrcamentoStatus.emAndamento) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.done),
            label: const Text('Concluir serviço'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final ok = await _confirm(
                context,
                'Concluir serviço?',
                'Marcar como concluído? (Pagamento será registrado depois)',
              );
              if (ok) await provider.concluirOrcamento(orcamento.id);
            },
          ),
        ),
      );
    }

    if (status == OrcamentoStatus.concluido && !isPago) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.attach_money),
            label: const Text('Registrar pagamento'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final ok = await _confirm(
                context,
                'Confirmar pagamento',
                'Confirmar pagamento de ${Formatters.currency(orcamento.valorTotal)}?',
              );
              if (ok) await provider.registrarPagamento(orcamento.id);
            },
          ),
        ),
      );
    }

    // nada a fazer
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ações', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...actions.map((w) {
            // Row com 2 botões já vem pronto no "pendente"
            if (w is Row) return w;
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: w);
          }),
          if (status == OrcamentoStatus.pendente) ...[
            // pendente já veio com 2 botões lado a lado
            // não precisa padding extra
          ],
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String content) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    return ok == true;
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final bool pago;
  const _PaymentBadge({required this.pago});

  @override
  Widget build(BuildContext context) {
    final color = pago ? AppColors.success : AppColors.warning;
    final text = pago ? 'Pago' : 'Pendente';
    final icon = pago ? Icons.check_circle : Icons.pending_actions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrcamentoStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case OrcamentoStatus.concluido:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case OrcamentoStatus.emAndamento:
        color = AppColors.info;
        icon = Icons.access_time_filled;
        break;
      case OrcamentoStatus.pendente:
        color = AppColors.warning;
        icon = Icons.warning;
        break;
      case OrcamentoStatus.aprovado:
        color = AppColors.primaryYellow;
        icon = Icons.thumb_up;
        break;
      case OrcamentoStatus.cancelado:
        color = AppColors.error;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(status.displayName, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
