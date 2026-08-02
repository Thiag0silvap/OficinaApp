import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'status_pill.dart';
import 'app_snackbar.dart';
import 'cancelar_orcamento_dialog.dart';
import '../widgets/pdf_preview_dialog.dart';
import '../../models/orcamento.dart';
import '../../providers/app_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/pdf_file_service.dart';
import '../../services/whatsapp_service.dart';

/// Lógica de ações/UI de orçamento compartilhada entre o card da lista
/// (mobile e desktop, `orcamentos_screen.dart`) e o diálogo de detalhe
/// (`orcamento_detail_dialog.dart`) — fonte única de verdade, sem duplicar
/// a tabela de ação primária nem as regras do menu de 3 pontos.

/// Mapeia o status de domínio para o status visual do design system.
AppStatus toAppStatus(OrcamentoStatus s) {
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

/// Descreve a ação primária (amarela/bronze) de um card ou diálogo,
/// conforme o status.
class PrimaryOrcamentoAction {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;
  const PrimaryOrcamentoAction(this.label, this.icon, this.onTap);
}

/// Ação primária por status (mesma posição, sempre a cor de destaque) —
/// compartilhada entre o card mobile, o card desktop e o diálogo de
/// detalhe.
PrimaryOrcamentoAction? resolvePrimaryOrcamentoAction(
  Orcamento orcamento,
  BuildContext context,
  AppProvider provider,
) {
  switch (orcamento.status) {
    case OrcamentoStatus.pendente:
      return PrimaryOrcamentoAction(
        'Aprovar',
        Icons.check,
        () => OrcamentoActions.aprovar(context, provider, orcamento),
      );
    case OrcamentoStatus.aprovado:
      return PrimaryOrcamentoAction(
        'Iniciar',
        Icons.play_arrow,
        () => OrcamentoActions.iniciar(context, provider, orcamento),
      );
    case OrcamentoStatus.emAndamento:
      return PrimaryOrcamentoAction(
        'Concluir',
        Icons.done,
        () => OrcamentoActions.concluir(context, provider, orcamento),
      );
    case OrcamentoStatus.concluido:
      if (!orcamento.pago) {
        return PrimaryOrcamentoAction(
          'Receber',
          Icons.attach_money,
          () => OrcamentoActions.receber(context, provider, orcamento),
        );
      }
      return null;
    case OrcamentoStatus.cancelado:
      return null;
  }
}

/// Menu de 3 pontos (Editar/Imprimir/Cancelar/Excluir) — mesmas regras de
/// visibilidade por status, compartilhadas entre o card mobile, o desktop
/// e o diálogo de detalhe.
Widget buildOrcamentoMenu(
  BuildContext context,
  AppProvider provider,
  Orcamento orcamento, {
  required Future<void> Function() onEdit,
}) {
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
          await OrcamentoActions.imprimir(context, orcamento);
          break;
        case 'cancelar':
          await OrcamentoActions.cancelar(context, provider, orcamento);
          break;
        case 'excluir':
          await OrcamentoActions.excluir(context, provider, orcamento);
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
      if (orcamento.status == OrcamentoStatus.pendente ||
          orcamento.status == OrcamentoStatus.aprovado ||
          orcamento.status == OrcamentoStatus.emAndamento)
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

/// Ações de negócio dos orçamentos — fonte única de verdade para os cards
/// (lista) e o diálogo de detalhe.
class OrcamentoActions {
  const OrcamentoActions._();

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
    try {
      final cancelado =
          await collectMotivoAndCancelarOrcamento(context, provider, o);
      if (!cancelado) return;
      if (!context.mounted) return;
      AppSnackbar.show(context, 'Orçamento cancelado!', type: SnackType.info);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        'Erro ao cancelar orçamento: $e',
        type: SnackType.error,
      );
    }
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
