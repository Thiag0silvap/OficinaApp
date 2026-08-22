import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../models/veiculo.dart';
import '../../providers/app_provider.dart';
import 'app_buttons.dart';
import 'cliente_form_dialog.dart';
import 'orcamento_form_dialog.dart';
import 'veiculo_form_fields.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'responsive_components.dart';

/// Menu de 3 pontos compartilhado entre o card da lista de clientes e o
/// header do modal de detalhe (mesmo padrão de `buildOrcamentoMenu`).
Widget buildClienteMenu(
  BuildContext context,
  AppProvider provider,
  Cliente cliente, {
  bool fecharModalAntes = false,
}) {
  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
    color: AppColors.elevated,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      side: const BorderSide(color: AppColors.line),
    ),
    onSelected: (value) {
      if (fecharModalAntes) Navigator.pop(context);

      switch (value) {
        case 'orcamento':
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => OrcamentoFormDialog(clientePreSelecionado: cliente),
          );
          break;
        case 'veiculo':
          showVeiculoFormDialog(context, cliente: cliente);
          break;
        case 'editar':
          showDialog(
            context: context,
            builder: (_) => ClienteFormDialog(clienteEditar: cliente),
          );
          break;
        case 'excluir':
          showDeleteClienteDialog(context, cliente, provider);
          break;
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'orcamento',
        child: Row(
          children: [
            Icon(Icons.description, size: 20),
            SizedBox(width: 8),
            Text('Novo Orçamento'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'veiculo',
        child: Row(
          children: [
            Icon(Icons.directions_car, size: 20),
            SizedBox(width: 8),
            Text('Add Veículo'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'editar',
        child: Row(
          children: [
            Icon(Icons.edit, size: 20),
            SizedBox(width: 8),
            Text('Editar'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'excluir',
        child: Row(
          children: [
            Icon(Icons.delete, size: 20, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('Excluir', style: TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
    ],
  );
}

/// Diálogo de confirmação de exclusão de cliente (movido de
/// clientes_screen.dart para cá, reestilizado com tokens do design system).
void showDeleteClienteDialog(
  BuildContext context,
  Cliente cliente,
  AppProvider provider,
) {
  final veiculosVinculados = provider.getVeiculosByCliente(cliente.id).length;
  final orcamentosVinculados = provider
      .getOrcamentosByCliente(cliente.id)
      .length;
  final isOrcamentoSingular = orcamentosVinculados == 1;
  bool isDeleting = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        return AlertDialog(
          backgroundColor: AppColors.elevated,
          title: const Text('Excluir Cliente', style: AppText.title),
          content: Text(
            'Excluir ${cliente.nome} vai ocultar $veiculosVinculados '
            'veículo${veiculosVinculados == 1 ? '' : 's'} da lista ativa. '
            '${isOrcamentoSingular ? 'O' : 'Os'} $orcamentosVinculados '
            'orçamento${isOrcamentoSingular ? '' : 's'} vinculado'
            '${isOrcamentoSingular ? '' : 's'} a ele continua'
            '${isOrcamentoSingular ? '' : 'm'} ativo'
            '${isOrcamentoSingular ? '' : 's'}.',
            style: AppText.bodySecondary,
          ),
          actions: [
            GhostButton(
              label: 'Cancelar',
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
            ),
            PrimaryButton(
              label: 'Ocultar',
              icon: Icons.visibility_off,
              isLoading: isDeleting,
              onPressed: () async {
                setState(() => isDeleting = true);
                try {
                  await provider.deleteCliente(cliente.id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } finally {
                  if (dialogContext.mounted) {
                    setState(() => isDeleting = false);
                  }
                }
              },
            ),
          ],
        );
      },
    ),
  );
}

void showVeiculoFormDialog(
  BuildContext context, {
  required Cliente cliente,
  Veiculo? veiculoEditar,
  void Function(Veiculo veiculo)? onSaved,
}) {
  final scaffoldContext = context;
  final formKey = GlobalKey<FormState>();
  final isEdit = veiculoEditar != null;
  final provider = Provider.of<AppProvider>(context, listen: false);
  final controller = isEdit
      ? VeiculoFormController.fromVeiculo(veiculoEditar, provider)
      : VeiculoFormController();
  bool isSaving = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        Future<void> submit() async {
          if (isSaving) return;
          if (!formKey.currentState!.validate()) return;
          setState(() => isSaving = true);

          final providerLocal = Provider.of<AppProvider>(
            scaffoldContext,
            listen: false,
          );

          final veiculo = controller.buildVeiculo(
            id:
                veiculoEditar?.id ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            clienteId: cliente.id,
          );

          try {
            await providerLocal.addMarcaModeloCustom(
              marca: controller.marcaFinal,
              modelo: controller.modeloFinal,
            );
            if (isEdit) {
              await providerLocal.updateVeiculo(veiculo);
            } else {
              await providerLocal.addVeiculo(veiculo);
            }
            if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
              Navigator.pop(dialogContext);
            }
            onSaved?.call(veiculo);
            if (scaffoldContext.mounted) {
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(
                  content: Text(
                    isEdit
                        ? 'Veículo atualizado com sucesso!'
                        : 'Veículo adicionado com sucesso!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          } catch (e) {
            if (scaffoldContext.mounted) {
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(content: Text('Erro ao salvar veículo: $e')),
              );
            }
          } finally {
            if (dialogContext.mounted) setState(() => isSaving = false);
          }
        }

        final dialog = ResponsiveDialog(
          title: isEdit
              ? 'Editar Veículo - ${cliente.nome}'
              : 'Novo Veículo - ${cliente.nome}',
          stackedActions: true,
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: formKey,
                child: VeiculoFormFields(controller: controller),
              ),
            ),
          ),
          actions: [
            GhostButton(
              label: 'Cancelar',
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
            ),
            PrimaryButton(
              label: 'Salvar',
              isLoading: isSaving,
              onPressed: submit,
            ),
          ],
        );

        return Focus(autofocus: false, child: dialog);
      },
    ),
  ).then((_) {
    Future.delayed(const Duration(milliseconds: 350), () {
      controller.dispose();
    });
  });
}
