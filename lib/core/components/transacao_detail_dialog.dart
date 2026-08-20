import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/orcamento.dart';
import '../../models/transacao.dart';
import '../../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';

class TransacaoDetailDialog extends StatelessWidget {
  final Transacao transacao;
  const TransacaoDetailDialog({super.key, required this.transacao});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        Orcamento? orcamentoVinculado;
        if (transacao.orcamentoId != null) {
          for (final o in provider.orcamentos) {
            if (o.id == transacao.orcamentoId) {
              orcamentoVinculado = o;
              break;
            }
          }
        }

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
                    _Header(transacao: transacao),
                    const SizedBox(height: AppSpacing.lg),
                    _DadosGeraisCard(transacao: transacao),
                    if (orcamentoVinculado != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _OrcamentoVinculadoCard(orcamento: orcamentoVinculado),
                    ],
                    if ((transacao.observacoes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _ObservacoesCard(text: transacao.observacoes!.trim()),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    GhostButton(
                      label: 'Fechar',
                      onPressed: () => Navigator.pop(context),
                    ),
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

class _Header extends StatelessWidget {
  final Transacao transacao;
  const _Header({required this.transacao});

  @override
  Widget build(BuildContext context) {
    final isEntrada = transacao.tipo == TipoTransacao.entrada;
    final badgeColor = isEntrada ? AppColors.success : AppColors.danger;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            isEntrada ? 'Entrada' : 'Saída',
            style: AppText.caption.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Spacer(),
        GhostIconButton(
          icon: Icons.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _DadosGeraisCard extends StatelessWidget {
  final Transacao transacao;
  const _DadosGeraisCard({required this.transacao});

  @override
  Widget build(BuildContext context) {
    final isEntrada = transacao.tipo == TipoTransacao.entrada;
    final valorColor = isEntrada ? AppColors.success : AppColors.danger;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');

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
          Text(
            transacao.descricao,
            style: AppText.title,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            money.format(transacao.valor),
            style: AppText.money.copyWith(color: valorColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 1,
            color: AppColors.line,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          ),
          const SizedBox(height: AppSpacing.xs),
          _kv('Categoria', transacao.categoria),
          _kv('Data', dateFmt.format(transacao.data)),
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

class _OrcamentoVinculadoCard extends StatelessWidget {
  final Orcamento orcamento;
  const _OrcamentoVinculadoCard({required this.orcamento});

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
          Text('ORÇAMENTO VINCULADO', style: AppText.label),
          const SizedBox(height: AppSpacing.sm),
          Text(
            orcamento.clienteNome,
            style: AppText.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(orcamento.veiculoDescricao, style: AppText.bodySecondary),
          const SizedBox(height: AppSpacing.xs),
          Text(
            orcamento.status.displayName,
            style: AppText.bodySecondary.copyWith(
              color: AppColors.primary,
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