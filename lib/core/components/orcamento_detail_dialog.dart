import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/orcamento.dart';
import '../../providers/app_provider.dart';
import '../../services/pdf_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../utils/formatters.dart';
import 'app_buttons.dart';
import 'orcamento_actions.dart';
import 'orcamento_form_dialog.dart';
import 'responsive_components.dart';

/// Diálogo de detalhe do orçamento (Sprint 4). Substitui a antiga tela
/// cheia `OrderDetailScreen` (Navigator.push com AppBar própria) — agora é
/// um overlay de verdade, aberto via `showDialog` a partir de
/// `orcamentos_screen.dart._openDetails`.
///
/// Fecha com ✕ ou tap no scrim: o `showDialog`/`Dialog` do Flutter já cuida
/// disso por padrão (o `ModalBarrier` só recebe toque fora do conteúdo do
/// diálogo), então não precisa do `stopPropagation` manual que o protótipo
/// React precisava.
class OrcamentoDetailDialog extends StatelessWidget {
  final Orcamento orcamento;
  const OrcamentoDetailDialog({super.key, required this.orcamento});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // Sempre a versão mais atual no provider — o diálogo permanece
        // aberto entre ações (ex. aprovar não fecha o diálogo).
        final current = provider.orcamentos.firstWhere(
          (o) => o.id == orcamento.id,
          orElse: () => orcamento,
        );

        final isCancelado = current.status == OrcamentoStatus.cancelado;
        final isConcluido = current.status == OrcamentoStatus.concluido;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.modal),
                border: Border.all(color: AppColors.line),
              ),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(orcamento: current, provider: provider),
                    const SizedBox(height: AppSpacing.lg),

                    // Stepper de status (só leitura, derivado do status) —
                    // substituído pelo banner de cancelamento quando
                    // aplicável, igual ao handoff.
                    if (isCancelado)
                      _InfoBanner(
                        icon: Icons.cancel,
                        color: AppColors.danger,
                        text: (current.motivoCancelamento != null &&
                                current.motivoCancelamento!.trim().isNotEmpty)
                            ? 'Orçamento cancelado. Motivo: '
                                '${current.motivoCancelamento!.trim()}'
                            : 'Orçamento cancelado. Nenhuma ação disponível.',
                      )
                    else
                      _StatusStepper(status: current.status, pago: current.pago),

                    const SizedBox(height: AppSpacing.lg),
                    _ItensTotalCard(orcamento: current),

                    // Conteúdo que já existia na tela antiga e não tem
                    // equivalente no handoff (datas, observações, avisos de
                    // pagamento) — mantido integralmente, só reestilizado.
                    if (current.dataAprovacao != null ||
                        current.dataConclusao != null ||
                        current.dataPagamento != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _DatesCard(orcamento: current),
                    ],

                    if ((current.observacoes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _ObservacoesCard(text: current.observacoes!.trim()),
                    ],

                    if (isConcluido && current.pago) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _InfoBanner(
                        icon: Icons.verified,
                        color: AppColors.success,
                        text: 'Pagamento confirmado em '
                            '${Formatters.dateShort(current.dataPagamento ?? DateTime.now())}.',
                      ),
                    ],

                    if (isConcluido && !current.pago) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _InfoBanner(
                        icon: Icons.pending_actions,
                        color: AppColors.warning,
                        text: 'Serviço concluído, mas o pagamento ainda não '
                            'foi registrado.',
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    _FooterActions(orcamento: current, provider: provider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===========================================================================
// HEADER — cliente + veículo, menu de 3 pontos e fechar.
// ===========================================================================

class _Header extends StatelessWidget {
  final Orcamento orcamento;
  final AppProvider provider;
  const _Header({required this.orcamento, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
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
              const SizedBox(height: 2),
              Text(
                orcamento.veiculoDescricao,
                style: AppText.bodySecondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildMoreMenu(context, provider, orcamento),
        const SizedBox(width: AppSpacing.xs),
        GhostIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Menu de 3 pontos do diálogo de detalhe. Reúne as 4 ações que hoje ficam
/// na AppBar da tela antiga (editar/imprimir/compartilhar genérico/salvar
/// no aparelho) mais o "Cancelar" que hoje é um botão ao lado da ação
/// primária — como a ação primária agora é largura total (sem espaço ao
/// lado), Cancelar entra aqui, com a mesma regra de status de antes.
///
/// Diferente do `buildOrcamentoMenu` compartilhado com o card da lista:
/// este menu não tem "Excluir" (a tela de detalhe nunca ofereceu excluir)
/// e tem "Compartilhar"/"Salvar no aparelho", que só existem aqui.
Widget _buildMoreMenu(
  BuildContext context,
  AppProvider provider,
  Orcamento orcamento,
) {
  final podeCancelar = orcamento.status == OrcamentoStatus.pendente ||
      orcamento.status == OrcamentoStatus.aprovado ||
      orcamento.status == OrcamentoStatus.emAndamento;

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
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => OrcamentoFormDialog(orcamentoEditar: orcamento),
          );
          break;
        case 'imprimir':
          await OrcamentoActions.imprimir(context, orcamento);
          break;
        case 'compartilhar':
          await _sharePdfGeneric(context, orcamento);
          break;
        case 'salvar':
          await _savePdfToDevice(context, orcamento);
          break;
        case 'cancelar':
          await OrcamentoActions.cancelar(context, provider, orcamento);
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
          Text('Pré-visualizar / Imprimir'),
        ]),
      ),
      const PopupMenuItem(
        value: 'compartilhar',
        child: Row(children: [
          Icon(Icons.share, size: 18),
          SizedBox(width: 8),
          Text('Compartilhar (outro app)'),
        ]),
      ),
      const PopupMenuItem(
        value: 'salvar',
        child: Row(children: [
          Icon(Icons.save_alt, size: 18),
          SizedBox(width: 8),
          Text('Salvar PDF no aparelho'),
        ]),
      ),
      if (podeCancelar) ...[
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'cancelar',
          child: Row(children: [
            Icon(Icons.cancel, size: 18),
            SizedBox(width: 8),
            Text('Cancelar'),
          ]),
        ),
      ],
    ],
  );
}

/// Compartilhamento genérico via share sheet do SO (diferente do
/// `OrcamentoActions.pdfWhatsapp`, que salva local e abre o WhatsApp
/// direto). Lógica preservada da `OrderDetailScreen` original.
Future<void> _sharePdfGeneric(BuildContext context, Orcamento o) async {
  try {
    final bytes = await PDFService.generateOrcamentoPdf(o);
    final filename = PDFService.buildPdfFilename(o);

    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, filename));
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], subject: filename);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  } catch (e) {
    if (!context.mounted) return;
    AppFeedback.showError(context, 'Erro ao gerar PDF: $e');
  }
}

/// Salva o PDF nos documentos do app. Lógica preservada da
/// `OrderDetailScreen` original.
Future<void> _savePdfToDevice(BuildContext context, Orcamento o) async {
  try {
    final bytes = await PDFService.generateOrcamentoPdf(o);
    final filename = PDFService.buildPdfFilename(o);
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    if (!context.mounted) return;
    AppFeedback.showSuccess(context, 'PDF salvo em: ${file.path}');
  } catch (e) {
    if (!context.mounted) return;
    AppFeedback.showError(context, 'Erro ao salvar PDF: $e');
  }
}

// ===========================================================================
// STEPPER DE STATUS — só leitura, derivado de status + pago.
// ===========================================================================

class _StatusStepper extends StatelessWidget {
  final OrcamentoStatus status;
  final bool pago;
  const _StatusStepper({required this.status, required this.pago});

  static const _labels = [
    'Pendente',
    'Aprovado',
    'Em andamento',
    'Concluído',
    'Pago',
  ];

  /// Índice do passo atual entre os 5 rótulos acima. `cancelado` nunca
  /// chega aqui — o diálogo mostra o banner de cancelamento no lugar.
  int get _currentIndex {
    switch (status) {
      case OrcamentoStatus.pendente:
        return 0;
      case OrcamentoStatus.aprovado:
        return 1;
      case OrcamentoStatus.emAndamento:
        return 2;
      case OrcamentoStatus.concluido:
        return pago ? 4 : 3;
      case OrcamentoStatus.cancelado:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;

    return Row(
      children: List.generate(_labels.length, (i) {
        final isCurrent = i == current;
        final isAccented = i <= current;
        final dotColor = isAccented ? AppColors.primary : AppColors.line;

        return Expanded(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isCurrent ? 2 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 2,
                        )
                      : null,
                ),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isAccented
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ===========================================================================
// ITENS + TOTAL — card único (antes eram 2 containers separados).
// ===========================================================================

class _ItensTotalCard extends StatelessWidget {
  final Orcamento orcamento;
  const _ItensTotalCard({required this.orcamento});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nota: o campo `peca` do item nunca foi exibido aqui (só
          // servico + valor) — comportamento preservado, fora de escopo
          // desta sprint mudar o que é exibido.
          for (final item in orcamento.itens)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.servico,
                      style: AppText.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    Formatters.currency(item.valor),
                    style: AppText.bodySecondary.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            height: 1,
            color: AppColors.line,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppText.title),
              Text(
                Formatters.currency(orcamento.valorTotal),
                style: AppText.money,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// DATAS / OBSERVAÇÕES / BANNERS DE PAGAMENTO — sem equivalente no handoff,
// mantidos por decisão explícita (não perder funcionalidade), só
// reestilizados pros tokens novos.
// ===========================================================================

class _DatesCard extends StatelessWidget {
  final Orcamento orcamento;
  const _DatesCard({required this.orcamento});

  @override
  Widget build(BuildContext context) {
    String fmt(DateTime? d) => d == null ? '—' : Formatters.dateShort(d);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DATAS', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          _kv('Aprovação', fmt(orcamento.dataAprovacao)),
          _kv('Conclusão', fmt(orcamento.dataConclusao)),
          _kv('Pagamento', fmt(orcamento.dataPagamento)),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: AppText.bodySecondary),
          Text(
            v,
            style: AppText.bodySecondary.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
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
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OBSERVAÇÕES', style: AppText.label),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: AppText.bodySecondary),
        ],
      ),
    );
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// RODAPÉ — ação primária (largura total, com confirmação) + PDF/WhatsApp.
// ===========================================================================

class _FooterActions extends StatelessWidget {
  final Orcamento orcamento;
  final AppProvider provider;
  const _FooterActions({required this.orcamento, required this.provider});

  @override
  Widget build(BuildContext context) {
    final primary = resolvePrimaryOrcamentoAction(orcamento, context, provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primary != null) ...[
          PrimaryButton(
            label: primary.label,
            icon: primary.icon,
            expanded: true,
            onPressed: () => _confirmAndRun(context, orcamento, primary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        GhostButton(
          label: 'Enviar PDF / WhatsApp',
          icon: Icons.picture_as_pdf_outlined,
          onPressed: () =>
              OrcamentoActions.pdfWhatsapp(context, provider, orcamento),
        ),
      ],
    );
  }
}

/// Confirmação antes de avançar o status — só existe no diálogo de
/// detalhe (decisão explícita: a lista continua com ação de 1 toque, o
/// detalhe mantém essa trava extra, que já existia na tela antiga).
Future<void> _confirmAndRun(
  BuildContext context,
  Orcamento orcamento,
  PrimaryOrcamentoAction primary,
) async {
  final copy = _confirmCopyFor(orcamento);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(copy.title),
      content: Text(copy.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  if (ok == true) await primary.onTap();
}

class _ConfirmCopy {
  final String title;
  final String message;
  const _ConfirmCopy(this.title, this.message);
}

/// Textos de confirmação por status — portados da `OrderDetailScreen`
/// original (`_confirm` por ação).
_ConfirmCopy _confirmCopyFor(Orcamento o) {
  switch (o.status) {
    case OrcamentoStatus.pendente:
      return const _ConfirmCopy(
        'Aprovar orçamento?',
        'Deseja aprovar este orçamento?',
      );
    case OrcamentoStatus.aprovado:
      return const _ConfirmCopy(
        'Iniciar serviço?',
        'Deseja iniciar o serviço para esta ordem?',
      );
    case OrcamentoStatus.emAndamento:
      return const _ConfirmCopy(
        'Concluir serviço?',
        'Marcar como concluído? (Pagamento será registrado depois)',
      );
    case OrcamentoStatus.concluido:
      return _ConfirmCopy(
        'Confirmar pagamento',
        'Confirmar pagamento de ${Formatters.currency(o.valorTotal)}?',
      );
    case OrcamentoStatus.cancelado:
      // Sem ação primária quando cancelado — nunca chamado neste estado.
      return const _ConfirmCopy('', '');
  }
}
