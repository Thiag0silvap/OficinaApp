import 'package:flutter/material.dart';

import '../../models/orcamento.dart';
import '../../providers/app_provider.dart';

/// Abre o diálogo de cancelamento de orçamento, coletando um motivo.
///
/// Quando [motivoObrigatorio] é true (orçamento Em andamento), o campo de
/// motivo é validado como obrigatório. Caso contrário, é um diálogo de
/// confirmação simples com campo de observação opcional.
///
/// Retorna `null` se o usuário desistir do cancelamento; caso contrário
/// retorna o motivo informado (string vazia se deixado em branco quando
/// opcional).
Future<String?> showCancelarOrcamentoDialog(
  BuildContext context, {
  required bool motivoObrigatorio,
}) async {
  final motivoController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancelar orçamento?'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                motivoObrigatorio
                    ? 'Este orçamento está Em andamento. Informe o motivo do cancelamento.'
                    : 'Esta ação muda o status do orçamento para Cancelado.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoController,
                autofocus: motivoObrigatorio,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText:
                      motivoObrigatorio ? 'Motivo *' : 'Motivo (opcional)',
                ),
                validator: (v) {
                  if (!motivoObrigatorio) return null;
                  return (v == null || v.trim().isEmpty)
                      ? 'Informe o motivo do cancelamento'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Voltar'),
        ),
        TextButton(
          onPressed: () {
            if (motivoObrigatorio &&
                !(formKey.currentState?.validate() ?? false)) {
              return;
            }
            Navigator.of(ctx).pop(true);
          },
          child: const Text('Confirmar cancelamento'),
        ),
      ],
    ),
  );

  if (confirmed != true) {
    motivoController.dispose();
    return null;
  }
  final motivo = motivoController.text.trim();
  motivoController.dispose();
  return motivo;
}

/// Abre [showCancelarOrcamentoDialog] (motivo obrigatório apenas quando o
/// status atual é Em andamento) e, se confirmado, chama
/// `AppProvider.cancelarOrcamento`. Retorna `true` se o orçamento foi
/// cancelado, `false` se o usuário desistiu. Deixa exceções do provider
/// propagarem para quem chamou decidir como exibir o erro.
Future<bool> collectMotivoAndCancelarOrcamento(
  BuildContext context,
  AppProvider provider,
  Orcamento orcamento,
) async {
  final motivoObrigatorio = orcamento.status == OrcamentoStatus.emAndamento;
  final motivo = await showCancelarOrcamentoDialog(
    context,
    motivoObrigatorio: motivoObrigatorio,
  );
  if (motivo == null) return false;
  if (!context.mounted) return false;

  await provider.cancelarOrcamento(
    orcamento.id,
    motivo: motivo.isEmpty ? null : motivo,
  );
  return true;
}
